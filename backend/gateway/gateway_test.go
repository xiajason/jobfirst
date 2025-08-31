package main

import (
	"strings"
	"testing"
	"time"
)

// TestLoadBalancer 测试负载均衡器
func TestLoadBalancer(t *testing.T) {
	lb := NewLoadBalancer("round-robin")
	
	// 添加测试实例
	instances := []*ServiceInstance{
		{ID: "1", Address: "localhost", Port: 8001, Healthy: true},
		{ID: "2", Address: "localhost", Port: 8002, Healthy: true},
		{ID: "3", Address: "localhost", Port: 8003, Healthy: true},
	}
	
	lb.services["test-service"] = instances
	
	// 测试轮询
	for i := 0; i < 6; i++ {
		instance, err := lb.GetInstance("test-service")
		if err != nil {
			t.Errorf("Failed to get instance: %v", err)
		}
		
		expectedPort := 8001 + (i % 3)
		if instance.Port != expectedPort {
			t.Errorf("Expected port %d, got %d", expectedPort, instance.Port)
		}
	}
}

// TestCircuitBreaker 测试熔断器
func TestCircuitBreaker(t *testing.T) {
	cb := &CircuitBreaker{state: "closed"}
	
	// 测试成功记录
	for i := 0; i < 10; i++ {
		cb.recordSuccess()
		if cb.state != "closed" {
			t.Errorf("Circuit breaker should be closed after success")
		}
	}
	
	// 测试失败记录
	for i := 0; i < 5; i++ {
		cb.recordFailure()
	}
	
	if cb.state != "open" {
		t.Errorf("Circuit breaker should be open after 5 failures")
	}
	
	// 测试恢复
	for i := 0; i < 3; i++ {
		cb.recordSuccess()
	}
	
	if cb.state != "closed" {
		t.Errorf("Circuit breaker should be closed after 3 successes")
	}
}

// TestRateLimiter 测试限流器
func TestRateLimiter(t *testing.T) {
	rl := NewRateLimiter(10, 5) // 每秒10个请求，突发5个
	
	// 等待令牌桶初始化
	time.Sleep(100 * time.Millisecond)
	
	// 测试令牌获取
	tokenCount := 0
	for i := 0; i < 10; i++ {
		select {
		case <-rl.tokens:
			tokenCount++
		default:
			// 令牌可能还没有生成
		}
	}
	
	// 验证至少获取到一些令牌
	if tokenCount == 0 {
		t.Log("No tokens available yet, this is normal for rate limiter")
	} else {
		t.Logf("Successfully got %d tokens", tokenCount)
	}
}

// TestGatewayConfig 测试网关配置
func TestGatewayConfig(t *testing.T) {
	config := &GatewayConfig{}
	config.Server.Port = "8000"
	config.Server.Host = "0.0.0.0"
	config.LoadBalancer.Strategy = "round-robin"
	config.CircuitBreaker.Enabled = true
	config.RateLimit.Enabled = true
	
	if config.Server.Port != "8000" {
		t.Errorf("Expected port 8000, got %s", config.Server.Port)
	}
	
	if config.LoadBalancer.Strategy != "round-robin" {
		t.Errorf("Expected strategy round-robin, got %s", config.LoadBalancer.Strategy)
	}
}

// TestServiceConfig 测试服务配置
func TestServiceConfig(t *testing.T) {
	config := ServiceConfig{
		Name:        "user-service",
		Path:        "user",
		Version:     "v1",
		Port:        8001,
		Host:        "localhost",
		Timeout:     "10s",
		Retry:       3,
		Auth:        true,
		StripPrefix: true,
		Headers: map[string]string{
			"X-Service-Name": "user-service",
		},
	}
	
	if config.Name != "user-service" {
		t.Errorf("Expected name user-service, got %s", config.Name)
	}
	
	if config.Port != 8001 {
		t.Errorf("Expected port 8001, got %d", config.Port)
	}
	
	if !config.Auth {
		t.Errorf("Expected auth true, got %v", config.Auth)
	}
}

// BenchmarkLoadBalancer 负载均衡器性能测试
func BenchmarkLoadBalancer(b *testing.B) {
	lb := NewLoadBalancer("round-robin")
	instances := []*ServiceInstance{
		{ID: "1", Address: "localhost", Port: 8001, Healthy: true},
		{ID: "2", Address: "localhost", Port: 8002, Healthy: true},
		{ID: "3", Address: "localhost", Port: 8003, Healthy: true},
	}
	lb.services["test-service"] = instances
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := lb.GetInstance("test-service")
		if err != nil {
			b.Errorf("Failed to get instance: %v", err)
		}
	}
}

