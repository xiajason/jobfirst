package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"resume-centre/shared/infrastructure"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/hashicorp/consul/api"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var (
	consulClient *api.Client
	logger       *logrus.Logger
	redisClient  *redis.Client
	db           *gorm.DB
)

func main() {
	// 初始化日志
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})
	logger.SetOutput(os.Stdout)

	// 加载配置
	if err := loadConfig(); err != nil {
		logger.Fatalf("Failed to load config: %v", err)
	}

	// 初始化数据库
	if err := initDatabase(); err != nil {
		logger.Fatalf("Failed to init database: %v", err)
	}

	// 初始化Consul客户端
	if err := initConsulClient(); err != nil {
		logger.Fatalf("Failed to init consul client: %v", err)
	}

	// 初始化Redis客户端
	if err := initRedisClient(); err != nil {
		logger.Fatalf("Failed to init redis client: %v", err)
	}

	// 注册服务到Consul
	if err := registerService(); err != nil {
		logger.Fatalf("Failed to register service: %v", err)
	}

	// 启动HTTP服务器
	router := setupRouter()
	port := viper.GetString("server.port")
	if port == "" {
		port = "8081"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		logger.Infof("Starting points service on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

	// 注销服务
	if err := deregisterService(); err != nil {
		logger.Errorf("Failed to deregister service: %v", err)
	}

	// 优雅关闭服务器
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatalf("Server forced to shutdown: %v", err)
	}

	logger.Info("Server exited")
}

func loadConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 设置默认值
	viper.SetDefault("consul.address", "localhost:8202")
	viper.SetDefault("consul.datacenter", "dc1")
	viper.SetDefault("server.port", "9004")
	viper.SetDefault("redis.address", "localhost:8201")
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 8200)
	viper.SetDefault("database.name", "jobfirst")
	viper.SetDefault("database.user", "jobfirst")
	viper.SetDefault("database.password", "jobfirst123")

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		logger.Warnf("Failed to read config file: %v", err)
	}

	// 绑定环境变量
	viper.AutomaticEnv()
	viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))

	// 如果环境变量存在，则覆盖配置文件中的值
	if consulAddr := os.Getenv("CONSUL_ADDRESS"); consulAddr != "" {
		viper.Set("consul.address", consulAddr)
	}
	if redisAddr := os.Getenv("REDIS_ADDRESS"); redisAddr != "" {
		viper.Set("redis.address", redisAddr)
	}
	if mysqlAddr := os.Getenv("MYSQL_ADDRESS"); mysqlAddr != "" {
		viper.Set("database.host", mysqlAddr)
	}
	if mysqlUser := os.Getenv("MYSQL_USER"); mysqlUser != "" {
		viper.Set("database.user", mysqlUser)
	}
	if mysqlPassword := os.Getenv("MYSQL_PASSWORD"); mysqlPassword != "" {
		viper.Set("database.password", mysqlPassword)
	}
	if mysqlDatabase := os.Getenv("MYSQL_DATABASE"); mysqlDatabase != "" {
		viper.Set("database.name", mysqlDatabase)
	}

	return nil
}

func initDatabase() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.host"),
		viper.GetInt("database.port"),
		viper.GetString("database.name"),
	)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// 自动迁移
	if err := db.AutoMigrate(&User{}); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
	}

	logger.Info("Successfully connected to database")
	return nil
}

func initConsulClient() error {
	config := api.DefaultConfig()
	config.Address = viper.GetString("consul.address")
	config.Datacenter = viper.GetString("consul.datacenter")

	var err error
	consulClient, err = api.NewClient(config)
	if err != nil {
		return fmt.Errorf("failed to create consul client: %v", err)
	}

	// 测试连接
	_, err = consulClient.Agent().Self()
	if err != nil {
		return fmt.Errorf("failed to connect to consul: %v", err)
	}

	logger.Info("Successfully connected to Consul")
	return nil
}

func initRedisClient() error {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     viper.GetString("redis.address"),
		Password: viper.GetString("redis.password"),
		DB:       viper.GetInt("redis.db"),
	})

	// 测试连接
	ctx := context.Background()
	_, err := redisClient.Ping(ctx).Result()
	if err != nil {
		return fmt.Errorf("failed to connect to redis: %v", err)
	}

	logger.Info("Successfully connected to Redis")
	return nil
}

