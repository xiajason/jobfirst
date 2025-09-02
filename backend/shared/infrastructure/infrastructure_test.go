package infrastructure

import (
	"testing"
	"time"
)

func TestLogger(t *testing.T) {
	// 测试日志器创建
	logger := NewLogrusLogger()
	if logger == nil {
		t.Fatal("Failed to create logger")
	}

	// 测试日志级别设置
	logger.SetLevel(InfoLevel)
	logger.SetLevel(DebugLevel)
	logger.SetLevel(WarnLevel)
	logger.SetLevel(ErrorLevel)
	logger.SetLevel(FatalLevel)

	// 测试日志输出
	logger.Info("Test info message", Field{Key: "test", Value: "value"})
	logger.Debug("Test debug message", Field{Key: "test", Value: "value"})
	logger.Warn("Test warn message", Field{Key: "test", Value: "value"})
	logger.Error("Test error message", Field{Key: "test", Value: "value"})

	// 测试带字段的日志器
	loggerWithFields := logger.WithFields(Field{Key: "service", Value: "test"})
	loggerWithFields.Info("Test message with fields")
}

func TestConfig(t *testing.T) {
	// 测试配置创建
	config := NewConfig()
	if config == nil {
		t.Fatal("Failed to create config")
	}

	// 测试配置设置和获取
	err := config.Set("test.key", "test_value")
	if err != nil {
		t.Fatalf("Failed to set config: %v", err)
	}

	value := config.Get("test.key")
	if value != "test_value" {
		t.Errorf("Expected 'test_value', got '%v'", value)
	}

	// 测试字符串获取
	strValue := config.GetString("test.key")
	if strValue != "test_value" {
		t.Errorf("Expected 'test_value', got '%s'", strValue)
	}

	// 测试整数获取
	config.Set("test.int", "123")
	intValue := config.GetInt("test.int")
	if intValue != 123 {
		t.Errorf("Expected 123, got %d", intValue)
	}

	// 测试布尔获取
	config.Set("test.bool", "true")
	boolValue := config.GetBool("test.bool")
	if !boolValue {
		t.Error("Expected true, got false")
	}

	// 测试浮点数获取
	config.Set("test.float", "123.45")
	floatValue := config.GetFloat("test.float")
	if floatValue != 123.45 {
		t.Errorf("Expected 123.45, got %f", floatValue)
	}

	// 测试时间间隔获取
	config.Set("test.duration", "1h")
	durationValue := config.GetDuration("test.duration")
	if durationValue != time.Hour {
		t.Errorf("Expected 1h, got %v", durationValue)
	}

	// 测试字符串切片获取
	config.Set("test.slice", "a,b,c")
	sliceValue := config.GetStringSlice("test.slice")
	expected := []string{"a", "b", "c"}
	if len(sliceValue) != len(expected) {
		t.Errorf("Expected slice length %d, got %d", len(expected), len(sliceValue))
	}
}

func TestConfigBuilder(t *testing.T) {
	// 测试配置构建器
	builder := NewConfigBuilder()
	if builder == nil {
		t.Fatal("Failed to create config builder")
	}

	// 设置默认值
	defaults := map[string]interface{}{
		"app.name": "TestApp",
		"app.port": 8080,
	}
	builder.WithDefaults(defaults)

	// 构建配置
	config, err := builder.Build()
	if err != nil {
		t.Fatalf("Failed to build config: %v", err)
	}

	// 验证默认值
	appName := config.GetString("app.name")
	if appName != "TestApp" {
		t.Errorf("Expected 'TestApp', got '%s'", appName)
	}

	appPort := config.GetInt("app.port")
	if appPort != 8080 {
		t.Errorf("Expected 8080, got %d", appPort)
	}
}

func TestDatabaseConfig(t *testing.T) {
	// 测试数据库配置创建
	config := CreateDefaultDatabaseConfig()
	if config == nil {
		t.Fatal("Failed to create database config")
	}

	// 验证MySQL配置
	if config.MySQL.Host != "localhost" {
		t.Errorf("Expected 'localhost', got '%s'", config.MySQL.Host)
	}
	if config.MySQL.Port != 8200 {
		t.Errorf("Expected 8200, got %d", config.MySQL.Port)
	}

	// 验证PostgreSQL配置
	if config.PostgreSQL.Host != "localhost" {
		t.Errorf("Expected 'localhost', got '%s'", config.PostgreSQL.Host)
	}
	if config.PostgreSQL.Port != 8203 {
		t.Errorf("Expected 8203, got %d", config.PostgreSQL.Port)
	}

	// 验证Neo4j配置
	if config.Neo4j.Host != "localhost" {
		t.Errorf("Expected 'localhost', got '%s'", config.Neo4j.Host)
	}
	if config.Neo4j.Port != 8205 {
		t.Errorf("Expected 8205, got %d", config.Neo4j.Port)
	}

	// 验证Redis配置
	if config.Redis.Host != "localhost" {
		t.Errorf("Expected 'localhost', got '%s'", config.Redis.Host)
	}
	if config.Redis.Port != 8201 {
		t.Errorf("Expected 8201, got %d", config.Redis.Port)
	}
}

func TestInfrastructure(t *testing.T) {
	// 测试基础设施创建
	infra := NewInfrastructure()
	if infra == nil {
		t.Fatal("Failed to create infrastructure")
	}

	// 注意：这里不测试实际的数据库连接，因为需要真实的数据库服务
	// 在实际环境中，这些测试应该使用测试数据库或mock

	// 测试健康检查（在没有连接的情况下）
	health := infra.HealthCheck()
	if health == nil {
		t.Fatal("Health check returned nil")
	}

	// 验证健康检查结构
	if _, exists := health["logger"]; !exists {
		t.Error("Health check missing logger status")
	}
	if _, exists := health["config"]; !exists {
		t.Error("Health check missing config status")
	}
	if _, exists := health["database"]; !exists {
		t.Error("Health check missing database status")
	}
}

func TestGlobalFunctions(t *testing.T) {
	// 测试全局函数（在没有初始化的情况下）
	logger := GetLogger()
	if logger == nil {
		t.Error("GetLogger returned nil")
	}

	// 注意：GetConfig在没有初始化时返回nil是正常的
	_ = GetConfig() // 这里不检查config是否为nil，因为这是预期的行为

	dbManager := GetDatabaseManager()
	if dbManager != nil {
		t.Error("GetDatabaseManager should return nil when not initialized")
	}
}

// Benchmark测试
func BenchmarkLogger(b *testing.B) {
	logger := NewLogrusLogger()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		logger.Info("Benchmark test message", Field{Key: "iteration", Value: i})
	}
}

func BenchmarkConfig(b *testing.B) {
	config := NewConfig()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		config.Set("benchmark.key", i)
		config.Get("benchmark.key")
	}
}
