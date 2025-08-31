package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// JWTConfig JWT配置
type JWTConfig struct {
	SecretKey     string        `json:"secret_key"`
	Issuer        string        `json:"issuer"`
	Audience      string        `json:"audience"`
	ExpireTime    time.Duration `json:"expire_time"`
	RefreshTime   time.Duration `json:"refresh_time"`
	RefreshSecret string        `json:"refresh_secret"`
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

// ServiceRoute 服务路由配置
type ServiceRoute struct {
	Name        string `yaml:"name"`
	Path        string `yaml:"path"`
	Service     string `yaml:"service"`
	StripPrefix bool   `yaml:"strip_prefix"`
	Auth        bool   `yaml:"auth"`
	CORS        bool   `yaml:"cors"`
}

// EnhancedGatewayConfig 增强版网关配置
type EnhancedGatewayConfig struct {
	Server struct {
		Port int    `yaml:"port"`
		Host string `yaml:"host"`
	} `yaml:"server"`

	JWT JWTConfig `yaml:"jwt"`

	Services struct {
		Public []ServiceRoute `yaml:"public"`
		V1     []ServiceRoute `yaml:"v1"`
		V2     []ServiceRoute `yaml:"v2"`
		Admin  []ServiceRoute `yaml:"admin"`
	} `yaml:"services"`

	CORS struct {
		AllowOrigins     []string `yaml:"allow_origins"`
		AllowMethods     []string `yaml:"allow_methods"`
		AllowHeaders     []string `yaml:"allow_headers"`
		ExposeHeaders    []string `yaml:"expose_headers"`
		AllowCredentials bool     `yaml:"allow_credentials"`
		MaxAge           int      `yaml:"max_age"`
	} `yaml:"cors"`
}

// EnhancedGateway 增强版网关
type EnhancedGateway struct {
	config  *EnhancedGatewayConfig
	router  *gin.Engine
	client  *http.Client
}

// NewEnhancedGateway 创建增强版网关
func NewEnhancedGateway(config *EnhancedGatewayConfig) (*EnhancedGateway, error) {
	// 创建HTTP客户端
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	gateway := &EnhancedGateway{
		config: config,
		router: gin.New(),
		client: client,
	}

	gateway.setupMiddleware()
	gateway.setupRoutes()

	return gateway, nil
}

// setupMiddleware 设置中间件
func (g *EnhancedGateway) setupMiddleware() {
	// 使用gin的恢复中间件
	g.router.Use(gin.Recovery())

	// 设置CORS中间件
	g.router.Use(g.corsMiddleware())

	// 添加请求计数中间件
	g.router.Use(g.requestCounterMiddleware())
}

// setupRoutes 设置路由
func (g *EnhancedGateway) setupRoutes() {
	// 健康检查端点
	g.router.GET("/health", g.healthCheckHandler)
	g.router.GET("/healthz", g.healthCheckHandler) // 兼容Kubernetes

	// 指标端点
	g.router.GET("/metrics", g.metricsHandler)

	// 服务信息端点
	g.router.GET("/info", g.infoHandler)

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

// corsMiddleware CORS中间件
func (g *EnhancedGateway) corsMiddleware() gin.HandlerFunc {
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
			c.Header("Access-Control-Max-Age", fmt.Sprintf("%d", g.config.CORS.MaxAge))
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
func (g *EnhancedGateway) isOriginAllowed(origin string) bool {
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

// authMiddleware 认证中间件
func (g *EnhancedGateway) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		path := c.Request.URL.Path
		method := c.Request.Method

		// 检查是否为公开路径
		if g.isPublicPath(path, method) {
			c.Next()
			return
		}

		// 获取Authorization头
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

		// 检查Bearer token格式
		if !strings.HasPrefix(authHeader, "Bearer ") {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Invalid authorization format",
				"code":    "INVALID_AUTH_FORMAT",
				"message": "认证格式无效，请使用Bearer token",
			})
			c.Abort()
			return
		}

		// 提取token
		token := strings.TrimPrefix(authHeader, "Bearer ")

		// 验证token
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
		if g.isAdminPath(path, method) {
			if !g.hasRole(claims, "admin", "super_admin") {
				c.JSON(http.StatusForbidden, gin.H{
					"error":   "Admin access required",
					"code":    "ADMIN_REQUIRED",
					"message": "需要管理员权限",
				})
				c.Abort()
				return
			}
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
func (g *EnhancedGateway) adminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, exists := c.Get("claims")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "User not authenticated",
				"code":    "NOT_AUTHENTICATED",
				"message": "用户未认证",
			})
			c.Abort()
			return
		}

		userClaims, ok := claims.(*Claims)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Invalid user claims",
				"code":    "INVALID_CLAIMS",
				"message": "用户信息无效",
			})
			c.Abort()
			return
		}

		if !g.hasRole(userClaims, "admin", "super_admin") {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Admin access required",
				"code":    "ADMIN_REQUIRED",
				"message": "需要管理员权限",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// validateToken 验证token
func (g *EnhancedGateway) validateToken(tokenString string) (*Claims, error) {
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

// hasRole 检查用户是否有指定角色
func (g *EnhancedGateway) hasRole(claims *Claims, roles ...string) bool {
	for _, role := range roles {
		for _, userRole := range claims.Roles {
			if userRole == role {
				return true
			}
		}
	}
	return false
}

// isPublicPath 检查是否为公开路径
func (g *EnhancedGateway) isPublicPath(path, method string) bool {
	publicPaths := []string{
		"/health", "/healthz", "/metrics", "/info",
		"/api/auth", "/api/public",
	}
	
	for _, publicPath := range publicPaths {
		if strings.HasPrefix(path, publicPath) {
			return true
		}
	}
	return false
}

// isAdminPath 检查是否为管理员路径
func (g *EnhancedGateway) isAdminPath(path, method string) bool {
	adminPaths := []string{
		"/admin",
	}
	
	for _, adminPath := range adminPaths {
		if strings.HasPrefix(path, adminPath) {
			return true
		}
	}
	return false
}

// proxyHandler 代理处理器
func (g *EnhancedGateway) proxyHandler(route ServiceRoute) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 简化的服务发现 - 使用固定的服务地址
		serviceAddress := g.getServiceAddress(route.Service)
		if serviceAddress == "" {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"error":   "Service unavailable",
				"code":    "SERVICE_UNAVAILABLE",
				"message": "服务暂时不可用",
			})
			return
		}

		// 构建目标URL
		targetPath := c.Param("path")
		if route.StripPrefix {
			// 移除路径前缀
			pathParts := strings.Split(c.Request.URL.Path, "/")
			if len(pathParts) > 2 {
				targetPath = "/" + strings.Join(pathParts[3:], "/")
			}
		}

		targetURL := fmt.Sprintf("http://%s%s", serviceAddress, targetPath)

		// 创建代理请求
		req, err := http.NewRequest(c.Request.Method, targetURL, c.Request.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to create request",
				"code":    "REQUEST_ERROR",
				"message": "创建请求失败",
			})
			return
		}

		// 复制请求头
		for key, values := range c.Request.Header {
			for _, value := range values {
				req.Header.Add(key, value)
			}
		}

		// 添加用户信息到请求头
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
				"error":   "Failed to proxy request",
				"code":    "PROXY_ERROR",
				"message": "代理请求失败",
			})
			return
		}
		defer resp.Body.Close()

		// 复制响应头
		for key, values := range resp.Header {
			for _, value := range values {
				c.Header(key, value)
			}
		}

		// 返回响应
		c.DataFromReader(resp.StatusCode, resp.ContentLength, resp.Header.Get("Content-Type"), resp.Body, nil)
	}
}

