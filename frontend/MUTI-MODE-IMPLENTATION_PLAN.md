# 多模式小程序架构指南

## 项目概述
支持三种发布模式：
- 基础版：核心功能，轻量级部署
- 增强版：增加数据分析能力  
- 专业版：全功能企业级方案

## 目录结构
- `common/` 
  - 共享组件
  - 工具函数(utils)
  - 全局样式(styles)
  - 基础配置(config)
- `basic/` - 基础模式专属逻辑
- `plus/` - 增强模式扩展功能  
- `pro/` - 专业模式企业级模块

## 开发规范
1. 代码组织原则：
   - 优先将通用逻辑放入`common`
   - 模式差异代码隔离到对应目录
   - 通过环境变量区分构建模式

2. 条件编译示例：
```javascript
// 方式1：构建时环境变量
if (process.env.MODE === 'pro') {
  initEnterpriseFeatures() 
}

// 方式2：动态特性检测
const features = {
  analytics: MODE !== 'basic'
}
```

3. 路由配置要求：
```javascript
// routes.js
const basicRoutes = [...]
const plusRoutes = [...basicRoutes, analyticsRoute]
const proRoutes = [...plusRoutes, enterpriseRoute]
```

## 构建部署
参考 [MULTI-MODE-DEPLOYMENT.md](./MULTI-MODE-DEPLOYMENT.md)

## API对接
1. 基础模式：
   - 核心用户服务(/user)
   - 基础聊天功能(/chat)

2. 增强模式：
   - 增加数据分析API(/statistics)
   - 扩展积分系统(/points)

3. 专业模式：
   - 全量API访问权限
   - 企业级功能(/enterprise)

## 测试验证
```bash
# 运行模式兼容性测试
npm run test:modes

# 验证API调用权限
npm run test:api-access
```
