# JobFirst 简历中心系统

一个基于微服务架构的现代化简历管理系统，提供简历创建、管理、分享和统计分析功能。

## 🏗️ 系统架构

### 后端微服务架构

#### 核心微服务
- **Gateway** (端口: 8080): API网关，统一入口和路由
- **User** (端口: 8081): 用户管理服务
- **Resume** (端口: 8087): 简历管理服务  
- **Statistics** (端口: 8097): 数据统计服务
- **Storage** (端口: 8088): 文件存储服务
- **Points** (端口: 8086): 积分系统服务

#### 原有系统微服务
- **Admin** (端口: 8003): 管理端服务
- **Personal** (端口: 6001): 个人端服务
- **Enterprise** (端口: 8002): 企业端服务
- **Resource** (端口: 9002): 资源服务
- **Open** (端口: 9006): 开放API服务
- **Blockchain** (端口: 9009): 区块链服务 (已禁用)

#### 共享模块
- **Common** (`backend/common/`): 共享组件库
  - `common-core`: 核心功能和常量
  - `common-security`: 安全认证和授权
  - `common-jwt`: JWT令牌处理
  - `common-swagger`: API文档配置
  - `common-cache`: 缓存处理
  - `common-log`: 日志处理
  - `common-thread`: 线程池管理
  - `common-storage`: 存储服务
  - `common-es`: ElasticSearch集成
  - `common-mq`: 消息队列

- **API** (`backend/api/`): 服务间通信契约层
  - `types/`: 共享数据模型
  - `interfaces/`: 服务接口定义
  - `constants/`: 常量和状态码
  - `utils/`: 工具函数

### 前端应用
- **Web**: Next.js Web应用 (端口: 3000)
- **Miniprogram**: 微信小程序

### 基础设施
- **MySQL**: 数据库服务 (端口: 8200)
- **Redis**: 缓存服务 (端口: 8201)
- **Consul**: 服务发现和配置中心 (端口: 8202)

## 🚀 快速开始

### 前置要求

- Docker & Docker Compose
- Go 1.21+
- Node.js 18+
- npm 或 yarn

### 一键启动开发环境

```bash
# 克隆项目
git clone <repository-url>
cd jobfirst

# 一键启动开发环境
./quick-start.sh
```

### 手动启动

```bash
# 启动开发环境
./scripts/dev-start.sh start

# 查看服务状态
./scripts/dev-start.sh status

# 查看日志
./scripts/dev-start.sh logs

# 停止所有服务
./scripts/dev-start.sh stop
```

### 分步启动

```bash
# 1. 启动基础设施
./scripts/start-infrastructure.sh

# 2. 配置开发环境
./scripts/setup-dev-env.sh

# 3. 启动后端开发服务
./scripts/start-backend-dev.sh

# 4. 启动前端开发服务
./scripts/start-frontend-dev.sh
```

## 🌐 访问地址

### 开发环境
- **前端Web应用**: http://localhost:3000
- **API网关**: http://localhost:8080
- **Consul管理界面**: http://localhost:8202
- **MySQL数据库**: localhost:8200
- **Redis缓存**: localhost:8201

### 微服务端口映射
- **用户服务**: http://localhost:8081
- **简历服务**: http://localhost:8087
- **积分服务**: http://localhost:8086
- **统计服务**: http://localhost:8097
- **存储服务**: http://localhost:8088

### 原有系统服务
- **管理端服务**: http://localhost:8003
- **个人端服务**: http://localhost:6001
- **企业端服务**: http://localhost:8002
- **资源服务**: http://localhost:9002
- **开放API服务**: http://localhost:9006

## 📋 开发指南

### 开发环境特性

#### ✨ 热加载支持
- 使用 `air` 实现 Go 服务热加载
- 修改代码后自动重新编译和重启服务
- 无需手动重启服务

#### 🎯 后台运行
- 所有微服务在后台运行
- 不占用终端，可以继续其他操作
- 支持日志查看和状态监控

#### 📊 服务管理
- 统一的服务启动、停止、重启
- 实时状态监控
- 日志集中管理

### 后端开发

#### 开发模式（推荐）
```bash
# 使用air热重载开发
cd backend/gateway
air

# 或者使用VS Code调试
# 在VS Code中按F5启动调试
```