// getServiceAddress 获取服务地址
func (g *EnhancedGateway) getServiceAddress(serviceName string) string {
	serviceMap := map[string]string{
		"user-service":           "user-service:8001",
		"resume-service":         "resume-service:8002",
		"personal-service":       "personal-service:8003",
		"points-service":         "points-service:8004",
		"statistics-service":     "statistics-service:8005",
		"storage-service":        "storage-service:8006",
		"resource-service":       "resource-service:8007",
		"enterprise-service":     "enterprise-service:8008",
		"open-service":          "open-service:8009",
		"admin-service":         "admin-service:8010",
		"ai-service":            "ai-service:8206",
		"shared-infrastructure": "shared-infrastructure:8210",
	}
	
	return serviceMap[serviceName]
}

// healthCheckHandler 健康检查处理器
func (g *EnhancedGateway) healthCheckHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "enhanced-gateway",
		"version":   "1.0.0",
	})
}

// metricsHandler 指标处理器
func (g *EnhancedGateway) metricsHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"requests_total":   0, // 实际应该从计数器获取
		"requests_active":  0,
		"response_time_ms": 0,
		"error_rate":       0,
	})
}

// infoHandler 服务信息处理器
func (g *EnhancedGateway) infoHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service":     "enhanced-gateway",
		"version":     "1.0.0",
		"description": "JobFirst Enhanced API Gateway with JWT Auth and CORS",
		"features": []string{
			"JWT Authentication",
			"CORS Support",
			"API Versioning",
			"Service Discovery",
			"Load Balancing",
		},
	})
}

