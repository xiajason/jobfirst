# 测试环境CI/CD自动部署配置指南

## 🎯 目标
实现JobFirst项目的测试环境自动部署，当代码推送到`develop`分支时，自动部署到腾讯云测试环境。

## 📋 需要配置的GitHub Secrets

### 1. Docker Hub配置
| Secret名称 | 说明 | 示例值 |
|------------|------|--------|
| `DOCKER_USERNAME` | Docker Hub用户名 | `your-docker-username` |
| `DOCKER_PASSWORD` | Docker Hub密码或访问令牌 | `your-docker-password` |

### 2. 腾讯云测试环境配置
| Secret名称 | 说明 | 示例值 |
|------------|------|--------|
| `TENCENT_STAGING_HOST` | 测试环境服务器IP地址 | `123.456.789.123` |
| `TENCENT_USER` | SSH用户名 | `ubuntu` |
| `TENCENT_SSH_KEY` | SSH私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

## 🔧 配置步骤

### 步骤1: 配置GitHub Secrets
1. 进入GitHub仓库: https://github.com/xiajason/jobfirst
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret** 添加上述所有Secrets

### 步骤2: 获取SSH私钥内容
```bash
# 如果您有SSH私钥文件，运行以下命令获取内容
cat ~/.ssh/id_rsa
# 或者
cat /path/to/your/tencent_cloud_key
```

### 步骤3: 验证配置
配置完成后，推送代码到`develop`分支即可触发自动部署：
```bash
git checkout develop
git add .
git commit -m "test: 触发测试环境自动部署"
git push origin develop
```

## 🚀 部署流程

### 自动触发条件
- 推送代码到 `develop` 分支
- 所有测试通过
- 构建成功

### 部署步骤
1. **构建阶段**
   - 构建Go服务（网关、共享基础设施）
   - 构建Docker镜像
   - 推送到Docker Hub

2. **部署阶段**
   - 连接到腾讯云测试服务器
   - 拉取最新Docker镜像
   - 启动服务（网关、共享基础设施、MySQL、Redis、Prometheus、Grafana）

3. **验证阶段**
   - 运行健康检查
   - 执行冒烟测试
   - 运行集成测试

## 📊 测试环境服务

| 服务 | 端口 | 访问地址 | 说明 |
|------|------|----------|------|
| API网关 | 8000 | http://your-server-ip:8000 | 统一API入口 |
| 共享基础设施 | 8210 | http://your-server-ip:8210 | 基础设施服务 |
| MySQL | 3306 | - | 数据库服务 |
| Redis | 6379 | - | 缓存服务 |
| Prometheus | 9090 | http://your-server-ip:9090 | 监控服务 |
| Grafana | 3001 | http://your-server-ip:3001 | 可视化面板 |

## 🔍 监控和日志

### 健康检查端点
- API网关: `http://your-server-ip:8000/health`
- 共享基础设施: `http://your-server-ip:8210/health`

### 监控面板
- Grafana: `http://your-server-ip:3001`
  - 用户名: `admin`
  - 密码: `jobfirst_staging_2024`

## 🛠️ 故障排除

### 常见问题
1. **SSH连接失败**
   - 检查SSH密钥是否正确
   - 确认服务器防火墙允许SSH连接（端口22）

2. **Docker构建失败**
   - 检查Docker Hub凭据
   - 确认Dockerfile配置正确

3. **服务启动失败**
   - 检查端口是否被占用
   - 查看Docker容器日志

### 查看部署状态
```bash
# 在测试服务器上查看服务状态
docker-compose -f /home/ubuntu/jobfirst-staging/docker-compose.staging.yml ps

# 查看服务日志
docker-compose -f /home/ubuntu/jobfirst-staging/docker-compose.staging.yml logs -f
```

## 📝 注意事项

1. **安全性**
   - 定期轮换SSH密钥
   - 使用强密码
   - 限制服务器访问权限

2. **资源管理**
   - 监控服务器资源使用情况
   - 定期清理Docker镜像和容器

3. **备份策略**
   - 定期备份数据库
   - 备份配置文件

## 🎉 成功标志

当看到以下信息时，表示部署成功：
```
✅ Staging deployment status: success
✅ Staging deployment completed for branch: refs/heads/develop
✅ Staging URL: http://your-server-ip:3000
✅ API Gateway: http://your-server-ip:8000
✅ Monitoring: http://your-server-ip:3001
```

## 📞 支持

如果遇到问题，请检查：
1. GitHub Actions日志
2. 服务器Docker日志
3. 网络连接状态
4. 配置文件语法
