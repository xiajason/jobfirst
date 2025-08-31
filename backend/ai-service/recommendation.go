package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"
)

// RecommendationService 推荐服务
type RecommendationService struct {
	dbManager *DatabaseManager
}

// NewRecommendationService 创建推荐服务
func NewRecommendationService(dbManager *DatabaseManager) *RecommendationService {
	return &RecommendationService{
		dbManager: dbManager,
	}
}

// JobRecommendation 职位推荐结果
type JobRecommendation struct {
	JobID      uint    `json:"job_id"`
	Title      string  `json:"title"`
	Company    string  `json:"company"`
	Location   string  `json:"location"`
	SalaryMin  int     `json:"salary_min"`
	SalaryMax  int     `json:"salary_max"`
	Score      float64 `json:"score"`
	SkillMatch int     `json:"skill_match"`
	Reason     string  `json:"reason"`
	Algorithm  string  `json:"algorithm"`
}

// SkillRecommendation 技能推荐结果
type SkillRecommendation struct {
	SkillName string  `json:"skill_name"`
	Category  string  `json:"category"`
	Score     float64 `json:"score"`
	Demand    int     `json:"demand"`
	Reason    string  `json:"reason"`
}

// GetJobRecommendations 获取职位推荐
func (rs *RecommendationService) GetJobRecommendations(userID uint, limit int) ([]JobRecommendation, error) {
	// 从缓存获取推荐结果
	cacheKey := fmt.Sprintf("job_recommendations:%d", userID)
	cached, err := rs.getCachedRecommendations(cacheKey)
	if err == nil && len(cached) > 0 {
		return cached, nil
	}

	// 获取模拟推荐数据
	recommendations := rs.getMockJobRecommendations(userID, limit)

	// 缓存结果
	rs.cacheRecommendations(cacheKey, recommendations, 30*time.Minute)

	return recommendations, nil
}

// GetSkillRecommendations 获取技能推荐
func (rs *RecommendationService) GetSkillRecommendations(userID uint, limit int) ([]SkillRecommendation, error) {
	return rs.getMockSkillRecommendations(userID, limit), nil
}

// GetPersonalizedRecommendations 获取个性化推荐
func (rs *RecommendationService) GetPersonalizedRecommendations(userID uint, skills []string, limit int) ([]JobRecommendation, error) {
	// 基于技能进行推荐
	recommendations := rs.getMockJobRecommendations(userID, limit)

	// 根据技能调整评分
	for i := range recommendations {
		recommendations[i].Score += 0.1 // 增加个性化评分
		recommendations[i].Reason = fmt.Sprintf("基于技能 %v 的个性化推荐", skills)
	}

	return recommendations, nil
}

// CalculateSimilarity 计算相似度
func (rs *RecommendationService) CalculateSimilarity(skills1, skills2 []string) float64 {
	if len(skills1) == 0 || len(skills2) == 0 {
		return 0.0
	}

	// 计算Jaccard相似度
	set1 := make(map[string]bool)
	for _, skill := range skills1 {
		set1[strings.ToLower(skill)] = true
	}

	set2 := make(map[string]bool)
	for _, skill := range skills2 {
		set2[strings.ToLower(skill)] = true
	}

	// 计算交集
	intersection := 0
	for skill := range set1 {
		if set2[skill] {
			intersection++
		}
	}

	// 计算并集
	union := len(set1) + len(set2) - intersection

	if union == 0 {
		return 0.0
	}

	return float64(intersection) / float64(union)
}

// CalculateSkillMatch 计算技能匹配度
func (rs *RecommendationService) CalculateSkillMatch(requiredSkills, userSkills []string) (int, float64) {
	if len(requiredSkills) == 0 {
		return 0, 0.0
	}

	// 转换为小写进行比较
	requiredSet := make(map[string]bool)
	for _, skill := range requiredSkills {
		requiredSet[strings.ToLower(skill)] = true
	}

	userSet := make(map[string]bool)
	for _, skill := range userSkills {
		userSet[strings.ToLower(skill)] = true
	}

	// 计算匹配的技能数量
	matched := 0
	for skill := range requiredSet {
		if userSet[skill] {
			matched++
		}
	}

	matchRate := float64(matched) / float64(len(requiredSkills))
	return matched, matchRate
}

// getCachedRecommendations 从缓存获取推荐结果
func (rs *RecommendationService) getCachedRecommendations(cacheKey string) ([]JobRecommendation, error) {
	ctx := context.Background()
	data, err := rs.dbManager.Redis.Get(ctx, cacheKey).Result()
	if err != nil {
		return nil, err
	}

	var recommendations []JobRecommendation
	err = json.Unmarshal([]byte(data), &recommendations)
	return recommendations, err
}

// cacheRecommendations 缓存推荐结果
func (rs *RecommendationService) cacheRecommendations(cacheKey string, recommendations []JobRecommendation, duration time.Duration) {
	ctx := context.Background()
	data, err := json.Marshal(recommendations)
	if err != nil {
		log.Printf("Failed to marshal recommendations: %v", err)
		return
	}

	rs.dbManager.Redis.Set(ctx, cacheKey, data, duration)
}

// getMockJobRecommendations 获取模拟职位推荐
func (rs *RecommendationService) getMockJobRecommendations(userID uint, limit int) []JobRecommendation {
	return []JobRecommendation{
		{
			JobID:      1,
			Title:      "Java开发工程师",
			Company:    "腾讯科技",
			Location:   "深圳",
			SalaryMin:  15000,
			SalaryMax:  25000,
			Score:      0.85,
			SkillMatch: 3,
			Reason:     "技能匹配度高",
			Algorithm:  "content_based",
		},
		{
			JobID:      2,
			Title:      "前端开发工程师",
			Company:    "阿里巴巴",
			Location:   "杭州",
			SalaryMin:  12000,
			SalaryMax:  20000,
			Score:      0.72,
			SkillMatch: 2,
			Reason:     "技能部分匹配",
			Algorithm:  "collaborative",
		},
		{
			JobID:      3,
			Title:      "DevOps工程师",
			Company:    "美团",
			Location:   "北京",
			SalaryMin:  18000,
			SalaryMax:  30000,
			Score:      0.82,
			SkillMatch: 2,
			Reason:     "基于技能关系图推荐",
			Algorithm:  "graph_based",
		},
	}
}

// getMockSkillRecommendations 获取模拟技能推荐
func (rs *RecommendationService) getMockSkillRecommendations(userID uint, limit int) []SkillRecommendation {
	return []SkillRecommendation{
		{
			SkillName: "Spring Boot",
			Category:  "framework",
			Score:     0.92,
			Demand:    85,
			Reason:    "与Java技能高度相关，市场需求大",
		},
		{
			SkillName: "Docker",
			Category:  "devops",
			Score:     0.78,
			Demand:    72,
			Reason:    "现代化部署必备技能",
		},
		{
			SkillName: "Kubernetes",
			Category:  "devops",
			Score:     0.75,
			Demand:    68,
			Reason:    "容器编排必备技能",
		},
	}
}
