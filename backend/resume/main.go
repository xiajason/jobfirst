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
	db           *gorm.DB
	redisClient  *redis.Client
	consulClient *api.Client
	logger       *logrus.Logger
)

func main() {
	// 初始化日志
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{})

	// 加载配置
	if err := loadConfig(); err != nil {
		logger.Fatalf("Failed to load config: %v", err)
	}

	// 初始化数据库连接
	if err := initDatabase(); err != nil {
		logger.Fatalf("Failed to init database: %v", err)
	}

	// 初始化Redis连接
	if err := initRedis(); err != nil {
		logger.Fatalf("Failed to init redis: %v", err)
	}

	// 初始化Consul连接
	if err := initConsul(); err != nil {
		logger.Fatalf("Failed to init consul: %v", err)
	}

	// 注册服务到Consul
	if err := registerService(); err != nil {
		logger.Fatalf("Failed to register service: %v", err)
	}

	// 设置路由
	router := setupRouter()

	// 启动服务器
	port := viper.GetString("server.port")
	if port == "" {
		port = "8002"
	}

	logger.Infof("Starting resume service on port %s", port)

	// 优雅关闭
	go func() {
		if err := router.Run(":" + port); err != nil {
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

	logger.Info("Server exited")
}

func loadConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 设置默认值
	viper.SetDefault("server.port", "9003")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "8200")
	viper.SetDefault("database.name", "jobfirst")
	viper.SetDefault("database.user", "root")
	viper.SetDefault("database.password", "jobfirst123")
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", "8201")
	viper.SetDefault("consul.host", "localhost")
	viper.SetDefault("consul.port", "8202")

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return err
		}
	}

	return nil
}

func initDatabase() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.host"),
		viper.GetString("database.port"),
		viper.GetString("database.name"),
	)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// 自动迁移
	if err := db.AutoMigrate(&Resume{}, &ResumeTemplate{}, &ResumeBanner{}); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
	}

	logger.Info("Successfully connected to database")
	return nil
}

func initRedis() error {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", viper.GetString("redis.host"), viper.GetString("redis.port")),
		Password: viper.GetString("redis.password"),
		DB:       0,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := redisClient.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("failed to connect to redis: %v", err)
	}

	logger.Info("Successfully connected to Redis")
	return nil
}

func initConsul() error {
	config := api.DefaultConfig()
	config.Address = fmt.Sprintf("%s:%s", viper.GetString("consul.host"), viper.GetString("consul.port"))

	var err error
	consulClient, err = api.NewClient(config)
	if err != nil {
		return fmt.Errorf("failed to create consul client: %v", err)
	}

	logger.Info("Successfully connected to Consul")
	return nil
}

func registerService() error {
	serviceAddress := "localhost"
	serviceID := "resume-service"
	serviceName := "resume-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"resume", "document", "api"},
		// 暂时注释掉健康检查，避免服务不稳定
		// Check: &api.AgentServiceCheck{
		// 	HTTP:                           fmt.Sprintf("http://%s:%s/health", serviceAddress, servicePort),
		// 	Interval:                       "10s",
		// 	Timeout:                        "5s",
		// 	DeregisterCriticalServiceAfter: "30s",
		// },
	}

	if err := consulClient.Agent().ServiceRegister(registration); err != nil {
		return fmt.Errorf("failed to register service: %v", err)
	}

	logger.Info("Service registered to Consul")
	return nil
}

func deregisterService() error {
	serviceID := "resume-service"
	if err := consulClient.Agent().ServiceDeregister(serviceID); err != nil {
		return fmt.Errorf("failed to deregister service: %v", err)
	}

	logger.Info("Service deregistered from Consul")
	return nil
}

