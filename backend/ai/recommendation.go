package ai

import (
	"fmt"
	"log"
	"math"
	"sort"
)

// JobRecommendation 职位推荐
type JobRecommendation struct {
	JobID       int64   `json:"job_id"`
	Title       string  `json:"title"`
	Company     string  `json:"company"`
	Location    string  `json:"location"`
	SalaryMin   int     `json:"salary_min"`
	SalaryMax   int     `json:"salary_max"`
	Score       float64 `json:"score"`
	SkillMatch  int     `json:"skill_match"`
	Reason      string  `json:"reason"`
}

// UserRecommendation 用户推荐
type UserRecommendation struct {
	UserID      int64   `json:"user_id"`
	Username    string  `json:"username"`
	Nickname    string  `json:"nickname"`
	Score       float64 `json:"score"`
	SkillMatch  int     `json:"skill_match"`
	Reason      string  `json:"reason"`
}

// SkillRecommendation 技能推荐
type SkillRecommendation struct {
	SkillName   string  `json:"skill_name"`
	Category    string  `json:"category"`
	Score       float64 `json:"score"`
	Demand      int     `json:"demand"`
	Reason      string  `json:"reason"`
}

// RecommendationService 推荐服务
type RecommendationService struct {
	// 这里可以注入数据库连接
	// MySQL, PostgreSQL, Neo4j, Redis等
}

// NewRecommendationService 创建推荐服务
func NewRecommendationService() *RecommendationService {
	return &RecommendationService{}
}

// GetJobRecommendations 获取职位推荐
func (rs *RecommendationService) GetJobRecommendations(userID int64, limit int) ([]JobRecommendation, error) {
	log.Printf("Getting job recommendations for user %d", userID)
	
	// 模拟推荐算法
	recommendations := []JobRecommendation{
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
		},
		{
			JobID:      3,
			Title:      "Python算法工程师",
			Company:    "字节跳动",
			Location:   "北京",
			SalaryMin:  20000,
			SalaryMax:  35000,
			Score:      0.68,
			SkillMatch: 1,
			Reason:     "技能相关",
		},
	}
	
	// 按分数排序
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})
	
	// 限制返回数量
	if limit > 0 && limit < len(recommendations) {
		recommendations = recommendations[:limit]
	}
	
	return recommendations, nil
}

// GetUserRecommendations 获取用户推荐（用于招聘方）
func (rs *RecommendationService) GetUserRecommendations(jobID int64, limit int) ([]UserRecommendation, error) {
	log.Printf("Getting user recommendations for job %d", jobID)
	
	// 模拟推荐算法
	recommendations := []UserRecommendation{
		{
			UserID:     1,
			Username:   "zhangsan",
			Nickname:   "张三",
			Score:      0.88,
			SkillMatch: 4,
			Reason:     "技能完全匹配",
		},
		{
			UserID:     2,
			Username:   "lisi",
			Nickname:   "李四",
			Score:      0.75,
			SkillMatch: 3,
			Reason:     "技能高度匹配",
		},
		{
			UserID:     3,
			Username:   "wangwu",
			Nickname:   "王五",
			Score:      0.65,
			SkillMatch: 2,
			Reason:     "技能部分匹配",
		},
	}
	
	// 按分数排序
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})
	
	// 限制返回数量
	if limit > 0 && limit < len(recommendations) {
		recommendations = recommendations[:limit]
	}
	
	return recommendations, nil
}

// GetSkillRecommendations 获取技能推荐
func (rs *RecommendationService) GetSkillRecommendations(userID int64, limit int) ([]SkillRecommendation, error) {
	log.Printf("Getting skill recommendations for user %d", userID)
	
	// 模拟推荐算法
	recommendations := []SkillRecommendation{
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
			Score:     0.65,
			Demand:    58,
			Reason:    "容器编排热门技能",
		},
	}
	
	// 按分数排序
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})
	
	// 限制返回数量
	if limit > 0 && limit < len(recommendations) {
		recommendations = recommendations[:limit]
	}
	
	return recommendations, nil
}

// CalculateSimilarity 计算相似度
func (rs *RecommendationService) CalculateSimilarity(skills1, skills2 []string) float64 {
	if len(skills1) == 0 || len(skills2) == 0 {
		return 0.0
	}
	
	// 计算交集
	intersection := make(map[string]bool)
	for _, skill := range skills1 {
		intersection[skill] = true
	}
	
	commonSkills := 0
	for _, skill := range skills2 {
		if intersection[skill] {
			commonSkills++
		}
	}
	
	// 计算Jaccard相似度
	union := len(skills1) + len(skills2) - commonSkills
	if union == 0 {
		return 0.0
	}
	
	return float64(commonSkills) / float64(union)
}

