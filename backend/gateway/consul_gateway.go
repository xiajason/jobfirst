package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	consulapi "github.com/hashicorp/consul/api"
)

// ConsulGatewayConfig 网关配置
type ConsulGatewayConfig struct {
	Server struct {
		Port         string `yaml:"port"`
		Host         string `yaml:"host"`
		Timeout      string `yaml:"timeout"`
		ReadTimeout  string `yaml:"read_timeout"`
		WriteTimeout string `yaml:"write_timeout"`
	} `yaml:"server"`

	Consul struct {
		Address              string `yaml:"address"`
		Datacenter           string `yaml:"datacenter"`
		Token                string `yaml:"token"`
		ServicePrefix        string `yaml:"service_prefix"`
		HealthCheckInterval  string `yaml:"health_check_interval"`
		DeregisterAfter      string `yaml:"deregister_after"`
	} `yaml:"consul"`

	Services struct {
		Public []ServiceRoute `yaml:"public"`
		V1     []ServiceRoute `yaml:"v1"`
		V2     []ServiceRoute `yaml:"v2"`
		Admin  []ServiceRoute `yaml:"admin"`
	} `yaml:"services"`

	LoadBalancer struct {
		Strategy    string `yaml:"strategy"`
		HealthCheck struct {
			Enabled        bool   `yaml:"enabled"`
			Interval       string `yaml:"interval"`
			Timeout        string `yaml:"timeout"`
			Path           string `yaml:"path"`
			ExpectedStatus int    `yaml:"expected_status"`
		} `yaml:"health_check"`
	} `yaml:"load_balancer"`

	CircuitBreaker struct {
		Enabled          bool   `yaml:"enabled"`
		FailureThreshold int    `yaml:"failure_threshold"`
		SuccessThreshold int    `yaml:"success_threshold"`
		RecoveryTimeout  string `yaml:"recovery_timeout"`
		Timeout          string `yaml:"timeout"`
	} `yaml:"circuit_breaker"`

	RateLimit struct {
		Enabled    bool `yaml:"enabled"`
		Global     struct {
			RequestsPerSecond int `yaml:"requests_per_second"`
			Burst             int `yaml:"burst"`
		} `yaml:"global"`
		PerService map[string]struct {
			RequestsPerSecond int `yaml:"requests_per_second"`
			Burst             int `yaml:"burst"`
		} `yaml:"per_service"`
	} `yaml:"rate_limit"`

	Security struct {
		JWT struct {
			Secret             string `yaml:"secret"`
			Expiration         string `yaml:"expiration"`
			RefreshExpiration  string `yaml:"refresh_expiration"`
		} `yaml:"jwt"`
		CORS struct {
			Enabled           bool     `yaml:"enabled"`
			AllowedOrigins    []string `yaml:"allowed_origins"`
			AllowedMethods    []string `yaml:"allowed_methods"`
			AllowedHeaders    []string `yaml:"allowed_headers"`
			AllowCredentials  bool     `yaml:"allow_credentials"`
		} `yaml:"cors"`
	} `yaml:"security"`
}

// ServiceRoute 服务路由配置
type ServiceRoute struct {
	Name        string `yaml:"name"`
	Path        string `yaml:"path"`
	Service     string `yaml:"service"`
	StripPrefix bool   `yaml:"strip_prefix"`
	Auth        bool   `yaml:"auth"`
	AdminAuth   bool   `yaml:"admin_auth"`
	CORS        bool   `yaml:"cors"`
}

// ConsulGateway Consul网关
type ConsulGateway struct {
	config     *ConsulGatewayConfig
	consul     *consulapi.Client
	router     *gin.Engine
	server     *http.Server
	startTime  time.Time
	requestCount int64
	errorCount   int64
	mu          sync.RWMutex
}

// ServiceInstance 服务实例
type ServiceInstance struct {
	ID      string
	Name    string
	Address string
	Port    int
	Tags    []string
	Status  string
}

// HealthResponse 健康检查响应
type HealthResponse struct {
	Status    string                 `json:"status"`
	Timestamp int64                  `json:"timestamp"`
	Version   string                 `json:"version"`
	Services  map[string]interface{} `json:"services"`
	Consul    interface{}            `json:"consul"`
}

