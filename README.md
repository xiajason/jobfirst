# JobFirst

JobFirst是一个现代化的求职招聘平台，采用微服务架构设计，提供完整的求职和招聘解决方案。

## 🚀 快速开始

### 环境要求
- Go 1.21+
- Node.js 18+
- Docker & Docker Compose
- MySQL 8.0
- Redis 7.0

### 本地开发
```bash
# 克隆项目
git clone https://github.com/xiajason/jobfirst.git
cd jobfirst

# 启动数据库
docker-compose up -d

# 启动后端服务
cd backend
go mod tidy
go run main.go

# 启动前端服务
cd frontend/web
npm install
npm run dev
```

## 📚 文档

- [开发指南](docs/DEVELOPMENT.md)
- [API文档](docs/API.md)
- [部署指南](docs/DEPLOYMENT.md)
- [腾讯云配置](docs/TENCENT_CLOUD_SETUP.md)

## 🏗️ 架构

```
JobFirst
├── 前端 (Next.js + TypeScript)
├── API网关 (Go + Gin)
├── 微服务
│   ├── 用户服务
│   ├── 简历服务
│   ├── 职位服务
│   └── 推荐服务
└── 基础设施
    ├── 数据库 (MySQL + Redis)
    ├── 监控 (Prometheus + Grafana)
    └── 容器化 (Docker + Kubernetes)
```

## 🔧 技术栈

### 后端
- **语言**: Go 1.21+
- **框架**: Gin
- **数据库**: MySQL 8.0, Redis 7.0
- **认证**: JWT
- **容器化**: Docker, Kubernetes

### 前端
- **框架**: Next.js 15.3.0
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **测试**: Jest, Playwright

### 基础设施
- **CI/CD**: GitHub Actions
- **容器编排**: Kubernetes
- **监控**: Prometheus, Grafana
- **云服务**: 腾讯云 TKE

## 📊 项目状态

- ✅ **开发环境**: 100% 就绪
- ✅ **CI/CD管道**: 100% 就绪
- ✅ **测试框架**: 100% 就绪
- ✅ **腾讯云部署**: 90% 就绪
- ✅ **监控系统**: 100% 就绪

## 🤝 贡献

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

**最后更新**: 2025年8月31日 - CI/CD同步完成，准备部署到腾讯云测试环境
# JobFirst CI/CD Test