func registerService() error {
	serviceAddress := "localhost"
	serviceID := "points-service"
	serviceName := "points-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"points", "reward", "api"},
		// 暂时注释掉健康检查，避免服务不稳定
		// Check: &api.AgentServiceCheck{
		// 	HTTP:                           fmt.Sprintf("http://%s:%d/health", serviceAddress, viper.GetInt("server.port")),
		// 	Interval:                       "10s",
		// 	Timeout:                        "5s",
		// 	DeregisterCriticalServiceAfter: "30s",
		// },
	}

	err := consulClient.Agent().ServiceRegister(registration)
	if err != nil {
		return fmt.Errorf("failed to register service: %v", err)
	}

	logger.Info("Service registered to Consul")
	return nil
}

func deregisterService() error {
	// 使用服务ID而不是服务名称进行注销
	serviceID := "points-service"
	err := consulClient.Agent().ServiceDeregister(serviceID)
	if err != nil {
		// 如果服务已经不存在，这不是一个错误
		if strings.Contains(err.Error(), "Unknown service ID") || strings.Contains(err.Error(), "404") {
			logger.Info("Service already deregistered from Consul")
			return nil
		}
		return fmt.Errorf("failed to deregister service: %v", err)
	}

	logger.Info("Service deregistered from Consul")
	return nil
}

