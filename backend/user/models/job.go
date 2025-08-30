package models

import (
	"time"
)

// Job 职位模型
type Job struct {
	ID                 uint      `json:"id" gorm:"primaryKey"`
	CompanyID          uint      `json:"company_id" gorm:"not null"`
	CategoryID         uint      `json:"category_id" gorm:"not null"`
	Title              string    `json:"title" gorm:"not null;size:200"`
	JobType            string    `json:"job_type" gorm:"type:enum('full_time','part_time','internship','contract');default:'full_time'"`
	Location           string    `json:"location" gorm:"not null;size:200"`
	SalaryMin          int       `json:"salary_min"`
	SalaryMax          int       `json:"salary_max"`
	SalaryType         string    `json:"salary_type" gorm:"type:enum('monthly','yearly','hourly');default:'monthly'"`
	ExperienceRequired string    `json:"experience_required" gorm:"type:enum('entry','junior','mid','senior','expert')"`
	EducationRequired  string    `json:"education_required" gorm:"type:enum('high_school','college','bachelor','master','phd')"`
	Description        string    `json:"description" gorm:"type:text;not null"`
	Requirements       string    `json:"requirements" gorm:"type:text"`
	Benefits           string    `json:"benefits" gorm:"type:text"`
	Skills             string    `json:"skills" gorm:"type:json"`
	Tags               string    `json:"tags" gorm:"type:json"`
	Status             string    `json:"status" gorm:"type:enum('draft','published','paused','closed');default:'draft'"`
	Priority           int       `json:"priority" gorm:"default:0"`
	ViewCount          int       `json:"view_count" gorm:"default:0"`
	ApplicationCount   int       `json:"application_count" gorm:"default:0"`
	FavoriteCount      int       `json:"favorite_count" gorm:"default:0"`
	PublishAt          *time.Time `json:"publish_at"`
	ExpireAt           *time.Time `json:"expire_at"`
	CreatedAt          time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt          time.Time `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt          *time.Time `json:"deleted_at" gorm:"index"`

	// 关联字段
	Company  Company  `json:"company" gorm:"foreignKey:CompanyID"`
	Category Category `json:"category" gorm:"foreignKey:CategoryID"`
}

// Company 企业模型
type Company struct {
	ID                uint      `json:"id" gorm:"primaryKey"`
	Name              string    `json:"name" gorm:"not null;size:200"`
	ShortName         string    `json:"short_name" gorm:"size:100"`
	LogoURL           string    `json:"logo_url" gorm:"size:500"`
	Industry          string    `json:"industry" gorm:"size:100"`
	CompanySize       string    `json:"company_size" gorm:"size:50"`
	Location          string    `json:"location" gorm:"size:200"`
	Website           string    `json:"website" gorm:"size:500"`
	Description       string    `json:"description" gorm:"type:text"`
	FoundedYear       int       `json:"founded_year"`
	BusinessLicense   string    `json:"business_license" gorm:"size:100"`
	Status            string    `json:"status" gorm:"type:enum('pending','verified','rejected');default:'pending'"`
	VerificationLevel string    `json:"verification_level" gorm:"type:enum('basic','premium','enterprise');default:'basic'"`
	JobCount          int       `json:"job_count" gorm:"default:0"`
	ViewCount         int       `json:"view_count" gorm:"default:0"`
	CreatedAt         time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt         time.Time `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt         *time.Time `json:"deleted_at" gorm:"index"`
}

// Category 职位分类模型
type Category struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	Name        string    `json:"name" gorm:"not null;size:100"`
	ParentID    *uint     `json:"parent_id"`
	Level       int       `json:"level" gorm:"default:1"`
	SortOrder   int       `json:"sort_order" gorm:"default:0"`
	Icon        string    `json:"icon" gorm:"size:50"`
	Description string    `json:"description" gorm:"type:text"`
	JobCount    int       `json:"job_count" gorm:"default:0"`
	Status      string    `json:"status" gorm:"type:enum('active','inactive');default:'active'"`
	CreatedAt   time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"autoUpdateTime"`
	DeletedAt   *time.Time `json:"deleted_at" gorm:"index"`
}

// TableName 指定表名
func (Job) TableName() string {
	return "jobs"
}

func (Company) TableName() string {
	return "companies"
}

func (Category) TableName() string {
	return "job_categories"
}
