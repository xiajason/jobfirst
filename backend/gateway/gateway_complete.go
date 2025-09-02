package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/hashicorp/consul/api"
	"gopkg.in/yaml.v2"
)

// ConsulConfig Consul配置
type ConsulConfig struct {
	Address             string `yaml:"address"`
	Datacenter          string `yaml:"datacenter"`
	Token               string `yaml:"token"`
	ServicePrefix       string `yaml:"service_prefix"`
	HealthCheckInterval string `yaml:"health_check_interval"`
	DeregisterAfter     string `yaml:"deregister_after"`
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

		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

// isOriginAllowed 检查来源是否允许
func (g *CompleteGateway) isOriginAllowed(origin string) bool {
	if len(g.config.CORS.AllowOrigins) == 0 {
		return true
	}

	for _, allowedOrigin := range g.config.CORS.AllowOrigins {
		if allowedOrigin == "*" || allowedOrigin == origin {
			return true
		}
	}
	return false
}

// loggingMiddleware 日志中间件
func (g *CompleteGateway) loggingMiddleware() gin.HandlerFunc {
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

// rateLimitMiddleware 限流中间件
func (g *CompleteGateway) rateLimitMiddleware() gin.HandlerFunc {
	// 简化的限流实现
	return func(c *gin.Context) {
		// 这里可以实现更复杂的限流逻辑
		c.Next()
	}
}

// setupRoutes 设置路由
func (g *CompleteGateway) setupRoutes() {
	// 健康检查
	g.router.GET("/health", g.healthHandler)

	// 公开API
	for _, route := range g.config.Services.Public {
		g.router.Any(route.Path+"/*path", g.proxyHandler(route))
	}

	// V1 API (需要认证)
	v1Group := g.router.Group("/api/v1")
	v1Group.Use(g.authMiddleware())
	{
		for _, route := range g.config.Services.V1 {
			v1Group.Any(route.Path+"/*path", g.proxyHandler(route))
		}
	}

	// V2 API (需要认证)
	v2Group := g.router.Group("/api/v2")
	v2Group.Use(g.authMiddleware())
	{
		for _, route := range g.config.Services.V2 {
			v2Group.Any(route.Path+"/*path", g.proxyHandler(route))
		}
	}

	// Admin API (需要管理员权限)
	adminGroup := g.router.Group("/api/admin")
	adminGroup.Use(g.authMiddleware(), g.adminMiddleware())
	{
		for _, route := range g.config.Services.Admin {
			adminGroup.Any(route.Path+"/*path", g.proxyHandler(route))
		}
	}
}

// healthHandler 健康检查处理器
func (g *CompleteGateway) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "jobfirst-gateway",
		"version":   "1.0.0",
	})
}

// authMiddleware 认证中间件
func (g *CompleteGateway) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"code":    "UNAUTHORIZED",
				"message": "未授权访问",
			})
			c.Abort()
			return
		}

		// 移除Bearer前缀
		if len(token) > 7 && token[:7] == "Bearer " {
			token = token[7:]
		}

		// 验证JWT token
		claims, err := g.validateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid token",
				"code":    "INVALID_TOKEN",
				"message": "无效的访问令牌",
			})
			c.Abort()
			return
		}

		// 将用户信息存储到上下文中
		c.Set("user_id", claims.UserID)
		c.Set("username", claims.Username)
		c.Set("email", claims.Email)
		c.Set("roles", claims.Roles)

		c.Next()
	}
}

// adminMiddleware 管理员权限中间件
func (g *CompleteGateway) adminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		roles, exists := c.Get("roles")
		if !exists {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"code":    "FORBIDDEN",
				"message": "访问被拒绝",
			})
			c.Abort()
			return
		}

		userRoles := roles.([]string)
		hasAdminRole := false
		for _, role := range userRoles {
			if role == "admin" || role == "super_admin" {
				hasAdminRole = true
				break
			}
		}

		if !hasAdminRole {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"code":    "FORBIDDEN",
				"message": "需要管理员权限",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// validateToken 验证JWT token
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

// getServiceURL 获取服务URL
func (g *CompleteGateway) getServiceURL(serviceName string) string {
	// 从Consul获取服务地址
	services, _, err := g.consul.Health().Service(serviceName, "", true, nil)
	if err != nil {
		return ""
	}

	if len(services) == 0 {
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

// main函数已移至enhanced_gateway_simple.go
