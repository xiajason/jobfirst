# Shared Components - 共享组件

这是Resume Centre项目的共享组件，采用DDD（领域驱动设计）分层架构，提供跨领域的共享功能。

## 📁 目录结构

```
shared/
├── kernel/           # 领域核心层 - 最基础的共享功能
│   ├── entity.go     # 基础实体
│   ├── value_object.go # 值对象
│   ├── domain_event.go # 领域事件
│   └── errors.go     # 错误定义
├── infrastructure/   # 基础设施层 - 技术基础设施
│   ├── repository.go # 仓储接口和实现
│   └── cache.go      # 缓存接口和实现
└── application/      # 应用服务层 - 业务应用服务
    └── application_service.go # 应用服务基类
```

## 🏗️ 架构设计

### 分层架构

1. **Kernel层** - 领域核心
   - 提供最基础的领域概念
   - 包含实体、值对象、领域事件
   - 定义通用错误类型

2. **Infrastructure层** - 基础设施
   - 提供技术基础设施抽象
   - 包含仓储、缓存、数据库接口
   - 实现技术细节的封装

3. **Application层** - 应用服务
   - 提供应用服务基类
   - 包含命令查询分离（CQRS）
   - 定义应用服务接口

## 🚀 快速开始

### 1. 使用基础实体

```go
import "resume-centre/shared/kernel"

// 创建基础实体
entity := kernel.NewBaseEntity()

// 更新实体
entity.Update()

// 删除实体
entity.Delete()
```

### 2. 使用值对象

```go
// 创建邮箱值对象
email, err := kernel.NewEmail("user@example.com")

// 创建金额值对象
money := kernel.NewMoney(100.50, "CNY")

// 创建日期范围值对象
dateRange, err := kernel.NewDateRange(startDate, endDate)
```

### 3. 使用仓储模式

```go
import "resume-centre/shared/infrastructure"

// 创建仓储
repo := infrastructure.NewBaseRepository[User](db)

// 保存实体
err := repo.Save(ctx, user)

// 查找实体
user, err := repo.FindByID(ctx, "user-id")
```

### 4. 使用缓存服务

```go
// 创建缓存服务
cacheService := infrastructure.NewCacheService(redisCache)

// 缓存对象
err := cacheService.SetObject(ctx, "user:123", user, time.Hour)

// 获取对象
var user User
err := cacheService.GetObject(ctx, "user:123", &user)
```

### 5. 使用应用服务

```go
import "resume-centre/shared/application"

// 创建应用服务
appService := application.NewBaseApplicationService(logger)

// 创建命令总线
commandBus := application.NewBaseCommandBus()

// 创建查询总线
queryBus := application.NewBaseQueryBus()
```

## 📋 核心组件

### 基础实体 (BaseEntity)

提供所有实体的基础功能：
- 唯一ID生成
- 创建时间、更新时间、删除时间
- 软删除支持
- 实体状态管理

### 值对象 (Value Objects)

提供不可变的值对象：
- **Email**: 邮箱地址值对象
- **Phone**: 电话号码值对象
- **Money**: 金额值对象
- **DateRange**: 日期范围值对象

### 领域事件 (Domain Events)

支持事件驱动架构：
- 事件发布和订阅
- 事件存储和查询
- 事件处理器注册

### 仓储模式 (Repository Pattern)

提供数据访问抽象：
- 通用CRUD操作
- 事务支持
- 查询优化

### 缓存服务 (Cache Service)

提供高性能缓存：
- Redis缓存实现
- 对象序列化
- 过期时间管理

### 应用服务 (Application Service)

提供应用层抽象：
- 命令查询分离
- 事务管理
- 事件发布

## 🔧 配置和依赖

### 依赖管理

每个层都有独立的`go.mod`文件：

```go
// kernel/go.mod
module resume-centre/shared/kernel

// infrastructure/go.mod
module resume-centre/shared/infrastructure
require resume-centre/shared/kernel v0.0.0

// application/go.mod
module resume-centre/shared/application
require (
    resume-centre/shared/kernel v0.0.0
    resume-centre/shared/infrastructure v0.0.0
)
```

### 模块替换

使用`replace`指令进行本地模块引用：

```go
replace (
    resume-centre/shared/kernel => ../kernel
    resume-centre/shared/infrastructure => ../infrastructure
)
```

## 🎯 设计原则

### 1. 依赖倒置原则
- 高层模块不依赖低层模块
- 抽象不依赖具体实现
- 具体实现依赖抽象

### 2. 单一职责原则
- 每个组件只负责一个功能
- 清晰的职责边界
- 易于测试和维护

### 3. 开闭原则
- 对扩展开放
- 对修改关闭
- 通过接口和抽象实现

### 4. 接口隔离原则
- 客户端不应该依赖它不需要的接口
- 接口应该小而精确
- 避免胖接口

## 📊 性能优化

### 1. 缓存策略
- 多级缓存
- 缓存预热
- 缓存失效策略

### 2. 数据库优化
- 连接池管理
- 查询优化
- 索引策略

### 3. 并发处理
- 协程池
- 异步处理
- 限流控制

## 🧪 测试

### 单元测试
```bash
# 测试Kernel层
cd kernel && go test ./...

# 测试Infrastructure层
cd infrastructure && go test ./...

# 测试Application层
cd application && go test ./...
```

### 集成测试
```bash
# 运行所有测试
go test ./shared/...
```

## 📚 最佳实践

### 1. 错误处理
- 使用预定义的错误类型
- 提供有意义的错误信息
- 实现错误链传递

### 2. 日志记录
- 结构化日志
- 日志级别控制
- 敏感信息过滤

### 3. 配置管理
- 环境变量配置
- 配置文件管理
- 配置验证

### 4. 监控和指标
- 性能指标收集
- 健康检查
- 告警机制

## 🔄 版本管理

### 语义化版本
- 主版本号：不兼容的API修改
- 次版本号：向下兼容的功能性新增
- 修订号：向下兼容的问题修正

### 向后兼容
- 保持接口稳定性
- 渐进式功能增强
- 废弃通知机制

## 📞 支持

如有问题或建议，请：
1. 查看文档
2. 提交Issue
3. 联系开发团队

## 📄 许可证

MIT License
