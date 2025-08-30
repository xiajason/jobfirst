# JobFirst 开发环境指南

## 🚀 快速开始

### 一键启动开发环境
```bash
./quick-start.sh
```

### 手动启动
```bash
./scripts/dev-start.sh start
```

## 🔧 开发环境特性

### ✨ 热加载支持
- 使用 `air` 实现 Go 服务热加载
- 修改代码后自动重新编译和重启服务
- 无需手动重启服务

### 🎯 后台运行
- 所有微服务在后台运行
- 不占用终端，可以继续其他操作
- 支持日志查看和状态监控

### 📊 服务管理
- 统一的服务启动、停止、重启
- 实时状态监控
- 日志集中管理

## 📋 常用命令

### 服务管理
```bash
# 启动所有服务
./scripts/dev-start.sh start

# 停止所有服务
./scripts/dev-start.sh stop

# 查看服务状态
./scripts/dev-start.sh status

# 重启指定服务
./scripts/dev-start.sh restart user
./scripts/dev-start.sh restart resume
./scripts/dev-start.sh restart gateway
```

### 日志查看
```bash
# 查看所有日志文件
./scripts/dev-start.sh logs

# 查看指定服务日志
./scripts/dev-start.sh logs user
./scripts/dev-start.sh logs gateway

# 实时查看日志
tail -f logs/user.log
```

### 帮助信息
```bash
./scripts/dev-start.sh help
```

## 🌐 服务访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| API 网关 | http://localhost:8080 | 统一 API 入口 |
| 用户服务 | http://localhost:8081 | 用户管理服务 |
| 简历服务 | http://localhost:8087 | 简历管理服务 |
| 积分服务 | http://localhost:8086 | 积分管理服务 |
| 统计服务 | http://localhost:8097 | 数据统计服务 |
| 存储服务 | http://localhost:8088 | 文件存储服务 |
| 管理端服务 | http://localhost:8003 | 管理端服务 |
| 个人端服务 | http://localhost:6001 | 个人端服务 |
| 企业端服务 | http://localhost:8002 | 企业端服务 |
| 资源服务 | http://localhost:9002 | 资源服务 |
| 开放API服务 | http://localhost:9006 | 开放API服务 |
| Consul UI | http://localhost:8202 | 服务发现管理 |
| MySQL | localhost:8200 | 数据库 |
| Redis | localhost:8201 | 缓存 |

## 🔍 API 测试

### 健康检查
```bash
# 网关健康检查
curl http://localhost:8080/health

# 用户服务健康检查
curl http://localhost:8081/health

# 简历服务健康检查
curl http://localhost:8087/health
```

### API 测试
```bash
# 获取首页横幅
curl http://localhost:8081/api/v1/public/home/banners

# 获取通知
curl http://localhost:8081/api/v1/public/home/notifications

# 用户登录
curl -X POST http://localhost:8081/api/v1/public/authentication/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'
```

## 🛠️ 开发工作流

### 1. 启动开发环境
```bash
./quick-start.sh
```

### 2. 修改代码
- 直接修改 `backend/` 目录下的代码
- air 会自动检测文件变化
- 服务会自动重新编译和重启

### 3. 测试 API
- 使用 curl 或 Postman 测试 API
- 查看服务日志了解运行状态

### 4. 查看日志
```bash
# 查看实时日志
./scripts/dev-start.sh logs user

# 查看错误日志
tail -f logs/user.log | grep ERROR
```

## 📁 项目结构

```
jobfirst/
├── backend/                 # 后端微服务
│   ├── user/               # 用户服务
│   ├── resume/             # 简历服务
│   ├── points/             # 积分服务
│   ├── statistics/         # 统计服务
│   ├── storage/            # 存储服务
│   ├── gateway/            # API 网关
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
│   ├── web/               # Web 应用
│   └── miniprogram-4/     # 小程序
├── scripts/               # 脚本文件
│   └── dev-start.sh       # 开发环境管理脚本
├── logs/                  # 日志文件
├── docker-compose.yml     # Docker 编排文件
└── quick-start.sh         # 快速启动脚本
```

## 🔧 故障排除

### 端口被占用
```bash
# 查看端口占用
lsof -i :8081

# 杀死占用进程
lsof -ti:8081 | xargs kill -9
```

### 服务启动失败
```bash
# 查看服务日志
./scripts/dev-start.sh logs user

# 重启服务
./scripts/dev-start.sh restart user
```

### 热加载不工作
```bash
# 检查 air 是否安装
which air

# 重新安装 air
go install github.com/air-verse/air@latest
```

## 🎯 开发建议

1. **使用热加载**：充分利用 air 的热加载功能，提高开发效率
2. **查看日志**：经常查看服务日志，及时发现问题
3. **API 测试**：使用 curl 或 Postman 测试 API 功能
4. **状态监控**：使用 `./scripts/dev-start.sh status` 监控服务状态
5. **代码规范**：遵循 Go 代码规范，保持代码整洁

## 📞 技术支持

如果遇到问题，请：
1. 查看服务日志：`./scripts/dev-start.sh logs <service>`
2. 检查服务状态：`./scripts/dev-start.sh status`
3. 重启服务：`./scripts/dev-start.sh restart <service>`
4. 查看帮助：`./scripts/dev-start.sh help`
