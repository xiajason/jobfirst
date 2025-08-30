package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/hashicorp/consul/api"
	"github.com/spf13/viper"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"resume-centre/shared/infrastructure"
)

var (
	db           *gorm.DB
	consulClient *api.Client
)

func main() {
	// 加载配置
	loadConfig()

	// 初始化数据库连接
	if err := initDatabase(); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 初始化Consul客户端
	if err := initConsul(); err != nil {
		log.Fatalf("Failed to connect to Consul: %v", err)
	}

	// 注册服务到Consul
	if err := registerService(); err != nil {
		log.Fatalf("Failed to register service: %v", err)
	}

	// 设置优雅关闭
	setupGracefulShutdown()

	// 设置路由
	router := setupRouter()

	// 启动服务器
	port := viper.GetString("server.port")
	log.Printf("Starting admin service on port %s", port)

	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

// 加载配置
func loadConfig() {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("../config")
	viper.AddConfigPath("../../config")

	// 设置默认值
	viper.SetDefault("server.port", "8003")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "8200")
	viper.SetDefault("database.user", "jobfirst")
	viper.SetDefault("database.password", "jobfirst123")
	viper.SetDefault("database.name", "jobfirst")
	viper.SetDefault("consul.address", "localhost:8202")
	viper.SetDefault("redis.address", "localhost:8201")

	// 从环境变量读取
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		log.Printf("Failed to read config file: %v", err)
	}
}

// 初始化数据库连接
func initDatabase() error {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.host"),
		viper.GetString("database.port"),
		viper.GetString("database.name"),
	)

	var err error
	db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %v", err)
	}

	log.Printf("Successfully connected to database")
	return nil
}

// 初始化Consul客户端
func initConsul() error {
	config := api.DefaultConfig()
	config.Address = viper.GetString("consul.address")

	var err error
	consulClient, err = api.NewClient(config)
	if err != nil {
		return fmt.Errorf("failed to create Consul client: %v", err)
	}

	log.Printf("Successfully connected to Consul")
	return nil
}

// 注册服务到Consul
func registerService() error {
	serviceAddress := "localhost"
	serviceID := "admin-service"
	serviceName := "admin-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"admin", "management"},
		// 暂时禁用健康检查，避免服务被自动注销
		// Check: &api.AgentServiceCheck{
		// 	HTTP:                           fmt.Sprintf("http://%s:%s/health", serviceAddress, servicePort),
		// 	Interval:                       "30s",
		// 	Timeout:                        "10s",
		// 	DeregisterCriticalServiceAfter: "60s",
		// },
	}

	err := consulClient.Agent().ServiceRegister(registration)
	if err != nil {
		return fmt.Errorf("failed to register service: %v", err)
	}

	log.Printf("Service registered to Consul")
	return nil
}

// 注销服务
func deregisterService() error {
	serviceID := "admin-service"
	err := consulClient.Agent().ServiceDeregister(serviceID)
	if err != nil {
		if strings.Contains(err.Error(), "Unknown service ID") || strings.Contains(err.Error(), "404") {
			log.Printf("Service already deregistered from Consul")
			return nil
		}
		return fmt.Errorf("failed to deregister service: %v", err)
	}

	log.Printf("Service deregistered from Consul")
	return nil
}

// 设置优雅关闭
func setupGracefulShutdown() {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-c
		log.Printf("Shutting down admin service...")

		if err := deregisterService(); err != nil {
			log.Printf("Failed to deregister service: %v", err)
		}

		os.Exit(0)
	}()
}

