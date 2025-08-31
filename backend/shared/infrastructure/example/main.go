package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"resume-centre/shared/infrastructure"
)

func main() {
	// 示例1：基础使用
	basicExample()

	// 示例2：完整基础设施初始化
	fullInfrastructureExample()

	// 示例3：配置管理示例
	configExample()

	// 示例4：日志系统示例
	loggerExample()

	// 示例5：服务注册与发现示例
	serviceRegistryExample()

	// 示例6：安全管理示例
	securityExample()

	// 示例7：数据库连接示例（需要真实数据库）
	// databaseExample()
}

// basicExample 基础使用示例
func basicExample() {
	fmt.Println("=== 基础使用示例 ===")

	// 创建日志器
	logger := infrastructure.NewLogrusLogger()
	logger.Info("Hello from JobFirst infrastructure!")

	// 创建配置管理器
	config := infrastructure.NewConfig()
	config.Set("app.name", "JobFirst")
	config.Set("app.version", "1.0.0")

	appName := config.GetString("app.name")
	appVersion := config.GetString("app.version")

	logger.Info("Application info",
		infrastructure.Field{Key: "name", Value: appName},
		infrastructure.Field{Key: "version", Value: appVersion},
	)

	fmt.Println()
}

// fullInfrastructureExample 完整基础设施初始化示例
func fullInfrastructureExample() {
	fmt.Println("=== 完整基础设施初始化示例 ===")

	// 初始化全局基础设施
	err := infrastructure.InitGlobalInfrastructure()
	if err != nil {
		log.Fatalf("Failed to initialize infrastructure: %v", err)
	}

	// 获取基础设施实例
	infra := infrastructure.GetInfrastructure()
	if infra == nil {
		log.Fatal("Failed to get infrastructure")
	}

	// 健康检查
	health := infra.HealthCheck()
	fmt.Printf("Infrastructure health: %+v\n", health)

	// 关闭基础设施
	defer infrastructure.CloseGlobalInfrastructure()

	fmt.Println()
}

// configExample 配置管理示例
func configExample() {
	fmt.Println("=== 配置管理示例 ===")

	// 使用配置构建器
	builder := infrastructure.NewConfigBuilder()

	// 设置默认值
	defaults := map[string]interface{}{
		"app.name":        "JobFirst",
		"app.version":     "1.0.0",
		"app.environment": "development",
		"database.host":   "localhost",
		"database.port":   3306,
		"cache.enabled":   true,
		"cache.ttl":       "1h",
	}

	builder.WithDefaults(defaults)
	builder.WithEnvPrefix("JOBFIRST_")

	// 构建配置
	config, err := builder.Build()
	if err != nil {
		log.Fatalf("Failed to build config: %v", err)
	}

	// 读取配置
	appName := config.GetString("app.name")
	appVersion := config.GetString("app.version")
	environment := config.GetString("app.environment")
	dbHost := config.GetString("database.host")
	dbPort := config.GetInt("database.port")
	cacheEnabled := config.GetBool("cache.enabled")
	cacheTTL := config.GetDuration("cache.ttl")

	fmt.Printf("App Name: %s\n", appName)
	fmt.Printf("App Version: %s\n", appVersion)
	fmt.Printf("Environment: %s\n", environment)
	fmt.Printf("Database Host: %s\n", dbHost)
	fmt.Printf("Database Port: %d\n", dbPort)
	fmt.Printf("Cache Enabled: %t\n", cacheEnabled)
	fmt.Printf("Cache TTL: %v\n", cacheTTL)

	fmt.Println()
}

// loggerExample 日志系统示例
func loggerExample() {
	fmt.Println("=== 日志系统示例 ===")

	// 创建日志器
	logger := infrastructure.NewLogrusLogger()

	// 设置日志级别
	logger.SetLevel(infrastructure.DebugLevel)

	// 基础日志
	logger.Info("Application started")
	logger.Debug("Debug information",
		infrastructure.Field{Key: "component", Value: "main"},
		infrastructure.Field{Key: "timestamp", Value: time.Now()},
	)

	// 带上下文的日志
	ctx := context.Background()
	loggerWithContext := logger.WithContext(ctx)
	loggerWithContext.Info("Request processed",
		infrastructure.Field{Key: "user_id", Value: "12345"},
		infrastructure.Field{Key: "action", Value: "login"},
	)

	// 带字段的日志器
	loggerWithFields := logger.WithFields(
		infrastructure.Field{Key: "service", Value: "user-service"},
		infrastructure.Field{Key: "version", Value: "1.0.0"},
	)

	loggerWithFields.Info("User service operation",
		infrastructure.Field{Key: "operation", Value: "create_user"},
		infrastructure.Field{Key: "duration", Value: "150ms"},
	)

	// 错误日志
	logger.Error("Database connection failed",
		infrastructure.Field{Key: "error", Value: "connection timeout"},
		infrastructure.Field{Key: "retry_count", Value: 3},
	)

	// 警告日志
	logger.Warn("High memory usage detected",
		infrastructure.Field{Key: "memory_usage", Value: "85%"},
		infrastructure.Field{Key: "threshold", Value: "80%"},
	)

	fmt.Println()
}

