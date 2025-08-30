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
	log.Printf("Starting open service on port %s", port)

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
	viper.SetDefault("server.port", "9006")
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
	serviceID := "open-service"
	serviceName := "open-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"open", "api"},
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
	serviceID := "open-service"
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
		log.Printf("Shutting down open service...")

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
				"title":       "JobFirst Open Service API",
				"description": "开放API服务文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "open@jobfirst.com",
				},
			},
			"host":     "localhost:9006",
			"basePath": "/open",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/open/version": gin.H{
					"get": gin.H{
						"summary":     "获取服务版本",
						"description": "获取开放API服务版本信息",
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
												"service": gin.H{"type": "string", "example": "open-service"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
				"/open/api/statistics/resume": gin.H{
					"get": gin.H{
						"summary":     "获取简历统计",
						"description": "获取简历相关统计数据",
						"tags":        []string{"开放统计"},
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
												"total_resumes": gin.H{"type": "integer", "example": 1000},
												"published":     gin.H{"type": "integer", "example": 800},
												"draft":         gin.H{"type": "integer", "example": 200},
												"update_time":   gin.H{"type": "string", "example": "2025-08-30 08:06:09"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"Statistics": gin.H{
					"type": "object",
					"properties": gin.H{
						"total_resumes": gin.H{"type": "integer", "example": 1000},
						"published":     gin.H{"type": "integer", "example": 800},
						"draft":         gin.H{"type": "integer", "example": 200},
						"update_time":   gin.H{"type": "string", "example": "2025-08-30 08:06:09"},
					},
				},
			},
		})
	})

	// 开放API服务路由 - 完全兼容原有系统
	open := router.Group("/open")
	{
		// 白名单路由 - 无需认证
		open.GET("/version", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"version": "1.0.0",
					"build":   "2025-08-30",
					"service": "open-service",
				},
				"msg": "success",
			})
		})

		// API文档相关
		docs := open.Group("/docs")
		{
			docs.GET("/swagger", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"swagger": "2.0",
						"info": gin.H{
							"title":   "JobFirst Open API",
							"version": "1.0.0",
						},
						"paths": gin.H{},
					},
					"msg": "success",
				})
			})

			docs.GET("/api-list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"name": "职位查询API", "path": "/open/job/search", "method": "GET"},
						{"name": "简历上传API", "path": "/open/resume/upload", "method": "POST"},
						{"name": "用户注册API", "path": "/open/user/register", "method": "POST"},
					},
					"msg": "success",
				})
			})
		}

		// 职位相关开放API
		job := open.Group("/job")
		{
			job.GET("/search", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":           1,
							"title":        "软件工程师",
							"company":      "示例企业",
							"location":     "北京",
							"salary":       "15k-25k",
							"description":  "负责公司核心产品的开发...",
							"requirements": "3年以上经验，熟悉Go语言...",
							"publishTime":  "2025-08-30 10:00:00",
						},
						{
							"id":           2,
							"title":        "产品经理",
							"company":      "示例企业",
							"location":     "上海",
							"salary":       "20k-35k",
							"description":  "负责产品规划和设计...",
							"requirements": "5年以上产品经验...",
							"publishTime":  "2025-08-30 09:00:00",
						},
					},
					"msg": "success",
				})
			})

			job.GET("/detail/:jobId", func(c *gin.Context) {
				jobId := c.Param("jobId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":           jobId,
						"title":        "软件工程师",
						"company":      "示例企业",
						"location":     "北京",
						"salary":       "15k-25k",
						"description":  "负责公司核心产品的开发...",
						"requirements": "3年以上经验，熟悉Go语言...",
						"benefits":     "五险一金，年终奖，带薪年假...",
						"publishTime":  "2025-08-30 10:00:00",
						"applications": 25,
					},
					"msg": "success",
				})
			})

			job.GET("/recommend", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":       1,
							"title":    "推荐职位1",
							"company":  "推荐企业1",
							"location": "北京",
							"salary":   "20k-30k",
						},
						{
							"id":       2,
							"title":    "推荐职位2",
							"company":  "推荐企业2",
							"location": "上海",
							"salary":   "25k-35k",
						},
					},
					"msg": "success",
				})
			})
		}

		// 简历相关开放API
		resume := open.Group("/resume")
		{
			resume.POST("/upload", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"resumeId": "resume-123",
						"url":      "https://example.com/resume/resume-123.pdf",
						"status":   "uploaded",
					},
					"msg": "简历上传成功",
				})
			})

			resume.GET("/templates", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":          "template-1",
							"name":        "标准简历模板",
							"description": "适用于大多数职位的标准简历模板",
							"preview":     "https://example.com/template1-preview.jpg",
						},
						{
							"id":          "template-2",
							"name":        "创意简历模板",
							"description": "适合创意行业的简历模板",
							"preview":     "https://example.com/template2-preview.jpg",
						},
					},
					"msg": "success",
				})
			})

			resume.GET("/banners", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":    "banner-1",
							"title": "简历制作指南",
							"image": "https://example.com/banner1.jpg",
							"url":   "https://example.com/guide",
						},
						{
							"id":    "banner-2",
							"title": "简历模板下载",
							"image": "https://example.com/banner2.jpg",
							"url":   "https://example.com/templates",
						},
					},
					"msg": "success",
				})
			})
		}

		// 用户相关开放API
		user := open.Group("/user")
		{
			user.POST("/register", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"userId": 1,
						"status": "registered",
					},
					"msg": "用户注册成功",
				})
			})

			user.GET("/profile/:userId", func(c *gin.Context) {
				userId := c.Param("userId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":       userId,
						"username": "示例用户",
						"avatar":   "https://example.com/avatar.jpg",
						"title":    "软件工程师",
						"location": "北京",
					},
					"msg": "success",
				})
			})
		}

		// API相关开放接口 - 白名单路径
		api := open.Group("/api")
		{
			// 统计API
			api.GET("/statistics/resume", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total_resumes": 1000,
						"published":     800,
						"draft":         200,
						"update_time":   time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})

			api.GET("/statistics/personal", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total_users": 5000,
						"active":      3000,
						"new_today":   100,
						"update_time": time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})

			api.GET("/statistics/enterprise", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total_enterprises": 200,
						"verified":          150,
						"new_today":         10,
						"update_time":       time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})

			// 简历API
			api.GET("/resume/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "title": "软件工程师简历", "user": "张三", "update_time": "2025-08-30"},
						{"id": 2, "title": "产品经理简历", "user": "李四", "update_time": "2025-08-29"},
					},
					"msg": "success",
				})
			})

			api.GET("/resume/detail/:id", func(c *gin.Context) {
				id := c.Param("id")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":          id,
						"title":       "软件工程师简历",
						"user":        "张三",
						"experience":  "5年",
						"skills":      []string{"Go", "Java", "MySQL"},
						"update_time": "2025-08-30",
					},
					"msg": "success",
				})
			})

			// 交易历史API
			api.GET("/transaction/history", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "type": "resume_download", "amount": 100, "time": "2025-08-30 10:00:00"},
						{"id": 2, "type": "job_promotion", "amount": 200, "time": "2025-08-29 15:30:00"},
					},
					"msg": "success",
				})
			})

			// 个人用户API
			api.GET("/personal/users", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "username": "张三", "title": "软件工程师", "location": "北京"},
						{"id": 2, "username": "李四", "title": "产品经理", "location": "上海"},
					},
					"msg": "success",
				})
			})

			// 企业API
			api.GET("/enterprises", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "name": "示例企业1", "industry": "互联网", "location": "北京"},
						{"id": 2, "name": "示例企业2", "industry": "金融", "location": "上海"},
					},
					"msg": "success",
				})
			})

			api.GET("/enterprise/users", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "username": "企业用户1", "company": "示例企业1", "role": "HR"},
						{"id": 2, "username": "企业用户2", "company": "示例企业2", "role": "招聘经理"},
					},
					"msg": "success",
				})
			})
		}

		// 统计相关开放API
		stats := open.Group("/stats")
		{
			stats.GET("/job-count", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"totalJobs":  1000,
						"activeJobs": 800,
						"newJobs":    50,
						"updateTime": time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})

			stats.GET("/user-count", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"totalUsers":  5000,
						"activeUsers": 3000,
						"newUsers":    100,
						"updateTime":  time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})

			stats.GET("/company-count", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"totalCompanies":  200,
						"activeCompanies": 150,
						"newCompanies":    10,
						"updateTime":      time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})
		}

		// 工具相关开放API
		tools := open.Group("/tools")
		{
			tools.GET("/salary-calculator", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"minSalary": 5000,
						"maxSalary": 50000,
						"avgSalary": 15000,
						"currency":  "CNY",
					},
					"msg": "success",
				})
			})

			tools.GET("/skill-analysis", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"skill": "Go", "demand": "high", "salary": "20k-35k"},
						{"skill": "Java", "demand": "high", "salary": "18k-30k"},
						{"skill": "Python", "demand": "medium", "salary": "15k-25k"},
					},
					"msg": "success",
				})
			})

			tools.POST("/resume-parse", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"name":       "张三",
						"title":      "软件工程师",
						"experience": "5年",
						"skills":     []string{"Go", "Java", "MySQL", "Redis"},
						"education":  "本科",
						"confidence": 0.95,
					},
					"msg": "简历解析成功",
				})
			})
		}

		// 通知相关开放API
		notification := open.Group("/notification")
		{
			notification.POST("/subscribe", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"subscriptionId": "sub-123",
						"status":         "subscribed",
					},
					"msg": "订阅成功",
				})
			})

			notification.POST("/unsubscribe", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"status": "unsubscribed",
					},
					"msg": "取消订阅成功",
				})
			})

			notification.GET("/status/:subscriptionId", func(c *gin.Context) {
				subscriptionId := c.Param("subscriptionId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"subscriptionId": subscriptionId,
						"status":         "active",
						"type":           "job-alert",
						"createdAt":      "2025-08-30 10:00:00",
					},
					"msg": "success",
				})
			})
		}
	}

	return router
}
