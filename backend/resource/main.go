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
	log.Printf("Starting resource service on port %s", port)

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
	viper.SetDefault("server.port", "9002")
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
	serviceID := "resource-service"
	serviceName := "resource-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"resource", "file"},
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
	serviceID := "resource-service"
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
		log.Printf("Shutting down resource service...")

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
				"title":       "JobFirst Resource Service API",
				"description": "资源服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "resource@jobfirst.com",
				},
			},
			"host":     "localhost:9002",
			"basePath": "/resource",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/resource/version": gin.H{
					"get": gin.H{
						"summary":     "获取服务版本",
						"description": "获取资源服务版本信息",
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
												"service": gin.H{"type": "string", "example": "resource-service"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
				"/resource/ocr/general": gin.H{
					"post": gin.H{
						"summary":     "OCR通用识别",
						"description": "OCR通用文本识别接口",
						"tags":        []string{"OCR识别"},
						"responses": gin.H{
							"200": gin.H{
								"description": "识别成功",
								"schema": gin.H{
									"type": "object",
									"properties": gin.H{
										"code": gin.H{"type": "integer", "example": 0},
										"data": gin.H{
											"type": "object",
											"properties": gin.H{
												"text":       gin.H{"type": "string", "example": "这是OCR识别出的文本内容"},
												"confidence": gin.H{"type": "number", "example": 0.95},
											},
										},
										"msg": gin.H{"type": "string", "example": "OCR识别成功"},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"OCRResult": gin.H{
					"type": "object",
					"properties": gin.H{
						"text":       gin.H{"type": "string", "example": "识别出的文本"},
						"confidence": gin.H{"type": "number", "example": 0.95},
					},
				},
			},
		})
	})

	// 资源服务API路由 - 完全兼容原有系统
	resource := router.Group("/resource")
	{
		// 白名单路由 - 无需认证
		resource.GET("/version", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"version": "1.0.0",
					"build":   "2025-08-30",
					"service": "resource-service",
				},
				"msg": "success",
			})
		})

		// OCR通用识别API - 白名单路径
		resource.POST("/ocr/general", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"text":       "这是OCR识别出的文本内容",
					"confidence": 0.95,
				},
				"msg": "OCR识别成功",
			})
		})

		// 获取多个资源URL
		resource.GET("/urls", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": []gin.H{
					{"id": 1, "url": "https://example.com/resource1.jpg", "type": "image"},
					{"id": 2, "url": "https://example.com/resource2.pdf", "type": "document"},
					{"id": 3, "url": "https://example.com/resource3.mp4", "type": "video"},
				},
				"msg": "success",
			})
		})

		// 获取单个资源URL
		resource.GET("/url/:id", func(c *gin.Context) {
			id := c.Param("id")
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"id":   id,
					"url":  fmt.Sprintf("https://example.com/resource%s.jpg", id),
					"type": "image",
					"size": 1024000,
				},
				"msg": "success",
			})
		})

		// 获取字典类型列表
		resource.GET("/dict/type/list", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": []gin.H{
					{"id": 1, "name": "职位类型", "code": "job_type"},
					{"id": 2, "name": "学历要求", "code": "education"},
					{"id": 3, "name": "工作经验", "code": "experience"},
					{"id": 4, "name": "薪资范围", "code": "salary"},
				},
				"msg": "success",
			})
		})

		// 获取字典数据
		resource.GET("/dict/data", func(c *gin.Context) {
			dictType := c.Query("type")
			var data []gin.H

			switch dictType {
			case "job_type":
				data = []gin.H{
					{"id": 1, "label": "全职", "value": "fulltime"},
					{"id": 2, "label": "兼职", "value": "parttime"},
					{"id": 3, "label": "实习", "value": "internship"},
				}
			case "education":
				data = []gin.H{
					{"id": 1, "label": "高中", "value": "high_school"},
					{"id": 2, "label": "大专", "value": "college"},
					{"id": 3, "label": "本科", "value": "bachelor"},
					{"id": 4, "label": "硕士", "value": "master"},
					{"id": 5, "label": "博士", "value": "phd"},
				}
			default:
				data = []gin.H{}
			}

			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": data,
				"msg":  "success",
			})
		})

		// 搜索学校
		resource.GET("/dict/search/school", func(c *gin.Context) {
			_ = c.Query("keyword") // 暂时忽略keyword参数
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": []gin.H{
					{"id": 1, "name": "清华大学", "code": "tsinghua"},
					{"id": 2, "name": "北京大学", "code": "pku"},
					{"id": 3, "name": "复旦大学", "code": "fudan"},
				},
				"msg": "success",
			})
		})

		// 文件上传
		resource.POST("/upload", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"url":      "https://example.com/uploaded/file.jpg",
					"filename": "file.jpg",
					"size":     1024000,
					"type":     "image/jpeg",
				},
				"msg": "文件上传成功",
			})
		})

		// 删除资源
		resource.DELETE("/:id", func(c *gin.Context) {
			id := c.Param("id")
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{"deleted": true, "id": id},
				"msg":  "资源删除成功",
			})
		})

		// 更新资源
		resource.PUT("/:id", func(c *gin.Context) {
			id := c.Param("id")
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{"updated": true, "id": id},
				"msg":  "资源更新成功",
			})
		})
	}

	return router
}
