# JobFirst CI/CD 体系搭建指南

## 📋 概述

本文档详细说明了JobFirst项目的CI/CD体系搭建方案，包括代码质量检查、自动化测试、构建、部署和监控等环节。

## 🏗️ 架构设计

### CI/CD 流水线架构

```
代码提交 → 代码质量检查 → 单元测试 → 集成测试 → 构建镜像 → 部署测试环境 → 性能测试 → 部署生产环境
```

### 环境策略

- **开发环境**: 本地开发，热重载
- **测试环境**: 自动化部署，功能验证
- **生产环境**: 蓝绿部署，零停机时间

## 🔧 核心组件

### 1. GitHub Actions 工作流

#### 主要工作流文件
- `.github/workflows/ci-cd-pipeline.yml` - 主CI/CD流水线
- `.github/workflows/deploy.yml` - 原有部署工作流（保留兼容）

#### 工作流阶段
1. **代码质量检查** (`code-quality`)
   - Go代码静态分析 (golangci-lint)
   - 安全漏洞扫描 (Trivy)
   - 代码覆盖率分析

2. **单元测试** (`unit-tests`)
   - 多版本Go测试 (1.21, 1.22)
   - 多平台测试 (Ubuntu, Windows)
   - 竞态条件检测

3. **集成测试** (`integration-tests`)
   - 数据库集成测试
   - Redis集成测试
   - 服务间通信测试

4. **构建阶段** (`build-services`, `build-frontend`)
   - 微服务Docker镜像构建
   - 前端应用构建
   - 镜像推送到容器仓库

5. **部署阶段** (`deploy-staging`, `deploy-production`)
   - 测试环境自动部署
   - 生产环境蓝绿部署
   - 健康检查和回滚机制

6. **性能测试** (`performance-tests`)
   - 负载测试
   - 性能基准测试
   - 资源使用监控

### 2. 部署脚本

#### 测试环境部署
- `scripts/deploy-staging.sh` - 测试环境部署脚本
  - 自动备份当前版本
  - 拉取最新镜像
  - 健康检查和回滚

#### 生产环境部署
- `scripts/blue-green-deploy.sh` - 蓝绿部署脚本
  - 零停机时间部署
  - 自动流量切换
  - 失败自动回滚

### 3. Docker配置

#### 环境配置文件
- `docker-compose.staging.yml` - 测试环境配置
- `docker-compose.prod.yml` - 生产环境配置

#### 服务架构
```
基础设施服务:
├── MySQL (数据库)
├── Redis (缓存)
├── Consul (服务发现)
└── Neo4j (图数据库)

微服务:
├── Gateway (API网关)
├── User (用户服务)
├── Resume (简历服务)
├── Points (积分服务)
├── Statistics (统计服务)
├── Storage (存储服务)
├── Admin (管理服务)
├── Enterprise (企业服务)
├── Personal (个人服务)
├── Resource (资源服务)
└── Open (开放API服务)

监控服务:
├── Prometheus (指标收集)
└── Grafana (可视化)
```

## 🚀 快速开始

### 1. 环境准备

#### GitHub Secrets 配置
```bash
# 容器仓库配置
DOCKER_REGISTRY=ghcr.io
GITHUB_TOKEN=${GITHUB_TOKEN}

# 测试环境配置
STAGING_HOST=your-staging-server.com
STAGING_USER=ubuntu
STAGING_SSH_KEY=${STAGING_SSH_PRIVATE_KEY}

# 生产环境配置
PROD_HOST=your-prod-server.com
PROD_USER=ubuntu
PROD_SSH_KEY=${PROD_SSH_PRIVATE_KEY}

# 通知配置
SLACK_WEBHOOK=${SLACK_WEBHOOK_URL}

# 数据库配置
MYSQL_ROOT_PASSWORD=your-mysql-root-password
MYSQL_USER=jobfirst
MYSQL_PASSWORD=your-mysql-password
MYSQL_DATABASE=jobfirst

# 监控配置
GRAFANA_PASSWORD=your-grafana-password
NEO4J_AUTH=neo4j/your-neo4j-password
```

#### 服务器环境准备
```bash
# 安装Docker和Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Nginx (负载均衡器)
sudo apt update
sudo apt install nginx

# 配置SSH密钥认证
ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@your-server.com
```

