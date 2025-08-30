package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type PointsHandler struct{}

func NewPointsHandler() *PointsHandler {
	return &PointsHandler{}
}

// GetPointsBalance 获取积分余额
func (h *PointsHandler) GetPointsBalance(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	// 模拟积分账户数据
	account := map[string]interface{}{
		"user_id":             userID,
		"balance":             1250,
		"total_earned":        1500,
		"total_spent":         250,
		"level":               "silver",
		"level_points":        1250,
		"next_level_points":   2000,
		"last_activity_time":  "2024-08-30T16:00:00Z",
		"points_needed":       750,
		"level_progress":      62.5, // 百分比
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"account": account,
			"version": "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetPointsRecords 获取积分记录
func (h *PointsHandler) GetPointsRecords(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// 模拟积分记录数据
	records := []map[string]interface{}{
		{
			"id":             1,
			"user_id":        userID,
			"rule_code":      "DAILY_CHECKIN",
			"rule_name":      "每日签到",
			"points":         10,
			"balance_before": 1240,
			"balance_after":  1250,
			"record_type":    "earn",
			"source_type":    "daily_checkin",
			"description":    "每日签到获得积分",
			"created_at":     "2024-08-30T08:00:00Z",
		},
		{
			"id":             2,
			"user_id":        userID,
			"rule_code":      "JOB_APPLY",
			"rule_name":      "投递简历",
			"points":         5,
			"balance_before": 1235,
			"balance_after":  1240,
			"record_type":    "earn",
			"source_type":    "job_apply",
			"description":    "投递简历获得积分",
			"created_at":     "2024-08-30T10:30:00Z",
		},
		{
			"id":             3,
			"user_id":        userID,
			"rule_code":      "RESUME_VIEW",
			"rule_name":      "简历被查看",
			"points":         2,
			"balance_before": 1233,
			"balance_after":  1235,
			"record_type":    "earn",
			"source_type":    "resume_view",
			"description":    "简历被HR查看获得积分",
			"created_at":     "2024-08-30T14:15:00Z",
		},
		{
			"id":             4,
			"user_id":        userID,
			"rule_code":      "EXCHANGE_COUPON",
			"rule_name":      "兑换优惠券",
			"points":         -100,
			"balance_before": 1333,
			"balance_after":  1233,
			"record_type":    "spend",
			"source_type":    "exchange",
			"description":    "兑换优惠券消耗积分",
			"created_at":     "2024-08-29T16:20:00Z",
		},
		{
			"id":             5,
			"user_id":        userID,
			"rule_code":      "COMPLETE_PROFILE",
			"rule_name":      "完善资料",
			"points":         20,
			"balance_before": 1313,
			"balance_after":  1333,
			"record_type":    "earn",
			"source_type":    "system",
			"description":    "完善个人资料获得积分",
			"created_at":     "2024-08-28T09:00:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"records": records,
			"total":   len(records),
			"page":    page,
			"limit":   limit,
			"version": "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetPointsRules 获取积分规则
func (h *PointsHandler) GetPointsRules(c *gin.Context) {
	// 模拟积分规则数据
	rules := []map[string]interface{}{
		{
			"rule_code":    "DAILY_CHECKIN",
			"rule_name":    "每日签到",
			"rule_type":    "earn",
			"points":       10,
			"description":  "每日签到获得积分",
			"daily_limit":  1,
			"total_limit":  0,
			"status":       "active",
		},
		{
			"rule_code":    "JOB_APPLY",
			"rule_name":    "投递简历",
			"rule_type":    "earn",
			"points":       5,
			"description":  "投递简历获得积分",
			"daily_limit":  10,
			"total_limit":  0,
			"status":       "active",
		},
		{
			"rule_code":    "RESUME_VIEW",
			"rule_name":    "简历被查看",
			"rule_type":    "earn",
			"points":       2,
			"description":  "简历被HR查看获得积分",
			"daily_limit":  0,
			"total_limit":  0,
			"status":       "active",
		},
		{
			"rule_code":    "INVITE_FRIEND",
			"rule_name":    "邀请好友",
			"rule_type":    "earn",
			"points":       50,
			"description":  "邀请好友注册获得积分",
			"daily_limit":  0,
			"total_limit":  0,
			"status":       "active",
		},
		{
			"rule_code":    "COMPLETE_PROFILE",
			"rule_name":    "完善资料",
			"rule_type":    "earn",
			"points":       20,
			"description":  "完善个人资料获得积分",
			"daily_limit":  0,
			"total_limit":  1,
			"status":       "active",
		},
		{
			"rule_code":    "EXCHANGE_COUPON",
			"rule_name":    "兑换优惠券",
			"rule_type":    "spend",
			"points":       -100,
			"description":  "兑换优惠券消耗积分",
			"daily_limit":  0,
			"total_limit":  0,
			"status":       "active",
		},
		{
			"rule_code":    "EXCHANGE_VIP",
			"rule_name":    "兑换VIP",
			"rule_type":    "spend",
			"points":       -500,
			"description":  "兑换VIP会员消耗积分",
			"daily_limit":  0,
			"total_limit":  0,
			"status":       "active",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"rules":   rules,
			"total":   len(rules),
			"version": "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// ExchangePoints 积分兑换
func (h *PointsHandler) ExchangePoints(c *gin.Context) {
	var request struct {
		ItemType   string  `json:"item_type" binding:"required"`
		ItemName   string  `json:"item_name" binding:"required"`
		PointsCost int     `json:"points_cost" binding:"required"`
		ItemValue  float64 `json:"item_value"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	// 模拟兑换记录
	exchange := map[string]interface{}{
		"id":             1,
		"user_id":        userID,
		"exchange_code":  "EXCH_" + strconv.FormatInt(time.Now().Unix(), 10),
		"item_name":      request.ItemName,
		"item_type":      request.ItemType,
		"points_cost":    request.PointsCost,
		"item_value":     request.ItemValue,
		"status":         "completed",
		"exchange_time":  time.Now().Format("2006-01-02T15:04:05Z"),
		"expire_time":    time.Now().AddDate(0, 1, 0).Format("2006-01-02T15:04:05Z"), // 1个月后过期
		"description":    "积分兑换成功",
		"created_at":     time.Now().Format("2006-01-02T15:04:05Z"),
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Exchange successful",
		"data": map[string]interface{}{
			"exchange": exchange,
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetExchangeHistory 获取兑换历史
func (h *PointsHandler) GetExchangeHistory(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// 模拟兑换历史数据
	exchanges := []map[string]interface{}{
		{
			"id":             1,
			"user_id":        userID,
			"exchange_code":  "EXCH_1735567890",
			"item_name":      "优惠券",
			"item_type":      "coupon",
			"points_cost":    100,
			"item_value":     50.00,
			"status":         "completed",
			"exchange_time":  "2024-08-29T16:20:00Z",
			"expire_time":    "2024-09-29T16:20:00Z",
			"description":    "兑换优惠券",
			"created_at":     "2024-08-29T16:20:00Z",
		},
		{
			"id":             2,
			"user_id":        userID,
			"exchange_code":  "EXCH_1735471234",
			"item_name":      "VIP会员",
			"item_type":      "vip",
			"points_cost":    500,
			"item_value":     200.00,
			"status":         "completed",
			"exchange_time":  "2024-08-28T10:30:00Z",
			"expire_time":    "2024-11-28T10:30:00Z",
			"description":    "兑换VIP会员",
			"created_at":     "2024-08-28T10:30:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"exchanges": exchanges,
			"total":     len(exchanges),
			"page":      page,
			"limit":     limit,
			"version":   "v2",
			"database":  "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}
