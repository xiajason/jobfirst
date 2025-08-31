package ai

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// AIHandler AI服务处理器
type AIHandler struct {
	recommendationService *RecommendationService
}

// NewAIHandler 创建AI处理器
func NewAIHandler() *AIHandler {
	return &AIHandler{
		recommendationService: NewRecommendationService(),
	}
}

// GetJobRecommendations 获取职位推荐
func (h *AIHandler) GetJobRecommendations(c *gin.Context) {
	userIDStr := c.Param("userID")
	limitStr := c.DefaultQuery("limit", "10")
	
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid user ID",
		})
		return
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 10
	}
	
	recommendations, err := h.recommendationService.GetJobRecommendations(userID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get recommendations",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":          len(recommendations),
			"user_id":        userID,
		},
	})
}

// GetUserRecommendations 获取用户推荐
func (h *AIHandler) GetUserRecommendations(c *gin.Context) {
	jobIDStr := c.Param("jobID")
	limitStr := c.DefaultQuery("limit", "10")
	
	jobID, err := strconv.ParseInt(jobIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid job ID",
		})
		return
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 10
	}
	
	recommendations, err := h.recommendationService.GetUserRecommendations(jobID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get user recommendations",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":          len(recommendations),
			"job_id":         jobID,
		},
	})
}

// GetSkillRecommendations 获取技能推荐
func (h *AIHandler) GetSkillRecommendations(c *gin.Context) {
	userIDStr := c.Param("userID")
	limitStr := c.DefaultQuery("limit", "10")
	
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid user ID",
		})
		return
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 10
	}
	
	recommendations, err := h.recommendationService.GetSkillRecommendations(userID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get skill recommendations",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":          len(recommendations),
			"user_id":        userID,
		},
	})
}

// GetPersonalizedRecommendations 获取个性化推荐
func (h *AIHandler) GetPersonalizedRecommendations(c *gin.Context) {
	userIDStr := c.Param("userID")
	limitStr := c.DefaultQuery("limit", "10")
	
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid user ID",
		})
		return
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 10
	}
	
	// 从请求体获取用户技能
	var request struct {
		Skills []string `json:"skills"`
	}
	
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request body",
		})
		return
	}
	
	recommendations, err := h.recommendationService.GetPersonalizedRecommendations(userID, request.Skills, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get personalized recommendations",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":          len(recommendations),
			"user_id":        userID,
			"skills":         request.Skills,
		},
	})
}

// GetCollaborativeRecommendations 获取协同过滤推荐
func (h *AIHandler) GetCollaborativeRecommendations(c *gin.Context) {
	userIDStr := c.Param("userID")
	limitStr := c.DefaultQuery("limit", "10")
	
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid user ID",
		})
		return
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		limit = 10
	}
	
	recommendations, err := h.recommendationService.GetCollaborativeRecommendations(userID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to get collaborative recommendations",
		})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"recommendations": recommendations,
			"total":          len(recommendations),
			"user_id":        userID,
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
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request body",
		})
		return
	}
	
	similarity := h.recommendationService.CalculateSimilarity(request.Skills1, request.Skills2)
	
	c.JSON(http.StatusOK, gin.H{
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
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request body",
		})
		return
	}
	
	skillMatch, matchRate := h.recommendationService.CalculateSkillMatch(request.RequiredSkills, request.UserSkills)
	
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"skill_match": skillMatch,
			"match_rate":  matchRate,
			"required_skills": request.RequiredSkills,
			"user_skills":     request.UserSkills,
		},
	})
}

// HealthCheck 健康检查
func (h *AIHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"service": "AI Recommendation Service",
			"status":  "healthy",
			"version": "1.0.0",
		},
	})
}
