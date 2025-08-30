package types

import (
	"time"
)

// PointsBalance 积分余额
type PointsBalance struct {
	UserID      string    `json:"user_id"`      // 用户ID
	Balance     int64     `json:"balance"`      // 当前余额
	TotalEarned int64     `json:"total_earned"` // 总获得积分
	TotalSpent  int64     `json:"total_spent"`  // 总消费积分
	Level       string    `json:"level"`        // 用户等级
	UpdatedAt   time.Time `json:"updated_at"`   // 更新时间
}

// PointsRecord 积分记录
type PointsRecord struct {
	ID        string                 `json:"id"`         // 记录ID
	UserID    string                 `json:"user_id"`    // 用户ID
	Type      string                 `json:"type"`       // 类型：earn, spend
	Amount    int64                  `json:"amount"`     // 积分数量
	Reason    string                 `json:"reason"`     // 原因
	RuleID    string                 `json:"rule_id"`    // 规则ID
	ItemID    string                 `json:"item_id"`    // 项目ID
	Metadata  map[string]interface{} `json:"metadata"`   // 元数据
	Balance   int64                  `json:"balance"`    // 操作后余额
	CreatedAt time.Time              `json:"created_at"` // 创建时间
}

// PointsRule 积分规则
type PointsRule struct {
	ID          string    `json:"id"`          // 规则ID
	Name        string    `json:"name"`        // 规则名称
	Description string    `json:"description"` // 规则描述
	Type        string    `json:"type"`        // 类型：earn, spend
	Amount      int64     `json:"amount"`      // 积分数量
	Condition   string    `json:"condition"`   // 触发条件
	Status      string    `json:"status"`      // 状态：active, inactive
	StartTime   time.Time `json:"start_time"`  // 开始时间
	EndTime     time.Time `json:"end_time"`    // 结束时间
	CreatedAt   time.Time `json:"created_at"`  // 创建时间
	UpdatedAt   time.Time `json:"updated_at"`  // 更新时间
}

// PointsItem 积分商品
type PointsItem struct {
	ID          string    `json:"id"`          // 商品ID
	Name        string    `json:"name"`        // 商品名称
	Description string    `json:"description"` // 商品描述
	Category    string    `json:"category"`    // 商品分类
	Price       int64     `json:"price"`       // 积分价格
	Stock       int64     `json:"stock"`       // 库存数量
	ImageURL    string    `json:"image_url"`   // 商品图片
	Status      string    `json:"status"`      // 状态：active, inactive
	CreatedAt   time.Time `json:"created_at"`  // 创建时间
	UpdatedAt   time.Time `json:"updated_at"`  // 更新时间
}

// GetBalanceRequest 获取余额请求
type GetBalanceRequest struct {
	UserID string `json:"user_id" uri:"user_id" binding:"required"` // 用户ID
}

// EarnPointsRequest 赚取积分请求
type EarnPointsRequest struct {
	UserID   string                 `json:"user_id" uri:"user_id" binding:"required"` // 用户ID
	RuleID   string                 `json:"rule_id" binding:"required"`               // 规则ID
	Amount   int64                  `json:"amount" binding:"required"`                // 积分数量
	Reason   string                 `json:"reason" binding:"required"`                // 原因
	Metadata map[string]interface{} `json:"metadata"`                                 // 元数据
}

// SpendPointsRequest 消费积分请求
type SpendPointsRequest struct {
	UserID   string                 `json:"user_id" uri:"user_id" binding:"required"` // 用户ID
	ItemID   string                 `json:"item_id" binding:"required"`               // 商品ID
	Amount   int64                  `json:"amount" binding:"required"`                // 积分数量
	Reason   string                 `json:"reason" binding:"required"`                // 原因
	Metadata map[string]interface{} `json:"metadata"`                                 // 元数据
}

// GetHistoryRequest 获取历史记录请求
type GetHistoryRequest struct {
	UserID string `json:"user_id" uri:"user_id" binding:"required"` // 用户ID
	PageRequest
	Type      string `json:"type" form:"type"`             // 类型过滤
	StartDate string `json:"start_date" form:"start_date"` // 开始日期
	EndDate   string `json:"end_date" form:"end_date"`     // 结束日期
}

// ListRulesRequest 获取规则列表请求
type ListRulesRequest struct {
	PageRequest
	Type   string `json:"type" form:"type"`     // 类型过滤
	Status string `json:"status" form:"status"` // 状态过滤
}

// ListItemsRequest 获取商品列表请求
type ListItemsRequest struct {
	PageRequest
	Category string `json:"category" form:"category"` // 分类过滤
	Status   string `json:"status" form:"status"`     // 状态过滤
}

// BalanceResponse 余额响应
type BalanceResponse struct {
	Balance *PointsBalance `json:"balance"`
}

// PointsResponse 积分操作响应
type PointsResponse struct {
	Record *PointsRecord `json:"record"`
}

// HistoryResponse 历史记录响应
type HistoryResponse struct {
	PageResponse
	List []*PointsRecord `json:"list"`
}

// ListRulesResponse 规则列表响应
type ListRulesResponse struct {
	PageResponse
	List []*PointsRule `json:"list"`
}

// ListItemsResponse 商品列表响应
type ListItemsResponse struct {
	PageResponse
	List []*PointsItem `json:"list"`
}

// PointsStats 积分统计
type PointsStats struct {
	TotalUsers   int64 `json:"total_users"`   // 总用户数
	TotalBalance int64 `json:"total_balance"` // 总积分余额
	TotalEarned  int64 `json:"total_earned"`  // 总获得积分
	TotalSpent   int64 `json:"total_spent"`   // 总消费积分
	TodayEarned  int64 `json:"today_earned"`  // 今日获得积分
	TodaySpent   int64 `json:"today_spent"`   // 今日消费积分
	ActiveRules  int64 `json:"active_rules"`  // 活跃规则数
	ActiveItems  int64 `json:"active_items"`  // 活跃商品数
}
