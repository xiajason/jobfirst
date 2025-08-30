# JobFirst API 模块

## 概述

API模块是简历中心系统的服务间通信契约层，它不是独立运行的微服务，而是被各个微服务引用的接口定义库。该模块定义了标准化的数据结构、接口和协议，确保微服务之间的解耦和标准化通信。

## 设计理念

### 1. 接口定义库
- **非独立服务**：API模块不包含main函数，不独立运行
- **共享契约**：定义微服务间的通信接口和数据模型
- **版本管理**：支持API版本控制和向后兼容性

### 2. 标准化通信
- **统一数据结构**：所有微服务使用相同的数据模型
- **接口契约**：明确定义服务间的调用接口
- **错误处理**：统一的错误码和响应格式

### 3. 微服务解耦
- **松耦合设计**：微服务通过接口进行通信，不直接依赖实现
- **独立开发**：各微服务可以独立开发和部署
- **接口演进**：支持接口的平滑演进和版本升级

## 模块结构

```
backend/api/
├── go.mod                    # 模块依赖管理
├── README.md                 # 模块文档
├── types/                    # 共享数据类型定义
│   ├── common.go            # 通用数据结构
│   ├── resume.go            # 简历相关数据结构
│   ├── points.go            # 积分相关数据结构
│   └── statistics.go        # 统计相关数据结构
├── interfaces/              # 服务接口定义
│   ├── resume.go            # 简历服务接口
│   ├── points.go            # 积分服务接口
│   └── statistics.go        # 统计服务接口
├── constants/               # 常量定义
│   └── status.go            # 状态码常量
└── utils/                   # 工具函数
    └── response.go          # 响应工具
```

## 核心组件

### 1. 数据类型 (types/)

#### 通用数据类型 (common.go)
- `BaseResponse`：通用响应结构
- `PageRequest/PageResponse`：分页请求和响应
- `UserContext`：用户上下文
- `AuditLog`：审计日志
- `FileInfo`：文件信息
- `Notification`：通知信息

#### 简历数据类型 (resume.go)
- `Resume`：简历数据结构
- `ResumeSection`：简历章节
- `ResumeTemplate`：简历模板
- `ResumeBanner`：简历横幅
- 相关请求和响应结构

#### 积分数据类型 (points.go)
- `PointsBalance`：积分余额
- `PointsRecord`：积分记录
- `PointsRule`：积分规则
- `PointsItem`：积分商品
- 相关请求和响应结构

#### 统计数据类型 (statistics.go)
- `StatisticsData`：统计数据
- `StatisticsReport`：统计报表
- `UserStatistics`：用户统计
- `ResumeStatistics`：简历统计
- `PointsStatistics`：积分统计
- `SystemStatistics`：系统统计

### 2. 服务接口 (interfaces/)

#### 简历服务接口 (resume.go)
```go
type ResumeService interface {
    CreateResume(ctx context.Context, req *types.CreateResumeRequest) (*types.ResumeResponse, error)
    GetResume(ctx context.Context, req *types.GetResumeRequest) (*types.ResumeResponse, error)
    UpdateResume(ctx context.Context, req *types.UpdateResumeRequest) (*types.ResumeResponse, error)
    DeleteResume(ctx context.Context, req *types.DeleteResumeRequest) (*types.EmptyResponse, error)
    ListResumes(ctx context.Context, req *types.ListResumesRequest) (*types.ListResumesResponse, error)
    // ... 更多方法
}
```

#### 积分服务接口 (points.go)
```go
type PointsService interface {
    GetBalance(ctx context.Context, req *types.GetBalanceRequest) (*types.BalanceResponse, error)
    EarnPoints(ctx context.Context, req *types.EarnPointsRequest) (*types.PointsResponse, error)
    SpendPoints(ctx context.Context, req *types.SpendPointsRequest) (*types.PointsResponse, error)
    GetHistory(ctx context.Context, req *types.GetHistoryRequest) (*types.HistoryResponse, error)
    // ... 更多方法
}
```