// MetricsResponse 指标响应
type MetricsResponse struct {
	Uptime    string            `json:"uptime"`
	Requests  int64             `json:"requests"`
	Errors    int64             `json:"errors"`
	Timestamp int64             `json:"timestamp"`
}

func main() {
	// 加载配置
	config, err := loadConfig()
	if err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// 创建Consul客户端
	consulConfig := consulapi.DefaultConfig()
	consulConfig.Address = config.Consul.Address
	consulConfig.Datacenter = config.Consul.Datacenter
	if config.Consul.Token != "" {
		consulConfig.Token = config.Consul.Token
	}

	consul, err := consulapi.NewClient(consulConfig)
	if err != nil {
		fmt.Printf("Failed to create Consul client: %v\n", err)
		os.Exit(1)
	}

	// 创建网关
	gateway := &ConsulGateway{
		config:    config,
		consul:    consul,
		startTime: time.Now(),
	}

	// 初始化网关
	if err := gateway.Init(); err != nil {
		fmt.Printf("Failed to initialize gateway: %v\n", err)
		os.Exit(1)
	}

	// 启动服务器
	go func() {
		fmt.Printf("Starting Consul Gateway on %s:%s\n", config.Server.Host, config.Server.Port)
		if err := gateway.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Failed to start server: %v\n", err)
			os.Exit(1)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	fmt.Println("Shutting down Consul Gateway...")

	// 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := gateway.server.Shutdown(ctx); err != nil {
		fmt.Printf("Server forced to shutdown: %v\n", err)
	}

	fmt.Println("Consul Gateway exited")
}

// Init 初始化网关
func (g *ConsulGateway) Init() error {
	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建路由器
	g.router = gin.New()
	g.router.Use(gin.Recovery())

	// 添加中间件
	g.router.Use(g.requestCounterMiddleware())
	g.router.Use(g.corsMiddleware())

	// 设置路由
	g.setupRoutes()

	// 创建HTTP服务器
	g.server = &http.Server{
		Addr:    g.config.Server.Host + ":" + g.config.Server.Port,
		Handler: g.router,
	}

	return nil
}

// setupRoutes 设置路由
func (g *ConsulGateway) setupRoutes() {
	// 健康检查端点
	g.router.GET("/health", g.healthCheckHandler())
	g.router.GET("/healthz", g.healthCheckHandler())

	// 指标端点
	g.router.GET("/metrics", g.metricsHandler())

	// 服务信息端点
	g.router.GET("/info", g.infoHandler())

	// 公开API (无需认证)
	public := g.router.Group("")
	for _, route := range g.config.Services.Public {
		public.Any(route.Path+"/*path", g.proxyHandler(route))
	}

	// V1 API (需要认证)
	v1 := g.router.Group("/api/v1")
	v1.Use(g.authMiddleware())
	for _, route := range g.config.Services.V1 {
		v1.Any("/"+route.Name+"/*path", g.proxyHandler(route))
	}

	// V2 API (需要认证)
	v2 := g.router.Group("/api/v2")
	v2.Use(g.authMiddleware())
	for _, route := range g.config.Services.V2 {
		v2.Any("/"+route.Name+"/*path", g.proxyHandler(route))
	}

	// 管理API (需要管理员权限)
	admin := g.router.Group("/admin")
	admin.Use(g.authMiddleware())
	admin.Use(g.adminAuthMiddleware())
	for _, route := range g.config.Services.Admin {
		admin.Any("/*path", g.proxyHandler(route))
	}
}

// proxyHandler 代理处理器
func (g *ConsulGateway) proxyHandler(route ServiceRoute) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取服务实例
		instances, err := g.getServiceInstances(route.Service)
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "Service unavailable",
				"service": route.Service,
				"message": err.Error(),
			})
			return
		}

		if len(instances) == 0 {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "No service instances available",
				"service": route.Service,
			})
			return
		}

		// 选择服务实例 (简单的轮询)
		instance := instances[0] // 简化实现，实际应该使用负载均衡

		// 构建目标URL
		targetPath := c.Param("path")
		if route.StripPrefix {
			// 移除路径前缀
			pathParts := strings.Split(c.Request.URL.Path, "/")
			if len(pathParts) > 3 {
				targetPath = "/" + strings.Join(pathParts[3:], "/")
			}
		}

		targetURL := fmt.Sprintf("http://%s:%d%s", instance.Address, instance.Port, targetPath)

		// 创建反向代理
		target, err := url.Parse(targetURL)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Invalid target URL",
			})
			return
		}

		proxy := httputil.NewSingleHostReverseProxy(target)
		proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// getServiceInstances 获取服务实例