func setupRouter() *gin.Engine {
	router := gin.Default()

	// 添加metrics中间件
	router.Use(infrastructure.RequestMetricsMiddleware())

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		infrastructure.SetServiceHealth(true)
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		})
	})

	// Metrics端点
	router.GET("/metrics", infrastructure.GetMetricsHandler())
	router.GET("/v1/.well-known/metrics", infrastructure.GetMetricsHandler())

	// Swagger API文档 - 白名单路由
	router.GET("/v2/api-docs", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"swagger": "2.0",
			"info": gin.H{
				"title":       "JobFirst Points Service API",
				"description": "积分服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "points@jobfirst.com",
				},
			},
			"host":     "localhost:9004",
			"basePath": "/points",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/points/rules": gin.H{
					"get": gin.H{
						"summary":     "获取积分规则",
						"description": "获取积分获取和消费规则",
						"tags":        []string{"积分规则"},
						"responses": gin.H{
							"200": gin.H{
								"description": "获取成功",
								"schema": gin.H{
									"type": "object",
									"properties": gin.H{
										"code":    gin.H{"type": "integer", "example": 200},
										"message": gin.H{"type": "string", "example": "success"},
										"data": gin.H{
											"type": "array",
											"items": gin.H{
												"type": "object",
												"properties": gin.H{
													"action":      gin.H{"type": "string", "example": "注册"},
													"description": gin.H{"type": "string", "example": "新用户注册奖励"},
													"points":      gin.H{"type": "integer", "example": 100},
												},
											},
										},
									},
								},
							},
						},
					},
				},
				"/points/balance": gin.H{
					"get": gin.H{
						"summary":     "获取积分余额",
						"description": "获取用户积分余额（需要认证）",
						"tags":        []string{"积分管理"},
						"security":    []gin.H{{"Bearer": []string{}}},
						"responses": gin.H{
							"200": gin.H{
								"description": "获取成功",
								"schema": gin.H{
									"type": "object",
									"properties": gin.H{
										"code":    gin.H{"type": "integer", "example": 200},
										"message": gin.H{"type": "string", "example": "success"},
										"data": gin.H{
											"type": "object",
											"properties": gin.H{
												"balance": gin.H{"type": "integer", "example": 100},
											},
										},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"PointsRule": gin.H{
					"type": "object",
					"properties": gin.H{
						"action":      gin.H{"type": "string", "example": "注册"},
						"description": gin.H{"type": "string", "example": "新用户注册奖励"},
						"points":      gin.H{"type": "integer", "example": 100},
					},
				},
			},
		})
	})

	// 积分服务上下文路径 - 兼容原有系统
	points := router.Group("/points")
	{
		// 公开的积分API（不需要认证）
		points.GET("/rules", getPointsRules)
		points.GET("/levels", getPointsLevels)
		points.GET("/rewards", getPointsRewards)

		// 需要认证的积分管理API
		authPoints := points.Group("")
		authPoints.Use(authMiddleware())
		{
			// 积分查询
			authPoints.GET("/balance", getPointsBalance)
			authPoints.GET("/history", getPointsHistory)
			authPoints.GET("/transactions", getTransactions)
			authPoints.GET("/summary", getPointsSummary)

			// 积分操作
			authPoints.POST("/earn", earnPoints)
			authPoints.POST("/spend", spendPoints)
			authPoints.POST("/transfer", transferPoints)
			authPoints.POST("/exchange", exchangePoints)

			// 积分任务
			authPoints.GET("/tasks", getPointsTasks)
			authPoints.POST("/tasks/complete", completePointsTask)
			authPoints.GET("/tasks/progress", getTaskProgress)

			// 积分商城
			authPoints.GET("/mall/items", getMallItems)
			authPoints.POST("/mall/purchase", purchaseMallItem)
			authPoints.GET("/mall/orders", getMallOrders)
		}
	}

	// API路由 - 兼容小程序
	api := router.Group("/api/v1")
	{
		// 小程序兼容路由
		pointsAPI := api.Group("/points")
		{
			// 公开的积分API（不需要认证）
			pointsAPI.GET("/rules", getPointsRules)
			pointsAPI.GET("/levels", getPointsLevels)
			pointsAPI.GET("/rewards", getPointsRewards)

			// 需要认证的积分管理API
			authPointsAPI := pointsAPI.Group("")
			authPointsAPI.Use(authMiddleware())
			{
				// 积分查询
				authPointsAPI.GET("/balance", getPointsBalance)
				authPointsAPI.GET("/history", getPointsHistory)
				authPointsAPI.GET("/transactions", getTransactions)
				authPointsAPI.GET("/summary", getPointsSummary)

				// 积分操作
				authPointsAPI.POST("/earn", earnPoints)
				authPointsAPI.POST("/spend", spendPoints)
				authPointsAPI.POST("/transfer", transferPoints)
				authPointsAPI.POST("/exchange", exchangePoints)

				// 积分任务
				authPointsAPI.GET("/tasks", getPointsTasks)
				authPointsAPI.POST("/tasks/complete", completePointsTask)
				authPointsAPI.GET("/tasks/progress", getTaskProgress)

				// 积分商城
				authPointsAPI.GET("/mall/items", getMallItems)
				authPointsAPI.POST("/mall/purchase", purchaseMallItem)
				authPointsAPI.GET("/mall/orders", getMallOrders)
			}
		}
	}

	return router
}

// 用户模型
type User struct {
	ID           uint       `json:"id" gorm:"primaryKey;autoIncrement"`
	Username     string     `json:"username" gorm:"type:varchar(50);uniqueIndex;not null"`
	Email        string     `json:"email" gorm:"type:varchar(100);uniqueIndex;not null"`
	PasswordHash string     `json:"-" gorm:"column:password_hash;type:varchar(255);not null"`
	Phone        string     `json:"phone" gorm:"type:varchar(20)"`
	AvatarURL    string     `json:"avatar_url" gorm:"column:avatar_url;type:varchar(255)"`
	Status       string     `json:"status" gorm:"type:enum('active','inactive','banned');default:'active'"`
	CreatedAt    time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt    *time.Time `json:"deleted_at" gorm:"index"`
}

