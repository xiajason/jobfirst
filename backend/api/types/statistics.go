package types

import (
	"time"
)

// StatisticsData 统计数据
type StatisticsData struct {
	ID        string                 `json:"id"`         // 数据ID
	EventType string                 `json:"event_type"` // 事件类型
	EventData map[string]interface{} `json:"event_data"` // 事件数据
	Timestamp time.Time              `json:"timestamp"`  // 时间戳
	UserID    string                 `json:"user_id"`    // 用户ID
	SessionID string                 `json:"session_id"` // 会话ID
	IPAddress string                 `json:"ip_address"` // IP地址
	UserAgent string                 `json:"user_agent"` // 用户代理
}

// StatisticsReport 统计报表
type StatisticsReport struct {
	ID          string     `json:"id"`           // 报表ID
	Name        string     `json:"name"`         // 报表名称
	Type        string     `json:"type"`         // 报表类型
	StartDate   time.Time  `json:"start_date"`   // 开始日期
	EndDate     time.Time  `json:"end_date"`     // 结束日期
	Data        string     `json:"data"`         // 报表数据JSON
	Format      string     `json:"format"`       // 格式：json, csv, excel
	Status      string     `json:"status"`       // 状态：pending, completed, failed
	CreatedAt   time.Time  `json:"created_at"`   // 创建时间
	CompletedAt *time.Time `json:"completed_at"` // 完成时间
}

// UserStatistics 用户统计
type UserStatistics struct {
	TotalUsers    int64   `json:"total_users"`    // 总用户数
	ActiveUsers   int64   `json:"active_users"`   // 活跃用户数
	NewUsers      int64   `json:"new_users"`      // 新用户数
	PremiumUsers  int64   `json:"premium_users"`  // 付费用户数
	TodayActive   int64   `json:"today_active"`   // 今日活跃
	WeekActive    int64   `json:"week_active"`    // 本周活跃
	MonthActive   int64   `json:"month_active"`   // 本月活跃
	RetentionRate float64 `json:"retention_rate"` // 留存率
}

// ResumeStatistics 简历统计
type ResumeStatistics struct {
	TotalResumes     int64   `json:"total_resumes"`     // 总简历数
	PublishedResumes int64   `json:"published_resumes"` // 已发布简历数
	DraftResumes     int64   `json:"draft_resumes"`     // 草稿简历数
	TotalViews       int64   `json:"total_views"`       // 总浏览次数
	TotalDownloads   int64   `json:"total_downloads"`   // 总下载次数
	TodayViews       int64   `json:"today_views"`       // 今日浏览次数
	TodayDownloads   int64   `json:"today_downloads"`   // 今日下载次数
	AvgViews         float64 `json:"avg_views"`         // 平均浏览次数
	AvgDownloads     float64 `json:"avg_downloads"`     // 平均下载次数
}

// PointsStatistics 积分统计
type PointsStatistics struct {
	TotalUsers   int64   `json:"total_users"`   // 总用户数
	TotalBalance int64   `json:"total_balance"` // 总积分余额
	TotalEarned  int64   `json:"total_earned"`  // 总获得积分
	TotalSpent   int64   `json:"total_spent"`   // 总消费积分
	TodayEarned  int64   `json:"today_earned"`  // 今日获得积分
	TodaySpent   int64   `json:"today_spent"`   // 今日消费积分
	ActiveRules  int64   `json:"active_rules"`  // 活跃规则数
	ActiveItems  int64   `json:"active_items"`  // 活跃商品数
	AvgBalance   float64 `json:"avg_balance"`   // 平均余额
}

// SystemStatistics 系统统计
type SystemStatistics struct {
	TotalRequests   int64   `json:"total_requests"`    // 总请求数
	SuccessRequests int64   `json:"success_requests"`  // 成功请求数
	ErrorRequests   int64   `json:"error_requests"`    // 错误请求数
	AvgResponseTime float64 `json:"avg_response_time"` // 平均响应时间
	CPUUsage        float64 `json:"cpu_usage"`         // CPU使用率
	MemoryUsage     float64 `json:"memory_usage"`      // 内存使用率
	DiskUsage       float64 `json:"disk_usage"`        // 磁盘使用率
	OnlineUsers     int64   `json:"online_users"`      // 在线用户数
}

// ReportRequest 报表请求
type ReportRequest struct {
	Name       string   `json:"name" binding:"required"`       // 报表名称
	Type       string   `json:"type" binding:"required"`       // 报表类型
	StartDate  string   `json:"start_date" binding:"required"` // 开始日期
	EndDate    string   `json:"end_date" binding:"required"`   // 结束日期
	EventTypes []string `json:"event_types"`                   // 事件类型
	Format     string   `json:"format"`                        // 格式
}

// GetReportRequest 获取报表请求
type GetReportRequest struct {
	ID string `json:"id" uri:"id" binding:"required"` // 报表ID
}

// ListReportsRequest 获取报表列表请求
type ListReportsRequest struct {
	PageRequest
	Type   string `json:"type" form:"type"`     // 类型过滤
	Status string `json:"status" form:"status"` // 状态过滤
}

// TrackEventRequest 追踪事件请求
type TrackEventRequest struct {
	EventType string                 `json:"event_type" binding:"required"` // 事件类型
	EventData map[string]interface{} `json:"event_data"`                    // 事件数据
	UserID    string                 `json:"user_id"`                       // 用户ID
	SessionID string                 `json:"session_id"`                    // 会话ID
}

// GetStatisticsRequest 获取统计请求
type GetStatisticsRequest struct {
	Type      string `json:"type" form:"type" binding:"required"` // 统计类型
	StartDate string `json:"start_date" form:"start_date"`        // 开始日期
	EndDate   string `json:"end_date" form:"end_date"`            // 结束日期
	GroupBy   string `json:"group_by" form:"group_by"`            // 分组方式
}

// ReportResponse 报表响应
type ReportResponse struct {
	Report *StatisticsReport `json:"report"`
}

// ListReportsResponse 报表列表响应
type ListReportsResponse struct {
	PageResponse
	List []*StatisticsReport `json:"list"`
}

// StatisticsResponse 统计响应
type StatisticsResponse struct {
	Type  string      `json:"type"`  // 统计类型
	Data  interface{} `json:"data"`  // 统计数据
	Total int64       `json:"total"` // 总数
}

// DashboardResponse 仪表板响应
type DashboardResponse struct {
	User      *UserStatistics   `json:"user"`       // 用户统计
	Resume    *ResumeStatistics `json:"resume"`     // 简历统计
	Points    *PointsStatistics `json:"points"`     // 积分统计
	System    *SystemStatistics `json:"system"`     // 系统统计
	UpdatedAt time.Time         `json:"updated_at"` // 更新时间
}
