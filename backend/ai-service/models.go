package main

import (
	"time"
)

// User 用户模型
type User struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	OpenID            string    `json:"openid" gorm:"uniqueIndex"`
	UnionID           string    `json:"unionid" gorm:"uniqueIndex"`
	Username          string    `json:"username" gorm:"uniqueIndex;not null"`
	Email             string    `json:"email" gorm:"uniqueIndex"`
	Phone             string    `json:"phone" gorm:"uniqueIndex"`
	PasswordHash      string    `json:"-"`
	AvatarURL         string    `json:"avatar_url"`
	Nickname          string    `json:"nickname"`
	RealName          string    `json:"real_name"`
	Gender            string    `json:"gender"`
	BirthDate         *time.Time `json:"birth_date"`
	Location          string    `json:"location"`
	Status            string    `json:"status" gorm:"default:'active'"`
	UserType          string    `json:"user_type" gorm:"default:'jobseeker'"`
	CertificationStatus string  `json:"certification_status" gorm:"default:'pending'"`
	LastLoginAt       *time.Time `json:"last_login_at"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
	DeletedAt         *time.Time `json:"deleted_at" gorm:"index"`
}

// UserProfile 用户详细资料
type UserProfile struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"not null"`
	EducationLevel    string    `json:"education_level"`
	WorkExperience    int       `json:"work_experience"`
	CurrentPosition   string    `json:"current_position"`
	ExpectedSalaryMin int       `json:"expected_salary_min"`
	ExpectedSalaryMax int       `json:"expected_salary_max"`
	Skills            string    `json:"skills" gorm:"type:json"`
	SelfIntroduction  string    `json:"self_introduction"`
	ResumeCount       int       `json:"resume_count" gorm:"default:0"`
	ApplicationCount  int       `json:"application_count" gorm:"default:0"`
	FavoriteCount     int       `json:"favorite_count" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// Job 职位模型
type Job struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	Title             string    `json:"title" gorm:"not null"`
	CompanyID         *uint     `json:"company_id"`
	CompanyName       string    `json:"company_name"`
	Description       string    `json:"description"`
	Requirements      string    `json:"requirements" gorm:"type:json"`
	SalaryMin         int       `json:"salary_min"`
	SalaryMax         int       `json:"salary_max"`
	SalaryType        string    `json:"salary_type" gorm:"default:'monthly'"`
	Location          string    `json:"location"`
	JobType           string    `json:"job_type" gorm:"default:'full_time'"`
	ExperienceLevel   string    `json:"experience_level"`
	EducationLevel    string    `json:"education_level"`
	Skills            string    `json:"skills" gorm:"type:json"`
	Benefits          string    `json:"benefits" gorm:"type:json"`
	Status            string    `json:"status" gorm:"default:'active'"`
	ViewCount         int       `json:"view_count" gorm:"default:0"`
	ApplicationCount  int       `json:"application_count" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
	DeletedAt         *time.Time `json:"deleted_at" gorm:"index"`
}

// Resume 简历模型
type Resume struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"not null"`
	Title             string    `json:"title" gorm:"not null"`
	Content           string    `json:"content" gorm:"type:json"`
	TemplateID        *uint     `json:"template_id"`
	Status            string    `json:"status" gorm:"default:'draft'"`
	IsDefault         bool      `json:"is_default" gorm:"default:false"`
	ViewCount         int       `json:"view_count" gorm:"default:0"`
	DownloadCount     int       `json:"download_count" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
	DeletedAt         *time.Time `json:"deleted_at" gorm:"index"`
}

