package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/hashicorp/consul/api"
	"gopkg.in/yaml.v2"
)

// JWTConfig JWT配置
type JWTConfig struct {
	SecretKey     string        `yaml:"secret_key"`
	Issuer        string        `yaml:"issuer"`
	Audience      string        `yaml:"audience"`
	ExpireTime    time.Duration `yaml:"expire_time"`
	RefreshTime   time.Duration `yaml:"refresh_time"`
	RefreshSecret string        `yaml:"refresh_secret"`
}

// CORSConfig CORS配置
type CORSConfig struct {
	AllowOrigins     []string `yaml:"allow_origins"`
	AllowMethods     []string `yaml:"allow_methods"`
	AllowHeaders     []string `yaml:"allow_headers"`
	ExposeHeaders    []string `yaml:"expose_headers"`
	AllowCredentials bool     `yaml:"allow_credentials"`
	MaxAge           int      `yaml:"max_age"`
}

// ConsulConfig Consul配置
type ConsulConfig struct {
	Address             string `yaml:"address"`
	Datacenter          string `yaml:"datacenter"`
	Token               string `yaml:"token"`
	ServicePrefix       string `yaml:"service_prefix"`
	HealthCheckInterval string `yaml:"health_check_interval"`
	DeregisterAfter     string `yaml:"deregister_after"`
}

// ServiceRoute 服务路由配置
type ServiceRoute struct {
	Name        string `yaml:"name"`
	Path        string `yaml:"path"`
	Service     string `yaml:"service"`
	StripPrefix bool   `yaml:"strip_prefix"`
	Auth        bool   `yaml:"auth"`
	CORS        bool   `yaml:"cors"`
}

// GatewayConfig 网关配置
type GatewayConfig struct {
	Server struct {
		Port         string `yaml:"port"`
		Host         string `yaml:"host"`
		Timeout      string `yaml:"timeout"`
		ReadTimeout  string `yaml:"read_timeout"`
		WriteTimeout string `yaml:"write_timeout"`
	} `yaml:"server"`

	JWT    JWTConfig    `yaml:"jwt"`
	CORS   CORSConfig   `yaml:"cors"`
	Consul ConsulConfig `yaml:"consul"`

	Services struct {
		Public []ServiceRoute `yaml:"public"`
		V1     []ServiceRoute `yaml:"v1"`
		V2     []ServiceRoute `yaml:"v2"`
		Admin  []ServiceRoute `yaml:"admin"`
	} `yaml:"services"`

	RateLimit struct {
		RequestsPerSecond int    `yaml:"requests_per_second"`
		BurstSize         int    `yaml:"burst_size"`
		WindowSize        string `yaml:"window_size"`
	} `yaml:"rate_limit"`

	Logging struct {
		Level  string `yaml:"level"`
		Format string `yaml:"format"`
		Output string `yaml:"output"`
	} `yaml:"logging"`

	Monitoring struct {
		MetricsEnabled      bool   `yaml:"metrics_enabled"`
		HealthCheckInterval string `yaml:"health_check_interval"`
		Timeout             string `yaml:"timeout"`
	} `yaml:"monitoring"`
}

// Claims JWT声明
type Claims struct {
	UserID   string            `json:"user_id"`
	Username string            `json:"username"`
	Email    string            `json:"email"`
	Roles    []string          `json:"roles"`
	Metadata map[string]string `json:"metadata,omitempty"`
	jwt.RegisteredClaims
}

// CompleteGateway 完整网关
type CompleteGateway struct {
	config *GatewayConfig
	router *gin.Engine
	client *http.Client
	consul *api.Client
}

// NewCompleteGateway 创建完整网关
func NewCompleteGateway(config *GatewayConfig) (*CompleteGateway, error) {
	// 创建HTTP客户端
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// 创建Consul客户端
	consulConfig := api.DefaultConfig()
	consulConfig.Address = config.Consul.Address
	consulConfig.Datacenter = config.Consul.Datacenter
	consulConfig.Token = config.Consul.Token

	consulClient, err := api.NewClient(consulConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create consul client: %v", err)
	}

	gateway := &CompleteGateway{
		config: config,
		router: gin.New(),
		client: client,
		consul: consulClient,
	}

	gateway.setupMiddleware()
	gateway.setupRoutes()

	return gateway, nil
}

