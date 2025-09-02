package main

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// JWTConfig JWT配置
type JWTConfig struct {
	SecretKey     string        `yaml:"secret_key" json:"secret_key"`
	Issuer        string        `yaml:"issuer" json:"issuer"`
	Audience      string        `yaml:"audience" json:"audience"`
	ExpireTime    time.Duration `yaml:"expire_time" json:"expire_time"`
	RefreshTime   time.Duration `yaml:"refresh_time" json:"refresh_time"`
	RefreshSecret string        `yaml:"refresh_secret" json:"refresh_secret"`
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

// CORSConfig CORS配置
type CORSConfig struct {
	AllowOrigins     []string `yaml:"allow_origins"`
	AllowMethods     []string `yaml:"allow_methods"`
	AllowHeaders     []string `yaml:"allow_headers"`
	ExposeHeaders    []string `yaml:"expose_headers"`
	AllowCredentials bool     `yaml:"allow_credentials"`
	MaxAge           int      `yaml:"max_age"`
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

// ServerConfig 服务器配置
type ServerConfig struct {
	Port         string `yaml:"port"`
	Host         string `yaml:"host"`
	Timeout      string `yaml:"timeout"`
	ReadTimeout  string `yaml:"read_timeout"`
	WriteTimeout string `yaml:"write_timeout"`
}

// RateLimitConfig 限流配置
type RateLimitConfig struct {
	RequestsPerSecond int    `yaml:"requests_per_second"`
	BurstSize         int    `yaml:"burst_size"`
	WindowSize        string `yaml:"window_size"`
}

// LoggingConfig 日志配置
type LoggingConfig struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
	Output string `yaml:"output"`
}

// MonitoringConfig 监控配置
type MonitoringConfig struct {
	MetricsEnabled      bool   `yaml:"metrics_enabled"`
	HealthCheckInterval string `yaml:"health_check_interval"`
	Timeout             string `yaml:"timeout"`
}

// ServicesConfig 服务配置
type ServicesConfig struct {
	Public []ServiceRoute `yaml:"public"`
	V1     []ServiceRoute `yaml:"v1"`
	V2     []ServiceRoute `yaml:"v2"`
	Admin  []ServiceRoute `yaml:"admin"`
}
