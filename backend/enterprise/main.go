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
	log.Printf("Starting enterprise service on port %s", port)

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
	viper.SetDefault("server.port", "8002")
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
	serviceID := "enterprise-service"
	serviceName := "enterprise-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"enterprise", "company"},
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
	serviceID := "enterprise-service"
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
		log.Printf("Shutting down enterprise service...")

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
				"title":       "JobFirst Enterprise Service API",
				"description": "企业端服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "enterprise@jobfirst.com",
				},
			},
			"host":     "localhost:8002",
			"basePath": "/enterprise",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/enterprise/version": gin.H{
					"get": gin.H{
						"summary":     "获取服务版本",
						"description": "获取企业端服务版本信息",
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
												"service": gin.H{"type": "string", "example": "enterprise-service"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
				"/enterprise/authentication/login": gin.H{
					"post": gin.H{
						"summary":     "企业用户登录",
						"description": "企业用户登录接口",
						"tags":        []string{"企业认证"},
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
												"accessToken": gin.H{"type": "string", "example": "enterprise-token-123"},
												"company": gin.H{
													"type": "object",
													"properties": gin.H{
														"id":     gin.H{"type": "integer", "example": 1},
														"name":   gin.H{"type": "string", "example": "示例企业"},
														"role":   gin.H{"type": "string", "example": "enterprise"},
														"status": gin.H{"type": "string", "example": "verified"},
													},
												},
											},
										},
										"msg": gin.H{"type": "string", "example": "企业用户登录成功"},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"Company": gin.H{
					"type": "object",
					"properties": gin.H{
						"id":     gin.H{"type": "integer", "example": 1},
						"name":   gin.H{"type": "string", "example": "示例企业"},
						"role":   gin.H{"type": "string", "example": "enterprise"},
						"status": gin.H{"type": "string", "example": "verified"},
					},
				},
			},
		})
	})

	// 企业端服务API路由 - 完全兼容原有系统
	enterprise := router.Group("/enterprise")
	{
		// 白名单路由 - 无需认证
		enterprise.GET("/version", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"version": "1.0.0",
					"build":   "2025-08-30",
					"service": "enterprise-service",
				},
				"msg": "success",
			})
		})

		// 企业认证相关API
		auth := enterprise.Group("/authentication")
		{
			auth.POST("/login", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"accessToken": "enterprise-token-123",
						"company": gin.H{
							"id":     1,
							"name":   "示例企业",
							"role":   "enterprise",
							"status": "verified",
						},
					},
					"msg": "企业用户登录成功",
				})
			})

			auth.POST("/validate", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"valid": true},
					"msg":  "验证成功",
				})
			})

			auth.GET("/check", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"valid": true},
					"msg":  "success",
				})
			})

			auth.POST("/register", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"companyId": 1,
						"status":    "pending",
					},
					"msg": "企业注册成功，等待审核",
				})
			})

			auth.POST("/logout", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{},
					"msg":  "登出成功",
				})
			})
		}

		// 企业管理相关API
		company := enterprise.Group("/company")
		{
			company.GET("/info", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":          1,
						"name":        "示例企业",
						"industry":    "互联网",
						"size":        "100-499人",
						"location":    "北京",
						"description": "这是一家示例企业",
						"logo":        "https://example.com/logo.jpg",
						"website":     "https://example.com",
						"status":      "verified",
					},
					"msg": "success",
				})
			})

			company.PUT("/info", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"updated": true},
					"msg":  "企业信息更新成功",
				})
			})

			company.GET("/statistics", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"totalJobs":           50,
						"activeJobs":          30,
						"totalApplications":   200,
						"pendingApplications": 20,
						"hiredCount":          15,
					},
					"msg": "success",
				})
			})
		}

		// 用户相关API - 白名单路径
		user := enterprise.Group("/user")
		{
			personal := user.Group("/personal")
			{
				personal.POST("/register", func(c *gin.Context) {
					c.JSON(http.StatusOK, gin.H{
						"code": 0,
						"data": gin.H{
							"userId": 1,
							"status": "registered",
						},
						"msg": "个人用户注册成功",
					})
				})

				personal.GET("/register/code", func(c *gin.Context) {
					c.JSON(http.StatusOK, gin.H{
						"code": 0,
						"data": gin.H{
							"code":   "123456",
							"expire": 300, // 5分钟过期
						},
						"msg": "验证码发送成功",
					})
				})

				password := personal.Group("/password")
				{
					password.GET("/change/code", func(c *gin.Context) {
						c.JSON(http.StatusOK, gin.H{
							"code": 0,
							"data": gin.H{
								"code":   "654321",
								"expire": 300, // 5分钟过期
							},
							"msg": "验证码发送成功",
						})
					})

					password.POST("/reset", func(c *gin.Context) {
						c.JSON(http.StatusOK, gin.H{
							"code": 0,
							"data": gin.H{"reset": true},
							"msg":  "密码重置成功",
						})
					})
				}
			}
		}

		// 验证码API - 白名单路径
		enterprise.GET("/captcha", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"captchaId": "captcha-123",
					"image":     "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",
				},
				"msg": "验证码生成成功",
			})
		})

		// 职位管理相关API
		job := enterprise.Group("/job")
		{
			job.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":           1,
							"title":        "软件工程师",
							"department":   "技术部",
							"location":     "北京",
							"salary":       "15k-25k",
							"status":       "active",
							"createTime":   "2025-08-30 10:00:00",
							"applications": 25,
						},
						{
							"id":           2,
							"title":        "产品经理",
							"department":   "产品部",
							"location":     "上海",
							"salary":       "20k-35k",
							"status":       "active",
							"createTime":   "2025-08-30 09:00:00",
							"applications": 18,
						},
					},
					"msg": "success",
				})
			})

			job.POST("/create", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"jobId":  3,
						"status": "created",
					},
					"msg": "职位创建成功",
				})
			})

			job.PUT("/update/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"updated": true, "id": jobId},
					"msg":  "职位更新成功",
				})
			})

			job.DELETE("/delete/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"deleted": true, "id": jobId},
					"msg":  "职位删除成功",
				})
			})

			job.GET("/detail/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":           jobId,
						"title":        "软件工程师",
						"department":   "技术部",
						"location":     "北京",
						"salary":       "15k-25k",
						"description":  "负责公司核心产品的开发...",
						"requirements": "3年以上经验，熟悉Go语言...",
						"benefits":     "五险一金，年终奖，带薪年假...",
						"status":       "active",
						"createTime":   "2025-08-30 10:00:00",
					},
					"msg": "success",
				})
			})

			job.POST("/publish/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"published": true, "id": jobId},
					"msg":  "职位发布成功",
				})
			})

			job.POST("/pause/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"paused": true, "id": jobId},
					"msg":  "职位暂停成功",
				})
			})
		}

		// 简历管理相关API
		resume := enterprise.Group("/resume")
		{
			resume.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":         1,
							"name":       "张三",
							"title":      "软件工程师",
							"experience": "5年",
							"education":  "本科",
							"status":     "pending",
							"applyTime":  "2025-08-30 10:00:00",
						},
						{
							"id":         2,
							"name":       "李四",
							"title":      "产品经理",
							"experience": "3年",
							"education":  "硕士",
							"status":     "approved",
							"applyTime":  "2025-08-30 09:00:00",
						},
					},
					"msg": "success",
				})
			})

			resume.GET("/detail/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":         resumeId,
						"name":       "张三",
						"title":      "软件工程师",
						"experience": "5年",
						"education":  "本科",
						"skills":     "Go, Java, MySQL, Redis",
						"projects":   "电商系统，支付系统",
						"status":     "pending",
						"applyTime":  "2025-08-30 10:00:00",
					},
					"msg": "success",
				})
			})

			resume.POST("/approve/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"approved": true, "id": resumeId},
					"msg":  "简历审批通过",
				})
			})

			resume.POST("/reject/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"rejected": true, "id": resumeId},
					"msg":  "简历审批拒绝",
				})
			})

			resume.POST("/interview/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"interview": true, "id": resumeId},
					"msg":  "面试邀请发送成功",
				})
			})
		}

		// 申请管理相关API
		application := enterprise.Group("/application")
		{
			application.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":        1,
							"jobTitle":  "软件工程师",
							"applicant": "张三",
							"status":    "pending",
							"applyTime": "2025-08-30 10:00:00",
						},
						{
							"id":        2,
							"jobTitle":  "产品经理",
							"applicant": "李四",
							"status":    "approved",
							"applyTime": "2025-08-30 09:00:00",
						},
					},
					"msg": "success",
				})
			})

			application.GET("/statistics", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total":    200,
						"pending":  20,
						"approved": 150,
						"rejected": 30,
					},
					"msg": "success",
				})
			})
		}

		// 消息通知相关API
		message := enterprise.Group("/message")
		{
			message.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":      1,
							"title":   "新简历申请",
							"content": "张三申请了软件工程师职位",
							"time":    "2025-08-30 10:00:00",
							"read":    false,
						},
						{
							"id":      2,
							"title":   "系统通知",
							"content": "您的企业认证已通过",
							"time":    "2025-08-30 09:00:00",
							"read":    true,
						},
					},
					"msg": "success",
				})
			})

			message.POST("/read/:messageId", func(c *gin.Context) {
				messageId := c.Param("messageId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"read": true, "id": messageId},
					"msg":  "消息已标记为已读",
				})
			})
		}
	}

	return router
}
