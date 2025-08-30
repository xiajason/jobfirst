package interfaces

import (
	"context"
	"resume-centre/api/types"
)

// PointsService 积分服务接口
type PointsService interface {
	// 积分余额操作
	GetBalance(ctx context.Context, req *types.GetBalanceRequest) (*types.BalanceResponse, error)

	// 积分操作
	EarnPoints(ctx context.Context, req *types.EarnPointsRequest) (*types.PointsResponse, error)
	SpendPoints(ctx context.Context, req *types.SpendPointsRequest) (*types.PointsResponse, error)

	// 历史记录
	GetHistory(ctx context.Context, req *types.GetHistoryRequest) (*types.HistoryResponse, error)

	// 积分统计
	GetPointsStats(ctx context.Context) (*types.PointsStats, error)
}

// PointsRuleService 积分规则服务接口
type PointsRuleService interface {
	// 规则操作
	ListRules(ctx context.Context, req *types.ListRulesRequest) (*types.ListRulesResponse, error)
	GetRule(ctx context.Context, ruleID string) (*types.PointsRule, error)
	CreateRule(ctx context.Context, rule *types.PointsRule) (*types.PointsRule, error)
	UpdateRule(ctx context.Context, ruleID string, rule *types.PointsRule) (*types.PointsRule, error)
	DeleteRule(ctx context.Context, ruleID string) error
	EnableRule(ctx context.Context, ruleID string) error
	DisableRule(ctx context.Context, ruleID string) error
}

// PointsItemService 积分商品服务接口
type PointsItemService interface {
	// 商品操作
	ListItems(ctx context.Context, req *types.ListItemsRequest) (*types.ListItemsResponse, error)
	GetItem(ctx context.Context, itemID string) (*types.PointsItem, error)
	CreateItem(ctx context.Context, item *types.PointsItem) (*types.PointsItem, error)
	UpdateItem(ctx context.Context, itemID string, item *types.PointsItem) (*types.PointsItem, error)
	DeleteItem(ctx context.Context, itemID string) error
	UpdateStock(ctx context.Context, itemID string, stock int64) error
}
