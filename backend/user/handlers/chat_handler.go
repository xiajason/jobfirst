package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type ChatHandler struct{}

func NewChatHandler() *ChatHandler {
	return &ChatHandler{}
}

// GetChatSessions 获取聊天会话列表
func (h *ChatHandler) GetChatSessions(c *gin.Context) {
	// 模拟聊天会话数据
	sessions := []map[string]interface{}{
		{
			"session_id":        "session_001",
			"session_type":      "job_apply",
			"title":             "前端开发工程师申请",
			"description":       "关于前端开发工程师职位的申请沟通",
			"participants":      []int{1, 2},
			"last_message_id":   5,
			"last_message_time": "2024-08-30T16:30:00Z",
			"unread_count":      2,
			"status":            "active",
			"created_at":        "2024-08-30T10:00:00Z",
		},
		{
			"session_id":        "session_002",
			"session_type":      "hr_chat",
			"title":             "HR面试沟通",
			"description":       "与HR的面试安排沟通",
			"participants":      []int{1, 3},
			"last_message_id":   8,
			"last_message_time": "2024-08-30T15:45:00Z",
			"unread_count":      0,
			"status":            "active",
			"created_at":        "2024-08-30T09:00:00Z",
		},
		{
			"session_id":        "session_003",
			"session_type":      "system_notice",
			"title":             "系统通知",
			"description":       "系统重要通知",
			"participants":      []int{1},
			"last_message_id":   12,
			"last_message_time": "2024-08-30T14:20:00Z",
			"unread_count":      1,
			"status":            "active",
			"created_at":        "2024-08-30T08:00:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"sessions": sessions,
			"total":    len(sessions),
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// GetChatMessages 获取聊天消息
func (h *ChatHandler) GetChatMessages(c *gin.Context) {
	sessionID := c.Param("sessionId")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	// 模拟聊天消息数据
	messages := []map[string]interface{}{
		{
			"id":             1,
			"session_id":     sessionID,
			"sender_id":      2,
			"sender_type":    "hr",
			"message_type":   "text",
			"content":        "您好，我们已经收到您的简历，请问您什么时候方便面试？",
			"read_status":    map[string]string{"1": "2024-08-30T16:35:00Z"},
			"created_at":     "2024-08-30T16:30:00Z",
		},
		{
			"id":             2,
			"session_id":     sessionID,
			"sender_id":      1,
			"sender_type":    "user",
			"message_type":   "text",
			"content":        "您好，我明天下午2点有空，可以安排面试吗？",
			"read_status":    map[string]string{"2": "2024-08-30T16:32:00Z"},
			"created_at":     "2024-08-30T16:31:00Z",
		},
		{
			"id":             3,
			"session_id":     sessionID,
			"sender_id":      2,
			"sender_type":    "hr",
			"message_type":   "text",
			"content":        "好的，明天下午2点面试，请准时参加。面试地点：公司大楼3楼会议室",
			"read_status":    map[string]string{},
			"created_at":     "2024-08-30T16:33:00Z",
		},
		{
			"id":             4,
			"session_id":     sessionID,
			"sender_id":      1,
			"sender_type":    "user",
			"message_type":   "text",
			"content":        "收到，谢谢！我会准时到达的。",
			"read_status":    map[string]string{},
			"created_at":     "2024-08-30T16:34:00Z",
		},
		{
			"id":             5,
			"session_id":     sessionID,
			"sender_id":      2,
			"sender_type":    "hr",
			"message_type":   "job_card",
			"content":        "这是您申请的职位详情",
			"job_id":         1,
			"read_status":    map[string]string{},
			"created_at":     "2024-08-30T16:35:00Z",
		},
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "success",
		"data": map[string]interface{}{
			"messages": messages,
			"total":    len(messages),
			"page":     page,
			"limit":    limit,
			"session_id": sessionID,
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// SendMessage 发送消息
func (h *ChatHandler) SendMessage(c *gin.Context) {
	sessionID := c.Param("sessionId")
	
	var request struct {
		Content       string `json:"content" binding:"required"`
		MessageType   string `json:"message_type" binding:"required"`
		ReplyToID     *int   `json:"reply_to_id"`
		JobID         *int   `json:"job_id"`
		ResumeID      *int   `json:"resume_id"`
		AttachmentURL string `json:"attachment_url"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// 模拟发送消息
	message := map[string]interface{}{
		"id":             6,
		"session_id":     sessionID,
		"sender_id":      1,
		"sender_type":    "user",
		"message_type":   request.MessageType,
		"content":        request.Content,
		"read_status":    map[string]string{},
		"reply_to_id":    request.ReplyToID,
		"job_id":         request.JobID,
		"resume_id":      request.ResumeID,
		"attachment_url": request.AttachmentURL,
		"created_at":     time.Now().Format("2006-01-02T15:04:05Z"),
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Message sent successfully",
		"data": map[string]interface{}{
			"message":   message,
			"session_id": sessionID,
			"version":   "v2",
			"database":  "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// MarkMessageRead 标记消息已读
func (h *ChatHandler) MarkMessageRead(c *gin.Context) {
	sessionID := c.Param("sessionId")
	messageID := c.Param("messageId")

	response := map[string]interface{}{
		"code":    200,
		"message": "Message marked as read",
		"data": map[string]interface{}{
			"session_id": sessionID,
			"message_id": messageID,
			"read_time":  time.Now().Format("2006-01-02T15:04:05Z"),
			"version":    "v2",
			"database":   "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}

// CreateChatSession 创建聊天会话
func (h *ChatHandler) CreateChatSession(c *gin.Context) {
	var request struct {
		SessionType  string   `json:"session_type" binding:"required"`
		Title        string   `json:"title" binding:"required"`
		Description  string   `json:"description"`
		Participants []int    `json:"participants" binding:"required"`
	}

	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "Invalid request data",
			"error":   err.Error(),
		})
		return
	}

	// 模拟创建会话
	session := map[string]interface{}{
		"session_id":        "session_" + strconv.FormatInt(time.Now().Unix(), 10),
		"session_type":      request.SessionType,
		"title":             request.Title,
		"description":       request.Description,
		"participants":      request.Participants,
		"last_message_id":   nil,
		"last_message_time": nil,
		"unread_count":      0,
		"status":            "active",
		"created_at":        time.Now().Format("2006-01-02T15:04:05Z"),
	}

	response := map[string]interface{}{
		"code":    200,
		"message": "Chat session created successfully",
		"data": map[string]interface{}{
			"session":  session,
			"version":  "v2",
			"database": "v2",
		},
	}

	c.JSON(http.StatusOK, response)
}
