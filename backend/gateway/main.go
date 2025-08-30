package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/go-redis/redis/v8"
	"github.com/hashicorp/consul/api"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"golang.org/x/time/rate"
)

var (
	consulClient *api.Client
	logger       *logrus.Logger
	redisClient  *redis.Client
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

	// 初始化Consul客户端
	if err := initConsulClient(); err != nil {
		logger.Fatalf("Failed to init consul client: %v", err)
	}

	// 初始化Redis客户端
	if err := initRedisClient(); err != nil {
		logger.Fatalf("Failed to init redis client: %v", err)
	}

	// 启动HTTP服务器
	router := setupRouter()
	port := viper.GetString("server.port")
	if port == "" {
		port = "8000"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		logger.Infof("Starting gateway server on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("Shutting down server...")

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
	viper.SetDefault("server.port", "8000")
	viper.SetDefault("redis.address", "localhost:8201")
	viper.SetDefault("redis.db", 0)

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

func setupRouter() *gin.Engine {
	router := gin.Default()

	// 中间件
	router.Use(loggingMiddleware())
	router.Use(corsMiddleware())
	router.Use(rateLimitMiddleware())

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		})
	})

	// 完全兼容原有系统的API路由 - 前端无需修改
	// 根据原有Spring Cloud Gateway配置重构
	router.Any("/resource/*path", proxyToService("resource-service"))
	router.Any("/admin/*path", proxyToService("admin-service"))
	router.Any("/personal/*path", proxyToService("personal-service"))
	router.Any("/enterprise/*path", proxyToService("enterprise-service"))
	router.Any("/open/*path", proxyToService("open-service"))
	router.Any("/resume/*path", proxyToService("resume-service"))
	router.Any("/statistics/*path", proxyToService("statistics-service"))
	router.Any("/points/*path", proxyToService("points-service"))
	// router.Any("/blockchain/*path", proxyToService("blockchain-service"))  // 暂时禁用，需要复杂认证

	// API路由组 - 兼容新的微服务架构
	api := router.Group("/api")
	{
		// 用户服务
		api.Any("/user/*path", proxyToService("user-service"))

		// 简历服务
		api.Any("/resume/*path", proxyToService("resume-service"))

		// 积分服务
		api.Any("/points/*path", proxyToService("points-service"))

		// 统计服务
		api.Any("/statistics/*path", proxyToService("statistics-service"))

		// 存储服务
		api.Any("/storage/*path", proxyToService("storage-service"))

		// V2 API - 支持新数据库表
		v2 := api.Group("/v2")
		{
			// 职位相关API
			v2.Any("/jobs/*path", proxyToService("user-service"))
			
			// 企业相关API
			v2.Any("/companies/*path", proxyToService("user-service"))
			
			// 轮播图API
			v2.Any("/banners/*path", proxyToService("user-service"))
		}

		// 受保护的API - 需要认证
		v1 := api.Group("/v1")
		{
			// 个人服务
			v1.Any("/personal/*path", proxyToService("personal-service"))

			// 用户服务
			v1.Any("/user/*path", proxyToService("user-service"))

			// 简历服务
			v1.Any("/resume/*path", proxyToService("resume-service"))

			// 积分服务
			v1.Any("/points/*path", proxyToService("points-service"))

			// 统计服务
			v1.Any("/statistics/*path", proxyToService("statistics-service"))

			// 存储服务
			v1.Any("/resources/*path", proxyToService("storage-service"))

			// 区块链服务
			// v1.Any("/blockchain/*path", proxyToService("blockchain-service"))  // 暂时禁用，需要复杂认证
		}
	}

	return router
}

// 日志中间件
func loggingMiddleware() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format(time.RFC1123),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	})
}

// CORS中间件
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// 限流中间件
func rateLimitMiddleware() gin.HandlerFunc {
	limiter := rate.NewLimiter(rate.Limit(100), 100) // 每秒100个请求，突发100个
	return func(c *gin.Context) {
		if !limiter.Allow() {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit exceeded"})
			c.Abort()
			return
		}
		c.Next()
	}
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

		// 验证JWT token
		if !validateToken(token) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// 验证JWT token
func validateToken(tokenString string) bool {
	// 这里应该实现JWT验证逻辑
	// 为了简化，这里只是检查token是否存在
	return len(tokenString) > 0
}

// 代理到具体服务
func proxyToService(serviceName string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从Consul获取服务地址
		service, err := getServiceFromConsul(serviceName)
		if err != nil {
			logger.Errorf("Failed to get service %s: %v", serviceName, err)
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Service unavailable"})
			return
		}

		// 构建目标URL - 在本地开发环境中使用localhost
		serviceAddress := service.Address
		if serviceAddress == serviceName || strings.Contains(serviceAddress, "-service") {
			serviceAddress = "localhost"
		}
		targetURL := fmt.Sprintf("http://%s:%d", serviceAddress, service.Port)
		target, err := url.Parse(targetURL)
		if err != nil {
			logger.Errorf("Failed to parse target URL: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			return
		}

		// 创建反向代理
		proxy := httputil.NewSingleHostReverseProxy(target)

		// 修改请求路径
		originalPath := c.Request.URL.Path
		logger.Infof("Proxy request: %s -> %s:%d, original path: %s", serviceName, serviceAddress, service.Port, originalPath)

		// 路径重写逻辑
		if strings.HasPrefix(originalPath, "/api/") {
			// 特殊处理 Swagger 相关路径
			if strings.Contains(originalPath, "/swagger/") {
				// 对于 Swagger UI 路径，转发到目标服务的根路径
				c.Request.URL.Path = strings.TrimPrefix(originalPath, "/api/user")
			} else if strings.Contains(originalPath, "/v2/api-docs") {
				// 对于 /api/v1/v2/api-docs，直接转发到目标服务的 /v2/api-docs
				c.Request.URL.Path = "/v2/api-docs"
			} else if strings.HasPrefix(originalPath, "/api/v2/") {
				// 处理 v2 API 路由 - 直接转发，不添加 /api/v1 前缀
				c.Request.URL.Path = originalPath
			} else if !strings.HasPrefix(originalPath, "/api/v1/") {
				// 处理新的API路由 - 将 /api/user/login 转换为 /api/v1/user/login
				c.Request.URL.Path = "/api/v1" + strings.TrimPrefix(originalPath, "/api")
			} else {
				// 对于 /api/v1/ 路径，去掉 /api/v1 前缀，转发给目标服务
				c.Request.URL.Path = strings.TrimPrefix(originalPath, "/api/v1")
			}
		} else {
			// 对于原有系统的路由（/admin, /resource, /personal等），直接转发
			c.Request.URL.Path = originalPath
		}

		logger.Infof("Rewritten path: %s", c.Request.URL.Path)

		// 转发请求
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// 从Consul获取服务信息
func getServiceFromConsul(serviceName string) (*api.AgentService, error) {
	services, err := consulClient.Agent().Services()
	if err != nil {
		return nil, err
	}

	for _, service := range services {
		if service.Service == serviceName {
			return service, nil
		}
	}

	return nil, fmt.Errorf("service %s not found", serviceName)
}