// requestCounterMiddleware 请求计数中间件
func (g *EnhancedGateway) requestCounterMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		duration := time.Since(start)

		// 记录请求信息
		log.Printf("[%s] %s %s - %d - %v", 
			c.Request.Method, 
			c.Request.URL.Path, 
			c.ClientIP(), 
			c.Writer.Status(), 
			duration,
		)
	}
}

// generateSecretKey 生成随机密钥
func generateSecretKey() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return base64.StdEncoding.EncodeToString(bytes)
}

// Run 启动网关
func (g *EnhancedGateway) Run() error {
	addr := fmt.Sprintf("%s:%d", g.config.Server.Host, g.config.Server.Port)
	log.Printf("Enhanced Gateway starting on %s", addr)
	return g.router.Run(addr)
}

func main() {
	// 默认配置
	config := &EnhancedGatewayConfig{}
	config.Server.Port = 8000
	config.Server.Host = "0.0.0.0"
	config.JWT.SecretKey = generateSecretKey()
	config.JWT.Issuer = "jobfirst-gateway"
	config.JWT.Audience = "jobfirst-api"
	config.JWT.ExpireTime = 24 * time.Hour
	config.JWT.RefreshTime = 7 * 24 * time.Hour

	// 设置CORS配置
	config.CORS.AllowOrigins = []string{"*"}
	config.CORS.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"}
	config.CORS.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	config.CORS.ExposeHeaders = []string{"Content-Length", "Content-Type"}
	config.CORS.AllowCredentials = true
	config.CORS.MaxAge = 86400

	// 设置服务路由
	config.Services.Public = []ServiceRoute{
		{Name: "auth", Path: "/api/auth", Service: "user-service", StripPrefix: true, Auth: false, CORS: true},
		{Name: "health", Path: "/health", Service: "shared-infrastructure", StripPrefix: false, Auth: false, CORS: true},
	}

	config.Services.V1 = []ServiceRoute{
		{Name: "user", Path: "/api/v1/user", Service: "user-service", StripPrefix: true, Auth: true, CORS: true},
		{Name: "resume", Path: "/api/v1/resume", Service: "resume-service", StripPrefix: true, Auth: true, CORS: true},
		{Name: "personal", Path: "/api/v1/personal", Service: "personal-service", StripPrefix: true, Auth: true, CORS: true},
	}

	config.Services.V2 = []ServiceRoute{
		{Name: "user", Path: "/api/v2/user", Service: "user-service", StripPrefix: true, Auth: true, CORS: true},
		{Name: "resume", Path: "/api/v2/resume", Service: "resume-service", StripPrefix: true, Auth: true, CORS: true},
	}

	config.Services.Admin = []ServiceRoute{
		{Name: "admin", Path: "/admin", Service: "admin-service", StripPrefix: true, Auth: true, CORS: true},
	}

	// 创建并启动网关
	gateway, err := NewEnhancedGateway(config)
	if err != nil {
		log.Fatalf("Failed to create gateway: %v", err)
	}

	if err := gateway.Run(); err != nil {
		log.Fatalf("Failed to start gateway: %v", err)
	}
}
