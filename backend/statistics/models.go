package main

import (
	"time"
)

// 统计类型
type StatisticsType string

const (
	StatisticsTypeResumeView       StatisticsType = "resume_view"
	StatisticsTypeResumeDownload   StatisticsType = "resume_download"
	StatisticsTypeUserRegister     StatisticsType = "user_register"
	StatisticsTypeUserLogin        StatisticsType = "user_login"
	StatisticsTypeTemplateUse      StatisticsType = "template_use"
	StatisticsTypePointsEarn       StatisticsType = "points_earn"
	StatisticsTypePointsSpend      StatisticsType = "points_spend"
	StatisticsTypeResourceUpload   StatisticsType = "resource_upload"
	StatisticsTypeResourceDownload StatisticsType = "resource_download"
)

// 统计周期
type StatisticsPeriod string

const (
	StatisticsPeriodHour  StatisticsPeriod = "hour"
	StatisticsPeriodDay   StatisticsPeriod = "day"
	StatisticsPeriodWeek  StatisticsPeriod = "week"
	StatisticsPeriodMonth StatisticsPeriod = "month"
	StatisticsPeriodYear  StatisticsPeriod = "year"
)

// 统计数据模型
type Statistics struct {
	ID          string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Type        StatisticsType   `json:"type" gorm:"type:varchar(50);not null;index"`
	Period      StatisticsPeriod `json:"period" gorm:"type:varchar(20);not null"`
	Date        time.Time        `json:"date" gorm:"not null;index"`
	Value       int64            `json:"value" gorm:"default:0"`
	UserID      *uint            `json:"user_id" gorm:"index"`
	ReferenceID string           `json:"reference_id" gorm:"type:varchar(100)"`
	Metadata    string           `json:"metadata" gorm:"type:text"`
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`
}

// 用户行为记录模型
type UserBehavior struct {
	ID          string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	UserID      uint           `json:"user_id" gorm:"not null;index"`
	Type        StatisticsType `json:"type" gorm:"type:varchar(50);not null"`
	ReferenceID string         `json:"reference_id" gorm:"type:varchar(100)"`
	IP          string         `json:"ip" gorm:"type:varchar(45)"`
	UserAgent   string         `json:"user_agent" gorm:"type:text"`
	Metadata    string         `json:"metadata" gorm:"type:text"`
	CreatedAt   time.Time      `json:"created_at"`
}

// 实时统计缓存模型
type RealTimeStats struct {
	ID          string         `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Type        StatisticsType `json:"type" gorm:"type:varchar(50);not null;uniqueIndex"`
	Value       int64          `json:"value" gorm:"default:0"`
	LastUpdated time.Time      `json:"last_updated"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

// 统计报表模型
type StatisticsReport struct {
	ID          string           `json:"id" gorm:"primaryKey;type:varchar(36)"`
	Name        string           `json:"name" gorm:"not null"`
	Type        StatisticsType   `json:"type" gorm:"type:varchar(50);not null"`
	Period      StatisticsPeriod `json:"period" gorm:"type:varchar(20);not null"`
	StartDate   time.Time        `json:"start_date" gorm:"not null"`
	EndDate     time.Time        `json:"end_date" gorm:"not null"`
	Data        string           `json:"data" gorm:"type:text"`
	IsGenerated bool             `json:"is_generated" gorm:"default:false"`
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`
}
