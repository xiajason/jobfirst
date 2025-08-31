package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
)

// AIHandler AI处理器
type AIHandler struct {
	dbManager             *DatabaseManager
	recommendationService *RecommendationService
}

// NewAIHandler 创建AI处理器
func NewAIHandler(dbManager *DatabaseManager) *AIHandler {
	recommendationService := NewRecommendationService(dbManager)
	return &AIHandler{
		dbManager:             dbManager,
		recommendationService: recommendationService,
	}
}

// GetJobRecommendations 获取职位推荐
func (h *AIHandler) GetJobRecommendations(c *gin.Context) {
	userIDStr := c.Param("userID")
	limit := 5 // 默认推荐数量

	// 解析用户ID
	var userID uint
	fmt.Sscanf(userIDStr, "%d", &userID)

	// 使用推荐服务获取推荐
	recommendations, err := h.recommendationService.GetJobRecommendations(userID, limit)
	if err != nil {
		c.JSON(500, gin.H{
			"success": false,
			"error":   "Failed to get recommendations",
		})
		return
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":           len(recommendations),
			"user_id":         userID,
		},
	})
}

// GetSkillRecommendations 获取技能推荐
func (h *AIHandler) GetSkillRecommendations(c *gin.Context) {
	userID := c.Param("userID")

	// 模拟技能推荐数据
	recommendations := []map[string]interface{}{
		{
			"skill_name": "Spring Boot",
			"category":   "framework",
			"score":      0.92,
			"demand":     85,
			"reason":     "与Java技能高度相关，市场需求大",
		},
		{
			"skill_name": "Docker",
			"category":   "devops",
			"score":      0.78,
			"demand":     72,
			"reason":     "现代化部署必备技能",
		},
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":           len(recommendations),
			"user_id":         userID,
		},
	})
}

// GetPersonalizedRecommendations 获取个性化推荐
func (h *AIHandler) GetPersonalizedRecommendations(c *gin.Context) {
	userID := c.Param("userID")

	// 从请求体获取用户技能
	var request struct {
		Skills []string `json:"skills"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{
			"error": "Invalid request body",
		})
		return
	}

	// 模拟个性化推荐数据
	recommendations := []map[string]interface{}{
		{
			"job_id":      1,
			"title":       "Java开发工程师",
			"company":     "腾讯科技",
			"location":    "深圳",
			"salary_min":  15000,
			"salary_max":  25000,
			"score":       0.85,
			"skill_match": 3,
			"reason":      "技能匹配度高",
		},
		{
			"job_id":      2,
			"title":       "前端开发工程师",
			"company":     "阿里巴巴",
			"location":    "杭州",
			"salary_min":  12000,
			"salary_max":  20000,
			"score":       0.72,
			"skill_match": 2,
			"reason":      "技能部分匹配",
		},
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":           len(recommendations),
			"user_id":         userID,
			"skills":          request.Skills,
		},
	})
}

// GetCollaborativeRecommendations 获取协同过滤推荐
func (h *AIHandler) GetCollaborativeRecommendations(c *gin.Context) {
	userID := c.Param("userID")

	// 模拟协同过滤推荐数据
	recommendations := []map[string]interface{}{
		{
			"job_id":      4,
			"title":       "DevOps工程师",
			"company":     "美团",
			"location":    "北京",
			"salary_min":  18000,
			"salary_max":  30000,
			"score":       0.82,
			"skill_match": 2,
			"reason":      "相似用户也喜欢这个职位",
		},
		{
			"job_id":      5,
			"title":       "数据工程师",
			"company":     "滴滴",
			"location":    "北京",
			"salary_min":  16000,
			"salary_max":  28000,
			"score":       0.76,
			"skill_match": 1,
			"reason":      "基于用户行为推荐",
		},
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":           len(recommendations),
			"user_id":         userID,
		},
	})
}

// CalculateSimilarity 计算相似度
func (h *AIHandler) CalculateSimilarity(c *gin.Context) {
	var request struct {
		Skills1 []string `json:"skills1"`
		Skills2 []string `json:"skills2"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{
			"error": "Invalid request body",
		})
		return
	}

	// 计算Jaccard相似度
	similarity := 0.0
	if len(request.Skills1) > 0 && len(request.Skills2) > 0 {
		// 计算交集
		intersection := make(map[string]bool)
		for _, skill := range request.Skills1 {
			intersection[skill] = true
		}

		commonSkills := 0
		for _, skill := range request.Skills2 {
			if intersection[skill] {
				commonSkills++
			}
		}

		// 计算Jaccard相似度
		union := len(request.Skills1) + len(request.Skills2) - commonSkills
		if union > 0 {
			similarity = float64(commonSkills) / float64(union)
		}
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"similarity": similarity,
			"skills1":    request.Skills1,
			"skills2":    request.Skills2,
		},
	})
}

