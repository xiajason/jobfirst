package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type NotificationHandler struct{}

func NewNotificationHandler() *NotificationHandler {
	return &NotificationHandler{}
}

// GetNotifications 获取通知列表
func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	notificationType := c.Query("type")
	readStatus := c.Query("read_status")

	// 模拟通知数据
	notifications := []map[string]interface{}{
		{
			"id":                 1,
			"user_id":            userID,
			"notification_type":  "job_apply",
			"title":              "申请成功",
			"content":            "您申请的职位\"前端开发工程师\"已成功提交，我们会尽快为您安排面试。",
			"data": map[string]interface{}{
				"job_id":    1,
				"job_title": "前端开发工程师",
				"company":   "腾讯科技有限公司",
			},
			"read_status":        "unread",
			"read_time":          nil,
			"send_status":        "sent",
			"send_time":          "2024-08-30T16:30:00Z",
			"expire_time":        "2024-09-30T16:30:00Z",
			"created_at":         "2024-08-30T16:30:00Z",
		},
		{
			"id":                 2,
			"user_id":            userID,
			"notification_type":  "resume_view",
			"title":              "简历被查看",
			"content":            "您的简历被\"阿里巴巴集团\"查看，请保持电话畅通。",
			"data": map[string]interface{}{
				"company_id":   2,
				"company_name": "阿里巴巴集团",
				"view_time":    "2024-08-30T15:45:00Z",
			},
			"read_status":        "read",
			"read_time":          "2024-08-30T16:00:00Z",
			"send_status":        "sent",
			"send_time":          "2024-08-30T15:45:00Z",
			"expire_time":        "2024-09-30T15:45:00Z",
			"created_at":         "2024-08-30T15:45:00Z",
		},
		{
			"id":                 3,
			"user_id":            userID,
			"notification_type":  "chat_message",
			"title":              "新消息",
			"content":            "您收到来自\"HR张经理\"的新消息：请问您明天下午2点有空面试吗？",
			"data": map[string]interface{}{
				"sender_id":   2,
				"sender_name": "HR张经理",
				"session_id":  "session_001",
				"message_id":  5,
			},
			"read_status":        "unread",
			"read_time":          nil,
			"send_status":        "sent",
			"send_time":          "2024-08-30T14:20:00Z",
			"expire_time":        "2024-09-30T14:20:00Z",
			"created_at":         "2024-08-30T14:20:00Z",
		},
		{
			"id":                 4,
			"user_id":            userID,
			"notification_type":  "points_earned",
			"title":              "获得积分",
			"content":            "恭喜您获得10积分！每日签到",
			"data": map[string]interface{}{
				"points":      10,
				"reason":      "每日签到",
				"rule_code":   "DAILY_CHECKIN",
				"balance":     1250,
			},
			"read_status":        "read",
			"read_time":          "2024-08-30T08:30:00Z",
			"send_status":        "sent",
			"send_time":          "2024-08-30T08:00:00Z",
			"expire_time":        "2024-09-30T08:00:00Z",
			"created_at":         "2024-08-30T08:00:00Z",
		},
		{
			"id":                 5,
			"user_id":            userID,
			"notification_type":  "system_announcement",
			"title":              "系统公告",
			"content":            "系统将于今晚22:00-24:00进行维护升级，期间可能影响部分功能使用，请提前做好准备。",
			"data": map[string]interface{}{
				"announcement_id": 1,
				"priority":        "high",
				"category":        "maintenance",
			},
			"read_status":        "unread",
			"read_time":          nil,
			"send_status":        "sent",
			"send_time":          "2024-08-30T10:00:00Z",
			"expire_time":        "2024-09-30T10:00:00Z",
			"created_at":         "2024-08-30T10:00:00Z",
		},
	}

	// 根据查询条件过滤
	filteredNotifications := notifications
	if notificationType != "" {
		var filtered []map[string]interface{}
		for _, notification := range filteredNotifications {
			if notification["notification_type"] == notificationType {
				filtered = append(filtered, notification)
			}
		}
		filteredNotifications = filtered
	}

	if readStatus != "" {
		var filtered []map[string]interface{}
		for _, notification := range filteredNotifications {
			if notification["read_status"] == readStatus {
				filtered = append(filtered, notification)
			}
		}
		filteredNotifications = filtered
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"notifications": filteredNotifications,
			"total":         len(filteredNotifications),
			"page":          page,
			"limit":         limit,
			"unread_count":  3, // 统计未读数量
			"version":       "v2",
			"database":      "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetNotificationDetail 获取通知详情
func (h *NotificationHandler) GetNotificationDetail(c *gin.Context) {
	_ = c.Param("id") // 暂时不使用notificationID
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	// 模拟通知详情数据
	notification := map[string]interface{}{
		"id":                 1,
		"user_id":            userID,
		"notification_type":  "job_apply",
		"title":              "申请成功",
		"content":            "您申请的职位\"前端开发工程师\"已成功提交，我们会尽快为您安排面试。",
		"data": map[string]interface{}{
			"job_id":    1,
			"job_title": "前端开发工程师",
			"company":   "腾讯科技有限公司",
			"salary":    "15k-25k",
			"location":  "深圳",
		},
		"read_status":        "unread",
		"read_time":          nil,
		"send_status":        "sent",
		"send_time":          "2024-08-30T16:30:00Z",
		"expire_time":        "2024-09-30T16:30:00Z",
		"created_at":         "2024-08-30T16:30:00Z",
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"notification": notification,
			"version":      "v2",
			"database":     "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// MarkNotificationRead 标记通知已读
func (h *NotificationHandler) MarkNotificationRead(c *gin.Context) {
	notificationID := c.Param("id")
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Notification marked as read",
		"data": map[string]interface{}{
			"notification_id": notificationID,
			"user_id":         userID,
			"read_time":       time.Now().Format("2006-01-02T15:04:05Z"),
			"version":         "v2",
			"database":        "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// MarkAllNotificationsRead 标记所有通知已读
func (h *NotificationHandler) MarkAllNotificationsRead(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	notificationType := c.Query("type")

	response := map[string]interface{}{
		"code":    200,
		"message": "All notifications marked as read",
		"data": map[string]interface{}{
			"user_id":         userID,
			"notification_type": notificationType,
			"read_time":       time.Now().Format("2006-01-02T15:04:05Z"),
			"affected_count":  3, // 标记为已读的通知数量
			"version":         "v2",
			"database":        "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetNotificationSettings 获取通知设置
func (h *NotificationHandler) GetNotificationSettings(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	// 模拟通知设置数据
	settings := map[string]interface{}{
		"user_id":                    userID,
		"email_notifications":        true,
		"sms_notifications":          true,
		"push_notifications":         true,
		"in_app_notifications":       true,
		"job_apply_notifications":    true,
		"resume_view_notifications":  true,
		"chat_notifications":         true,
		"system_notifications":       true,
		"points_notifications":       true,
		"quiet_hours_start":          "22:00:00",
		"quiet_hours_end":            "08:00:00",
		"created_at":                 "2024-08-30T10:00:00Z",
		"updated_at":                 "2024-08-30T16:00:00Z",
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"settings": settings,
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// UpdateNotificationSettings 更新通知设置
func (h *NotificationHandler) UpdateNotificationSettings(c *gin.Context) {
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "1" // 默认用户ID
	}

	var request struct {
		EmailNotifications       *bool  `json:"email_notifications"`
		SmsNotifications         *bool  `json:"sms_notifications"`
		PushNotifications        *bool  `json:"push_notifications"`
		InAppNotifications       *bool  `json:"in_app_notifications"`
		JobApplyNotifications    *bool  `json:"job_apply_notifications"`
		ResumeViewNotifications  *bool  `json:"resume_view_notifications"`
		ChatNotifications        *bool  `json:"chat_notifications"`
		SystemNotifications      *bool  `json:"system_notifications"`
		PointsNotifications      *bool  `json:"points_notifications"`
		QuietHoursStart          string `json:"quiet_hours_start"`
		QuietHoursEnd            string `json:"quiet_hours_end"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// 模拟更新后的设置
	settings := map[string]interface{}{
		"user_id":                    userID,
		"email_notifications":        request.EmailNotifications != nil && *request.EmailNotifications,
		"sms_notifications":          request.SmsNotifications != nil && *request.SmsNotifications,
		"push_notifications":         request.PushNotifications != nil && *request.PushNotifications,
		"in_app_notifications":       request.InAppNotifications != nil && *request.InAppNotifications,
		"job_apply_notifications":    request.JobApplyNotifications != nil && *request.JobApplyNotifications,
		"resume_view_notifications":  request.ResumeViewNotifications != nil && *request.ResumeViewNotifications,
		"chat_notifications":         request.ChatNotifications != nil && *request.ChatNotifications,
		"system_notifications":       request.SystemNotifications != nil && *request.SystemNotifications,
		"points_notifications":       request.PointsNotifications != nil && *request.PointsNotifications,
		"quiet_hours_start":          request.QuietHoursStart,
		"quiet_hours_end":            request.QuietHoursEnd,
		"updated_at":                 time.Now().Format("2006-01-02T15:04:05Z"),
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Notification settings updated successfully",
		"data": map[string]interface{}{
			"settings": settings,
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetNotificationTemplates 获取通知模板
func (h *NotificationHandler) GetNotificationTemplates(c *gin.Context) {
	// 模拟通知模板数据
	templates := []map[string]interface{}{
		{
			"id":             1,
			"template_code":  "JOB_APPLY_SUCCESS",
			"template_name":  "职位申请成功",
			"template_type":  "in_app",
			"title":          "申请成功",
			"content":        "您申请的职位\"{job_title}\"已成功提交，我们会尽快为您安排面试。",
			"variables": map[string]interface{}{
				"job_title": "职位名称",
			},
			"status":     "active",
			"created_at": "2024-08-30T10:00:00Z",
		},
		{
			"id":             2,
			"template_code":  "RESUME_VIEWED",
			"template_name":  "简历被查看",
			"template_type":  "in_app",
			"title":          "简历被查看",
			"content":        "您的简历被\"{company_name}\"查看，请保持电话畅通。",
			"variables": map[string]interface{}{
				"company_name": "公司名称",
			},
			"status":     "active",
			"created_at": "2024-08-30T10:00:00Z",
		},
		{
			"id":             3,
			"template_code":  "CHAT_MESSAGE",
			"template_name":  "新消息提醒",
			"template_type":  "in_app",
			"title":          "新消息",
			"content":        "您收到来自\"{sender_name}\"的新消息：{message_preview}",
			"variables": map[string]interface{}{
				"sender_name":     "发送者姓名",
				"message_preview": "消息预览",
			},
			"status":     "active",
			"created_at": "2024-08-30T10:00:00Z",
		},
		{
			"id":             4,
			"template_code":  "POINTS_EARNED",
			"template_name":  "获得积分",
			"template_type":  "in_app",
			"title":          "获得积分",
			"content":        "恭喜您获得{points}积分！{reason}",
			"variables": map[string]interface{}{
				"points": "积分数量",
				"reason": "获得原因",
			},
			"status":     "active",
			"created_at": "2024-08-30T10:00:00Z",
		},
		{
			"id":             5,
			"template_code":  "SYSTEM_ANNOUNCEMENT",
			"template_name":  "系统公告",
			"template_type":  "in_app",
			"title":          "系统公告",
			"content":        "{title}\n\n{content}",
			"variables": map[string]interface{}{
				"title":   "公告标题",
				"content": "公告内容",
			},
			"status":     "active",
			"created_at": "2024-08-30T10:00:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"templates": templates,
			"total":     len(templates),
			"version":   "v2",
			"database":  "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// SendNotification 发送通知
func (h *NotificationHandler) SendNotification(c *gin.Context) {
	var request struct {
		UserID           string                 `json:"user_id" binding:"required"`
		NotificationType string                 `json:"notification_type" binding:"required"`
		Title            string                 `json:"title" binding:"required"`
		Content          string                 `json:"content" binding:"required"`
		Data             map[string]interface{} `json:"data"`
		TemplateCode     string                 `json:"template_code"`
		Channels         []string               `json:"channels"` // email, sms, push, in_app
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// 模拟发送通知
	notification := map[string]interface{}{
		"id":                 6,
		"user_id":            request.UserID,
		"notification_type":  request.NotificationType,
		"title":              request.Title,
		"content":            request.Content,
		"data":               request.Data,
		"template_code":      request.TemplateCode,
		"read_status":        "unread",
		"read_time":          nil,
		"send_status":        "sent",
		"send_time":          time.Now().Format("2006-01-02T15:04:05Z"),
		"expire_time":        time.Now().AddDate(0, 1, 0).Format("2006-01-02T15:04:05Z"), // 1个月后过期
		"created_at":         time.Now().Format("2006-01-02T15:04:05Z"),
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Notification sent successfully",
		"data": map[string]interface{}{
			"notification": notification,
			"channels":     request.Channels,
			"version":      "v2",
			"database":     "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}