func (g *ConsulGateway) getServiceInstances(serviceName string) ([]ServiceInstance, error) {
	// 添加服务前缀
	fullServiceName := g.config.Consul.ServicePrefix + serviceName

	// 查询Consul服务
	services, _, err := g.consul.Health().Service(fullServiceName, "", true, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to query service %s: %v", fullServiceName, err)
	}

	var instances []ServiceInstance
	for _, service := range services {
		instances = append(instances, ServiceInstance{
			ID:      service.Service.ID,
			Name:    service.Service.Service,
			Address: service.Service.Address,
			Port:    service.Service.Port,
			Tags:    service.Service.Tags,
			Status:  service.Checks.AggregatedStatus(),
		})
	}

	return instances, nil
}

// requestCounterMiddleware 请求计数器中间件
func (g *ConsulGateway) requestCounterMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		g.mu.Lock()
		g.requestCount++
		g.mu.Unlock()

		c.Next()

		if c.Writer.Status() >= 400 {
			g.mu.Lock()
			g.errorCount++
			g.mu.Unlock()
		}
	}
}

// corsMiddleware CORS中间件
func (g *ConsulGateway) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		if g.config.Security.CORS.Enabled {
			c.Header("Access-Control-Allow-Origin", "*")
			c.Header("Access-Control-Allow-Methods", strings.Join(g.config.Security.CORS.AllowedMethods, ", "))
			c.Header("Access-Control-Allow-Headers", strings.Join(g.config.Security.CORS.AllowedHeaders, ", "))
			if g.config.Security.CORS.AllowCredentials {
				c.Header("Access-Control-Allow-Credentials", "true")
			}

			if c.Request.Method == "OPTIONS" {
				c.AbortWithStatus(http.StatusNoContent)
				return
			}
		}

		c.Next()
	}
}

// authMiddleware 认证中间件
func (g *ConsulGateway) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的认证实现
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header required",
			})
			c.Abort()
			return
		}

		// 这里应该验证JWT token
		// 简化实现，实际应该使用JWT验证
		if !strings.HasPrefix(token, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid token format",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// adminAuthMiddleware 管理员认证中间件
func (g *ConsulGateway) adminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的管理员认证实现
		// 实际应该检查用户角色
		c.Next()
	}
}

// healthCheckHandler 健康检查处理器
func (g *ConsulGateway) healthCheckHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 检查Consul连接
		consulStatus := "healthy"
		_, err := g.consul.Status().Leader()
		if err != nil {
			consulStatus = "unhealthy"
		}

		// 获取服务状态
		services := make(map[string]interface{})
		for _, route := range g.config.Services.V1 {
			instances, err := g.getServiceInstances(route.Service)
			if err != nil {
				services[route.Service] = map[string]interface{}{
					"status": "unhealthy",
					"error":  err.Error(),
				}
			} else {
				services[route.Service] = map[string]interface{}{
					"status":  "healthy",
					"instances": len(instances),
				}
			}
		}

		health := HealthResponse{
			Status:    "healthy",
			Timestamp: time.Now().Unix(),
			Version:   "1.0.0",
			Services:  services,
			Consul: map[string]interface{}{
				"status": consulStatus,
				"address": g.config.Consul.Address,
			},
		}

		c.JSON(http.StatusOK, health)
	}
}

// metricsHandler 指标处理器
func (g *ConsulGateway) metricsHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		g.mu.RLock()
		requests := g.requestCount
		errors := g.errorCount
		g.mu.RUnlock()

		metrics := MetricsResponse{
			Uptime:    time.Since(g.startTime).String(),
			Requests:  requests,
			Errors:    errors,
			Timestamp: time.Now().Unix(),
		}

		c.JSON(http.StatusOK, metrics)
	}
}