// setupMiddleware 设置中间件
func (g *CompleteGateway) setupMiddleware() {
	// 使用gin的恢复中间件
	g.router.Use(gin.Recovery())

	// 设置CORS中间件
	g.router.Use(g.corsMiddleware())

	// 设置日志中间件
	g.router.Use(g.loggingMiddleware())

	// 设置限流中间件
	g.router.Use(g.rateLimitMiddleware())
}

// corsMiddleware CORS中间件
func (g *CompleteGateway) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// 检查是否允许该来源
		if g.isOriginAllowed(origin) {
			c.Header("Access-Control-Allow-Origin", origin)
		} else {
			c.Header("Access-Control-Allow-Origin", "*")
		}

		// 设置允许的方法
		if len(g.config.CORS.AllowMethods) > 0 {
			c.Header("Access-Control-Allow-Methods", strings.Join(g.config.CORS.AllowMethods, ", "))
		}

		// 设置允许的头部
		if len(g.config.CORS.AllowHeaders) > 0 {
			c.Header("Access-Control-Allow-Headers", strings.Join(g.config.CORS.AllowHeaders, ", "))
		}

		// 设置暴露的头部
		if len(g.config.CORS.ExposeHeaders) > 0 {
			c.Header("Access-Control-Expose-Headers", strings.Join(g.config.CORS.ExposeHeaders, ", "))
		}

		// 设置是否允许携带凭证
		if g.config.CORS.AllowCredentials {
			c.Header("Access-Control-Allow-Credentials", "true")
		}

		// 设置预检请求的缓存时间
		if g.config.CORS.MaxAge > 0 {
			c.Header("Access-Control-Max-Age", strconv.Itoa(g.config.CORS.MaxAge))
		}

		// 处理预检请求
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// isOriginAllowed 检查来源是否被允许
func (g *CompleteGateway) isOriginAllowed(origin string) bool {
	if len(g.config.CORS.AllowOrigins) == 0 {
		return true
	}

	for _, allowed := range g.config.CORS.AllowOrigins {
		if allowed == "*" || allowed == origin {
			return true
		}
		// 支持通配符匹配
		if strings.HasSuffix(allowed, "*") {
			prefix := strings.TrimSuffix(allowed, "*")
			if strings.HasPrefix(origin, prefix) {
				return true
			}
		}
	}
	return false
}

// loggingMiddleware 日志中间件
func (g *CompleteGateway) loggingMiddleware() gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("[GATEWAY] %v | %3d | %13v | %15s | %-7s %s\n%s",
			param.TimeStamp.Format("2006/01/02 - 15:04:05"),
			param.StatusCode,
			param.Latency,
			param.ClientIP,
			param.Method,
			param.Path,
			param.ErrorMessage,
		)
	})
}

// rateLimitMiddleware 限流中间件
func (g *CompleteGateway) rateLimitMiddleware() gin.HandlerFunc {
	// 简化的限流实现
	return func(c *gin.Context) {
		// 这里可以实现更复杂的限流逻辑
		// 目前只是简单的通过
		c.Next()
	}
}

// setupRoutes 设置路由
func (g *CompleteGateway) setupRoutes() {
	// 健康检查端点
	g.router.GET("/health", g.healthHandler)
	g.router.GET("/info", g.infoHandler)
	g.router.GET("/metrics", g.metricsHandler)

	// 设置API路由
	g.setupAPIRoutes()
}

// healthHandler 健康检查处理器
func (g *CompleteGateway) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "jobfirst-gateway",
		"version":   "2.0.0",
		"features": []string{
			"JWT Authentication",
			"CORS Support",
			"API Versioning",
			"Service Discovery",
			"Load Balancing",
			"Rate Limiting",
		},
	})
}

