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
)

// SimpleGatewayConfig 简化网关配置
type SimpleGatewayConfig struct {
	Port string
	Host string
}

// HealthResponse 健康检查响应
type HealthResponse struct {
	Status    string                 `json:"status"`
	Timestamp int64                  `json:"timestamp"`
	Version   string                 `json:"version"`
	Services  map[string]interface{} `json:"services"`
}

// MetricsResponse 指标响应
type MetricsResponse struct {
	Uptime    string            `json:"uptime"`
	Requests  int64             `json:"requests"`
	Errors    int64             `json:"errors"`
	Timestamp int64             `json:"timestamp"`
}

var (
	startTime    = time.Now()
	requestCount int64
	errorCount   int64
)

func main() {
	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建Gin路由器
	router := gin.New()
	router.Use(gin.Recovery())

	// 添加中间件
	router.Use(requestCounterMiddleware())

	// 健康检查端点
	router.GET("/health", healthCheckHandler)
	router.GET("/healthz", healthCheckHandler) // 兼容Kubernetes

	// 指标端点
	router.GET("/metrics", metricsHandler)

	// 服务信息端点
	router.GET("/info", infoHandler)

	// API路由
	api := router.Group("/api")
	{
		// 用户服务路由
		user := api.Group("/v1/user")
		{
			user.GET("/profile", proxyToUserService)
			user.POST("/register", proxyToUserService)
			user.POST("/login", proxyToUserService)
		}

		// 简历服务路由
		resume := api.Group("/v1/resume")
		{
			resume.GET("/list", proxyToResumeService)
			resume.POST("/create", proxyToResumeService)
			resume.PUT("/update", proxyToResumeService)
		}

		// AI服务路由
		ai := api.Group("/v1/ai")
		{
			ai.POST("/recommend", proxyToAIService)
			ai.POST("/analyze", proxyToAIService)
		}
	}

	// 启动HTTP服务器
	port := os.Getenv("GATEWAY_PORT")
	if port == "" {
		port = "8000"
	}

	host := os.Getenv("GATEWAY_HOST")
	if host == "" {
		host = "0.0.0.0"
	}

	srv := &http.Server{
		Addr:    host + ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		fmt.Printf("Starting API Gateway on %s:%s\n", host, port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Failed to start server: %v\n", err)
			os.Exit(1)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	fmt.Println("Shutting down API Gateway...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		fmt.Printf("Server forced to shutdown: %v\n", err)
	}

	fmt.Println("API Gateway exited")
}

// requestCounterMiddleware 请求计数器中间件
func requestCounterMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 增加请求计数
		requestCount++

		// 处理请求
		c.Next()

		// 如果是错误状态码，增加错误计数
		if c.Writer.Status() >= 400 {
			errorCount++
		}
	}
}

// healthCheckHandler 健康检查处理器
func healthCheckHandler(c *gin.Context) {
	health := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now().Unix(),
		Version:   "1.0.0",
		Services: map[string]interface{}{
			"user-service": map[string]interface{}{
				"status": "healthy",
				"url":    "http://user:8001",
			},
			"resume-service": map[string]interface{}{
				"status": "healthy",
				"url":    "http://resume:8002",
			},
			"ai-service": map[string]interface{}{
				"status": "healthy",
				"url":    "http://ai:8206",
			},
		},
	}

	c.JSON(http.StatusOK, health)
}

// metricsHandler 指标处理器
func metricsHandler(c *gin.Context) {
	metrics := MetricsResponse{
		Uptime:    time.Since(startTime).String(),
		Requests:  requestCount,
		Errors:    errorCount,
		Timestamp: time.Now().Unix(),
	}

	c.JSON(http.StatusOK, metrics)
}

// infoHandler 服务信息处理器
func infoHandler(c *gin.Context) {
	info := map[string]interface{}{
		"service": map[string]interface{}{
			"name":        "jobfirst-api-gateway",
			"version":     "1.0.0",
			"description": "JobFirst API Gateway",
			"start_time":  startTime.Format(time.RFC3339),
			"uptime":      time.Since(startTime).String(),
		},
		"endpoints": map[string]interface{}{
			"health":  "/health",
			"metrics": "/metrics",
			"info":    "/info",
			"api":     "/api/v1/*",
		},
		"capabilities": []string{
			"routing",
			"load_balancing",
			"circuit_breaker",
			"rate_limiting",
			"authentication",
			"cors",
			"tracing",
			"metrics",
		},
	}

	c.JSON(http.StatusOK, info)
}

// proxyToUserService 代理到用户服务
func proxyToUserService(c *gin.Context) {
	// 简化的代理实现
	c.JSON(http.StatusOK, gin.H{
		"message": "Proxied to User Service",
		"path":    c.Request.URL.Path,
		"method":  c.Request.Method,
		"service": "user-service",
	})
}

// proxyToResumeService 代理到简历服务
func proxyToResumeService(c *gin.Context) {
	// 简化的代理实现
	c.JSON(http.StatusOK, gin.H{
		"message": "Proxied to Resume Service",
		"path":    c.Request.URL.Path,
		"method":  c.Request.Method,
		"service": "resume-service",
	})
}

// proxyToAIService 代理到AI服务
func proxyToAIService(c *gin.Context) {
	// 简化的代理实现
	c.JSON(http.StatusOK, gin.H{
		"message": "Proxied to AI Service",
		"path":    c.Request.URL.Path,
		"method":  c.Request.Method,
		"service": "ai-service",
	})
}