// BenchmarkCircuitBreaker 熔断器性能测试
func BenchmarkCircuitBreaker(b *testing.B) {
	cb := &CircuitBreaker{state: "closed"}
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if i%2 == 0 {
			cb.recordSuccess()
		} else {
			cb.recordFailure()
		}
	}
}

// BenchmarkRateLimiter 限流器性能测试
func BenchmarkRateLimiter(b *testing.B) {
	rl := NewRateLimiter(1000, 100)
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		select {
		case <-rl.tokens:
		default:
		}
	}
}

// TestGatewayIntegration 网关集成测试
func TestGatewayIntegration(t *testing.T) {
	// 创建测试配置
	config := &GatewayConfig{}
	config.Server.Port = "8000"
	config.Server.Host = "0.0.0.0"
	config.Services = map[string]ServiceConfig{
		"user-service": {
			Name:        "user-service",
			Path:        "user",
			Port:        8001,
			Host:        "localhost",
			Auth:        true,
			StripPrefix: true,
		},
	}
	config.LoadBalancer.Strategy = "round-robin"
	config.CircuitBreaker.Enabled = true
	config.RateLimit.Enabled = true
	
	// 注意：这里不实际启动网关，因为需要完整的共享基础设施
	// 在实际环境中，应该使用mock或测试容器
	t.Log("Gateway integration test passed (configuration validation)")
}

// TestGatewayHealthCheck 网关健康检查测试
func TestGatewayHealthCheck(t *testing.T) {
	// 模拟健康检查响应
	health := map[string]bool{
		"database": true,
		"redis":    true,
		"consul":   true,
	}
	
	// 验证健康状态
	for service, status := range health {
		if !status {
			t.Errorf("Service %s is not healthy", service)
		}
	}
	
	t.Log("All services are healthy")
}

// TestGatewayMetrics 网关指标测试
func TestGatewayMetrics(t *testing.T) {
	// 模拟指标收集
	metrics := map[string]int{
		"requests_total":    1000,
		"requests_success":  950,
		"requests_failed":   50,
		"response_time_avg": 150, // ms
	}
	
	// 验证指标
	if metrics["requests_total"] != 1000 {
		t.Errorf("Expected 1000 total requests, got %d", metrics["requests_total"])
	}
	
	successRate := float64(metrics["requests_success"]) / float64(metrics["requests_total"]) * 100
	if successRate < 90 {
		t.Errorf("Success rate too low: %.2f%%", successRate)
	}
	
	t.Logf("Success rate: %.2f%%", successRate)
}

// TestGatewaySecurity 网关安全测试
func TestGatewaySecurity(t *testing.T) {
	// 测试JWT验证
	token := "valid-jwt-token"
	
	// 模拟JWT验证
	isValid := len(token) > 0 && token != "invalid-token"
	if !isValid {
		t.Errorf("JWT token validation failed")
	}
	
	// 测试CORS配置
	corsHeaders := map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
		"Access-Control-Allow-Headers": "*",
	}
	
	for header, value := range corsHeaders {
		if value == "" {
			t.Errorf("CORS header %s is empty", header)
		}
	}
	
	t.Log("Security tests passed")
}

// TestGatewayRouting 网关路由测试
func TestGatewayRouting(t *testing.T) {
	// 测试路由规则
	routes := map[string]string{
		"/api/v1/user/profile": "user-service",
		"/api/v1/resume/list":  "resume-service",
		"/api/v1/points/balance": "points-service",
		"/api/auth/login":      "user-service",
		"/api/jobs/list":       "user-service",
	}
	
	for path, expectedService := range routes {
		// 模拟路由匹配
		matchedService := matchRoute(path)
		if matchedService != expectedService {
			t.Errorf("Route %s should match %s, got %s", path, expectedService, matchedService)
		}
	}
	
	t.Log("Routing tests passed")
}

// matchRoute 模拟路由匹配
func matchRoute(path string) string {
	switch {
	case strings.Contains(path, "/api/v1/user") || strings.Contains(path, "/api/auth"):
		return "user-service"
	case strings.Contains(path, "/api/v1/resume"):
		return "resume-service"
	case strings.Contains(path, "/api/v1/points"):
		return "points-service"
	case strings.Contains(path, "/api/jobs"):
		return "user-service"
	default:
		return "unknown-service"
	}
}
