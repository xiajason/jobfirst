# 路由重构计划

## 当前问题
1. 路由组织混乱，公开API和需要认证的API混在一起
2. 缺乏明确的认证中间件应用
3. 白名单规则不清晰

## 重构方案

### 1. 白名单路由 (无需认证)
- `/health` - 健康检查
- `/metrics` - 监控指标
- `/swagger/*` - API文档

### 2. 公开API路由组 (无需认证)
- `/api/v2/auth/*` - 用户认证相关
- `/api/v2/jobs/*` - 职位展示相关
- `/api/v2/companies/*` - 企业展示相关
- `/api/v2/banners/*` - 轮播图相关

### 3. 需要认证的API路由组
- `/api/v2/user/*` - 用户个人中心
- `/api/v2/jobs/applications` - 职位申请相关
- `/api/v2/chat/*` - 聊天系统
- `/api/v2/points/*` - 积分系统
- `/api/v2/notifications/*` - 通知系统

### 4. 兼容性API (v1)
- 保持现有v1 API不变
- 逐步迁移到v2 API

## 实施步骤
1. 重新组织路由结构
2. 应用认证中间件
3. 测试API访问权限
4. 更新前端调用
