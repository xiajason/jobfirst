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
