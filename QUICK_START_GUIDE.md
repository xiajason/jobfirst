# ADIRP数智招聘系统 - 快速启动指南

## 🚀 系统概述

ADIRP数智招聘系统是一个完整的招聘解决方案，包含：
- **微信小程序前端**：用户求职和企业招聘的主要入口
- **后端微服务**：提供API接口和业务逻辑
- **数据库系统**：存储用户、职位、企业等核心数据

## 📋 系统要求

### 基础环境
- **操作系统**：macOS 10.15+ / Ubuntu 18.04+ / CentOS 7+
- **内存**：8GB+ RAM
- **存储**：20GB+ 可用空间
- **网络**：稳定的互联网连接

### 软件依赖
- **Docker**：20.10+
- **Docker Compose**：2.0+
- **MySQL**：8.0+
- **Redis**：6.0+
- **Node.js**：18.0+ (前端开发)
- **Go**：1.21+ (后端开发)

## 🛠️ 快速安装

### 1. 克隆项目
```bash
git clone <repository-url>
cd jobfirst
```

### 2. 环境配置
```bash
# 复制环境配置文件
cp .env.example .env

# 编辑环境配置
vim .env
```

### 3. 启动基础设施
```bash
# 启动数据库、Redis等基础设施
docker-compose up -d mysql redis
```

### 4. 数据库升级
```bash
# 执行数据库升级脚本
cd scripts
./upgrade-database.sh

# 或者跳过备份直接升级
./upgrade-database.sh --no-backup --force
```

### 5. 启动后端服务
```bash
# 启动所有后端微服务
./scripts/start-all-services.sh
```

### 6. 启动前端开发
```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

## 📱 小程序开发

### 1. 微信开发者工具
- 下载并安装[微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
- 导入项目：`frontend/miniprogram/`

### 2. 配置小程序
- 在微信公众平台注册小程序
- 配置服务器域名
- 设置AppID和AppSecret

### 3. 开发调试
```bash
# 在微信开发者工具中
# 1. 点击"编译"
# 2. 检查控制台输出
# 3. 测试各页面功能
```

## 🔧 开发环境配置

### 后端开发
```bash
# 进入后端目录
cd backend

# 安装Go依赖
go mod tidy

# 启动开发模式（支持热重载）
cd user && air
cd ../resume && air
cd ../points && air
# ... 其他服务
```

### 前端开发
```bash
# 进入前端目录
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

## 📊 数据库管理

### 数据库连接
```bash
# 连接MySQL
mysql -h localhost -P 3306 -u root -p jobfirst

# 查看表结构
SHOW TABLES;
DESCRIBE users;
```

### 数据备份
```bash
# 备份数据库
mysqldump -h localhost -u root -p jobfirst > backup.sql

# 恢复数据库
mysql -h localhost -u root -p jobfirst < backup.sql
```

### 数据迁移
```bash
# 执行升级脚本
./scripts/upgrade-database.sh

# 查看升级状态
mysql -h localhost -u root -p jobfirst -e "SELECT * FROM database_version;"
```

## 🧪 测试验证

### API测试
```bash
# 测试健康检查
curl http://localhost:8080/health

# 测试用户API
curl http://localhost:8080/api/v1/user/auth/check

# 测试职位API
curl http://localhost:8080/open/job/search
```

### 小程序测试
1. 在微信开发者工具中打开项目
2. 点击"编译"检查是否有错误
3. 测试各个页面功能
4. 验证API接口连接

### 功能测试清单
- [ ] 用户注册/登录
- [ ] 职位搜索/浏览
- [ ] 简历创建/编辑
- [ ] 职位投递
- [ ] 聊天功能
- [ ] 积分系统

## 🔍 故障排除

### 常见问题

#### 1. 数据库连接失败
```bash
# 检查MySQL服务状态
docker ps | grep mysql

# 检查端口占用
netstat -an | grep 3306

# 重启MySQL服务
docker-compose restart mysql
```

#### 2. 小程序编译错误
- 检查TabBar图标大小（必须<40KB）
- 移除WXML中的emoji字符
- 检查基础库版本配置

#### 3. API接口404
- 检查后端服务是否启动
- 验证API路由配置
- 检查网关服务状态

#### 4. 图片加载失败
- 检查图片文件是否存在
- 验证图片路径配置
- 确认文件权限设置

### 日志查看
```bash
# 查看后端日志
tail -f logs/user.log
tail -f logs/resume.log

# 查看Docker日志
docker-compose logs -f

# 查看小程序日志
# 在微信开发者工具控制台查看
```

## 📈 性能优化

### 数据库优化
- 定期更新统计信息
- 优化慢查询
- 配置合适的索引

### 缓存策略
- 启用Redis缓存
- 配置CDN加速
- 优化静态资源

### 监控告警
- 配置Prometheus监控
- 设置Grafana仪表板
- 配置告警规则

## 🚀 部署上线

### 生产环境准备
1. 配置生产数据库
2. 设置域名和SSL证书
3. 配置CDN和负载均衡
4. 设置监控和日志

### 部署步骤
```bash
# 构建生产镜像
docker-compose -f docker-compose.prod.yml build

# 部署到生产环境
docker-compose -f docker-compose.prod.yml up -d

# 验证部署
curl https://your-domain.com/health
```

## 📚 相关文档

- [API接口文档](./docs/API_STATUS_REPORT.md)
- [数据库升级方案](./DATABASE_UPGRADE_PLAN.md)
- [系统架构文档](./docs/CURRENT_SYSTEM_STATUS.md)
- [开发指南](./docs/DEVELOPMENT.md)

## 🆘 获取帮助

### 技术支持
- 查看[故障排除](#故障排除)部分
- 检查[相关文档](#相关文档)
- 提交Issue到项目仓库

### 联系方式
- 项目维护者：[维护者信息]
- 技术支持：[技术支持邮箱]
- 项目仓库：[GitHub链接]

---

**最后更新**：2024-08-30  
**版本**：v2.0  
**状态**：🚀 准备就绪
