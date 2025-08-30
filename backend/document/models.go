package main

import (
	"time"
)

// 文档类型
type DocumentType string

const (
	DocumentTypeResume     DocumentType = "resume"
	DocumentTypeCoverLetter DocumentType = "cover_letter"
	DocumentTypeCertificate DocumentType = "certificate"
	DocumentTypeReference  DocumentType = "reference"
	DocumentTypeOther      DocumentType = "other"
)

// 文档格式
type DocumentFormat string

const (
	DocumentFormatPDF  DocumentFormat = "pdf"
	DocumentFormatDOC  DocumentFormat = "doc"
	DocumentFormatDOCX DocumentFormat = "docx"
	DocumentFormatTXT  DocumentFormat = "txt"
	DocumentFormatRTF  DocumentFormat = "rtf"
	DocumentFormatHTML DocumentFormat = "html"
	DocumentFormatMD   DocumentFormat = "md"
)

// 处理状态
type ProcessingStatus string

const (
	ProcessingStatusPending   ProcessingStatus = "pending"
	ProcessingStatusProcessing ProcessingStatus = "processing"
	ProcessingStatusCompleted ProcessingStatus = "completed"
	ProcessingStatusFailed    ProcessingStatus = "failed"
)

// 文档处理任务模型
type DocumentTask struct {
	ID              string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint             `json:"user_id" gorm:"not null;index"`
	TaskType        string           `json:"task_type" gorm:"type:varchar(50);not null"`
	DocumentType    DocumentType     `json:"document_type" gorm:"type:varchar(50);not null"`
	SourceFormat    DocumentFormat   `json:"source_format" gorm:"type:varchar(20);not null"`
	TargetFormat    DocumentFormat   `json:"target_format" gorm:"type:varchar(20)"`
	SourceFileID    string           `json:"source_file_id" gorm:"type:varchar(36);not null"`
	TargetFileID    string           `json:"target_file_id" gorm:"type:varchar(36)"`
	Status          ProcessingStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	Progress        int              `json:"progress" gorm:"default:0"`
	Error           string           `json:"error" gorm:"type:text"`
	Metadata        string           `json:"metadata" gorm:"type:text"`
	StartedAt       *time.Time       `json:"started_at"`
	CompletedAt     *time.Time       `json:"completed_at"`
	CreatedAt       time.Time        `json:"created_at"`
	UpdatedAt       time.Time        `json:"updated_at"`
}

// 文档内容提取结果模型
type DocumentExtraction struct {
	ID              string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint             `json:"user_id" gorm:"not null;index"`
	DocumentID      string           `json:"document_id" gorm:"type:varchar(36);not null;index"`
	ExtractionType  string           `json:"extraction_type" gorm:"type:varchar(50);not null"`
	Content         string           `json:"content" gorm:"type:longtext"`
	StructuredData  string           `json:"structured_data" gorm:"type:json"`
	Confidence      float64          `json:"confidence" gorm:"default:0"`
	Status          ProcessingStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	Error           string           `json:"error" gorm:"type:text"`
	CreatedAt       time.Time        `json:"created_at"`
	UpdatedAt       time.Time        `json:"updated_at"`
}

// 文档模板模型
type DocumentTemplate struct {
	ID              string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Name            string         `json:"name" gorm:"not null"`
	Description     string         `json:"description" gorm:"type:text"`
	DocumentType    DocumentType   `json:"document_type" gorm:"type:varchar(50);not null"`
	Format          DocumentFormat `json:"format" gorm:"type:varchar(20);not null"`
	TemplateFileID  string         `json:"template_file_id" gorm:"type:varchar(36)"`
	TemplateContent string         `json:"template_content" gorm:"type:longtext"`
	Variables       string         `json:"variables" gorm:"type:json"`
	IsActive        bool           `json:"is_active" gorm:"default:true"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
}

// OCR识别结果模型
type OCRResult struct {
	ID              string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint             `json:"user_id" gorm:"not null;index"`
	DocumentID      string           `json:"document_id" gorm:"type:varchar(36);not null;index"`
	ImageFileID     string           `json:"image_file_id" gorm:"type:varchar(36);not null"`
	TextContent     string           `json:"text_content" gorm:"type:longtext"`
	Confidence      float64          `json:"confidence" gorm:"default:0"`
	Language        string           `json:"language" gorm:"type:varchar(10);default:'en'"`
	Status          ProcessingStatus `json:"status" gorm:"type:varchar(20);default:'pending'"`
	Error           string           `json:"error" gorm:"type:text"`
	ProcessingTime  int64            `json:"processing_time" gorm:"default:0"`
	CreatedAt       time.Time        `json:"created_at"`
	UpdatedAt       time.Time        `json:"updated_at"`
}

// 文档转换配置模型
type ConversionConfig struct {
	ID              string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	SourceFormat    DocumentFormat `json:"source_format" gorm:"type:varchar(20);not null"`
	TargetFormat    DocumentFormat `json:"target_format" gorm:"type:varchar(20);not null"`
	ConfigName      string         `json:"config_name" gorm:"not null"`
	ConfigData      string         `json:"config_data" gorm:"type:json"`
	IsActive        bool           `json:"is_active" gorm:"default:true"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
}

// 文档处理统计模型
type ProcessingStats struct {
	ID              string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID          uint           `json:"user_id" gorm:"not null;index"`
	DocumentType    DocumentType   `json:"document_type" gorm:"type:varchar(50);not null"`
	Format          DocumentFormat `json:"format" gorm:"type:varchar(20);not null"`
	TaskType        string         `json:"task_type" gorm:"type:varchar(50);not null"`
	SuccessCount    int64          `json:"success_count" gorm:"default:0"`
	FailureCount    int64          `json:"failure_count" gorm:"default:0"`
	TotalProcessingTime int64      `json:"total_processing_time" gorm:"default:0"`
	Date            time.Time      `json:"date" gorm:"not null;index"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
}
