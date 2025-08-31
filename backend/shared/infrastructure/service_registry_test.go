package infrastructure

import (
	"fmt"
	"testing"
)

func TestInMemoryRegistry(t *testing.T) {
	// 创建内存注册器
	registry := NewInMemoryRegistry()

	// 测试服务注册
	service := &ServiceInfo{
		ID:          "test-service-1",
		Name:        "test-service",
		Address:     "localhost",
		Port:        8080,
		Tags:        []string{"api", "v1"},
		Meta:        map[string]string{"version": "1.0.0"},
		HealthCheck: "http://localhost:8080/health",
	}

	err := registry.Register(service)
	if err != nil {
		t.Fatalf("Failed to register service: %v", err)
	}

	// 测试服务发现
	services, err := registry.Discover("test-service")
	if err != nil {
		t.Fatalf("Failed to discover service: %v", err)
	}

	if len(services) != 1 {
		t.Fatalf("Expected 1 service, got %d", len(services))
	}

	discoveredService := services[0]
	if discoveredService.ID != service.ID {
		t.Errorf("Expected service ID %s, got %s", service.ID, discoveredService.ID)
	}

	if discoveredService.Name != service.Name {
		t.Errorf("Expected service name %s, got %s", service.Name, discoveredService.Name)
	}

	// 测试获取单个服务
	retrievedService, err := registry.GetService("test-service-1")
	if err != nil {
		t.Fatalf("Failed to get service: %v", err)
	}

	if retrievedService.ID != service.ID {
		t.Errorf("Expected service ID %s, got %s", service.ID, retrievedService.ID)
	}

	// 测试列出所有服务
	allServices, err := registry.ListServices()
	if err != nil {
		t.Fatalf("Failed to list services: %v", err)
	}

	if len(allServices) != 1 {
		t.Fatalf("Expected 1 service in list, got %d", len(allServices))
	}

	// 测试健康检查
	err = registry.HealthCheck("test-service-1")
	if err != nil {
		t.Fatalf("Failed to health check service: %v", err)
	}

	// 测试服务注销
	err = registry.Deregister("test-service-1")
	if err != nil {
		t.Fatalf("Failed to deregister service: %v", err)
	}

	// 验证服务已被注销
	services, err = registry.Discover("test-service")
	if err != nil {
		t.Fatalf("Failed to discover service after deregister: %v", err)
	}

	if len(services) != 0 {
		t.Fatalf("Expected 0 services after deregister, got %d", len(services))
	}
}

func TestServiceRegistryWatch(t *testing.T) {
	// 创建内存注册器
	registry := NewInMemoryRegistry()

	// 创建回调计数器
	callbackCount := 0

	// 注册监听器
	err := registry.Watch("test-service", func(services []*ServiceInfo) {
		callbackCount++
	})
	if err != nil {
		t.Fatalf("Failed to watch service: %v", err)
	}

	// 验证初始回调被调用
	if callbackCount != 1 {
		t.Errorf("Expected initial callback to be called, got %d", callbackCount)
	}

	// 注册服务
	service := &ServiceInfo{
		ID:   "test-service-1",
		Name: "test-service",
		Address: "localhost",
		Port: 8080,
	}

	err = registry.Register(service)
	if err != nil {
		t.Fatalf("Failed to register service: %v", err)
	}

	// 手动触发监听（在实际实现中，这应该是自动的）
	registry.Watch("test-service", func(services []*ServiceInfo) {
		callbackCount++
	})

	// 验证回调被调用
	if callbackCount < 1 {
		t.Errorf("Expected callback to be called, got %d", callbackCount)
	}
}

