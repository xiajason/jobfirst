package main

import (
	"fmt"
	"os"

	"github.com/spf13/viper"
)

func main() {
	// 加载配置
	config, err := loadGatewayConfig()
	if err != nil {
		fmt.Printf("Failed to load gateway config: %v\n", err)
		os.Exit(1)
	}

	// 创建增强版网关
	gateway, err := NewEnhancedGateway(config)
	if err != nil {
		fmt.Printf("Failed to create enhanced gateway: %v\n", err)
		os.Exit(1)
	}

	// 启动网关
	if err := gateway.Start(); err != nil {
		fmt.Printf("Failed to start gateway: %v\n", err)
		os.Exit(1)
	}
}

// loadGatewayConfig 加载网关配置
func loadGatewayConfig() (*GatewayConfig, error) {
	viper.SetConfigName("gateway_config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")

	// 设置默认值
	viper.SetDefault("server.port", "8000")
	viper.SetDefault("server.host", "0.0.0.0")
	viper.SetDefault("server.timeout", "30s")
	viper.SetDefault("load_balancer.strategy", "round-robin")
	viper.SetDefault("circuit_breaker.enabled", true)
	viper.SetDefault("rate_limit.enabled", true)

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	var config GatewayConfig
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %v", err)
	}

	return &config, nil
}