// CalculateSkillMatch 计算技能匹配度
func (rs *RecommendationService) CalculateSkillMatch(requiredSkills, userSkills []string) (int, float64) {
	if len(requiredSkills) == 0 {
		return 0, 0.0
	}
	
	// 计算匹配的技能数量
	matchedSkills := 0
	for _, requiredSkill := range requiredSkills {
		for _, userSkill := range userSkills {
			if requiredSkill == userSkill {
				matchedSkills++
				break
			}
		}
	}
	
	// 计算匹配率
	matchRate := float64(matchedSkills) / float64(len(requiredSkills))
	
	return matchedSkills, matchRate
}

// GetPersonalizedRecommendations 获取个性化推荐
func (rs *RecommendationService) GetPersonalizedRecommendations(userID int64, userSkills []string, limit int) ([]JobRecommendation, error) {
	log.Printf("Getting personalized recommendations for user %d", userID)
	
	// 模拟职位数据
	jobs := []struct {
		ID            int64
		Title         string
		Company       string
		Location      string
		SalaryMin     int
		SalaryMax     int
		RequiredSkills []string
	}{
		{
			ID:            1,
			Title:         "Java开发工程师",
			Company:       "腾讯科技",
			Location:      "深圳",
			SalaryMin:     15000,
			SalaryMax:     25000,
			RequiredSkills: []string{"Java", "Spring Boot", "MySQL"},
		},
		{
			ID:            2,
			Title:         "前端开发工程师",
			Company:       "阿里巴巴",
			Location:      "杭州",
			SalaryMin:     12000,
			SalaryMax:     20000,
			RequiredSkills: []string{"React", "Vue.js", "JavaScript"},
		},
		{
			ID:            3,
			Title:         "Python算法工程师",
			Company:       "字节跳动",
			Location:      "北京",
			SalaryMin:     20000,
			SalaryMax:     35000,
			RequiredSkills: []string{"Python", "Machine Learning", "TensorFlow"},
		},
	}
	
	var recommendations []JobRecommendation
	
	for _, job := range jobs {
		skillMatch, matchRate := rs.CalculateSkillMatch(job.RequiredSkills, userSkills)
		
		// 计算综合评分
		score := matchRate * 0.7 // 技能匹配权重70%
		
		// 添加位置偏好（这里简化处理）
		if len(userSkills) > 0 {
			score += 0.1 // 基础分数
		}
		
		// 添加薪资偏好（这里简化处理）
		score += 0.1 // 基础分数
		
		// 限制分数范围
		score = math.Min(score, 1.0)
		score = math.Max(score, 0.0)
		
		recommendations = append(recommendations, JobRecommendation{
			JobID:      job.ID,
			Title:      job.Title,
			Company:    job.Company,
			Location:   job.Location,
			SalaryMin:  job.SalaryMin,
			SalaryMax:  job.SalaryMax,
			Score:      score,
			SkillMatch: skillMatch,
			Reason:     fmt.Sprintf("技能匹配度%.1f%%", matchRate*100),
		})
	}
	
	// 按分数排序
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})
	
	// 限制返回数量
	if limit > 0 && limit < len(recommendations) {
		recommendations = recommendations[:limit]
	}
	
	return recommendations, nil
}

// GetCollaborativeRecommendations 获取协同过滤推荐
func (rs *RecommendationService) GetCollaborativeRecommendations(userID int64, limit int) ([]JobRecommendation, error) {
	log.Printf("Getting collaborative recommendations for user %d", userID)
	
	// 这里可以实现基于用户行为的协同过滤算法
	// 目前返回模拟数据
	
	recommendations := []JobRecommendation{
		{
			JobID:      4,
			Title:      "DevOps工程师",
			Company:    "美团",
			Location:   "北京",
			SalaryMin:  18000,
			SalaryMax:  30000,
			Score:      0.82,
			SkillMatch: 2,
			Reason:     "相似用户也喜欢这个职位",
		},
		{
			JobID:      5,
			Title:      "数据工程师",
			Company:    "滴滴",
			Location:   "北京",
			SalaryMin:  16000,
			SalaryMax:  28000,
			Score:      0.76,
			SkillMatch: 1,
			Reason:     "基于用户行为推荐",
		},
	}
	
	// 按分数排序
	sort.Slice(recommendations, func(i, j int) bool {
		return recommendations[i].Score > recommendations[j].Score
	})
	
	// 限制返回数量
	if limit > 0 && limit < len(recommendations) {
		recommendations = recommendations[:limit]
	}
	
	return recommendations, nil
}
