# JobFirst - 智能求职平台

## 项目概述

JobFirst是一个基于微服务架构的智能求职平台，支持多模式部署和AI驱动的简历优化功能。

## 架构特性

- **微服务架构**: 基于Golang和Python的混合技术栈
- **多模式支持**: Basic、Plus、Pro三种版本模式
- **AI驱动**: 基于Python Sanic的AI简历分析服务
- **跨平台**: 支持Web前端和微信小程序
- **容器化部署**: 完整的Docker和Docker Compose支持

## 快速开始

### 本地测试环境（推荐）

```bash
# 克隆项目
git clone https://github.com/xiajason/jobfirst.git
cd jobfirst

# 启动本地测试环境（完整微服务架构）
./scripts/start-local-test.sh

# 停止本地测试环境
./scripts/stop-local-test.sh

# 查看服务状态
docker-compose -f docker-compose.local-test.yml ps

# 查看服务日志
docker-compose -f docker-compose.local-test.yml logs -f
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

### 环境分离说明

**本地开发环境** (`docker-compose.local-test.yml`):
- 用于本地开发和测试
- 包含完整的微服务架构
- 数据持久化，便于开发调试
- 使用本地端口映射

**CI/CD测试环境** (`docker-compose.ci.yml`):
- 仅在GitHub Actions Runner中运行
- 独立的网络和容器命名
- 测试完成后自动清理
- 不影响本地开发环境

**生产环境**:
- 使用GitHub Container Registry
- 部署到生产服务器
- 完整的监控和日志

### 开发环境

```bash
# 克隆项目
git clone https://github.com/xiajason/jobfirst.git
cd jobfirst

# 启动集成模式
./start_enhanced_mode.sh

# 或者启动AI服务
cd backend/ai-service
docker-compose up -d
```

### 生产部署

```bash
# 使用Docker Compose
docker-compose -f docker-compose.integrated.yml up -d

# 或者使用增强模式
./start_enhanced_mode.sh
```

## 服务架构

- **API网关**: Golang + Gin框架
- **AI服务**: Python + Sanic框架
- **用户服务**: Golang + GORM
- **简历服务**: Golang + 向量数据库
- **前端**: Next.js + React + TypeScript
- **小程序**: 微信小程序原生开发

## 技术栈

- **后端**: Golang, Python, PostgreSQL, Redis
- **前端**: Next.js, React, TypeScript, Tailwind CSS
- **AI**: OpenAI API, Anthropic API, pgvector
- **部署**: Docker, Docker Compose, GitHub Actions

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

---

## CI/CD 状态

![CI/CD Pipeline](https://github.com/xiajason/jobfirst/workflows/JobFirst%20CI%2FCD%20Pipeline/badge.svg?branch=develop)

**最新构建状态**: [查看详情](https://github.com/xiajason/jobfirst/actions/workflows/ci-cd-pipeline.yml)
