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
		logger.Infof("Starting storage service on port %s", port)
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
	viper.SetDefault("consul.address", "localhost:8500")
	viper.SetDefault("consul.datacenter", "dc1")
	viper.SetDefault("server.port", "8081")
	viper.SetDefault("redis.address", "localhost:6379")
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 3306)
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
	// 在Docker环境中，使用容器名称作为地址
	serviceAddress := "storage-service"
	if viper.GetString("server.host") != "localhost" {
		serviceAddress = viper.GetString("server.host")
	}

	registration := &api.AgentServiceRegistration{
		ID:      "storage-service",
		Name:    "storage-service",
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"storage", "file"},
		Check: &api.AgentServiceCheck{
			HTTP:                           fmt.Sprintf("http://localhost:%d/health", viper.GetInt("server.port")),
			Interval:                       "10s",
			Timeout:                        "5s",
			DeregisterCriticalServiceAfter: "30s",
		},
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
	serviceID := "storage-service"
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

	// API路由
	api := router.Group("/api/v1")
	{
		// 用户认证
		auth := api.Group("/auth")
		{
			auth.POST("/register", registerUser)
			auth.POST("/login", loginUser)
			auth.POST("/logout", logoutUser)
		}

		// 用户管理
		users := api.Group("/users")
		users.Use(authMiddleware())
		{
			users.GET("/profile", getUserProfile)
			users.PUT("/profile", updateUserProfile)
			users.DELETE("/:id", deleteUser)
		}

		// 资源管理
		resources := api.Group("/resources")
		resources.Use(authMiddleware())
		{
			resources.GET("/urls", getResourceUrls)
			resources.GET("/urls/:id", getResourceUrl)
			resources.GET("/dict/types", getDictTypeList)
			resources.GET("/dict/data", getDictData)
			resources.GET("/schools", searchSchool)
			resources.POST("/upload", uploadResource)
			resources.DELETE("/:id", deleteResource)
			resources.PUT("/:id", updateResource)
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
		if len(token) > 7 && token[:7] == "Bearer " {
			token = token[7:]
		}

		// 验证JWT token
		userID, username, err := validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文
		c.Set("user_id", userID)
		c.Set("username", username)
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

// 获取多个资源URL
func getResourceUrls(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "url": "https://example.com/resource1.jpg", "type": "image"},
			{"id": 2, "url": "https://example.com/resource2.pdf", "type": "document"},
		},
	})
}

// 获取单个资源URL
func getResourceUrl(c *gin.Context) {
	resourceID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    gin.H{"id": resourceID, "url": "https://example.com/resource" + resourceID + ".jpg"},
	})
}

// 获取字典类型列表
func getDictTypeList(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "学历类型", "code": "education"},
			{"id": 2, "name": "工作经验", "code": "experience"},
		},
	})
}

// 获取字典数据
func getDictData(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "label": "本科", "value": "bachelor"},
			{"id": 2, "label": "硕士", "value": "master"},
			{"id": 3, "label": "博士", "value": "phd"},
		},
	})
}

// 搜索学校
func searchSchool(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "清华大学", "code": "tsinghua"},
			{"id": 2, "name": "北京大学", "code": "pku"},
		},
	})
}

// 上传资源
func uploadResource(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "资源上传成功",
		"data":    gin.H{"id": 1, "url": "https://example.com/uploaded.jpg"},
	})
}

// 删除资源
func deleteResource(c *gin.Context) {
	resourceID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "资源删除成功",
		"data":    gin.H{"id": resourceID},
	})
}

// 更新资源
func updateResource(c *gin.Context) {
	resourceID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "资源更新成功",
		"data":    gin.H{"id": resourceID},
	})
}