### 2. 本地开发环境

#### 启动开发环境
```bash
# 启动所有服务
./quick-start.sh

# 或者分步启动
./scripts/dev-start.sh
```

#### 运行测试
```bash
# 单元测试
go test -v ./...

# 集成测试
go test -v -tags=integration ./tests/integration/...

# 前端测试
cd frontend/web && npm test
```

### 3. 部署流程

#### 测试环境部署
```bash
# 手动触发测试环境部署
./scripts/deploy-staging.sh

# 或者通过GitHub Actions自动部署
git push origin develop
```

#### 生产环境部署
```bash
# 手动触发生产环境部署
./scripts/blue-green-deploy.sh

# 或者通过GitHub Actions自动部署
git push origin main
```

## 📊 监控和告警

### 1. 监控指标

#### 应用指标
- 服务响应时间
- 错误率
- 吞吐量
- 并发连接数

#### 系统指标
- CPU使用率
- 内存使用率
- 磁盘使用率
- 网络流量

#### 业务指标
- 用户注册数
- 职位发布数
- 简历投递数
- 系统活跃度

### 2. 告警规则

#### 严重告警
- 服务不可用 (>5分钟)
- 错误率 > 5%
- 响应时间 > 2秒

#### 警告告警
- 资源使用率 > 80%
- 磁盘空间 < 20%
- 内存使用率 > 85%

### 3. 通知渠道
- Slack通知
- 邮件告警
- 短信通知 (可选)

## 🔒 安全考虑

### 1. 代码安全
- 依赖漏洞扫描
- 代码静态分析
- 安全编码规范

### 2. 部署安全
- 镜像签名验证
- 密钥管理
- 网络隔离

### 3. 运行时安全
- 容器安全扫描
- 运行时监控
- 访问控制

## 📈 性能优化

### 1. 构建优化
- 多阶段Docker构建
- 构建缓存利用
- 并行构建

### 2. 部署优化
- 蓝绿部署策略
- 滚动更新
- 自动扩缩容

### 3. 监控优化
- 指标聚合
- 日志分析
- 性能基准

## 🛠️ 故障处理

### 1. 常见问题

#### 构建失败
```bash
# 检查构建日志
docker logs jobfirst-gateway

# 重新构建
docker-compose build --no-cache
```

#### 部署失败
```bash
# 检查服务状态
docker ps -a

# 查看服务日志
docker logs jobfirst-user

# 手动回滚
./scripts/rollback.sh
```

#### 性能问题
```bash
# 检查资源使用
docker stats

# 分析性能瓶颈
./scripts/performance-analysis.sh
```

### 2. 回滚策略
- 自动回滚 (部署失败时)
- 手动回滚 (业务问题)
- 数据回滚 (数据库问题)

## 📚 最佳实践

### 1. 代码管理
- 使用语义化版本
- 分支保护规则
- 代码审查流程

### 2. 测试策略
- 单元测试覆盖率 > 80%
- 集成测试覆盖关键路径
- 端到端测试验证用户流程

### 3. 部署策略
- 小批量频繁部署
- 自动化测试验证
- 灰度发布策略

### 4. 监控策略
- 全链路监控
- 实时告警
- 定期性能分析

## 🔄 持续改进

### 1. 指标收集
- 部署成功率
- 平均恢复时间
- 变更失败率

### 2. 流程优化
- 自动化程度提升
- 部署时间缩短
- 错误率降低

### 3. 工具升级
- 新技术评估
- 工具链优化
- 流程简化

## 📞 支持

### 1. 文档资源
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 文档](https://docs.docker.com/)
- [Prometheus 文档](https://prometheus.io/docs/)

### 2. 团队支持
- 技术问题: 开发团队
- 部署问题: DevOps团队
- 业务问题: 产品团队

### 3. 紧急联系
- 生产环境问题: 24/7 值班电话
- 安全事件: 安全团队
- 系统故障: 运维团队

---

通过这套完整的CI/CD体系，JobFirst项目可以实现：
- 🚀 快速可靠的代码交付
- 🔒 安全稳定的部署流程
- 📊 全面的监控和告警
- 🔄 持续的性能优化
- 🛡️ 完善的故障处理机制