// 注册用户
func registerUser(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=6"`
		Phone    string `json:"phone"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 检查用户是否已存在
	var existingUser User
	if err := db.Where("username = ? OR email = ?", req.Username, req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "User already exists"})
		return
	}

	// 加密密码
	hashedPassword, err := hashPassword(req.Password)
	if err != nil {
		logger.Errorf("Failed to hash password: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	// 创建用户
	user := User{
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: hashedPassword,
		Phone:        req.Phone,
		Status:       "active",
	}

	if err := db.Create(&user).Error; err != nil {
		logger.Errorf("Failed to create user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "User registered successfully",
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
		},
	})
}

// 用户登录
func loginUser(c *gin.Context) {
	var req struct {
		Username string `json:"username" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 查找用户
	var user User
	if err := db.Where("username = ? OR email = ?", req.Username, req.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 验证密码
	if !checkPasswordHash(req.Password, user.PasswordHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 生成JWT token
	token, err := generateToken(user.ID, user.Username)
	if err != nil {
		logger.Errorf("Failed to generate token: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Login successful",
		"token":   token,
		"user": gin.H{
			"id":       user.ID,
			"username": user.Username,
			"email":    user.Email,
		},
	})
}

// 用户登出
func logoutUser(c *gin.Context) {
	// 这里可以实现token黑名单逻辑
	c.JSON(http.StatusOK, gin.H{"message": "Logout successful"})
}

// 获取用户资料
func getUserProfile(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var user User
	if err := db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"user": user})
}

