package types

import (
	"time"
)

// BaseResponse 通用响应结构
type BaseResponse struct {
	Code    int         `json:"code"`               // 响应码
	Message string      `json:"message"`            // 响应消息
	Data    interface{} `json:"data,omitempty"`     // 响应数据
	TraceID string      `json:"trace_id,omitempty"` // 追踪ID
	Time    time.Time   `json:"time"`               // 响应时间
}

// PageRequest 分页请求
type PageRequest struct {
	Page     int `json:"page" form:"page"`           // 页码，从1开始
	PageSize int `json:"page_size" form:"page_size"` // 每页大小
}

// PageResponse 分页响应
type PageResponse struct {
	Total      int64       `json:"total"`       // 总记录数
	Page       int         `json:"page"`        // 当前页码
	PageSize   int         `json:"page_size"`   // 每页大小
	TotalPages int         `json:"total_pages"` // 总页数
	HasNext    bool        `json:"has_next"`    // 是否有下一页
	HasPrev    bool        `json:"has_prev"`    // 是否有上一页
	List       interface{} `json:"list"`        // 数据列表
}

// UserContext 用户上下文
type UserContext struct {
	UserID   string `json:"user_id"`   // 用户ID
	Username string `json:"username"`  // 用户名
	Role     string `json:"role"`      // 用户角色
	TenantID string `json:"tenant_id"` // 租户ID
}

// AuditLog 审计日志
type AuditLog struct {
	ID         string                 `json:"id"`          // 日志ID
	UserID     string                 `json:"user_id"`     // 操作用户ID
	Action     string                 `json:"action"`      // 操作类型
	Resource   string                 `json:"resource"`    // 操作资源
	ResourceID string                 `json:"resource_id"` // 资源ID
	Details    map[string]interface{} `json:"details"`     // 操作详情
	IP         string                 `json:"ip"`          // 操作IP
	UserAgent  string                 `json:"user_agent"`  // 用户代理
	CreatedAt  time.Time              `json:"created_at"`  // 创建时间
}

// FileInfo 文件信息
type FileInfo struct {
	ID          string    `json:"id"`           // 文件ID
	Name        string    `json:"name"`         // 文件名
	Path        string    `json:"path"`         // 文件路径
	Size        int64     `json:"size"`         // 文件大小
	ContentType string    `json:"content_type"` // 内容类型
	URL         string    `json:"url"`          // 访问URL
	Hash        string    `json:"hash"`         // 文件哈希
	CreatedAt   time.Time `json:"created_at"`   // 创建时间
	UpdatedAt   time.Time `json:"updated_at"`   // 更新时间
}

// Notification 通知信息
type Notification struct {
	ID        string                 `json:"id"`         // 通知ID
	UserID    string                 `json:"user_id"`    // 用户ID
	Type      string                 `json:"type"`       // 通知类型
	Title     string                 `json:"title"`      // 通知标题
	Content   string                 `json:"content"`    // 通知内容
	Data      map[string]interface{} `json:"data"`       // 通知数据
	Read      bool                   `json:"read"`       // 是否已读
	CreatedAt time.Time              `json:"created_at"` // 创建时间
	ReadAt    *time.Time             `json:"read_at"`    // 阅读时间
}

// EmptyResponse 空响应
type EmptyResponse struct{}

// NewSuccessResponse 创建成功响应
func NewSuccessResponse(data interface{}) *BaseResponse {
	return &BaseResponse{
		Code:    200,
		Message: "success",
		Data:    data,
		Time:    time.Now(),
	}
}

// NewErrorResponse 创建错误响应
func NewErrorResponse(code int, message string) *BaseResponse {
	return &BaseResponse{
		Code:    code,
		Message: message,
		Time:    time.Now(),
	}
}

// NewPageResponse 创建分页响应
func NewPageResponse(total int64, page, pageSize int, list interface{}) *PageResponse {
	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))
	return &PageResponse{
		Total:      total,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
		HasNext:    page < totalPages,
		HasPrev:    page > 1,
		List:       list,
	}
}
