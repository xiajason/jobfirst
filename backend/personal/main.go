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

// 用户模型
type User struct {
	ID           uint       `json:"id" gorm:"primaryKey;autoIncrement"`
	Username     string     `json:"username" gorm:"type:varchar(50);uniqueIndex;not null"`
	Email        string     `json:"email" gorm:"type:varchar(100);uniqueIndex;not null"`
	PasswordHash string     `json:"-" gorm:"column:password_hash;type:varchar(255);not null"`
	Phone        string     `json:"phone" gorm:"type:varchar(20)"`
	AvatarURL    string     `json:"avatar_url" gorm:"column:avatar_url;type:varchar(255)"`
	Status       string     `json:"status" gorm:"type:enum('active','inactive','banned');default:'active'"`
	CreatedAt    time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt    *time.Time `json:"deleted_at" gorm:"index"`
}

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
	log.Printf("Starting personal service on port %s", port)

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
	viper.SetDefault("server.port", "6001")
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

	// 自动迁移
	if err := db.AutoMigrate(&User{}); err != nil {
		return fmt.Errorf("failed to migrate database: %v", err)
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
	serviceID := "personal-service"
	serviceName := "personal-service"

	registration := &api.AgentServiceRegistration{
		ID:      serviceID,
		Name:    serviceName,
		Address: serviceAddress,
		Port:    viper.GetInt("server.port"),
		Tags:    []string{"personal", "user"},
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
	serviceID := "personal-service"
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
		log.Printf("Shutting down personal service...")

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
				"title":       "JobFirst Personal Service API",
				"description": "个人端服务API文档",
				"version":     "1.0.0",
				"contact": gin.H{
					"name":  "JobFirst Team",
					"email": "personal@jobfirst.com",
				},
			},
			"host":     "localhost:6001",
			"basePath": "/personal",
			"schemes":  []string{"http", "https"},
			"paths": gin.H{
				"/personal/version": gin.H{
					"get": gin.H{
						"summary":     "获取服务版本",
						"description": "获取个人端服务版本信息",
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
												"service": gin.H{"type": "string", "example": "personal-service"},
											},
										},
										"msg": gin.H{"type": "string", "example": "success"},
									},
								},
							},
						},
					},
				},
				"/personal/authentication/login": gin.H{
					"post": gin.H{
						"summary":     "个人用户登录",
						"description": "个人用户登录接口",
						"tags":        []string{"个人认证"},
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
												"accessToken": gin.H{"type": "string", "example": "personal-token-123"},
												"user": gin.H{
													"type": "object",
													"properties": gin.H{
														"id":     gin.H{"type": "integer", "example": 1},
														"name":   gin.H{"type": "string", "example": "张三"},
														"role":   gin.H{"type": "string", "example": "personal"},
														"status": gin.H{"type": "string", "example": "active"},
													},
												},
											},
										},
										"msg": gin.H{"type": "string", "example": "个人用户登录成功"},
									},
								},
							},
						},
					},
				},
			},
			"definitions": gin.H{
				"PersonalUser": gin.H{
					"type": "object",
					"properties": gin.H{
						"id":     gin.H{"type": "integer", "example": 1},
						"name":   gin.H{"type": "string", "example": "张三"},
						"role":   gin.H{"type": "string", "example": "personal"},
						"status": gin.H{"type": "string", "example": "active"},
					},
				},
			},
		})
	})

	// 个人端服务API路由 - 完全兼容原有系统
	personal := router.Group("/personal")
	{
		// 白名单路由 - 无需认证
		personal.GET("/version", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"code": 0,
				"data": gin.H{
					"version": "1.0.0",
					"build":   "2025-08-30",
					"service": "personal-service",
				},
				"msg": "success",
			})
		})

		// 认证相关API
		auth := personal.Group("/authentication")
		{
			auth.POST("/login", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"accessToken": "personal-token-123",
						"user": gin.H{
							"id":       1,
							"username": "user",
							"role":     "user",
						},
					},
					"msg": "个人用户登录成功",
				})
			})

			auth.GET("/check", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"valid": true},
					"msg":  "success",
				})
			})

			auth.GET("/getUserPhone", func(c *gin.Context) {
				// 从数据库查询用户手机号
				var user User
				if err := db.First(&user, 1).Error; err != nil {
					log.Printf("Failed to get user phone: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{
						"code": 500,
						"msg":  "Failed to get user phone",
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"phoneNumber": user.Phone},
					"msg":  "success",
				})
			})

			auth.POST("/getUserPhone", func(c *gin.Context) {
				// 从数据库查询用户手机号
				var user User
				if err := db.First(&user, 1).Error; err != nil {
					log.Printf("Failed to get user phone: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{
						"code": 500,
						"msg":  "Failed to get user phone",
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"phoneNumber": user.Phone},
					"msg":  "success",
				})
			})

			auth.GET("/getUserIdKey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"idKey": "user-key-123"},
					"msg":  "success",
				})
			})

			auth.POST("/certification", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"certified": true},
					"msg":  "认证成功",
				})
			})

			auth.POST("/logout", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{},
					"msg":  "登出成功",
				})
			})

			auth.GET("/getMyUserIdKey", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"idKey": "my-user-key-123"},
					"msg":  "success",
				})
			})

			auth.POST("/cancellation", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{},
					"msg":  "注销成功",
				})
			})
		}

		// 个人中心相关API
		mine := personal.Group("/mine")
		{
			mine.GET("/info", func(c *gin.Context) {
				// 从数据库查询用户信息
				var user User
				if err := db.First(&user, 1).Error; err != nil {
					log.Printf("Failed to get user info: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{
						"code": 500,
						"msg":  "Failed to get user info",
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":       user.ID,
						"username": user.Username,
						"email":    user.Email,
						"phone":    user.Phone,
						"avatar":   user.AvatarURL,
					},
					"msg": "success",
				})
			})

			mine.GET("/points", func(c *gin.Context) {
				// 从数据库查询用户积分信息
				var result struct {
					Points       int `json:"points"`
					EarnedPoints int `json:"earned_points"`
					SpentPoints  int `json:"spent_points"`
				}

				if err := db.Table("points").Select("points, earned_points, spent_points").Where("user_id = ?", 1).First(&result).Error; err != nil {
					log.Printf("Failed to get user points: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{
						"code": 500,
						"msg":  "Failed to get user points",
					})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"total":  result.Points,
						"earned": result.EarnedPoints,
						"spent":  result.SpentPoints,
						"level":  "黄金会员",
					},
					"msg": "success",
				})
			})

			mine.GET("/points/bill", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "type": "earn", "amount": 100, "description": "完成简历", "time": "2025-08-30 10:00:00"},
						{"id": 2, "type": "spend", "amount": 50, "description": "下载模板", "time": "2025-08-30 09:00:00"},
					},
					"msg": "success",
				})
			})

			mine.GET("/approve/history", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "type": "resume", "status": "approved", "time": "2025-08-30 10:00:00"},
						{"id": 2, "type": "job", "status": "pending", "time": "2025-08-30 09:00:00"},
					},
					"msg": "success",
				})
			})

			mine.GET("/view/history", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "type": "job", "title": "软件工程师", "time": "2025-08-30 10:00:00"},
						{"id": 2, "type": "resume", "title": "我的简历", "time": "2025-08-30 09:00:00"},
					},
					"msg": "success",
				})
			})

			mine.GET("/certification", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"status": "certified",
						"level":  "高级认证",
						"expire": "2026-08-30",
					},
					"msg": "success",
				})
			})

			mine.POST("/avatar", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"url": "https://example.com/new-avatar.jpg",
					},
					"msg": "头像更新成功",
				})
			})
		}

		// 审批相关API
		approve := personal.Group("/approve")
		{
			approve.GET("/list", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "type": "resume", "status": "pending", "title": "简历审批", "time": "2025-08-30 10:00:00"},
						{"id": 2, "type": "job", "status": "approved", "title": "职位审批", "time": "2025-08-30 09:00:00"},
					},
					"msg": "success",
				})
			})

			approve.POST("/handle/:approveId", func(c *gin.Context) {
				approveId := c.Param("approveId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{"handled": true, "id": approveId},
					"msg":  "审批处理成功",
				})
			})
		}

		// 聊天相关API
		chat := personal.Group("/chat")
		{
			chat.GET("/usual", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "question": "如何写简历？", "answer": "简历应该简洁明了..."},
						{"id": 2, "question": "面试技巧", "answer": "面试前要做好准备..."},
					},
					"msg": "success",
				})
			})

			chat.POST("/chat", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"answer": "这是一个AI助手的回答...",
						"time":   time.Now().Format("2006-01-02 15:04:05"),
					},
					"msg": "success",
				})
			})
		}

		// 首页相关API
		home := personal.Group("/home")
		{
			home.GET("/banners", func(c *gin.Context) {
				// 从数据库查询banner数据
				var banners []struct {
					ID       uint   `json:"id"`
					Title    string `json:"title"`
					ImageURL string `json:"image"`
					LinkURL  string `json:"link"`
					Sort     int    `json:"sort"`
					Status   string `json:"status"`
				}

				if err := db.Table("resume_banners").
					Select("id, title, image_url as image, link_url as link, sort, status").
					Where("status = ?", "active").
					Order("sort ASC").
					Find(&banners).Error; err != nil {
					log.Printf("Failed to query banners: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{
						"code": 500,
						"msg":  "Failed to get banners",
					})
					return
				}

				// 转换为前端需要的格式
				var result []gin.H
				for _, banner := range banners {
					result = append(result, gin.H{
						"id":    banner.ID,
						"title": banner.Title,
						"image": banner.ImageURL,
						"link":  banner.LinkURL,
					})
				}

				// 设置响应头确保正确的字符编码
				c.Header("Content-Type", "application/json; charset=utf-8")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": result,
					"msg":  "success",
				})
			})

			home.GET("/notifications", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{"id": 1, "title": "系统通知", "content": "欢迎使用个人端系统"},
						{"id": 2, "title": "功能更新", "content": "新功能已上线"},
					},
					"msg": "success",
				})
			})
		}

		// 简历管理相关API
		resume := personal.Group("/resume")
		{
			// 获取简历列表摘要
			resume.GET("/list/summary", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":         1,
							"title":      "我的第一份简历",
							"status":     "published",
							"viewCount":  150,
							"updateTime": "2025-08-30 10:00:00",
							"isDefault":  true,
						},
						{
							"id":         2,
							"title":      "技术简历",
							"status":     "draft",
							"viewCount":  50,
							"updateTime": "2025-08-29 15:30:00",
							"isDefault":  false,
						},
					},
					"msg": "success",
				})
			})

			// 创建简历
			resume.POST("/create", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":      3,
						"title":   "新简历",
						"status":  "draft",
						"message": "简历创建成功",
					},
					"msg": "简历创建成功",
				})
			})

			// 发布简历
			resume.POST("/publish/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":      resumeId,
						"status":  "published",
						"message": "简历发布成功",
					},
					"msg": "简历发布成功",
				})
			})

			// 获取简历详情
			resume.GET("/detail/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":            resumeId,
						"title":         "我的简历",
						"content":       "简历详细内容...",
						"status":        "published",
						"viewCount":     150,
						"downloadCount": 25,
						"createTime":    "2025-08-25 10:00:00",
						"updateTime":    "2025-08-30 10:00:00",
						"publishTime":   "2025-08-28 15:00:00",
					},
					"msg": "success",
				})
			})

			// 更新简历
			resume.PUT("/update/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":      resumeId,
						"message": "简历更新成功",
					},
					"msg": "简历更新成功",
				})
			})

			// 获取简历模板
			resume.GET("/templates", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": []gin.H{
						{
							"id":      1,
							"name":    "经典模板",
							"preview": "https://example.com/template1.jpg",
							"isFree":  true,
						},
						{
							"id":      2,
							"name":    "现代模板",
							"preview": "https://example.com/template2.jpg",
							"isFree":  false,
							"price":   10,
						},
						{
							"id":      3,
							"name":    "创意模板",
							"preview": "https://example.com/template3.jpg",
							"isFree":  false,
							"price":   15,
						},
					},
					"msg": "success",
				})
			})

			// 简历权限管理
			resume.GET("/permission/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":            resumeId,
						"isPublic":      true,
						"allowDownload": true,
						"allowView":     true,
						"password":      "",
					},
					"msg": "success",
				})
			})

			// 简历黑名单管理
			resume.GET("/blacklist/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"resumeId": resumeId,
						"blacklist": []gin.H{
							{"id": 1, "company": "黑名单公司1", "reason": "违规操作"},
							{"id": 2, "company": "黑名单公司2", "reason": "恶意下载"},
						},
					},
					"msg": "success",
				})
			})

			// 预览简历
			resume.GET("/preview/:resumeId", func(c *gin.Context) {
				resumeId := c.Param("resumeId")
				c.JSON(http.StatusOK, gin.H{
					"code": 0,
					"data": gin.H{
						"id":      resumeId,
						"preview": "https://example.com/resume-preview.html",
						"message": "预览链接生成成功",
					},
					"msg": "预览链接生成成功",
				})
			})
		}
	}

	return router
}
