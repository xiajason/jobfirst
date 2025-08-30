# API 认证规则文档

## 📋 概述

本文档定义了JobFirst系统中所有API的认证规则，明确区分哪些API需要用户登录认证，哪些可以公开访问。

## 🔐 认证方式

### 支持的认证方式
1. **Bearer Token**: `Authorization: Bearer <token>`
2. **Access Token**: `accessToken: <token>` (兼容原有系统)
3. **测试Token**: `test-token` 或 `wx-token-123` (开发环境)

### 认证中间件
- 位置: `backend/user/main.go` 中的 `authMiddleware()`
- 功能: 验证token并设置用户上下文

## 📊 API路由分类

### 🟢 公开API (无需认证)

#### 系统健康检查
- `GET /health` - 服务健康检查
- `GET /metrics` - 监控指标
- `GET /v1/.well-known/metrics` - 监控指标
- `GET /swagger/*` - API文档

#### 用户认证相关
- `POST /api/v2/auth/login` - 用户登录
- `POST /api/v2/auth/register` - 用户注册
- `GET /api/v2/auth/check` - 检查登录状态

#### 公开内容展示
- `GET /api/v2/jobs/` - 获取职位列表
- `GET /api/v2/jobs/:id` - 获取职位详情
- `GET /api/v2/jobs/search` - 搜索职位
- `GET /api/v2/companies/` - 获取企业列表
- `GET /api/v2/companies/:id` - 获取企业详情
- `GET /api/v2/banners/` - 获取轮播图

### 🔴 需要认证的API

#### 用户个人中心
- `GET /api/v2/user/profile` - 获取用户资料
- `PUT /api/v2/user/profile` - 更新用户资料
- `POST /api/v2/user/logout` - 用户登出

#### 职位申请相关
- `POST /api/v2/jobs/:id/apply` - 申请职位
- `GET /api/v2/jobs/applications` - 获取申请记录

#### 聊天系统
- `GET /api/v2/chat/sessions` - 获取聊天会话列表
- `GET /api/v2/chat/sessions/:sessionId/messages` - 获取聊天消息
- `POST /api/v2/chat/sessions/:sessionId/messages` - 发送消息
- `PUT /api/v2/chat/sessions/:sessionId/messages/:messageId/read` - 标记消息已读
- `POST /api/v2/chat/sessions` - 创建聊天会话

#### 积分系统
- `GET /api/v2/points/balance` - 获取积分余额
- `GET /api/v2/points/records` - 获取积分记录
- `GET /api/v2/points/rules` - 获取积分规则
- `POST /api/v2/points/exchange` - 积分兑换
- `GET /api/v2/points/exchanges` - 获取兑换历史

#### 通知系统
- `GET /api/v2/notifications/` - 获取通知列表
- `GET /api/v2/notifications/:id` - 获取通知详情
- `PUT /api/v2/notifications/:id/read` - 标记通知已读
- `PUT /api/v2/notifications/read-all` - 标记所有通知已读
- `GET /api/v2/notifications/settings` - 获取通知设置
- `PUT /api/v2/notifications/settings` - 更新通知设置
- `GET /api/v2/notifications/templates` - 获取通知模板
- `POST /api/v2/notifications/send` - 发送通知

## 🔄 兼容性API (v1)

### 公开API (v1)
- `POST /api/v1/user/auth/login` - 用户登录
- `GET /api/v1/user/auth/check` - 检查登录状态
- `GET /api/v1/user/auth/phone` - 获取用户手机号
- `GET /api/v1/user/auth/idkey` - 获取用户ID Key
- `POST /api/v1/user/auth/certification` - 用户认证
- `POST /api/v1/user/auth/logout` - 用户登出
- `GET /api/v1/user/auth/myidkey` - 获取我的用户ID Key
- `POST /api/v1/user/auth/unsubscribe` - 用户注销
- `GET /api/v1/public/home/banners` - 获取首页横幅
- `GET /api/v1/public/home/notifications` - 获取首页通知
- `POST /api/v1/public/authentication/login` - 认证登录
- `POST /api/v1/public/authentication/check` - 认证检查
- `GET /api/v1/public/authentication/getUserPhone` - 获取用户手机号
- `POST /api/v1/public/authentication/getUserIdKey` - 获取用户ID Key
- `POST /api/v1/public/authentication/certification` - 认证
- `POST /api/v1/public/authentication/logout` - 登出
- `GET /api/v1/public/authentication/getMyUserIdKey` - 获取我的用户ID Key
- `POST /api/v1/public/authentication/cancellation` - 注销

### 需要认证的API (v1)
- `GET /api/v1/mine/info` - 获取我的信息
- `GET /api/v1/mine/points` - 获取我的积分
- `GET /api/v1/mine/points/bill` - 获取积分账单
- `GET /api/v1/mine/approve/history` - 获取审批历史
- `GET /api/v1/mine/view/history` - 获取查看历史
- `GET /api/v1/mine/certification` - 获取认证状态
- `PUT /api/v1/mine/avatar` - 更新头像
- `GET /api/v1/approve/list` - 获取审批列表
- `POST /api/v1/approve/handle/:id` - 处理审批
- `GET /api/v1/chat/usual` - 获取常用聊天
- `POST /api/v1/chat/send` - 发送聊天消息
- `GET /api/v1/job/favoriteList` - 获取收藏职位列表
- `GET /api/v1/job/applyList` - 获取申请职位列表
- `GET /api/v1/notice/list` - 获取通知列表
- `POST /api/v1/notice/read` - 标记通知已读
- `GET /api/v1/notice/detail/:id` - 获取通知详情
- `POST /api/v1/approve/submit` - 提交认证
- `GET /api/v1/approve/status` - 获取认证状态
- `GET /api/v1/integral/list` - 获取积分列表
- `POST /api/v1/integral/exchange` - 积分兑换
- `POST /api/v1/common/upload` - 文件上传
- `GET /api/v1/common/config` - 获取配置
- `GET /api/v1/common/region` - 获取地区列表
- `GET /api/v1/common/category` - 获取分类列表

## 🛡️ 安全规则

### 白名单规则
1. **健康检查**: 所有 `/health` 和 `/metrics` 端点
2. **API文档**: 所有 `/swagger/*` 端点
3. **公开内容**: 职位、企业、轮播图等展示内容
4. **用户认证**: 登录、注册等认证相关API

### 认证要求
1. **个人数据**: 所有涉及用户个人数据的API都需要认证
2. **操作类API**: 申请、聊天、积分兑换等操作类API需要认证
3. **管理功能**: 通知管理、设置管理等需要认证

### 错误处理
- **401 Unauthorized**: 未提供token或token无效
- **403 Forbidden**: token有效但权限不足
- **100001**: 原有系统的登录过期错误码
- **100002**: 原有系统的token无效错误码

## 📝 实施建议

### 前端集成
1. 在请求拦截器中自动添加认证头
2. 处理401错误，跳转到登录页面
3. 支持token刷新机制

### 后端实施
1. 使用中间件统一处理认证
2. 在需要认证的路由组上应用 `authMiddleware()`
3. 保持向后兼容性

### 测试策略
1. 使用测试token进行开发调试
2. 编写认证相关的单元测试
3. 进行API权限测试

## 🔄 迁移计划

### 第一阶段
- 保持现有v1 API不变
- 新增v2 API，明确认证规则
- 前端逐步迁移到v2 API

### 第二阶段
- 完善v2 API功能
- 优化认证机制
- 添加更细粒度的权限控制

### 第三阶段
- 逐步废弃v1 API
- 统一使用v2 API
- 完善安全机制
