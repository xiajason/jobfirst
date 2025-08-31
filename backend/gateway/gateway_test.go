package main

import (
	"testing"
)

// TestEnhancedGatewayConfig 测试增强版网关配置
func TestEnhancedGatewayConfig(t *testing.T) {
	config := &EnhancedGatewayConfig{}
	config.Server.Port = 8000
	config.Server.Host = "0.0.0.0"
	
	if config.Server.Port != 8000 {
		t.Errorf("Expected port 8000, got %d", config.Server.Port)
	}
	
	if config.Server.Host != "0.0.0.0" {
		t.Errorf("Expected host 0.0.0.0, got %s", config.Server.Host)
	}
}

// TestServiceRoute 测试服务路由配置
func TestServiceRoute(t *testing.T) {
	route := ServiceRoute{
		Name:        "user-service",
		Path:        "/api/v1/user",
		Service:     "user-service",
		StripPrefix: true,
		Auth:        true,
		CORS:        true,
	}
	
	if route.Name != "user-service" {
		t.Errorf("Expected name user-service, got %s", route.Name)
	}
	
	if route.Path != "/api/v1/user" {
		t.Errorf("Expected path /api/v1/user, got %s", route.Path)
	}
	
	if !route.Auth {
		t.Errorf("Expected auth true, got %v", route.Auth)
	}
}

// TestJWTConfig 测试JWT配置
func TestJWTConfig(t *testing.T) {
	config := &JWTConfig{
		SecretKey:   "test-secret",
		Issuer:      "jobfirst-gateway",
		Audience:    "jobfirst-api",
		ExpireTime:  24 * 3600 * 1000000000, // 24小时
		RefreshTime: 7 * 24 * 3600 * 1000000000, // 7天
	}
	
	if config.SecretKey != "test-secret" {
		t.Errorf("Expected secret test-secret, got %s", config.SecretKey)
	}
	
	if config.Issuer != "jobfirst-gateway" {
		t.Errorf("Expected issuer jobfirst-gateway, got %s", config.Issuer)
	}
}

// TestClaims 测试JWT声明
func TestClaims(t *testing.T) {
	claims := &Claims{
		UserID:   "123",
		Username: "testuser",
		Email:    "test@example.com",
		Roles:    []string{"user", "admin"},
	}
	
	if claims.UserID != "123" {
		t.Errorf("Expected user ID 123, got %s", claims.UserID)
	}
	
	if claims.Username != "testuser" {
		t.Errorf("Expected username testuser, got %s", claims.Username)
	}
	
	if len(claims.Roles) != 2 {
		t.Errorf("Expected 2 roles, got %d", len(claims.Roles))
	}
}

// TestGenerateSecretKey 测试密钥生成
func TestGenerateSecretKey(t *testing.T) {
	key1 := generateSecretKey()
	key2 := generateSecretKey()
	
	if len(key1) == 0 {
		t.Errorf("Generated key is empty")
	}
	
	if len(key2) == 0 {
		t.Errorf("Generated key is empty")
	}
	
	// 密钥应该是不同的
	if key1 == key2 {
		t.Errorf("Generated keys should be different")
	}
}

// TestGetServiceURL 测试服务URL获取
func TestGetServiceURL(t *testing.T) {
	gateway := &EnhancedGateway{}
	
	// 测试已知服务
	url := gateway.getServiceURL("user-service")
	if url != "http://localhost:8081" {
		t.Errorf("Expected http://localhost:8081, got %s", url)
	}
	
	// 测试未知服务
	url = gateway.getServiceURL("unknown-service")
	if url != "http://localhost:8080" {
		t.Errorf("Expected http://localhost:8080, got %s", url)
	}
}

// TestHasAdminRole 测试管理员角色检查
func TestHasAdminRole(t *testing.T) {
	gateway := &EnhancedGateway{}
	
	// 测试有管理员角色
	roles := []string{"user", "admin"}
	if !gateway.hasAdminRole(roles) {
		t.Errorf("Should have admin role")
	}
	
	// 测试没有管理员角色
	roles = []string{"user", "editor"}
	if gateway.hasAdminRole(roles) {
		t.Errorf("Should not have admin role")
	}
	
	// 测试超级管理员角色
	roles = []string{"user", "super_admin"}
	if !gateway.hasAdminRole(roles) {
		t.Errorf("Should have super admin role")
	}
}
