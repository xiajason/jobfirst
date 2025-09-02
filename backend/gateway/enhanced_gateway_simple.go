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
		V2     []ServiceRoute `yaml:"admin"`
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
	config *EnhancedGatewayConfig
	router *gin.Engine
	client *http.Client
}

// NewEnhancedGateway 创建增强版网关
func NewEnhancedGateway(config *EnhancedGatewayConfig) (*EnhancedGateway, error) {
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

// setupRoutes 设置路由
func (g *EnhancedGateway) setupRoutes() {
	// 健康检查端点
	g.router.GET("/health", g.healthHandler)
	g.router.GET("/info", g.infoHandler)

	// 设置API路由
	g.setupAPIRoutes()
}

// healthHandler 健康检查处理器
func (g *EnhancedGateway) healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "jobfirst-gateway",
		"version":   "1.0.0",
	})
}

// infoHandler 信息处理器
func (g *EnhancedGateway) infoHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service":   "jobfirst-gateway",
		"version":   "1.0.0",
		"timestamp": time.Now().Unix(),
		"features": []string{
			"JWT Authentication",
			"CORS Support",
			"API Versioning",
			"Service Discovery",
			"Load Balancing",
		},
	})
}

// setupAPIRoutes 设置API路由
func (g *EnhancedGateway) setupAPIRoutes() {
	// 公开路由
	for _, route := range g.config.Services.Public {
		g.router.Any(route.Path+"/*path", g.proxyHandler(route))
	}

	// V1 API路由
	v1Group := g.router.Group("/api/v1")
	for _, route := range g.config.Services.V1 {
		v1Group.Any(route.Path+"/*path", g.authMiddleware(), g.proxyHandler(route))
	}

	// V2 API路由
	v2Group := g.router.Group("/api/v2")
	for _, route := range g.config.Services.V2 {
		v2Group.Any(route.Path+"/*path", g.authMiddleware(), g.proxyHandler(route))
	}

	// 管理员路由
	adminGroup := g.router.Group("/admin")
	for _, route := range g.config.Services.Admin {
		adminGroup.Any(route.Path+"/*path", g.adminAuthMiddleware(), g.proxyHandler(route))
	}
}

// authMiddleware 认证中间件
func (g *EnhancedGateway) authMiddleware() gin.HandlerFunc {
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
func (g *EnhancedGateway) adminAuthMiddleware() gin.HandlerFunc {
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

// hasAdminRole 检查是否有管理员角色
func (g *EnhancedGateway) hasAdminRole(roles []string) bool {
	for _, role := range roles {
		if role == "admin" || role == "super_admin" {
			return true
		}
	}
	return false
}

// proxyHandler 代理处理器
func (g *EnhancedGateway) proxyHandler(route ServiceRoute) gin.HandlerFunc {
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

		// 添加用户信息到请求头
		if userID, exists := c.Get("user_id"); exists {
			req.Header.Set("X-User-ID", userID.(string))
		}
		if username, exists := c.Get("username"); exists {
			req.Header.Set("X-Username", username.(string))
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

// getServiceURL 获取服务URL
func (g *EnhancedGateway) getServiceURL(serviceName string) string {
	// 简化的服务发现，使用固定映射
	serviceMap := map[string]string{
		"user-service":          "http://localhost:8081",
		"resume-service":        "http://localhost:8087",
		"personal-service":      "http://localhost:6001",
		"admin-service":         "http://localhost:8003",
		"shared-infrastructure": "http://localhost:8000",
	}

	if url, exists := serviceMap[serviceName]; exists {
		return url
	}

	// 如果找不到服务，返回默认地址
	return "http://localhost:8080"
}

// Run 启动网关
func (g *EnhancedGateway) Run() error {
	addr := fmt.Sprintf("%s:%d", g.config.Server.Host, g.config.Server.Port)
	log.Printf("Starting JobFirst Gateway on %s", addr)
	return g.router.Run(addr)
}

// generateSecretKey 生成随机密钥
func generateSecretKey() string {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		// 如果随机数生成失败，使用时间戳作为备选
		return base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%d", time.Now().UnixNano())))
	}
	return base64.StdEncoding.EncodeToString(bytes)
}

// main 主函数
func main() {
	config := &EnhancedGatewayConfig{}
	config.Server.Port = 8000
	config.Server.Host = "0.0.0.0"
	config.JWT.SecretKey = generateSecretKey()
	config.JWT.Issuer = "jobfirst-gateway"
	config.JWT.Audience = "jobfirst-api"
	config.JWT.ExpireTime = 24 * time.Hour
	config.JWT.RefreshTime = 7 * 24 * time.Hour

	config.CORS.AllowOrigins = []string{"*"}
	config.CORS.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"}
	config.CORS.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With"}
	config.CORS.ExposeHeaders = []string{"Content-Length", "Content-Type"}
	config.CORS.AllowCredentials = true
	config.CORS.MaxAge = 86400

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

	gateway, err := NewEnhancedGateway(config)
	if err != nil {
		log.Fatalf("Failed to create gateway: %v", err)
	}

	if err := gateway.Run(); err != nil {
		log.Fatalf("Failed to start gateway: %v", err)
	}
}
