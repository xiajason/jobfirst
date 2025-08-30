package interfaces

import (
	"context"
	"resume-centre/api/types"
)

// ResumeService 简历服务接口
type ResumeService interface {
	// 简历基础操作
	CreateResume(ctx context.Context, req *types.CreateResumeRequest) (*types.ResumeResponse, error)
	GetResume(ctx context.Context, req *types.GetResumeRequest) (*types.ResumeResponse, error)
	UpdateResume(ctx context.Context, req *types.UpdateResumeRequest) (*types.ResumeResponse, error)
	DeleteResume(ctx context.Context, req *types.DeleteResumeRequest) (*types.EmptyResponse, error)
	ListResumes(ctx context.Context, req *types.ListResumesRequest) (*types.ListResumesResponse, error)

	// 简历状态操作
	PublishResume(ctx context.Context, req *types.PublishResumeRequest) (*types.ResumeResponse, error)
	UnpublishResume(ctx context.Context, req *types.PublishResumeRequest) (*types.ResumeResponse, error)
	DuplicateResume(ctx context.Context, req *types.DuplicateResumeRequest) (*types.ResumeResponse, error)

	// 简历模板操作
	ListTemplates(ctx context.Context, req *types.PageRequest) (*types.ListResumeTemplatesResponse, error)
	GetTemplate(ctx context.Context, id string) (*types.ResumeTemplateResponse, error)
	ApplyTemplate(ctx context.Context, resumeID, templateID string) (*types.ResumeResponse, error)

	// 简历横幅操作
	ListBanners(ctx context.Context) (*types.ListResumeBannersResponse, error)

	// 简历统计
	GetResumeStats(ctx context.Context) (*types.ResumeStats, error)
}

// ResumeSectionService 简历章节服务接口
type ResumeSectionService interface {
	// 章节操作
	AddSection(ctx context.Context, resumeID string, section *types.ResumeSection) (*types.ResumeSection, error)
	ListSections(ctx context.Context, resumeID string) ([]*types.ResumeSection, error)
	GetSection(ctx context.Context, resumeID, sectionID string) (*types.ResumeSection, error)
	UpdateSection(ctx context.Context, resumeID, sectionID string, section *types.ResumeSection) (*types.ResumeSection, error)
	DeleteSection(ctx context.Context, resumeID, sectionID string) error
	MoveSection(ctx context.Context, resumeID, sectionID string, order int) error
}

// ResumeSearchService 简历搜索服务接口
type ResumeSearchService interface {
	// 搜索操作
	SearchResumes(ctx context.Context, keyword string, filters map[string]interface{}, req *types.PageRequest) (*types.ListResumesResponse, error)
	GetSearchSuggestions(ctx context.Context, keyword string) ([]string, error)
}