// serviceRegistryExample 服务注册与发现示例
func serviceRegistryExample() {
	fmt.Println("=== 服务注册与发现示例 ===")

	// 创建内存服务注册器
	registry := infrastructure.NewInMemoryRegistry()

	// 注册服务
	service1 := &infrastructure.ServiceInfo{
		ID:          "user-service-1",
		Name:        "user-service",
		Address:     "localhost",
		Port:        8001,
		Tags:        []string{"api", "v1", "user"},
		Meta:        map[string]string{"version": "1.0.0", "environment": "development"},
		HealthCheck: "http://localhost:8001/health",
	}

	service2 := &infrastructure.ServiceInfo{
		ID:          "resume-service-1",
		Name:        "resume-service",
		Address:     "localhost",
		Port:        8002,
		Tags:        []string{"api", "v1", "resume"},
		Meta:        map[string]string{"version": "1.0.0", "environment": "development"},
		HealthCheck: "http://localhost:8002/health",
	}

	// 注册服务
	err := registry.Register(service1)
	if err != nil {
		fmt.Printf("Failed to register service1: %v\n", err)
		return
	}

	err = registry.Register(service2)
	if err != nil {
		fmt.Printf("Failed to register service2: %v\n", err)
		return
	}

	// 发现服务
	userServices, err := registry.Discover("user-service")
	if err != nil {
		fmt.Printf("Failed to discover user services: %v\n", err)
		return
	}

	resumeServices, err := registry.Discover("resume-service")
	if err != nil {
		fmt.Printf("Failed to discover resume services: %v\n", err)
		return
	}

	fmt.Printf("Found %d user services\n", len(userServices))
	fmt.Printf("Found %d resume services\n", len(resumeServices))

	// 列出所有服务
	allServices, err := registry.ListServices()
	if err != nil {
		fmt.Printf("Failed to list services: %v\n", err)
		return
	}

	fmt.Printf("Total services: %d\n", len(allServices))
	for _, service := range allServices {
		fmt.Printf("- %s (%s:%d)\n", service.Name, service.Address, service.Port)
	}

	// 健康检查
	err = registry.HealthCheck("user-service-1")
	if err != nil {
		fmt.Printf("Health check failed: %v\n", err)
	} else {
		fmt.Println("Health check passed")
	}

	// 监听服务变化
	registry.Watch("user-service", func(services []*infrastructure.ServiceInfo) {
		fmt.Printf("User service changed: %d services\n", len(services))
	})

	fmt.Println()
}

// securityExample 安全管理示例
func securityExample() {
	fmt.Println("=== 安全管理示例 ===")

	// 创建安全配置
	config := infrastructure.CreateDefaultSecurityConfig()
	
	// 创建安全管理器
	securityManager := infrastructure.NewSecurityManager(config, nil)

	// 密码哈希示例
	password := "mySecurePassword123"
	hash, err := securityManager.HashPassword(password)
	if err != nil {
		fmt.Printf("Failed to hash password: %v\n", err)
		return
	}

	fmt.Printf("Password hash: %s\n", hash)

	// 验证密码
	if securityManager.CheckPassword(password, hash) {
		fmt.Println("Password verification successful")
	} else {
		fmt.Println("Password verification failed")
	}

	// JWT token示例
	userID := uint(12345)
	username := "john.doe"
	role := "user"

	token, err := securityManager.GenerateJWT(userID, username, role)
	if err != nil {
		fmt.Printf("Failed to generate JWT: %v\n", err)
		return
	}

	fmt.Printf("JWT Token: %s\n", token[:50] + "...")

	// 验证JWT
	claims, err := securityManager.ValidateJWT(token)
	if err != nil {
		fmt.Printf("Failed to validate JWT: %v\n", err)
		return
	}

	fmt.Printf("JWT Claims - UserID: %d, Username: %s, Role: %s\n", 
		claims.UserID, claims.Username, claims.Role)

	// 刷新token
	refreshToken, err := securityManager.GenerateRefreshToken(userID)
	if err != nil {
		fmt.Printf("Failed to generate refresh token: %v\n", err)
		return
	}

	fmt.Printf("Refresh Token: %s\n", refreshToken[:50] + "...")

	// HMAC签名示例
	data := "important-data-to-sign"
	signature := securityManager.GenerateHMAC(data)
	fmt.Printf("HMAC Signature: %s\n", signature)

	// 验证HMAC
	if securityManager.VerifyHMAC(data, signature) {
		fmt.Println("HMAC verification successful")
	} else {
		fmt.Println("HMAC verification failed")
	}

	fmt.Println()
}

// databaseExample 数据库连接示例（需要真实数据库）
func databaseExample() {
	fmt.Println("=== 数据库连接示例 ===")

	// 创建数据库配置
	dbConfig := infrastructure.CreateDefaultDatabaseConfig()

	// 创建数据库管理器
	dbManager := infrastructure.NewDatabaseManager(dbConfig)

	// 连接数据库
	err := dbManager.Connect()
	if err != nil {
		log.Printf("Database connection failed: %v", err)
		return
	}

	// 健康检查
	health := dbManager.HealthCheck()
	fmt.Printf("Database health: %+v\n", health)

	// 获取连接
	mysqlDB := dbManager.GetMySQLConnection()
	if mysqlDB != nil {
		fmt.Println("MySQL connection available")
	}

	postgresDB := dbManager.GetPostgreSQLConnection()
	if postgresDB != nil {
		fmt.Println("PostgreSQL connection available")
	}

	neo4jDriver := dbManager.GetNeo4jConnection()
	if neo4jDriver != nil {
		fmt.Println("Neo4j connection available")
	}

	redisClient := dbManager.GetRedisConnection()
	if redisClient != nil {
		fmt.Println("Redis connection available")
	}

	// 关闭连接
	dbManager.Close()

	fmt.Println()
}