// 更新用户资料
func updateUserProfile(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Email  string `json:"email"`
		Phone  string `json:"phone"`
		Avatar string `json:"avatar"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user User
	if err := db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// 更新字段
	if req.Email != "" {
		user.Email = req.Email
	}
	if req.Phone != "" {
		user.Phone = req.Phone
	}
	if req.Avatar != "" {
		user.AvatarURL = req.Avatar
	}

	if err := db.Save(&user).Error; err != nil {
		logger.Errorf("Failed to update user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User updated successfully",
		"user":    user,
	})
}

// 删除用户
func deleteUser(c *gin.Context) {
	userID := c.Param("id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User ID is required"})
		return
	}

	if err := db.Delete(&User{}, userID).Error; err != nil {
		logger.Errorf("Failed to delete user: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User deleted successfully"})
}

// 认证中间件
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		// 移除Bearer前缀
		if strings.HasPrefix(token, "Bearer ") {
			token = token[7:]
		}

		// 简化认证：接受test-token或wx-token-123
		if token == "test-token" || token == "wx-token-123" {
			// 设置默认用户信息
			c.Set("userID", uint(1))
			c.Next()
			return
		}

		// 这里应该验证token，暂时简化处理
		if !strings.HasPrefix(token, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		// 设置用户ID到上下文（简化处理）
		c.Set("userID", uint(1))
		c.Next()
	}
}

// 从上下文获取用户ID
func getUserIDFromContext(c *gin.Context) uint {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(uint); ok {
			return id
		}
	}
	return 0
}

// 密码加密和验证函数（需要实现）
func hashPassword(password string) (string, error) {
	// 这里应该使用bcrypt或其他加密算法
	// 为了简化，这里返回原密码
	return password, nil
}

func checkPasswordHash(password, hash string) bool {
	// 这里应该验证密码哈希
	// 为了简化，这里直接比较
	return password == hash
}

// JWT token生成和验证函数（需要实现）
func generateToken(userID uint, username string) (string, error) {
	// 这里应该生成JWT token
	// 为了简化，这里返回一个简单的字符串
	return fmt.Sprintf("token_%d_%s", userID, username), nil
}

func validateToken(tokenString string) (uint, string, error) {
	// 这里应该验证JWT token
	// 为了简化，这里解析简单的token格式
	var userID uint
	var username string
	_, err := fmt.Sscanf(tokenString, "token_%d_%s", &userID, &username)
	if err != nil {
		return 0, "", err
	}
	return userID, username, nil
}

// 获取积分余额
func getPointsBalance(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    gin.H{"balance": 100},
	})
}

// 获取积分历史
func getPointsHistory(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "amount": 10, "type": "earn", "description": "完成任务", "time": "2025-08-30"},
			{"id": 2, "amount": -5, "type": "spend", "description": "下载简历", "time": "2025-08-29"},
		},
	})
}

// 赚取积分
func earnPoints(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "积分赚取成功",
		"data":    gin.H{"earned": 10, "new_balance": 110},
	})
}

// 消费积分
func spendPoints(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "积分消费成功",
		"data":    gin.H{"spent": 5, "new_balance": 95},
	})
}

// 获取交易记录
func getTransactions(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "amount": 10, "type": "earn", "description": "完成任务", "time": "2025-08-30"},
			{"id": 2, "amount": -5, "type": "spend", "description": "下载简历", "time": "2025-08-29"},
		},
	})
}

// ========== 积分服务处理函数 ==========

// 获取积分规则
func getPointsRules(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"action": "注册", "points": 100, "description": "新用户注册奖励"},
			{"action": "完善简历", "points": 50, "description": "完善个人简历信息"},
			{"action": "每日签到", "points": 10, "description": "每日签到奖励"},
			{"action": "发布职位", "points": 20, "description": "企业发布职位奖励"},
		},
	})
}

// 获取积分等级
func getPointsLevels(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"level": 1, "name": "新手", "min_points": 0, "max_points": 999, "benefits": "基础功能"},
			{"level": 2, "name": "进阶", "min_points": 1000, "max_points": 4999, "benefits": "优先推荐"},
			{"level": 3, "name": "专家", "min_points": 5000, "max_points": 19999, "benefits": "VIP服务"},
			{"level": 4, "name": "大师", "min_points": 20000, "max_points": 99999, "benefits": "专属客服"},
			{"level": 5, "name": "传奇", "min_points": 100000, "max_points": 999999, "benefits": "定制服务"},
		},
	})
}

// 获取积分奖励
func getPointsRewards(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "简历下载券", "points": 100, "description": "可下载一份简历"},
			{"id": 2, "name": "职位置顶券", "points": 200, "description": "职位置顶24小时"},
			{"id": 3, "name": "VIP体验券", "points": 500, "description": "VIP功能体验7天"},
		},
	})
}

// 获取积分汇总
func getPointsSummary(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": gin.H{
			"total_earned":    1500,
			"total_spent":     800,
			"current_balance": 700,
			"current_level":   2,
			"level_name":      "进阶",
			"next_level":      3,
			"points_to_next":  4300,
		},
	})
}

// 转移积分
func transferPoints(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "积分转移成功",
		"data": gin.H{
			"transferred": 50,
			"new_balance": 650,
			"target_user": "user123",
		},
	})
}

// 兑换积分
func exchangePoints(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "积分兑换成功",
		"data": gin.H{
			"exchanged":   100,
			"reward":      "简历下载券",
			"new_balance": 600,
		},
	})
}

// 获取积分任务
func getPointsTasks(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "每日签到", "points": 10, "completed": true, "description": "每日签到获得积分"},
			{"id": 2, "name": "完善简历", "points": 50, "completed": false, "description": "完善个人简历信息"},
			{"id": 3, "name": "发布职位", "points": 20, "completed": false, "description": "发布一个新职位"},
		},
	})
}

// 完成任务
func completePointsTask(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "任务完成成功",
		"data": gin.H{
			"task_id":       2,
			"earned_points": 50,
			"new_balance":   750,
		},
	})
}

// 获取任务进度
func getTaskProgress(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": gin.H{
			"daily_tasks":          1,
			"weekly_tasks":         3,
			"monthly_tasks":        8,
			"completed_today":      1,
			"completed_this_week":  2,
			"completed_this_month": 5,
		},
	})
}

// 获取商城商品
func getMallItems(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "简历下载券", "points": 100, "stock": 50, "description": "可下载一份简历"},
			{"id": 2, "name": "职位置顶券", "points": 200, "stock": 30, "description": "职位置顶24小时"},
			{"id": 3, "name": "VIP体验券", "points": 500, "stock": 10, "description": "VIP功能体验7天"},
		},
	})
}

// 购买商城商品
func purchaseMallItem(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "购买成功",
		"data": gin.H{
			"order_id":     "ORD123456",
			"item_name":    "简历下载券",
			"points_spent": 100,
			"new_balance":  650,
		},
	})
}

// 获取商城订单
func getMallOrders(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": "ORD123456", "item": "简历下载券", "points": 100, "status": "completed", "time": "2025-08-30"},
			{"id": "ORD123457", "item": "职位置顶券", "points": 200, "status": "pending", "time": "2025-08-29"},
		},
	})
}