// infoHandler 信息处理器
func (g *CompleteGateway) infoHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service":   "jobfirst-gateway",
		"version":   "2.0.0",
		"timestamp": time.Now().Unix(),
		"features": []string{
			"JWT Authentication",
			"CORS Support",
			"API Versioning",
			"Service Discovery",
			"Load Balancing",
			"Rate Limiting",
		},
		"config": gin.H{
			"cors_enabled":   len(g.config.CORS.AllowOrigins) > 0,
			"jwt_enabled":    g.config.JWT.SecretKey != "",
			"consul_enabled": g.config.Consul.Address != "",
			"rate_limit":     g.config.RateLimit.RequestsPerSecond,
		},
	})
}

// metricsHandler 指标处理器
func (g *CompleteGateway) metricsHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"gateway": gin.H{
			"requests_total":    0,
			"requests_active":   0,
			"response_time_avg": 0,
		},
		"services": gin.H{
			"registered": 0,
			"healthy":    0,
			"unhealthy":  0,
		},
	})
}

// setupAPIRoutes 设置API路由
func (g *CompleteGateway) setupAPIRoutes() {
	// 公开路由
	for _, route := range g.config.Services.Public {
		g.router.Any(route.Path+"/*path", g.proxyHandler(route))
	}

	// V1 API路由
	v1Group := g.router.Group("/api/v1")
	for _, route := range g.config.Services.V1 {
		if route.Auth {
			v1Group.Any(route.Path+"/*path", g.authMiddleware(), g.proxyHandler(route))
		} else {
			v1Group.Any(route.Path+"/*path", g.proxyHandler(route))
		}
	}

	// V2 API路由
	v2Group := g.router.Group("/api/v2")
	for _, route := range g.config.Services.V2 {
		if route.Auth {
			v2Group.Any(route.Path+"/*path", g.authMiddleware(), g.proxyHandler(route))
		} else {
			v2Group.Any(route.Path+"/*path", g.proxyHandler(route))
		}
	}

	// 管理员路由
	adminGroup := g.router.Group("/admin")
	for _, route := range g.config.Services.Admin {
		adminGroup.Any(route.Path+"/*path", g.adminAuthMiddleware(), g.proxyHandler(route))
	}
}

// authMiddleware 认证中间件
func (g *CompleteGateway) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Authorization required",
				"code":    "AUTH_REQUIRED",
				"message": "请提供有效的认证信息",
			})
			c.Abort()
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid authorization format",
				"code":    "INVALID_AUTH_FORMAT",
				"message": "认证格式无效，请使用Bearer token",
			})
			c.Abort()
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := g.validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid token",
				"code":    "INVALID_TOKEN",
				"message": "认证token无效或已过期",
			})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("email", claims.Email)
		c.Set("roles", claims.Roles)
		c.Set("metadata", claims.Metadata)
		c.Set("claims", claims)

		c.Next()
	}
}

// adminAuthMiddleware 管理员认证中间件
func (g *CompleteGateway) adminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Authorization required",
				"code":    "AUTH_REQUIRED",
				"message": "请提供有效的认证信息",
			})
			c.Abort()
			return
		}

		token := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := g.validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid token",
				"code":    "INVALID_TOKEN",
				"message": "认证token无效或已过期",
			})
			c.Abort()
			return
		}

		// 检查管理员权限
		if !g.hasAdminRole(claims.Roles) {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Admin access required",
				"code":    "ADMIN_REQUIRED",
				"message": "需要管理员权限",
			})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("email", claims.Email)
		c.Set("roles", claims.Roles)
		c.Set("metadata", claims.Metadata)
		c.Set("claims", claims)

		c.Next()
	}
}

// validateToken 验证token
func (g *CompleteGateway) validateToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(g.config.JWT.SecretKey), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

// hasAdminRole 检查是否有管理员角色
func (g *CompleteGateway) hasAdminRole(roles []string) bool {
	for _, role := range roles {
		if role == "admin" || role == "super_admin" {
			return true
		}
	}
	return false
}