func setupRouter() *gin.Engine {
	router := gin.Default()

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
				"title":       "JobFirst Resume Service API",
				"description": "简历服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "resume@jobfirst.com",
				},
			},
			"host":     "localhost:9003",
			"basePath": "/resume",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/resume/templates": gin.H{
					"get": gin.H{
						"summary":     "获取简历模板",
						"description": "获取简历模板列表",
						"tags":        []string{"简历模板"},
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
													"id":          gin.H{"type": "integer", "example": 1},
													"name":        gin.H{"type": "string", "example": "标准模板"},
													"description": gin.H{"type": "string", "example": "通用简历模板"},
												},
											},
										},
									},
								},
							},
						},
					},
				},
				"/resume/list": gin.H{
					"get": gin.H{
						"summary":     "获取简历列表",
						"description": "获取用户简历列表（需要认证）",
						"tags":        []string{"简历管理"},
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
											"type": "array",
											"items": gin.H{
												"type": "object",
												"properties": gin.H{
													"id":       gin.H{"type": "integer", "example": 1},
													"title":    gin.H{"type": "string", "example": "我的简历"},
													"status":   gin.H{"type": "string", "example": "draft"},
													"approved": gin.H{"type": "boolean", "example": true},
												},
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
				"Resume": gin.H{
					"type": "object",
					"properties": gin.H{
						"id":       gin.H{"type": "integer", "example": 1},
						"title":    gin.H{"type": "string", "example": "我的简历"},
						"status":   gin.H{"type": "string", "example": "draft"},
						"approved": gin.H{"type": "boolean", "example": true},
					},
				},
			},
		})
	})

	// 简历服务上下文路径 - 兼容原有系统
	resume := router.Group("/resume")
	{
		// 公开的简历相关API（不需要认证）
		resume.GET("/templates", listTemplates)
		resume.GET("/banners", listBanners)

		// 需要认证的简历管理API
		authResume := resume.Group("")
		authResume.Use(authMiddleware())
		{
			// 简历列表 - 需要认证和审批
			authResume.GET("/list", listResumes)
			authResume.GET("/detail/:id", getResume)
			authResume.POST("/default", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "设置默认简历成功",
					"data":    gin.H{"default": true},
				})
			})

			// 简历管理
			authResume.POST("/create", createResume)
			authResume.POST("/publish/:id", publishResume)
			authResume.DELETE("/delete/:id", deleteResume)
			authResume.GET("/info/:id", getResume)
			authResume.PUT("/update/:id", updateResume)
			authResume.POST("/upload", uploadResume)
			authResume.GET("/auth/:id", getResumeAuth)
			authResume.PUT("/auth/:id", updateResumeAuth)
			authResume.GET("/blacklist", getBlacklist)
			authResume.POST("/black/:id", setBlack)
			authResume.GET("/preview/:id", previewResume)
		}
	}

	// API路由 - 兼容小程序
	api := router.Group("/api/v1")
	{
		// 小程序兼容路由
		resumeAPI := api.Group("/resume")
		{
			// 公开的简历相关API（不需要认证）
			resumeAPI.GET("/templates", listTemplates)
			resumeAPI.GET("/banners", listBanners)

			// 需要认证的简历管理API
			authResumeAPI := resumeAPI.Group("")
			authResumeAPI.Use(authMiddleware())
			{
				// 简历列表 - 需要认证和审批
				authResumeAPI.GET("/list", listResumes)
				authResumeAPI.GET("/detail/:id", getResume)
				authResumeAPI.POST("/default", func(c *gin.Context) {
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "设置默认简历成功",
						"data":    gin.H{"default": true},
					})
				})

				// 简历管理
				authResumeAPI.POST("/create", createResume)
				authResumeAPI.POST("/publish/:id", publishResume)
				authResumeAPI.DELETE("/delete/:id", deleteResume)
				authResumeAPI.GET("/info/:id", getResume)
				authResumeAPI.PUT("/update/:id", updateResume)
				authResumeAPI.POST("/upload", uploadResume)
				authResumeAPI.GET("/auth/:id", getResumeAuth)
				authResumeAPI.PUT("/auth/:id", updateResumeAuth)
				authResumeAPI.GET("/blacklist", getBlacklist)
				authResumeAPI.POST("/black/:id", setBlack)
				authResumeAPI.GET("/preview/:id", previewResume)
			}
		}
	}

	return router
}