#### 生产模式
```bash
# 进入后端目录
cd backend

# 编译特定服务
cd gateway
go build -o gateway-service .

# 运行服务
./gateway-service
```

### 前端开发

#### 开发模式（推荐）
```bash
# 启动Next.js开发服务器
cd frontend/web
npm run dev
```

#### 生产模式
```bash
# 构建生产版本
cd frontend/web
npm run build
npm start
```

### 小程序开发
```bash
# 使用微信开发者工具打开
# frontend/miniprogram-4/
```

## 🔧 配置说明

### 环境变量

主要配置在 `docker-compose.yml` 中：

```yaml
environment:
  - CONSUL_ADDRESS=consul:8500
  - REDIS_ADDRESS=redis:6379
  - MYSQL_ADDRESS=mysql:3306
```

### 服务配置

各服务的配置文件位于 `backend/*/config.yaml`

## 📊 监控和日志

### 查看服务状态

```bash
./scripts/dev-start.sh status
```

### 查看日志

```bash
# 查看所有日志文件
./scripts/dev-start.sh logs

# 查看指定服务日志
./scripts/dev-start.sh logs user
./scripts/dev-start.sh logs gateway

# 实时查看日志
tail -f logs/user.log
```

### 健康检查

所有服务都提供了健康检查端点：

```bash
# 检查服务健康状态
curl http://localhost:8080/health  # API网关
curl http://localhost:8081/health  # 用户服务
curl http://localhost:8087/health  # 简历服务
curl http://localhost:8086/health  # 积分服务
curl http://localhost:8097/health  # 统计服务
curl http://localhost:8088/health  # 存储服务
```

## 🧪 测试

### 后端测试

```bash
# 进入服务目录
cd backend/gateway

# 运行测试
go test ./...
```

### 前端测试

```bash
# 进入前端目录
cd frontend/web

# 运行测试
npm test
```

## 📚 API文档

### 网关API

- 基础URL: http://localhost:8080
- 认证: JWT Token
- 格式: JSON

### Swagger文档

- 统计服务: http://localhost:8097/swagger/index.html
- 其他服务: 各服务端口 + /swagger/index.html

## 🔍 故障排除

### 常见问题

1. **端口被占用**
```bash
# 查看端口占用
lsof -i :8080

# 停止占用进程
pkill -f process-name
```

2. **服务启动失败**
```bash
# 查看服务日志
./scripts/dev-start.sh logs [service-name]

# 重启服务
./scripts/dev-start.sh restart [service-name]
```

3. **依赖问题**
```bash
# 清理并重新构建
docker-compose down
docker-compose up --build
```

### 开发环境问题

1. **Go模块问题**
```bash
cd backend/[service-name]
go mod tidy
go mod download
```

2. **npm依赖问题**
```bash
cd frontend/web
rm -rf node_modules package-lock.json
npm install
```

## 📝 项目结构

```
jobfirst/
├── backend/                 # 后端微服务
│   ├── gateway/            # API网关
│   ├── user/               # 用户服务
│   ├── resume/             # 简历服务
│   ├── statistics/         # 统计服务
│   ├── storage/            # 存储服务
│   ├── points/             # 积分服务
│   ├── admin/              # 管理端服务
│   ├── personal/           # 个人端服务
│   ├── enterprise/         # 企业端服务
│   ├── resource/           # 资源服务
│   ├── open/               # 开放API服务
│   ├── blockchain/         # 区块链服务
│   ├── common/             # 共享组件库
│   ├── api/                # 服务间通信契约层
│   └── shared/             # 共享组件
├── frontend/               # 前端应用
│   ├── web/                # Next.js Web应用
│   └── miniprogram-4/      # 微信小程序
├── scripts/                # 开发脚本
├── logs/                   # 日志文件
├── docker-compose.yml      # Docker编排配置
├── quick-start.sh          # 一键启动脚本
└── README.md              # 项目文档
```

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 支持

如有问题或建议，请：

1. 查看 [Issues](../../issues)
2. 联系开发团队
3. 查看项目文档

---

**JobFirst 简历中心系统** - 让简历管理更简单、更智能