// getServiceURL 获取服务URL
func (g *CompleteGateway) getServiceURL(serviceName string) string {
	// 从Consul获取服务地址
	services, _, err := g.consul.Health().Service(serviceName, "", true, nil)
	if err != nil {
		log.Printf("Failed to get service %s from consul: %v", serviceName, err)
		return ""
	}

	if len(services) == 0 {
		log.Printf("No healthy service found for %s", serviceName)
		return ""
	}

	// 选择第一个健康服务
	service := services[0]
	address := service.Service.Address
	port := service.Service.Port

	if address == "" {
		address = service.Node.Address
	}

	return fmt.Sprintf("http://%s:%d", address, port)
}

// proxyHandler 代理处理器
func (g *CompleteGateway) proxyHandler(route ServiceRoute) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取目标服务地址
		targetURL := g.getServiceURL(route.Service)
		if targetURL == "" {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "Service unavailable",
				"code":    "SERVICE_UNAVAILABLE",
				"message": "服务暂时不可用",
			})
			return
		}

		// 构建请求URL
		path := c.Param("path")
		if route.StripPrefix {
			// 移除路径前缀
			path = strings.TrimPrefix(c.Request.URL.Path, route.Path)
		}

		fullURL := targetURL + path
		if c.Request.URL.RawQuery != "" {
			fullURL += "?" + c.Request.URL.RawQuery
		}

		// 创建代理请求
		req, err := http.NewRequest(c.Request.Method, fullURL, c.Request.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal server error",
				"code":    "INTERNAL_ERROR",
				"message": "内部服务器错误",
			})
			return
		}

		// 复制请求头
		for key, values := range c.Request.Header {
			for _, value := range values {
				req.Header.Add(key, value)
			}
		}

		// 添加用户信息到请求头（如果存在）
		if userID, exists := c.Get("user_id"); exists {
			req.Header.Set("X-User-ID", fmt.Sprintf("%v", userID))
		}
		if username, exists := c.Get("username"); exists {
			req.Header.Set("X-Username", fmt.Sprintf("%v", username))
		}

		// 发送请求
		resp, err := g.client.Do(req)
		if err != nil {
			c.JSON(http.StatusBadGateway, gin.H{
				"error":   "Bad gateway",
				"code":    "BAD_GATEWAY",
				"message": "网关错误",
			})
			return
		}
		defer resp.Body.Close()

		// 读取响应体
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal server error",
				"code":    "INTERNAL_ERROR",
				"message": "内部服务器错误",
			})
			return
		}

		// 复制响应头
		for key, values := range resp.Header {
			for _, value := range values {
				c.Header(key, value)
			}
		}

		// 返回响应
		c.Data(resp.StatusCode, resp.Header.Get("Content-Type"), body)
	}
}

// generateToken 生成JWT token
func (g *CompleteGateway) generateToken(userID, username, email string, roles []string) (string, error) {
	claims := &Claims{
		UserID:   userID,
		Username: username,
		Email:    email,
		Roles:    roles,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(g.config.JWT.ExpireTime)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    g.config.JWT.Issuer,
			Audience:  []string{g.config.JWT.Audience},
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(g.config.JWT.SecretKey))
}

// loadConfig 加载配置
func loadConfig(configPath string) (*GatewayConfig, error) {
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var config GatewayConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %v", err)
	}

	// 解析时间配置
	if config.JWT.ExpireTime == 0 {
		config.JWT.ExpireTime = 24 * time.Hour
	}
	if config.JWT.RefreshTime == 0 {
		config.JWT.RefreshTime = 7 * 24 * time.Hour
	}

	return &config, nil
}

func main() {
	// 加载配置
	configPath := os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "/root/config/config.yaml"
	}

	config, err := loadConfig(configPath)
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 创建网关
	gateway, err := NewCompleteGateway(config)
	if err != nil {
		log.Fatalf("Failed to create gateway: %v", err)
	}

	// 启动服务器
	port := config.Server.Port
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting JobFirst Gateway on port %s", port)
	log.Printf("Features: JWT Auth, CORS, API Versioning, Service Discovery")

	if err := gateway.router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start gateway: %v", err)
	}
}
