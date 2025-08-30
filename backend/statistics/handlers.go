package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// 记录统计事件
func recordEvent(c *gin.Context) {
	var req struct {
		Type        string `json:"type" binding:"required"`
		Value       int64  `json:"value" binding:"required"`
		UserID      *uint  `json:"user_id"`
		ReferenceID string `json:"reference_id"`
		Metadata    string `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 创建统计数据
	statistics := Statistics{
		ID:          uuid.New().String(),
		Type:        StatisticsType(req.Type),
		Period:      StatisticsPeriodDay,
		Date:        time.Now().Truncate(24 * time.Hour),
		Value:       req.Value,
		UserID:      req.UserID,
		ReferenceID: req.ReferenceID,
		Metadata:    req.Metadata,
	}

	if err := db.Create(&statistics).Error; err != nil {
		logger.Errorf("Failed to record event: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record event"})
		return
	}

	// 更新实时统计
	updateRealTimeStats(req.Type, req.Value)

	c.JSON(http.StatusOK, gin.H{
		"message": "Event recorded successfully",
		"data":    statistics,
	})
}

// 获取实时统计
func getRealTimeStats(c *gin.Context) {
	statsType := c.Query("type")
	if statsType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Type parameter is required"})
		return
	}

	var realTimeStats RealTimeStats
	if err := db.Where("type = ?", statsType).First(&realTimeStats).Error; err != nil {
		// 如果不存在，返回0
		c.JSON(http.StatusOK, gin.H{
			"type":  statsType,
			"value": 0,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"type":         realTimeStats.Type,
		"value":        realTimeStats.Value,
		"last_updated": realTimeStats.LastUpdated,
	})
}

// 获取统计摘要
func getStatisticsSummary(c *gin.Context) {
	statsType := c.Query("type")
	period := c.Query("period")
	if period == "" {
		period = "day"
	}

	var stats []Statistics
	query := db.Where("type = ? AND period = ?", statsType, period)

	// 添加时间范围过滤
	if startDate := c.Query("start_date"); startDate != "" {
		query = query.Where("date >= ?", startDate)
	}
	if endDate := c.Query("end_date"); endDate != "" {
		query = query.Where("date <= ?", endDate)
	}

	if err := query.Order("date ASC").Find(&stats).Error; err != nil {
		logger.Errorf("Failed to get statistics summary: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get statistics summary"})
		return
	}

	// 计算汇总数据
	var totalValue int64
	var dataPoints []gin.H

	for _, stat := range stats {
		totalValue += stat.Value
		dataPoints = append(dataPoints, gin.H{
			"date":  stat.Date.Format("2006-01-02"),
			"value": stat.Value,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"type":        statsType,
		"period":      period,
		"total_value": totalValue,
		"data_points": dataPoints,
	})
}

// 获取统计趋势
func getStatisticsTrend(c *gin.Context) {
	statsType := c.Query("type")
	period := c.Query("period")
	if period == "" {
		period = "day"
	}

	days, _ := strconv.Atoi(c.Query("days"))
	if days == 0 {
		days = 7
	}

	endDate := time.Now().Truncate(24 * time.Hour)
	startDate := endDate.AddDate(0, 0, -days)

	var stats []Statistics
	if err := db.Where("type = ? AND period = ? AND date BETWEEN ? AND ?",
		statsType, period, startDate, endDate).Order("date ASC").Find(&stats).Error; err != nil {
		logger.Errorf("Failed to get statistics trend: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get statistics trend"})
		return
	}

	// 构建趋势数据
	trendData := make(map[string]int64)
	for _, stat := range stats {
		dateKey := stat.Date.Format("2006-01-02")
		trendData[dateKey] = stat.Value
	}

	c.JSON(http.StatusOK, gin.H{
		"type":       statsType,
		"period":     period,
		"start_date": startDate.Format("2006-01-02"),
		"end_date":   endDate.Format("2006-01-02"),
		"trend":      trendData,
	})
}

// 生成统计报表
func generateReport(c *gin.Context) {
	var req struct {
		Name      string `json:"name" binding:"required"`
		Type      string `json:"type" binding:"required"`
		Period    string `json:"period" binding:"required"`
		StartDate string `json:"start_date" binding:"required"`
		EndDate   string `json:"end_date" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	startDate, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid start_date format"})
		return
	}

	endDate, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid end_date format"})
		return
	}

	// 获取统计数据
	var stats []Statistics
	if err := db.Where("type = ? AND period = ? AND date BETWEEN ? AND ?",
		req.Type, req.Period, startDate, endDate).Order("date ASC").Find(&stats).Error; err != nil {
		logger.Errorf("Failed to generate report: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate report"})
		return
	}

	// 生成报表数据
	reportData := gin.H{
		"summary": gin.H{
			"total_records": len(stats),
			"total_value":   calculateTotalValue(stats),
			"avg_value":     calculateAverageValue(stats),
		},
		"data": stats,
	}

	reportDataJSON, _ := json.Marshal(reportData)

	// 创建报表记录
	report := StatisticsReport{
		ID:          uuid.New().String(),
		Name:        req.Name,
		Type:        StatisticsType(req.Type),
		Period:      StatisticsPeriod(req.Period),
		StartDate:   startDate,
		EndDate:     endDate,
		Data:        string(reportDataJSON),
		IsGenerated: true,
	}

	if err := db.Create(&report).Error; err != nil {
		logger.Errorf("Failed to save report: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save report"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Report generated successfully",
		"report":  report,
		"data":    reportData,
	})
}

