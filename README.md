# JobFirst - 智能求职平台

## 🚀 项目概述

JobFirst是一个基于微服务架构的智能求职平台，采用"一个后端，两个前端"的设计理念，支持微信小程序和Web应用。

## ✨ 核心特性

- 🌐 **多模式架构**：支持Basic、Plus、Pro三种服务模式
- 🔐 **企业级API网关**：统一认证、限流、监控
- 🤖 **AI智能分析**：简历优化、职位匹配、智能推荐
- 📱 **双端一致**：小程序和Web端功能完全一致
- 🗄️ **向量数据库**：PostgreSQL + pgvector支持语义搜索
- 🐳 **容器化部署**：Docker + Docker Compose
- 🔄 **CI/CD自动化**：GitHub Actions自动化部署
- 📊 **监控告警**：Prometheus + Grafana
- 🔒 **环境分离**：本地开发、CI/CD测试、生产环境完全隔离

## 🏗️ 技术架构

### 后端服务
- **API网关**：Golang + Gin框架
- **AI服务**：Python + Sanic异步框架
- **用户服务**：Golang + GORM
- **简历服务**：Golang + GORM
- **积分服务**：Golang + GORM
- **个人服务**：Golang + GORM

### 前端应用
- **微信小程序**：原生小程序开发
- **Web前端**：Next.js 15 + React 19 + TypeScript

### 基础设施
- **数据库**：PostgreSQL 15 + pgvector
- **缓存**：Redis 7
- **消息队列**：Redis Streams
- **监控**：Prometheus + Grafana

## 🚀 快速开始

### 本地测试环境（推荐）

使用我们提供的自动化脚本来快速启动完整的本地测试环境：

```bash
# 启动本地测试环境
./scripts/start-local-test.sh

# 停止本地测试环境
./scripts/stop-local-test.sh
```

**本地测试环境包含：**
- 🗄️ PostgreSQL数据库 (端口: 5432)
- 🔴 Redis缓存 (端口: 6379)
- 🌐 API网关 (端口: 8000)
- 🤖 AI服务 (端口: 8001)
- 👤 用户服务 (端口: 8081)
- 📄 简历服务 (端口: 8082)
- 💻 Web前端 (端口: 3000)
- 📊 Prometheus监控 (端口: 9090)
- 📈 Grafana仪表板 (端口: 3001)

### 手动启动

如果需要手动控制，可以使用Docker Compose：

```bash
# 启动基础设施服务
docker-compose -f docker-compose.local-test.yml up -d postgres redis prometheus grafana

# 启动微服务
docker-compose -f docker-compose.local-test.yml up -d gateway ai-service user-service resume-service

# 启动前端
docker-compose -f docker-compose.local-test.yml up -d web-frontend

# 查看服务状态
docker-compose -f docker-compose.local-test.yml ps

# 停止所有服务
docker-compose -f docker-compose.local-test.yml down
```

## 🔧 开发指南

### 环境要求

- Docker 20.10+
- Docker Compose 2.0+
- Go 1.21+
- Python 3.11+
- Node.js 18+

### 代码结构

```
jobfirst/
├── backend/                 # 后端微服务
│   ├── gateway/            # API网关
│   ├── ai-service/         # AI服务
│   ├── user/               # 用户服务
│   ├── resume/             # 简历服务
│   ├── points/             # 积分服务
│   ├── personal/           # 个人服务
│   └── shared/             # 共享代码
├── frontend/               # 前端应用
│   ├── miniprogram/        # 微信小程序
│   └── web/                # Web前端
├── docs/                   # 文档
├── scripts/                # 自动化脚本
├── monitoring/             # 监控配置
└── docker-compose.*.yml    # Docker配置
```

## 📚 API文档

详细的API文档请参考：[API_DOC.md](frontend/API_DOC.md)

## 🔄 CI/CD流程

### 自动化流程

1. **代码推送** → 触发GitHub Actions
2. **代码质量检查** → Go/Python代码检查
3. **单元测试** → 多版本Go环境测试
4. **构建测试** → Docker镜像构建测试
5. **部署测试环境** → CI/CD测试环境部署
6. **生产部署** → 生产环境镜像推送

### 环境分离

- **本地环境**：开发调试，使用`docker-compose.local-test.yml`
- **CI/CD环境**：自动化测试，使用`docker-compose.ci.yml`
- **生产环境**：生产部署，使用GitHub Container Registry

## 🐛 故障排除

### 常见问题

1. **端口冲突**：确保本地端口未被占用
2. **数据库连接失败**：检查PostgreSQL服务状态
3. **Docker构建失败**：清理Docker缓存后重试
4. **服务健康检查失败**：查看容器日志排查问题

### 日志查看

```bash
# 查看服务日志
docker-compose -f docker-compose.local-test.yml logs [service-name]

# 查看特定容器日志
docker logs [container-name]

# 实时查看日志
docker-compose -f docker-compose.local-test.yml logs -f [service-name]
```

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证。

## 📞 联系我们

如有问题或建议，请通过以下方式联系：

- 项目Issues：[GitHub Issues](https://github.com/xiajason/jobfirst/issues)
- 邮箱：support@jobfirst.com

---

## 🔄 CI/CD触发标记

**最后更新**: 2025-09-02 23:50:00  
**CI/CD状态**: 准备触发  
**触发方式**: 代码推送到develop分支  

> 💡 每次推送代码到develop分支都会自动触发CI/CD流程，包括代码质量检查、测试、构建和部署测试环境。
