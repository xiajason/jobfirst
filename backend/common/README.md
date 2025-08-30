# JobFirst Common Module

JobFirst项目的通用功能模块，提供底层支持库，供其他微服务引用。

## 设计理念

- **无独立端口**：common模块的功能通过各微服务暴露，端口由主服务决定
- **上下文路径继承**：路由前缀由微服务自身配置，common模块仅提供底层支持
- **配置灵活性**：所有关键参数均支持微服务级覆盖

## 功能特性

### 1. 核心功能 (core)
- **控制器基类**：提供统一的控制器基类，包含常用方法
- **响应模型**：统一的响应格式、分页模型、错误模型
- **常量定义**：用户权限类型、角色类型、状态码等基础枚举
- **请求模型**：登录请求/响应模型、注册模型等

### 2. 安全框架 (security)
- **OAuth2Filter**：基于golang实现的安全框架，用于令牌验证
- **可配置白名单**：支持可配置的URL白名单，支持方法+路径匹配
- **权限控制**：基于角色和权限的访问控制
- **令牌管理**：令牌生成、验证、刷新功能
- **安全中间件**：RequirePermission、RequireRole等权限中间件

### 3. JWT令牌处理 (jwt)
- **令牌创建和解析**：提供完整的JWT令牌创建、解析、验证功能
- **令牌主体结构**：定义了包含用户ID、租户类型、角色等信息的令牌结构
- **多租户支持**：支持管理员(ADMIN)、个人用户(PERSONAL)、企业用户(ENTERPRISE)
- **令牌对管理**：访问令牌+刷新令牌的完整生命周期管理
- **租户权限**：为不同租户类型提供默认权限配置

### 4. Swagger文档配置 (swagger)
- **增强的Swagger文档**：配置API信息和安全认证
- **API文档生成**：自动生成Swagger JSON文档和UI界面
- **安全认证配置**：支持Bearer Token和Access Token认证
- **数据模型定义**：提供完整的API数据模型定义
- **标签分类**：按功能模块对API进行标签分类

### 5. 配置管理 (config)
- 统一的配置加载和管理
- 支持环境变量覆盖
- 支持多种配置源（文件、环境变量等）
- 提供默认配置值

### 6. 工具函数 (utils)
- MD5加密
- 随机字符串生成
- JSON格式化
- 令牌生成和验证
- 路径白名单检查
- 邮箱和手机号验证

### 7. 中间件 (middleware)
- 认证中间件（支持白名单）
- CORS中间件
- 日志中间件
- 恢复中间件
- 请求ID中间件
- 限流中间件
- 指标中间件

### 8. 通用处理器 (handlers)
- 健康检查
- 版本信息
- 工具函数API
- 系统监控
- 配置管理

## 使用方法

### 1. 在微服务中引入common模块

```go
// 在go.mod中添加依赖
require (
    resume-centre/common v0.0.0
)

// 添加replace指令
replace resume-centre/common => ../common
```

### 2. 在微服务中使用common模块

```go
package main

import (
    "github.com/gin-gonic/gin"
    "resume-centre/common"
)

func main() {
    // 创建common模块实例
    commonModule := common.New()
    
    // 初始化common模块
    if err := commonModule.Init(); err != nil {
        panic(err)
    }
    
    // 获取配置和日志
    config := commonModule.GetConfig()
    logger := commonModule.GetLogger()
    consulClient := commonModule.GetConsul()
    
    // 设置Gin路由
    router := gin.Default()
    
    // 设置通用中间件
    whitelist := []string{
        "/health",
        "/version",
        "/v2/api-docs",
        "/api/v1/user/auth/login",
    }
    commonModule.SetupMiddleware(router, whitelist)
    
    // 设置通用路由
    commonModule.SetupRoutes(router, "your-service-name")
    
    // 添加微服务特定路由
    // ...
    
    // 启动服务器
    port := config.GetServerPort()
    // ...
}
```

### 3. 配置覆盖