#### 统计服务接口 (statistics.go)
```go
type StatisticsService interface {
    TrackEvent(ctx context.Context, req *types.TrackEventRequest) error
    GetStatistics(ctx context.Context, req *types.GetStatisticsRequest) (*types.StatisticsResponse, error)
    GetDashboard(ctx context.Context) (*types.DashboardResponse, error)
    // ... 更多方法
}
```

### 3. 常量定义 (constants/)

#### 状态码常量 (status.go)
- HTTP状态码：200, 400, 401, 403, 404, 500等
- 业务状态码：1000-3999范围
- 状态消息映射表

### 4. 工具函数 (utils/)

#### 响应工具 (response.go)
- `Success()`：成功响应
- `Error()`：错误响应
- `BadRequest()`：参数错误响应
- `Unauthorized()`：未授权响应
- `PageSuccess()`：分页成功响应
- 用户上下文管理函数

## 使用方式

### 1. 在微服务中引用API模块

```go
// 在微服务的go.mod中添加依赖
require (
    resume-centre/api v0.1.0
)

// 在代码中导入
import (
    "resume-centre/api/types"
    "resume-centre/api/interfaces"
    "resume-centre/api/constants"
    "resume-centre/api/utils"
)
```

### 2. 实现服务接口

```go
// 简历服务实现
type ResumeServiceImpl struct {
    // 依赖注入
}

// 实现接口方法
func (s *ResumeServiceImpl) CreateResume(ctx context.Context, req *types.CreateResumeRequest) (*types.ResumeResponse, error) {
    // 实现逻辑
    resume := &types.Resume{
        ID:          generateID(),
        UserID:      req.UserID,
        Title:       req.Title,
        Description: req.Description,
        Status:      "draft",
        CreatedAt:   time.Now(),
        UpdatedAt:   time.Now(),
    }
    
    return &types.ResumeResponse{Resume: resume}, nil
}
```

### 3. 使用响应工具

```go
func (h *ResumeHandler) CreateResume(c *gin.Context) {
    var req types.CreateResumeRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        utils.BadRequest(c, "参数错误")
        return
    }
    
    response, err := h.service.CreateResume(c.Request.Context(), &req)
    if err != nil {
        utils.InternalError(c, "创建简历失败")
        return
    }
    
    utils.Created(c, response)
}
```

## 版本管理

### 1. 语义化版本
- 主版本号：不兼容的API修改
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正

### 2. 向后兼容
- 新增字段使用可选类型
- 保留旧字段，标记为废弃
- 提供迁移指南

### 3. 版本升级
- 渐进式升级策略
- 多版本并存支持
- 自动版本检测

## 最佳实践

### 1. 接口设计
- 保持接口简洁明确
- 使用统一的命名规范
- 提供完整的文档注释

### 2. 错误处理
- 使用预定义的错误码
- 提供详细的错误信息
- 实现统一的错误处理

### 3. 数据验证
- 在接口层定义验证规则
- 使用binding标签进行验证
- 提供自定义验证函数

### 4. 性能优化
- 避免过度设计
- 使用适当的数据结构
- 考虑序列化性能

## 扩展指南

### 1. 添加新的数据类型
1. 在`types/`目录下创建新文件
2. 定义数据结构和相关请求响应
3. 添加必要的验证标签
4. 更新文档

### 2. 添加新的服务接口
1. 在`interfaces/`目录下创建新文件
2. 定义服务接口方法
3. 使用标准的方法签名
4. 添加完整的注释

### 3. 添加新的常量
1. 在`constants/`目录下添加常量定义
2. 遵循命名规范
3. 更新状态消息映射
4. 添加使用示例

## 贡献指南

1. 遵循Go语言编码规范
2. 添加完整的单元测试
3. 更新相关文档
4. 提交前进行代码审查

## 许可证

本项目采用MIT许可证，详见LICENSE文件。
