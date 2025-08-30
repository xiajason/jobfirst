package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

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
		port = "8087"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		logger.Infof("Starting document processing service on port %s", port)
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
	viper.SetDefault("server.port", "8087")
	viper.SetDefault("redis.address", "localhost:6379")
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 3306)
	viper.SetDefault("database.name", "resume_centre")
	viper.SetDefault("database.user", "root")
	viper.SetDefault("database.password", "")

	return viper.ReadInConfig()
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
	if err := db.AutoMigrate(&DocumentTask{}, &DocumentExtraction{}, &DocumentTemplate{}, &OCRResult{}, &ConversionConfig{}, &ProcessingStats{}); err != nil {
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
	registration := &api.AgentServiceRegistration{
		ID:      "document-service",
		Name:    "document-service",
		Address: viper.GetString("server.host"),
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"document", "processing"},
		Check: &api.AgentServiceCheck{
			HTTP:                           fmt.Sprintf("http://%s:%d/health", viper.GetString("server.host"), viper.GetInt("server.port")),
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
	err := consulClient.Agent().ServiceDeregister("document-service")
	if err != nil {
		return fmt.Errorf("failed to deregister service: %v", err)
	}

	logger.Info("Service deregistered from Consul")
	return nil
}

func setupRouter() *gin.Engine {
	router := gin.Default()

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		})
	})

	// API路由
	api := router.Group("/api/v1")
	api.Use(authMiddleware())
	{
		// 文档处理任务
		tasks := api.Group("/tasks")
		{
			tasks.POST("/", createTask)
			tasks.GET("/", listTasks)
			tasks.GET("/:id", getTask)
			tasks.PUT("/:id/cancel", cancelTask)
		}

		// 文档转换
		conversion := api.Group("/conversion")
		{
			conversion.POST("/", convertDocument)
			conversion.GET("/formats", getSupportedFormats)
			conversion.GET("/configs", getConversionConfigs)
		}

		// 内容提取
		extraction := api.Group("/extraction")
		{
			extraction.POST("/", extractContent)
			extraction.GET("/:id", getExtraction)
			extraction.GET("/:id/structured", getStructuredData)
		}

		// OCR识别
		ocr := api.Group("/ocr")
		{
			ocr.POST("/", performOCR)
			ocr.GET("/:id", getOCRResult)
			ocr.GET("/languages", getSupportedLanguages)
		}

		// 文档模板
		templates := api.Group("/templates")
		{
			templates.POST("/", createTemplate)
			templates.GET("/", listTemplates)
			templates.GET("/:id", getTemplate)
			templates.PUT("/:id", updateTemplate)
			templates.DELETE("/:id", deleteTemplate)
		}

		// 处理统计
		stats := api.Group("/stats")
		{
			stats.GET("/", getProcessingStats)
			stats.GET("/summary", getStatsSummary)
		}
	}

	return router
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

// JWT token验证函数（简化版）
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