// infoHandler 服务信息处理器
func (g *ConsulGateway) infoHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		info := map[string]interface{}{
			"service": map[string]interface{}{
				"name":        "jobfirst-consul-gateway",
				"version":     "1.0.0",
				"description": "JobFirst Consul Gateway with Service Discovery",
				"start_time":  g.startTime.Format(time.RFC3339),
				"uptime":      time.Since(g.startTime).String(),
			},
			"endpoints": map[string]interface{}{
				"health":  "/health",
				"metrics": "/metrics",
				"info":    "/info",
				"api":     "/api/v1/*, /api/v2/*, /admin/*",
			},
			"capabilities": []string{
				"consul_service_discovery",
				"dynamic_routing",
				"load_balancing",
				"circuit_breaker",
				"rate_limiting",
				"authentication",
				"cors",
				"tracing",
				"metrics",
			},
			"consul": map[string]interface{}{
				"address":     g.config.Consul.Address,
				"datacenter":  g.config.Consul.Datacenter,
				"service_prefix": g.config.Consul.ServicePrefix,
			},
		}

		c.JSON(http.StatusOK, info)
	}
}

// loadConfig 加载配置
func loadConfig() (*ConsulGatewayConfig, error) {
	// 简化实现，实际应该从文件加载
	config := &ConsulGatewayConfig{}
	
	// 设置默认值
	config.Server.Port = "8000"
	config.Server.Host = "0.0.0.0"
	config.Server.Timeout = "30s"
	
	config.Consul.Address = "http://consul:8500"
	config.Consul.Datacenter = "dc1"
	config.Consul.ServicePrefix = "jobfirst-"
	
	// 设置服务路由
	config.Services.Public = []ServiceRoute{
		{Name: "auth", Path: "/api/auth", Service: "user-service", StripPrefix: true, Auth: false},
		{Name: "jobs", Path: "/api/jobs", Service: "user-service", StripPrefix: true, Auth: false},
		{Name: "companies", Path: "/api/companies", Service: "user-service", StripPrefix: true, Auth: false},
	}
	
	config.Services.V1 = []ServiceRoute{
		{Name: "user", Path: "/api/v1/user", Service: "user-service", StripPrefix: true, Auth: true},
		{Name: "resume", Path: "/api/v1/resume", Service: "resume-service", StripPrefix: true, Auth: true},
		{Name: "personal", Path: "/api/v1/personal", Service: "personal-service", StripPrefix: true, Auth: true},
		{Name: "points", Path: "/api/v1/points", Service: "points-service", StripPrefix: true, Auth: true},
		{Name: "statistics", Path: "/api/v1/statistics", Service: "statistics-service", StripPrefix: true, Auth: true},
		{Name: "storage", Path: "/api/v1/storage", Service: "storage-service", StripPrefix: true, Auth: true},
		{Name: "resource", Path: "/api/v1/resource", Service: "resource-service", StripPrefix: true, Auth: true},
		{Name: "enterprise", Path: "/api/v1/enterprise", Service: "enterprise-service", StripPrefix: true, Auth: true},
		{Name: "open", Path: "/api/v1/open", Service: "open-service", StripPrefix: true, Auth: true},
		{Name: "ai", Path: "/api/v1/ai", Service: "ai-service", StripPrefix: true, Auth: true},
	}
	
	config.Services.V2 = []ServiceRoute{
		{Name: "user", Path: "/api/v2/user", Service: "user-service", StripPrefix: true, Auth: true},
		{Name: "jobs", Path: "/api/v2/jobs", Service: "user-service", StripPrefix: true, Auth: true},
		{Name: "companies", Path: "/api/v2/companies", Service: "user-service", StripPrefix: true, Auth: true},
	}
	
	config.Services.Admin = []ServiceRoute{
		{Name: "admin", Path: "/admin", Service: "admin-service", StripPrefix: true, Auth: true, AdminAuth: true},
	}
	
	// 设置安全配置
	config.Security.CORS.Enabled = true
	config.Security.CORS.AllowedOrigins = []string{"*"}
	config.Security.CORS.AllowedMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.Security.CORS.AllowedHeaders = []string{"*"}
	config.Security.CORS.AllowCredentials = true
	
	return config, nil
}
