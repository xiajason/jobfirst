package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
)

func main() {
	log.Println("Starting AI Recommendation Service...")

	// 设置Gin模式
	gin.SetMode(gin.ReleaseMode)

	// 创建Gin路由
	r := gin.Default()

	// 创建AI处理器
	aiHandler := NewAIHandler()

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
			
			// 用户推荐（招聘方使用）
			recommendations.GET("/users/:jobID", handler.GetUserRecommendations)
			
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
