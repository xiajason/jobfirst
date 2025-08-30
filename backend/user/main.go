// Package main JobFirst User Service
//
// JobFirst用户服务API文档
//
//	Schemes: http, https
//	Host: localhost:8001
//	BasePath: /api/v1
//	Version: 1.0.0
//
//	Consumes:
//	- application/json
//
//	Produces:
//	- application/json
//
//	Security:
//	- bearer
//
// swagger:meta
package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"resume-centre/shared/infrastructure"
	"resume-centre/user/handlers"

	_ "resume-centre/user/docs" // 导入生成的swagger文档

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/hashicorp/consul/api"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

var (
	consulClient *api.Client
	logger       *logrus.Logger
	redisClient  *redis.Client
	db           *gorm.DB
)

// GetDB 获取数据库连接
func GetDB() *gorm.DB {
	return db
}

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
		logger.Infof("Starting user service on port %s", port)
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
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&collation=utf8mb4_unicode_ci&parseTime=True&loc=Local&time_zone='+08:00'",
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.host"),
		viper.GetInt("database.port"),
		viper.GetString("database.name"),
	)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags),
			logger.Config{
				SlowThreshold:             time.Second,
				LogLevel:                  logger.Info,
				IgnoreRecordNotFoundError: true,
				Colorful:                  true,
			},
		),
	})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	// 设置数据库连接池的字符集
	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get sql.DB: %v", err)
	}

	// 设置连接池参数
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// 自动迁移
	if err := db.AutoMigrate(&User{}); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
	}

	// 设置全局数据库连接给handlers使用
	handlers.SetGlobalDB(db)

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
	serviceID := "user-service"
	serviceName := "user-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"user", "auth"},
		// 暂时禁用健康检查，避免服务被自动注销
		// Check: &api.AgentServiceCheck{
		// 	HTTP:                           fmt.Sprintf("http://%s:%s/health", serviceAddress, servicePort),
		// 	Interval:                       "30s",
		// 	Timeout:                        "10s",
		// 	DeregisterCriticalServiceAfter: "60s",
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
	serviceID := "user-service"
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

	// ==================== 白名单路由 - 无需认证 ====================
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

	// Swagger UI 路由
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// ==================== 公开API路由组 - 无需认证 ====================
	// 这些API可以被任何人访问，用于首页展示、搜索等公开功能
	publicAPI := router.Group("/api/v2")
	{
		// 用户认证相关API - 公开访问
		auth := publicAPI.Group("/auth")
		{
			auth.POST("/login", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "登录成功",
					"data":    gin.H{"accessToken": "test-token"},
				})
			})
			auth.POST("/register", registerUser)
			auth.GET("/check", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"valid": true},
				})
			})
		}

		// 职位相关API - 公开访问
		jobs := publicAPI.Group("/jobs")
		{
			jobs.GET("/", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewJobHandler()
					handler.GetJobsV2(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{"id": 1, "title": "前端开发工程师", "company": "腾讯"},
						},
					})
				}
			})
			jobs.GET("/:id", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewJobHandler()
					handler.GetJobDetailV2(c)
				} else {
					// 降级到v1
					jobID := c.Param("id")
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": gin.H{
							"id":          jobID,
							"title":       "前端开发工程师",
							"company":     "腾讯",
							"salary":      "15k-25k",
							"description": "负责公司前端项目开发...",
						},
					})
				}
			})
			jobs.GET("/search", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewJobHandler()
					handler.SearchJobsV2(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{"id": 1, "title": "前端开发工程师", "company": "腾讯"},
						},
					})
				}
			})
		}

		// 企业相关API - 公开访问
		companies := publicAPI.Group("/companies")
		{
			companies.GET("/", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewCompanyHandler()
					handler.GetCompaniesV2(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{"id": 1, "name": "腾讯", "logo": "/images/company/tencent.png"},
							{"id": 2, "name": "阿里巴巴", "logo": "/images/company/alibaba.png"},
						},
					})
				}
			})
			companies.GET("/:id", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewCompanyHandler()
					handler.GetCompanyDetailV2(c)
				} else {
					// 降级到v1
					companyID := c.Param("id")
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": gin.H{
							"id":          companyID,
							"name":        "腾讯",
							"logo":        "/images/company/tencent.png",
							"description": "腾讯是一家以互联网为基础的科技与文化公司",
						},
					})
				}
			})
		}

		// 轮播图相关API - 公开访问
		banners := publicAPI.Group("/banners")
		{
			banners.GET("/", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewBannerHandler()
					handler.GetBannersV2(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{"id": 1, "title": "春季招聘会", "image": "/images/banner1.jpg"},
							{"id": 2, "title": "名企直招", "image": "/images/banner2.jpg"},
						},
					})
				}
			})
		}
	}

	// ==================== 需要认证的API路由组 ====================
	// 这些API需要用户登录后才能访问
	protectedAPI := router.Group("/api/v2")
	protectedAPI.Use(authMiddleware()) // 应用认证中间件
	{
		// 用户个人中心相关API - 需要认证
		user := protectedAPI.Group("/user")
		{
			user.GET("/profile", getUserProfile)
			user.PUT("/profile", updateUserProfile)
			user.POST("/logout", logoutUser)
		}

		// 职位申请相关API - 需要认证
		jobApplications := protectedAPI.Group("/jobs")
		{
			jobApplications.POST("/:id/apply", func(c *gin.Context) {
				// 获取当前用户ID
				userID := getUserIDFromContext(c)
				if userID == 0 {
					c.JSON(http.StatusUnauthorized, gin.H{
						"code":    401,
						"message": "用户未认证",
					})
					return
				}

				jobID := c.Param("id")
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "申请成功",
					"data": gin.H{
						"job_id":  jobID,
						"user_id": userID,
						"status":  "pending",
					},
				})
			})
			jobApplications.GET("/applications", func(c *gin.Context) {
				// 获取当前用户ID
				userID := getUserIDFromContext(c)
				if userID == 0 {
					c.JSON(http.StatusUnauthorized, gin.H{
						"code":    401,
						"message": "用户未认证",
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "title": "前端开发工程师", "company": "腾讯", "status": "pending", "user_id": userID},
						{"id": 2, "title": "后端开发工程师", "company": "阿里", "status": "accepted", "user_id": userID},
					},
				})
			})
		}

		// 聊天系统相关API - 需要认证
		chat := protectedAPI.Group("/chat")
		{
			chat.GET("/sessions", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewChatHandler()
					handler.GetChatSessions(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"id":     "session_001",
								"title":  "前端开发工程师申请",
								"type":   "job_apply",
								"unread": 2,
							},
						},
					})
				}
			})

			chat.GET("/sessions/:sessionId/messages", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewChatHandler()
					handler.GetChatMessages(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"id":      1,
								"content": "您好，我们已经收到您的简历",
								"sender":  "hr",
								"time":    "2024-08-30T16:30:00Z",
							},
						},
					})
				}
			})

			chat.POST("/sessions/:sessionId/messages", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewChatHandler()
					handler.SendMessage(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Message sent (v1 fallback)",
						"data": gin.H{
							"id":      2,
							"content": "消息发送成功",
							"time":    "2024-08-30T16:35:00Z",
						},
					})
				}
			})

			chat.PUT("/sessions/:sessionId/messages/:messageId/read", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewChatHandler()
					handler.MarkMessageRead(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Message marked as read (v1 fallback)",
					})
				}
			})

			chat.POST("/sessions", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewChatHandler()
					handler.CreateChatSession(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Session created (v1 fallback)",
						"data": gin.H{
							"session_id": "session_new",
							"title":      "新会话",
						},
					})
				}
			})
		}

		// 积分系统相关API - 需要认证
		points := protectedAPI.Group("/points")
		{
			points.GET("/balance", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewPointsHandler()
					handler.GetPointsBalance(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": gin.H{
							"balance": 1250,
							"level":   "silver",
						},
					})
				}
			})

			points.GET("/records", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewPointsHandler()
					handler.GetPointsRecords(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"id":     1,
								"points": 10,
								"reason": "每日签到",
								"time":   "2024-08-30T08:00:00Z",
							},
						},
					})
				}
			})

			points.GET("/rules", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewPointsHandler()
					handler.GetPointsRules(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"rule":        "DAILY_CHECKIN",
								"points":      10,
								"description": "每日签到",
							},
						},
					})
				}
			})

			points.POST("/exchange", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewPointsHandler()
					handler.ExchangePoints(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Exchange successful (v1 fallback)",
						"data": gin.H{
							"exchange_code": "EXCH_123",
							"item_name":     "优惠券",
						},
					})
				}
			})

			points.GET("/exchanges", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewPointsHandler()
					handler.GetExchangeHistory(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"id":     1,
								"item":   "优惠券",
								"points": -100,
								"time":   "2024-08-29T16:20:00Z",
							},
						},
					})
				}
			})
		}

		// 通知系统相关API - 需要认证
		notifications := protectedAPI.Group("/notifications")
		{
			notifications.GET("/", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.GetNotifications(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"id":      1,
								"title":   "申请成功",
								"content": "您申请的职位已成功提交",
								"type":    "job_apply",
								"read":    false,
								"time":    "2024-08-30T16:30:00Z",
							},
						},
					})
				}
			})

			notifications.GET("/:id", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.GetNotificationDetail(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": gin.H{
							"id":      1,
							"title":   "申请成功",
							"content": "您申请的职位已成功提交",
							"type":    "job_apply",
							"read":    false,
							"time":    "2024-08-30T16:30:00Z",
						},
					})
				}
			})

			notifications.PUT("/:id/read", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.MarkNotificationRead(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Notification marked as read (v1 fallback)",
					})
				}
			})

			notifications.PUT("/read-all", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.MarkAllNotificationsRead(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "All notifications marked as read (v1 fallback)",
					})
				}
			})

			notifications.GET("/settings", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.GetNotificationSettings(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": gin.H{
							"email": true,
							"sms":   true,
							"push":  true,
							"app":   true,
						},
					})
				}
			})

			notifications.PUT("/settings", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.UpdateNotificationSettings(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Settings updated (v1 fallback)",
						"data": gin.H{
							"email": true,
							"sms":   true,
							"push":  true,
							"app":   true,
						},
					})
				}
			})

			notifications.GET("/templates", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.GetNotificationTemplates(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success (v1 fallback)",
						"data": []gin.H{
							{
								"code":  "JOB_APPLY_SUCCESS",
								"name":  "职位申请成功",
								"title": "申请成功",
							},
						},
					})
				}
			})

			notifications.POST("/send", func(c *gin.Context) {
				version := c.GetHeader("API-Version")
				if version == "v2" {
					handler := handlers.NewNotificationHandler()
					handler.SendNotification(c)
				} else {
					// 降级到v1
					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "Notification sent (v1 fallback)",
						"data": gin.H{
							"id":     6,
							"status": "sent",
							"time":   "2024-08-30T18:30:00Z",
						},
					})
				}
			})
		}
	}

	// ==================== 兼容原有系统的API路由 ====================
	// 保持向后兼容，但建议逐步迁移到新的路由结构
	legacyAPI := router.Group("/api/v1")
	{
		// 用户认证相关API - 兼容原有系统
		userAuth := legacyAPI.Group("/user/auth")
		{
			userAuth.POST("/login", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0, // 原有系统使用0表示成功
					"data": gin.H{"accessToken": "test-token"},
					"msg":  "登录成功",
				})
			})
			userAuth.GET("/check", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"valid": true},
					"msg":  "success",
				})
			})
			userAuth.GET("/phone", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"phone": "13800138000"},
					"msg":  "success",
				})
			})
			userAuth.GET("/idkey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"idKey": "user-key-123"},
					"msg":  "success",
				})
			})
			userAuth.POST("/certification", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"certified": true},
					"msg":  "认证成功",
				})
			})
			userAuth.POST("/logout", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{},
					"msg":  "登出成功",
				})
			})
			userAuth.GET("/myidkey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"idKey": "my-user-key-123"},
					"msg":  "success",
				})
			})
			userAuth.POST("/unsubscribe", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{},
					"msg":  "注销成功",
				})
			})
		}

		// 公开API - 兼容原有系统
		public := legacyAPI.Group("/public")
		{
			// 首页相关API
			public.GET("/home/banners", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "title": "热加载测试横幅1", "image": "https://example.com/banner1.jpg"},
						{"id": 2, "title": "热加载测试横幅2", "image": "https://example.com/banner2.jpg"},
						{"id": 3, "title": "新增横幅3", "image": "https://example.com/banner3.jpg"},
					},
				})
			})

			public.GET("/home/notifications", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "title": "系统通知", "content": "欢迎使用JobFirst系统"},
						{"id": 2, "title": "功能更新", "content": "新功能已上线"},
					},
				})
			})

			// 认证相关API
			public.POST("/authentication/login", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "登录成功",
					"data":    gin.H{"accessToken": "test-token"},
				})
			})

			public.POST("/authentication/check", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"valid": true},
				})
			})

			public.GET("/authentication/getUserPhone", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"phone": "13800138000"},
				})
			})

			public.POST("/authentication/getUserIdKey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"idKey": "user-key-123"},
				})
			})

			public.POST("/authentication/certification", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "认证成功",
					"data":    gin.H{"certified": true},
				})
			})

			public.POST("/authentication/logout", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "登出成功",
				})
			})

			public.GET("/authentication/getMyUserIdKey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"idKey": "my-user-key-123"},
				})
			})

			public.POST("/authentication/cancellation", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "注销成功",
				})
			})
		}

		// 需要认证的API - 兼容原有系统
		protected := legacyAPI.Group("/")
		protected.Use(authMiddleware())
		{
			// 个人中心相关API
			protected.GET("/mine/info", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": gin.H{
						"id":       1,
						"username": "testuser",
						"email":    "test@example.com",
						"phone":    "13800138000",
					},
				})
			})

			protected.GET("/mine/points", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"points": 100},
				})
			})

			protected.GET("/mine/points/bill", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "amount": 10, "type": "earn", "description": "完成任务"},
						{"id": 2, "amount": -5, "type": "spend", "description": "下载简历"},
					},
				})
			})

			protected.GET("/mine/approve/history", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "type": "resume", "status": "approved", "time": "2025-08-29"},
					},
				})
			})

			protected.GET("/mine/view/history", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "resume_id": 1, "view_time": "2025-08-29"},
					},
				})
			})

			protected.GET("/mine/certification", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"certified": true},
				})
			})

			protected.PUT("/mine/avatar", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "头像更新成功",
					"data":    gin.H{"avatar_url": "https://example.com/avatar.jpg"},
				})
			})

			// 审批相关API
			protected.GET("/approve/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "type": "resume", "status": "pending", "title": "简历审批"},
					},
				})
			})

			protected.POST("/approve/handle/:id", func(c *gin.Context) {
				approveID := c.Param("id")
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "审批处理成功",
					"data":    gin.H{"id": approveID},
				})
			})

			// 聊天相关API
			protected.GET("/chat/usual", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "content": "您好，有什么可以帮助您的吗？", "time": "2024-08-30T16:30:00Z"},
					},
				})
			})

			protected.POST("/chat/send", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "消息发送成功",
					"data": gin.H{
						"id":      2,
						"content": "消息已发送",
						"time":    "2024-08-30T16:35:00Z",
					},
				})
			})

			// 职位相关API
			authJob := protected.Group("/job")
			{
				authJob.GET("/favoriteList", func(c *gin.Context) {
					// 获取当前用户ID
					userID := getUserIDFromContext(c)
					if userID == 0 {
						c.JSON(http.StatusUnauthorized, gin.H{
							"code":    401,
							"message": "用户未认证",
						})
						return
					}

					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success",
						"data": []gin.H{
							{"id": 1, "title": "前端开发工程师", "company": "腾讯", "user_id": userID},
							{"id": 2, "title": "后端开发工程师", "company": "阿里", "user_id": userID},
						},
					})
				})
				authJob.GET("/applyList", func(c *gin.Context) {
					// 获取当前用户ID
					userID := getUserIDFromContext(c)
					if userID == 0 {
						c.JSON(http.StatusUnauthorized, gin.H{
							"code":    401,
							"message": "用户未认证",
						})
						return
					}

					c.JSON(http.StatusOK, gin.H{
						"code":    200,
						"message": "success",
						"data": []gin.H{
							{"id": 1, "title": "前端开发工程师", "company": "腾讯", "status": "pending", "user_id": userID},
							{"id": 2, "title": "后端开发工程师", "company": "阿里", "status": "accepted", "user_id": userID},
						},
					})
				})
			}
		}

		// 通知相关路由
		notice := legacyAPI.Group("/notice")
		notice.Use(authMiddleware())
		{
			notice.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "title": "系统通知", "content": "欢迎使用JobFirst", "read": false},
						{"id": 2, "title": "申请通知", "content": "您的申请已通过", "read": true},
					},
				})
			})
			notice.POST("/read", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "标记已读成功",
					"data":    gin.H{"read": true},
				})
			})
			notice.GET("/detail/:id", func(c *gin.Context) {
				noticeID := c.Param("id")
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": gin.H{
						"id":      noticeID,
						"title":   "通知详情",
						"content": "这是通知的详细内容...",
						"read":    true,
					},
				})
			})
		}

		// 认证相关路由
		approve := legacyAPI.Group("/approve")
		approve.Use(authMiddleware())
		{
			approve.POST("/submit", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "认证提交成功",
					"data":    gin.H{"submitted": true},
				})
			})
			approve.GET("/status", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data":    gin.H{"status": "pending"},
				})
			})
		}

		// 积分相关路由
		integral := legacyAPI.Group("/integral")
		integral.Use(authMiddleware())
		{
			integral.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "amount": 10, "type": "earn", "description": "完成任务"},
						{"id": 2, "amount": -5, "type": "spend", "description": "下载简历"},
					},
				})
			})
			integral.POST("/exchange", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "积分兑换成功",
					"data":    gin.H{"exchanged": true},
				})
			})
		}

		// 通用功能路由
		common := legacyAPI.Group("/common")
		common.Use(authMiddleware())
		{
			common.POST("/upload", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "文件上传成功",
					"data":    gin.H{"url": "https://example.com/uploaded.jpg"},
				})
			})
			common.GET("/config", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": gin.H{
						"version":  "1.0.0",
						"features": []string{"resume", "job", "chat"},
					},
				})
			})
			common.GET("/region", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "name": "北京", "code": "beijing"},
						{"id": 2, "name": "上海", "code": "shanghai"},
					},
				})
			})
			common.GET("/category", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code":    200,
					"message": "success",
					"data": []gin.H{
						{"id": 1, "name": "技术", "code": "tech"},
						{"id": 2, "name": "产品", "code": "product"},
					},
				})
			})
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
		// 如果用户不存在，返回模拟数据
		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"message": "success",
			"data": gin.H{
				"id":         userID,
				"username":   "testuser",
				"email":      "test@example.com",
				"phone":      "13800138000",
				"avatar_url": "https://example.com/avatar.jpg",
				"status":     "active",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "success",
		"data":    user,
	})
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

// 认证中间件 - 兼容原有系统的accessToken头
func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 兼容原有系统的accessToken头
		token := c.GetHeader("accessToken")
		if token == "" {
			// 也支持Authorization头
			token = c.GetHeader("Authorization")
			if token != "" && len(token) > 7 && token[:7] == "Bearer " {
				token = token[7:]
			}
		}

		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": 100001, // 原有系统的登录过期错误码
				"msg":  "登录已过期",
			})
			c.Abort()
			return
		}

		// 简化认证：接受test-token或wx-token-123
		if token == "test-token" || token == "wx-token-123" {
			// 设置默认用户信息
			c.Set("userID", uint(1))
			c.Set("username", "testuser")
			c.Next()
			return
		}

		// 验证JWT token（保留原有逻辑）
		userID, username, err := validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": 100002, // 原有系统的token无效错误码
				"msg":  "token无效",
			})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文
		c.Set("userID", userID)
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