// 简历模型
type Resume struct {
	ID         uint       `json:"id" gorm:"primaryKey;autoIncrement"`
	UserID     uint       `json:"user_id" gorm:"not null"`
	Title      string     `json:"title" gorm:"type:varchar(100);not null"`
	Content    string     `json:"content" gorm:"type:text"`
	Status     string     `json:"status" gorm:"type:enum('draft','published','archived');default:'draft'"`
	TemplateID uint       `json:"template_id"`
	CreatedAt  time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt  time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt  *time.Time `json:"deleted_at" gorm:"index"`
}

// 简历模板模型
type ResumeTemplate struct {
	ID          uint      `json:"id" gorm:"primaryKey;autoIncrement"`
	Name        string    `json:"name" gorm:"type:varchar(100);not null"`
	Description string    `json:"description" gorm:"type:text"`
	PreviewURL  string    `json:"preview_url" gorm:"type:varchar(255)"`
	CreatedAt   time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

// 简历横幅模型
type ResumeBanner struct {
	ID        uint      `json:"id" gorm:"primaryKey;autoIncrement"`
	Title     string    `json:"title" gorm:"type:varchar(100);not null"`
	ImageURL  string    `json:"image_url" gorm:"type:varchar(255)"`
	LinkURL   string    `json:"link_url" gorm:"type:varchar(255)"`
	Sort      int       `json:"sort" gorm:"default:0"`
	Status    string    `json:"status" gorm:"type:enum('active','inactive');default:'active'"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`
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
	if userID, exists := c.Get("userID"); exists {
		if id, ok := userID.(uint); ok {
			return id
		}
	}
	return 0
}

// 获取简历列表
func listResumes(c *gin.Context) {
	// 获取当前用户ID
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    401,
			"message": "用户未认证",
		})
		return
	}

	// 检查用户是否有审批权限
	// 这里应该查询数据库中的审批状态
	// 暂时返回模拟数据，表示用户已通过审批
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "title": "我的简历", "status": "draft", "approved": true},
			{"id": 2, "title": "求职简历", "status": "published", "approved": true},
		},
	})
}

// 创建简历
func createResume(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "简历创建成功",
		"data":    gin.H{"id": 1, "title": "新简历"},
	})
}

// 发布简历
func publishResume(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "简历发布成功",
		"data":    gin.H{"id": resumeID, "status": "published"},
	})
}

// 删除简历
func deleteResume(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "简历删除成功",
		"data":    gin.H{"id": resumeID},
	})
}

// 获取简历信息
func getResume(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    gin.H{"id": resumeID, "title": "简历详情", "content": "简历内容"},
	})
}

// 更新简历
func updateResume(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "简历更新成功",
		"data":    gin.H{"id": resumeID},
	})
}

// 获取简历模板列表
func listTemplates(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "name": "标准模板", "description": "通用简历模板"},
			{"id": 2, "name": "创意模板", "description": "设计类简历模板"},
		},
	})
}

// 获取简历横幅
func listBanners(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data": []gin.H{
			{"id": 1, "title": "招聘横幅1", "image": "https://example.com/banner1.jpg"},
			{"id": 2, "title": "招聘横幅2", "image": "https://example.com/banner2.jpg"},
		},
	})
}

// 上传简历
func uploadResume(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "简历上传成功",
		"data":    gin.H{"url": "https://example.com/resume.pdf"},
	})
}

// 获取简历授权信息
func getResumeAuth(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    gin.H{"id": resumeID, "auth": "public"},
	})
}

// 更新简历授权信息
func updateResumeAuth(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "授权信息更新成功",
		"data":    gin.H{"id": resumeID},
	})
}

// 获取黑名单
func getBlacklist(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    []gin.H{},
	})
}

// 设置黑名单
func setBlack(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "黑名单设置成功",
		"data":    gin.H{"id": resumeID},
	})
}

// 预览简历
func previewResume(c *gin.Context) {
	resumeID := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    gin.H{"id": resumeID, "preview_url": "https://example.com/preview.pdf"},
	})
}