// 跟踪用户行为
func trackUserBehavior(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req struct {
		Type        string `json:"type" binding:"required"`
		ReferenceID string `json:"reference_id"`
		Metadata    string `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 获取客户端IP和User-Agent
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")

	// 创建用户行为记录
	behavior := UserBehavior{
		ID:          uuid.New().String(),
		UserID:      userID,
		Type:        StatisticsType(req.Type),
		ReferenceID: req.ReferenceID,
		IP:          clientIP,
		UserAgent:   userAgent,
		Metadata:    req.Metadata,
		CreatedAt:   time.Now(),
	}

	if err := db.Create(&behavior).Error; err != nil {
		logger.Errorf("Failed to track user behavior: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to track user behavior"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "User behavior tracked successfully",
		"data":    behavior,
	})
}

// 分析用户行为
func analyzeUserBehavior(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	days, _ := strconv.Atoi(c.Query("days"))
	if days == 0 {
		days = 30
	}

	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -days)

	var behaviors []UserBehavior
	if err := db.Where("user_id = ? AND created_at BETWEEN ? AND ?",
		userID, startDate, endDate).Order("created_at DESC").Find(&behaviors).Error; err != nil {
		logger.Errorf("Failed to analyze user behavior: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to analyze user behavior"})
		return
	}

	// 分析行为数据
	behaviorAnalysis := analyzeBehaviors(behaviors)

	c.JSON(http.StatusOK, gin.H{
		"user_id":          userID,
		"start_date":       startDate.Format("2006-01-02"),
		"end_date":         endDate.Format("2006-01-02"),
		"total_behaviors":  len(behaviors),
		"analysis":         behaviorAnalysis,
		"recent_behaviors": behaviors[:min(len(behaviors), 10)], // 最近10条行为
	})
}

// 更新实时统计
func updateRealTimeStats(statsType string, value int64) {
	var realTimeStats RealTimeStats
	if err := db.Where("type = ?", statsType).First(&realTimeStats).Error; err != nil {
		// 如果不存在，创建新的
		realTimeStats = RealTimeStats{
			ID:          uuid.New().String(),
			Type:        StatisticsType(statsType),
			Value:       value,
			LastUpdated: time.Now(),
		}
		db.Create(&realTimeStats)
	} else {
		// 更新现有记录
		realTimeStats.Value += value
		realTimeStats.LastUpdated = time.Now()
		db.Save(&realTimeStats)
	}
}

// 计算总价值
func calculateTotalValue(stats []Statistics) int64 {
	var total int64
	for _, stat := range stats {
		total += stat.Value
	}
	return total
}

// 计算平均价值
func calculateAverageValue(stats []Statistics) float64 {
	if len(stats) == 0 {
		return 0
	}
	total := calculateTotalValue(stats)
	return float64(total) / float64(len(stats))
}

// 分析用户行为
func analyzeBehaviors(behaviors []UserBehavior) gin.H {
	// 按类型统计
	typeCount := make(map[string]int)
	for _, behavior := range behaviors {
		typeCount[string(behavior.Type)]++
	}

	// 按日期统计
	dateCount := make(map[string]int)
	for _, behavior := range behaviors {
		dateKey := behavior.CreatedAt.Format("2006-01-02")
		dateCount[dateKey]++
	}

	return gin.H{
		"by_type": typeCount,
		"by_date": dateCount,
	}
}

// 辅助函数：取最小值
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