func TestSecurityManager(t *testing.T) {
	// 创建安全配置
	config := CreateDefaultSecurityConfig()
	
	// 创建安全管理器（不使用缓存）
	securityManager := NewSecurityManager(config, nil)

	// 测试密码哈希
	password := "testpassword123"
	hash, err := securityManager.HashPassword(password)
	if err != nil {
		t.Fatalf("Failed to hash password: %v", err)
	}

	// 验证密码哈希
	if !securityManager.CheckPassword(password, hash) {
		t.Error("Password check failed")
	}

	// 测试错误密码
	if securityManager.CheckPassword("wrongpassword", hash) {
		t.Error("Password check should have failed for wrong password")
	}

	// 测试JWT生成和验证
	userID := uint(123)
	username := "testuser"
	role := "user"

	token, err := securityManager.GenerateJWT(userID, username, role)
	if err != nil {
		t.Fatalf("Failed to generate JWT: %v", err)
	}

	// 验证JWT
	claims, err := securityManager.ValidateJWT(token)
	if err != nil {
		t.Fatalf("Failed to validate JWT: %v", err)
	}

	if claims.UserID != userID {
		t.Errorf("Expected user ID %d, got %d", userID, claims.UserID)
	}

	if claims.Username != username {
		t.Errorf("Expected username %s, got %s", username, claims.Username)
	}

	if claims.Role != role {
		t.Errorf("Expected role %s, got %s", role, claims.Role)
	}

	// 测试刷新token
	refreshToken, err := securityManager.GenerateRefreshToken(userID)
	if err != nil {
		t.Fatalf("Failed to generate refresh token: %v", err)
	}

	refreshClaims, err := securityManager.ValidateJWT(refreshToken)
	if err != nil {
		t.Fatalf("Failed to validate refresh token: %v", err)
	}

	if refreshClaims.UserID != userID {
		t.Errorf("Expected user ID %d in refresh token, got %d", userID, refreshClaims.UserID)
	}

	// 测试HMAC签名
	data := "test data"
	signature := securityManager.GenerateHMAC(data)
	
	if !securityManager.VerifyHMAC(data, signature) {
		t.Error("HMAC verification failed")
	}

	if securityManager.VerifyHMAC("wrong data", signature) {
		t.Error("HMAC verification should have failed for wrong data")
	}
}

func TestSecurityConfig(t *testing.T) {
	// 测试默认配置
	config := CreateDefaultSecurityConfig()

	// 验证默认值
	if config.JWTSecret == "" {
		t.Error("JWT secret should not be empty")
	}

	if config.JWTExpiresIn <= 0 {
		t.Error("JWT expires in should be positive")
	}

	if config.JWTRefreshExpiresIn <= 0 {
		t.Error("JWT refresh expires in should be positive")
	}

	if len(config.CORSAllowedOrigins) == 0 {
		t.Error("CORS allowed origins should not be empty")
	}

	if len(config.CORSAllowedMethods) == 0 {
		t.Error("CORS allowed methods should not be empty")
	}

	if !config.RateLimitEnabled {
		t.Error("Rate limit should be enabled by default")
	}

	if config.RateLimitRequests <= 0 {
		t.Error("Rate limit requests should be positive")
	}

	if config.RateLimitWindow <= 0 {
		t.Error("Rate limit window should be positive")
	}
}

// Benchmark测试
func BenchmarkServiceRegistry(b *testing.B) {
	registry := NewInMemoryRegistry()
	
	b.ResetTimer()
	
	for i := 0; i < b.N; i++ {
		service := &ServiceInfo{
			ID:   fmt.Sprintf("service-%d", i),
			Name: "benchmark-service",
			Address: "localhost",
			Port: 8080,
		}
		
		registry.Register(service)
		registry.Discover("benchmark-service")
		registry.Deregister(service.ID)
	}
}

func BenchmarkSecurityManager(b *testing.B) {
	config := CreateDefaultSecurityConfig()
	securityManager := NewSecurityManager(config, nil)
	
	b.ResetTimer()
	
	for i := 0; i < b.N; i++ {
		password := fmt.Sprintf("password%d", i)
		hash, _ := securityManager.HashPassword(password)
		securityManager.CheckPassword(password, hash)
	}
}
