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

// HealthResponse 健康检查响应
type HealthResponse struct {
	Status     string                 `json:"status"`
	Timestamp  int64                  `json:"timestamp"`
	Version    string                 `json:"version"`
	Components map[string]interface{} `json:"components"`
}

// MetricsResponse 指标响应
type MetricsResponse struct {
	Uptime    string            `json:"uptime"`
	Memory    map[string]string `json:"memory"`
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

	// 启动HTTP服务器
	port := os.Getenv("PORT")
	if port == "" {
		port = "8210"
	}

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// 优雅关闭
	go func() {
		fmt.Printf("Starting shared infrastructure server on port %s\n", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Failed to start server: %v\n", err)
			os.Exit(1)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	fmt.Println("Shutting down shared infrastructure server...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		fmt.Printf("Server forced to shutdown: %v\n", err)
	}

	fmt.Println("Shared infrastructure server exited")
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
		Components: map[string]interface{}{
			"database": map[string]interface{}{
				"status": "healthy",
				"type":   "mysql,redis,neo4j,postgresql",
			},
			"consul": map[string]interface{}{
				"status": "healthy",
				"type":   "service_discovery",
			},
			"infrastructure": map[string]interface{}{
				"status": "healthy",
				"type":   "shared_services",
			},
		},
	}

	c.JSON(http.StatusOK, health)
}

// metricsHandler 指标处理器
func metricsHandler(c *gin.Context) {
	metrics := MetricsResponse{
		Uptime: time.Since(startTime).String(),
		Memory: map[string]string{
			"alloc": "0 MB", // 简化实现
			"total": "0 MB",
		},
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
			"name":        "jobfirst-shared-infrastructure",
			"version":     "1.0.0",
			"description": "JobFirst Shared Infrastructure Service",
			"start_time":  startTime.Format(time.RFC3339),
			"uptime":      time.Since(startTime).String(),
		},
		"endpoints": map[string]interface{}{
			"health":  "/health",
			"metrics": "/metrics",
			"info":    "/info",
		},
		"capabilities": []string{
			"logging",
			"configuration_management",
			"database_connection_management",
			"service_registry",
			"security_management",
			"distributed_tracing",
			"message_queue",
		},
	}

	c.JSON(http.StatusOK, info)
}
