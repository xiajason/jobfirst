package types

import (
	"time"
)

// Resume 简历数据结构
type Resume struct {
	ID            string     `json:"id"`             // 简历ID
	UserID        string     `json:"user_id"`        // 用户ID
	Title         string     `json:"title"`          // 简历标题
	Description   string     `json:"description"`    // 简历描述
	Content       string     `json:"content"`        // 简历内容
	TemplateID    string     `json:"template_id"`    // 模板ID
	Status        string     `json:"status"`         // 状态：draft, published, archived
	Version       int        `json:"version"`        // 版本号
	IsDefault     bool       `json:"is_default"`     // 是否默认简历
	ViewCount     int64      `json:"view_count"`     // 浏览次数
	DownloadCount int64      `json:"download_count"` // 下载次数
	CreatedAt     time.Time  `json:"created_at"`     // 创建时间
	UpdatedAt     time.Time  `json:"updated_at"`     // 更新时间
	PublishedAt   *time.Time `json:"published_at"`   // 发布时间
}

// ResumeSection 简历章节
type ResumeSection struct {
	ID       string `json:"id"`        // 章节ID
	ResumeID string `json:"resume_id"` // 简历ID
	Type     string `json:"type"`      // 章节类型：basic, experience, education, skills, projects
	Title    string `json:"title"`     // 章节标题
	Content  string `json:"content"`   // 章节内容
	Order    int    `json:"order"`     // 排序
	Required bool   `json:"required"`  // 是否必需
}

// ResumeTemplate 简历模板
type ResumeTemplate struct {
	ID          string    `json:"id"`          // 模板ID
	Name        string    `json:"name"`        // 模板名称
	Description string    `json:"description"` // 模板描述
	Category    string    `json:"category"`    // 模板分类
	PreviewURL  string    `json:"preview_url"` // 预览图片URL
	HTML        string    `json:"html"`        // 模板HTML
	CSS         string    `json:"css"`         // 模板CSS
	Config      string    `json:"config"`      // 模板配置JSON
	IsFree      bool      `json:"is_free"`     // 是否免费
	Price       float64   `json:"price"`       // 价格
	Status      string    `json:"status"`      // 状态：active, inactive
	CreatedAt   time.Time `json:"created_at"`  // 创建时间
	UpdatedAt   time.Time `json:"updated_at"`  // 更新时间
}

// ResumeBanner 简历横幅
type ResumeBanner struct {
	ID        string    `json:"id"`         // 横幅ID
	Title     string    `json:"title"`      // 横幅标题
	Subtitle  string    `json:"subtitle"`   // 横幅副标题
	ImageURL  string    `json:"image_url"`  // 图片URL
	LinkURL   string    `json:"link_url"`   // 链接URL
	Order     int       `json:"order"`      // 排序
	Status    string    `json:"status"`     // 状态：active, inactive
	StartTime time.Time `json:"start_time"` // 开始时间
	EndTime   time.Time `json:"end_time"`   // 结束时间
	CreatedAt time.Time `json:"created_at"` // 创建时间
	UpdatedAt time.Time `json:"updated_at"` // 更新时间
}

// CreateResumeRequest 创建简历请求
type CreateResumeRequest struct {
	Title       string `json:"title" binding:"required"` // 简历标题
	Description string `json:"description"`              // 简历描述
	TemplateID  string `json:"template_id"`              // 模板ID
	Content     string `json:"content"`                  // 简历内容
}

// UpdateResumeRequest 更新简历请求
type UpdateResumeRequest struct {
	Title       string `json:"title"`       // 简历标题
	Description string `json:"description"` // 简历描述
	Content     string `json:"content"`     // 简历内容
	Status      string `json:"status"`      // 状态
}

// GetResumeRequest 获取简历请求
type GetResumeRequest struct {
	ID string `json:"id" uri:"id" binding:"required"` // 简历ID
}

// ListResumesRequest 获取简历列表请求
type ListResumesRequest struct {
	PageRequest
	Status     string `json:"status" form:"status"`           // 状态过滤
	TemplateID string `json:"template_id" form:"template_id"` // 模板过滤
	Keyword    string `json:"keyword" form:"keyword"`         // 关键词搜索
}

// DeleteResumeRequest 删除简历请求
type DeleteResumeRequest struct {
	ID string `json:"id" uri:"id" binding:"required"` // 简历ID
}

// PublishResumeRequest 发布简历请求
type PublishResumeRequest struct {
	ID string `json:"id" uri:"id" binding:"required"` // 简历ID
}

// DuplicateResumeRequest 复制简历请求
type DuplicateResumeRequest struct {
	ID string `json:"id" uri:"id" binding:"required"` // 简历ID
}

// ResumeResponse 简历响应
type ResumeResponse struct {
	Resume *Resume `json:"resume"`
}

// ListResumesResponse 简历列表响应
type ListResumesResponse struct {
	PageResponse
	List []*Resume `json:"list"`
}

// ResumeTemplateResponse 简历模板响应
type ResumeTemplateResponse struct {
	Template *ResumeTemplate `json:"template"`
}

// ListResumeTemplatesResponse 简历模板列表响应
type ListResumeTemplatesResponse struct {
	PageResponse
	List []*ResumeTemplate `json:"list"`
}

// ResumeBannerResponse 简历横幅响应
type ResumeBannerResponse struct {
	Banner *ResumeBanner `json:"banner"`
}

// ListResumeBannersResponse 简历横幅列表响应
type ListResumeBannersResponse struct {
	Banners []*ResumeBanner `json:"banners"`
}

// ResumeStats 简历统计
type ResumeStats struct {
	TotalResumes     int64 `json:"total_resumes"`     // 总简历数
	PublishedResumes int64 `json:"published_resumes"` // 已发布简历数
	DraftResumes     int64 `json:"draft_resumes"`     // 草稿简历数
	TotalViews       int64 `json:"total_views"`       // 总浏览次数
	TotalDownloads   int64 `json:"total_downloads"`   // 总下载次数
	TodayViews       int64 `json:"today_views"`       // 今日浏览次数
	TodayDownloads   int64 `json:"today_downloads"`   // 今日下载次数
}