每个微服务可以通过以下方式覆盖common模块的配置：

1. **配置文件覆盖**：在微服务目录下创建`config.yaml`
2. **环境变量覆盖**：设置对应的环境变量
3. **代码覆盖**：直接修改config实例

```yaml
# config.yaml
server:
  port: "8001"  # 覆盖默认端口

consul:
  address: "localhost:8202"  # 覆盖Consul地址

logging:
  level: "debug"  # 覆盖日志级别
```

## 模块结构

```
backend/common/
├── common.go          # 主包文件
├── core/              # 核心功能层
│   ├── constants.go   # 常量定义
│   ├── models.go      # 响应模型
│   └── controller.go  # 控制器基类
├── security/          # 安全框架层
│   ├── security.go    # 安全过滤器
│   └── types.go       # 安全相关类型
├── jwt/               # JWT令牌处理层
│   ├── jwt.go         # JWT管理器
│   └── types.go       # JWT相关类型
├── swagger/           # Swagger文档配置层
│   ├── swagger.go     # Swagger管理器
│   └── types.go       # Swagger相关类型
├── config/
│   └── config.go      # 配置管理
├── utils/
│   └── utils.go       # 工具函数
├── middleware/
│   └── middleware.go  # 中间件
├── handlers/
│   └── handlers.go    # 通用处理器
├── go.mod
└── README.md
```

## 白名单配置

每个微服务可以定义自己的白名单路径，common模块的认证中间件会自动跳过这些路径：

```go
whitelist := []string{
    "/health",                    // 健康检查
    "/version",                   // 版本信息
    "/v2/api-docs",              // Swagger文档
    "/swagger/",                  // Swagger UI
    "/utils/",                    // 工具函数
    "/monitor/",                  // 监控接口
    "/config/",                   // 配置管理
    "/api/v1/user/auth/login",    // 登录接口
    "/api/v1/user/public/",       // 公开接口
}
```

## 工具函数使用

```go
import "resume-centre/common/utils"

// MD5加密
hash := utils.MD5Hash("hello")

// 生成随机字符串
randomStr, err := utils.GenerateRandomString(16)

// 验证令牌
isValid := utils.ValidateToken("test-token")

// 检查白名单路径
isWhitelist := utils.IsWhitelistPath("/health", whitelist)
```

## 中间件使用

```go
import "resume-centre/common/middleware"

// 认证中间件
router.Use(middleware.AuthMiddleware(whitelist))

// CORS中间件
router.Use(middleware.CORSMiddleware())

// 日志中间件
router.Use(middleware.LoggingMiddleware())
```

## 配置管理

```go
// 获取配置
config := commonModule.GetConfig()

// 获取服务器端口
port := config.GetServerPort()

// 获取Consul地址
consulAddr := config.GetConsulAddress()

// 获取数据库DSN
dsn := config.GetDatabaseDSN()

// 获取日志级别
logLevel := config.GetLogLevel()
```

## 扩展指南

### 添加新的工具函数

1. 在`utils/utils.go`中添加新函数
2. 在`handlers/handlers.go`中添加对应的处理器
3. 在`common.go`中添加路由

### 添加新的中间件

1. 在`middleware/middleware.go`中添加新中间件
2. 在`common.go`的`SetupMiddleware`方法中注册

### 添加新的配置项

1. 在`config/config.go`中添加新的配置结构
2. 在`setDefaults`方法中设置默认值
3. 添加对应的getter方法

## 注意事项

1. **端口管理**：common模块不占用独立端口，所有功能通过微服务暴露
2. **路由前缀**：路由前缀由微服务决定，common模块提供底层支持
3. **配置优先级**：环境变量 > 配置文件 > 默认值
4. **依赖管理**：确保所有微服务都正确引用了common模块
5. **版本兼容**：common模块的更新需要确保向后兼容

## 示例微服务

参考`backend/user/`目录下的用户服务，了解如何在微服务中集成common模块。
