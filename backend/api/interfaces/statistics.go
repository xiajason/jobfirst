package interfaces

import (
	"context"
	"resume-centre/api/types"
)

// StatisticsService 统计服务接口
type StatisticsService interface {
	// 事件追踪
	TrackEvent(ctx context.Context, req *types.TrackEventRequest) error
	TrackEvents(ctx context.Context, events []*types.TrackEventRequest) error

	// 统计查询
	GetStatistics(ctx context.Context, req *types.GetStatisticsRequest) (*types.StatisticsResponse, error)
	GetUserStatistics(ctx context.Context) (*types.UserStatistics, error)
	GetResumeStatistics(ctx context.Context) (*types.ResumeStatistics, error)
	GetPointsStatistics(ctx context.Context) (*types.PointsStatistics, error)
	GetSystemStatistics(ctx context.Context) (*types.SystemStatistics, error)

	// 仪表板
	GetDashboard(ctx context.Context) (*types.DashboardResponse, error)
}

// ReportService 报表服务接口
type ReportService interface {
	// 报表操作
	CreateReport(ctx context.Context, req *types.ReportRequest) (*types.ReportResponse, error)
	GetReport(ctx context.Context, req *types.GetReportRequest) (*types.ReportResponse, error)
	ListReports(ctx context.Context, req *types.ListReportsRequest) (*types.ListReportsResponse, error)
	DeleteReport(ctx context.Context, reportID string) error

	// 报表生成
	GenerateReport(ctx context.Context, reportID string) error
	DownloadReport(ctx context.Context, reportID string, format string) ([]byte, error)

	// 报表模板
	GetReportTemplates(ctx context.Context) ([]string, error)
}