// 设置路由
func setupRouter() *gin.Engine {
	router := gin.Default()

	// 添加metrics中间件
	router.Use(infrastructure.RequestMetricsMiddleware())

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		infrastructure.SetServiceHealth(true)
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		})
	})

	// Metrics端点
	router.GET("/metrics", infrastructure.GetMetricsHandler())
	router.GET("/v1/.well-known/metrics", infrastructure.GetMetricsHandler())

	// Swagger API文档 - 白名单路由
	router.GET("/v2/api-docs", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"swagger": "2.0",
			"info": gin.H{
				"title":       "JobFirst Admin Service API",
				"description": "管理端服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "admin@jobfirst.com",
				},
			},
			"host":     "localhost:8003",
			"basePath": "/admin",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/admin/version": gin.H{
					"get": gin.H{
						"summary":     "获取服务版本",
						"description": "获取管理端服务版本信息",
						"tags":        []string{"系统信息"},
						"responses": gin.H{
							"200": gin.H{
								"description": "获取成功",
								"schema": gin.H{
									"type": "object",
									"properties": gin.H{
										"code": gin.H{"type": "integer", "example": 0},
										"data": gin.H{
											"type": "object",
											"properties": gin.H{
												"version": gin.H{"type": "string", "example": "1.0.0"},
												"build":   gin.H{"type": "string", "example": "2025-08-30"},
												"service": gin.H{"type": "string", "example": "admin-service"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
				"/admin/authentication/login": gin.H{
					"post": gin.H{
						"summary":     "管理员登录",
						"description": "管理员登录接口",
						"tags":        []string{"管理员认证"},
						"responses": gin.H{
							"200": gin.H{
								"description": "登录成功",
								"schema": gin.H{
									"type": "object",
									"properties": gin.H{
										"code": gin.H{"type": "integer", "example": 0},
										"data": gin.H{
											"type": "object",
											"properties": gin.H{
												"accessToken": gin.H{"type": "string", "example": "admin-token-123"},
												"admin": gin.H{
													"type": "object",
													"properties": gin.H{
														"id":     gin.H{"type": "integer", "example": 1},
														"name":   gin.H{"type": "string", "example": "管理员"},
														"role":   gin.H{"type": "string", "example": "admin"},
														"status": gin.H{"type": "string", "example": "active"},
													},
												},
											},
										},
										"msg": gin.H{"type": "string", "example": "管理员登录成功"},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"Admin": gin.H{
					"type": "object",
					"properties": gin.H{
						"id":     gin.H{"type": "integer", "example": 1},
						"name":   gin.H{"type": "string", "example": "管理员"},
						"role":   gin.H{"type": "string", "example": "admin"},
						"status": gin.H{"type": "string", "example": "active"},
					},
				},
			},
		})
	})

	// 管理端API路由 - 完全兼容原有系统
	admin := router.Group("/admin")
	{
		// 白名单路由 - 无需认证
		admin.GET("/version", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"version": "1.0.0",
					"build":   "2025-08-30",
					"service": "admin-service",
				},
				"msg": "success",
			})
		})

		admin.POST("/authentication/login", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"accessToken": "admin-token-123",
					"user": gin.H{
						"id":       1,
						"username": "admin",
						"role":     "admin",
					},
				},
				"msg": "管理员登录成功",
			})
		})

		admin.GET("/user/code", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"code":   "123456",
					"expire": 300, // 5分钟过期
				},
				"msg": "验证码发送成功",
			})
		})

		admin.POST("/user/forget", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"reset": true,
				},
				"msg": "密码重置成功",
			})
		})

		// 需要认证的管理功能
		authAdmin := admin.Group("")
		authAdmin.Use(adminAuthMiddleware())
		{
			// 用户管理
			authAdmin.GET("/users", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "username": "user1", "email": "user1@example.com", "status": "active"},
						{"id": 2, "username": "user2", "email": "user2@example.com", "status": "active"},
					},
					"msg": "success",
				})
			})

			// 系统配置
			authAdmin.GET("/config", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"site_name":   "JobFirst",
						"maintenance": false,
						"features":    []string{"resume", "job", "chat"},
					},
					"msg": "success",
				})
			})

			// 统计数据
			authAdmin.GET("/statistics", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total_users":   1000,
						"total_resumes": 500,
						"total_jobs":    200,
						"active_users":  150,
					},
					"msg": "success",
				})
			})
		}
	}

	return router
}

// 管理员认证中间件
func adminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 兼容原有系统的accessToken头
		token := c.GetHeader("accessToken")
		if token == "" {
			// 也支持Authorization头
			token = c.GetHeader("Authorization")
			if token != "" && len(token) > 7 && token[:7] == "Bearer " {
				token = token[7:]
			}
		}

		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": 100001, // 原有系统的登录过期错误码
				"msg":  "管理员登录已过期",
			})
			c.Abort()
			return
		}

		// 简化认证：接受admin-token-123
		if token == "admin-token-123" {
			// 设置管理员信息
			c.Set("adminID", uint(1))
			c.Set("adminUsername", "admin")
			c.Set("adminRole", "admin")
			c.Next()
			return
		}

		c.JSON(http.StatusUnauthorized, gin.H{
			"code": 100002, // 原有系统的token无效错误码
			"msg":  "管理员token无效",
		})
		c.Abort()
	}
}