// CalculateSkillMatch 计算技能匹配度
func (h *AIHandler) CalculateSkillMatch(c *gin.Context) {
	var request struct {
		RequiredSkills []string `json:"required_skills"`
		UserSkills     []string `json:"user_skills"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(400, gin.H{
			"error": "Invalid request body",
		})
		return
	}

	// 计算匹配的技能数量
	skillMatch := 0
	matchRate := 0.0

	if len(request.RequiredSkills) > 0 {
		for _, requiredSkill := range request.RequiredSkills {
			for _, userSkill := range request.UserSkills {
				if requiredSkill == userSkill {
					skillMatch++
					break
				}
			}
		}
		matchRate = float64(skillMatch) / float64(len(request.RequiredSkills))
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"skill_match":     skillMatch,
			"match_rate":      matchRate,
			"required_skills": request.RequiredSkills,
			"user_skills":     request.UserSkills,
		},
	})
}

// HealthCheck 健康检查
func (h *AIHandler) HealthCheck(c *gin.Context) {
	// 检查数据库连接状态
	dbHealth := h.dbManager.HealthCheck()

	// 计算整体健康状态
	allHealthy := true
	for _, healthy := range dbHealth {
		if !healthy {
			allHealthy = false
			break
		}
	}

	status := "healthy"
	if !allHealthy {
		status = "degraded"
	}

	c.JSON(200, gin.H{
		"success": true,
		"data": gin.H{
			"service":   "AI Recommendation Service",
			"status":    status,
			"version":   "1.0.0",
			"databases": dbHealth,
		},
	})
}

func main() {
	log.Println("Starting AI Recommendation Service...")

	// 初始化数据库连接
	dbManager, err := NewDatabaseManager()
	if err != nil {
		log.Fatalf("Failed to initialize database manager: %v", err)
	}
	defer dbManager.Close()

	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建Gin路由
	r := gin.Default()

	// 创建AI处理器
	aiHandler := NewAIHandler(dbManager)

	// 设置路由
	setupRoutes(r, aiHandler)

	// 启动服务器
	port := getPort()
	log.Printf("AI service starting on port %s", port)

	// 优雅关闭
	go func() {
		if err := r.Run(":" + port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down AI service...")
}

// setupRoutes 设置路由
func setupRoutes(r *gin.Engine, handler *AIHandler) {
	// 健康检查
	r.GET("/health", handler.HealthCheck)

	// API路由组
	api := r.Group("/api/v1")
	{
		// 推荐相关路由
		recommendations := api.Group("/recommendations")
		{
			// 职位推荐
			recommendations.GET("/jobs/:userID", handler.GetJobRecommendations)

			// 技能推荐
			recommendations.GET("/skills/:userID", handler.GetSkillRecommendations)

			// 个性化推荐
			recommendations.POST("/personalized/:userID", handler.GetPersonalizedRecommendations)

			// 协同过滤推荐
			recommendations.GET("/collaborative/:userID", handler.GetCollaborativeRecommendations)
		}

		// 算法相关路由
		algorithms := api.Group("/algorithms")
		{
			// 计算相似度
			algorithms.POST("/similarity", handler.CalculateSimilarity)

			// 计算技能匹配度
			algorithms.POST("/skill-match", handler.CalculateSkillMatch)
		}
	}

	// 添加中间件
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
}

// getPort 获取端口号
func getPort() string {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8089"
	}
	return port
}