// ResumeTemplate 简历模板
type ResumeTemplate struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	Name              string    `json:"name" gorm:"not null"`
	Description       string    `json:"description"`
	TemplateData      string    `json:"template_data" gorm:"type:json;not null"`
	PreviewImage      string    `json:"preview_image"`
	Category          string    `json:"category"`
	IsFree            bool      `json:"is_free" gorm:"default:true"`
	Price             float64   `json:"price" gorm:"default:0.00"`
	DownloadCount     int       `json:"download_count" gorm:"default:0"`
	Status            string    `json:"status" gorm:"default:'active'"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// Point 积分模型
type Point struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"uniqueIndex;not null"`
	Balance           int       `json:"balance" gorm:"default:0"`
	TotalEarned       int       `json:"total_earned" gorm:"default:0"`
	TotalSpent        int       `json:"total_spent" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// PointRecord 积分记录
type PointRecord struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"not null"`
	Type              string    `json:"type" gorm:"not null"`
	Amount            int       `json:"amount" gorm:"not null"`
	Reason            string    `json:"reason" gorm:"not null"`
	Description       string    `json:"description"`
	RelatedID         *uint     `json:"related_id"`
	RelatedType       string    `json:"related_type"`
	CreatedAt         time.Time `json:"created_at"`
}

// File 文件模型
type File struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"not null"`
	Filename          string    `json:"filename" gorm:"not null"`
	OriginalFilename  string    `json:"original_filename" gorm:"not null"`
	FilePath          string    `json:"file_path" gorm:"not null"`
	FileSize          int64     `json:"file_size" gorm:"not null"`
	MimeType          string    `json:"mime_type"`
	FileType          string    `json:"file_type"`
	Status            string    `json:"status" gorm:"default:'active'"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// Statistics 统计数据
type Statistics struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	Date              time.Time `json:"date" gorm:"uniqueIndex;not null"`
	UserCount         int       `json:"user_count" gorm:"default:0"`
	ResumeCount       int       `json:"resume_count" gorm:"default:0"`
	JobCount          int       `json:"job_count" gorm:"default:0"`
	ApplicationCount  int       `json:"application_count" gorm:"default:0"`
	ViewCount         int       `json:"view_count" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// UserBehavior 用户行为
type UserBehavior struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	UserID            uint      `json:"user_id" gorm:"not null"`
	Action            string    `json:"action" gorm:"not null"`
	TargetType        string    `json:"target_type"`
	TargetID          *uint     `json:"target_id"`
	Metadata          string    `json:"metadata" gorm:"type:json"`
	IPAddress         string    `json:"ip_address"`
	UserAgent         string    `json:"user_agent"`
	CreatedAt         time.Time `json:"created_at"`
}

// AIModel AI模型配置
type AIModel struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	Name              string    `json:"name" gorm:"not null"`
	Type              string    `json:"type" gorm:"not null"`
	Provider          string    `json:"provider" gorm:"not null"`
	Config            string    `json:"config" gorm:"type:json;not null"`
	Status            string    `json:"status" gorm:"default:'active'"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// Embedding 向量化数据
type Embedding struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	EntityType        string    `json:"entity_type" gorm:"not null"`
	EntityID          int64     `json:"entity_id" gorm:"not null"`
	EmbeddingVector   []float32 `json:"embedding_vector" gorm:"not null"`
	Metadata          string    `json:"metadata" gorm:"type:json"`
	CreatedAt         time.Time `json:"created_at"`
}

// SystemConfig 系统配置
type SystemConfig struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	ConfigKey         string    `json:"config_key" gorm:"uniqueIndex;not null"`
	ConfigValue       string    `json:"config_value"`
	ConfigType        string    `json:"config_type" gorm:"default:'string'"`
	Description       string    `json:"description"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// AdvancedAnalytics 高级分析
type AdvancedAnalytics struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	AnalysisType      string    `json:"analysis_type" gorm:"not null"`
	Data              string    `json:"data" gorm:"type:json;not null"`
	Result            string    `json:"result" gorm:"type:json"`
	Status            string    `json:"status" gorm:"default:'pending'"`
	CreatedAt         time.Time `json:"created_at"`
	CompletedAt       *time.Time `json:"completed_at"`
}
