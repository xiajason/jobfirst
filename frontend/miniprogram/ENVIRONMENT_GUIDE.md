# 环境切换指南

## 概述

本指南说明如何在不同环境之间切换，以及每种环境的特点。

## 环境类型

### 1. Mock模式 (推荐用于开发)
- **配置**: `CURRENT_ENV = 'mock'`
- **特点**: 
  - 不进行网络请求
  - 直接返回Mock数据
  - 快速响应，无网络依赖
  - 适合UI开发和测试

### 2. 开发环境
- **配置**: `CURRENT_ENV = 'development'`
- **特点**:
  - 连接本地API服务器 (`http://localhost:3000`)
  - 需要启动本地服务器
  - 适合后端联调

### 3. 生产环境
- **配置**: `CURRENT_ENV = 'production'`
- **特点**:
  - 连接生产API服务器 (`https://api.adirp.com`)
  - 真实数据
  - 适合生产部署

## 切换方法

### 方法1: 修改配置文件
编辑 `config/api.js` 文件：
```javascript
// 修改这一行
const CURRENT_ENV = 'mock'        // Mock模式
const CURRENT_ENV = 'development' // 开发环境
const CURRENT_ENV = 'production'  // 生产环境
```

### 方法2: 使用构建脚本
```bash
# Mock模式构建
./build.sh -m mock

# 开发环境构建
./build.sh -m development

# 生产环境构建
./build.sh -m production
```

## 当前状态

✅ **当前环境**: Mock模式
- 无需API服务器
- 使用本地Mock数据
- 无网络请求错误

## 环境对比

| 环境 | API地址 | 数据源 | 网络依赖 | 适用场景 |
|------|---------|--------|----------|----------|
| Mock | 无 | Mock数据 | 无 | 开发、测试 |
| Development | localhost:3000 | 本地服务器 | 有 | 后端联调 |
| Production | api.adirp.com | 生产服务器 | 有 | 生产部署 |

## 使用建议

### 开发阶段
1. **UI开发**: 使用Mock模式
2. **功能测试**: 使用Mock模式
3. **后端联调**: 使用Development模式

### 测试阶段
1. **单元测试**: 使用Mock模式
2. **集成测试**: 使用Development模式
3. **端到端测试**: 使用Production模式

### 部署阶段
1. **测试环境**: 使用Development模式
2. **生产环境**: 使用Production模式

## 常见问题

### Q: 为什么选择Mock模式？
A: 
- 无需启动API服务器
- 避免网络请求错误
- 快速开发和测试
- 数据稳定可控

### Q: 如何启动本地API服务器？
A:
```bash
# 如果使用Node.js
npm install
npm run dev

# 如果使用其他框架
# 参考对应的启动文档
```

### Q: 如何添加新的Mock数据？
A:
1. 在 `config/api.js` 的 `MOCK_DATA` 中添加数据
2. 在 `utils/api.js` 的 `getMockResponse` 中添加处理逻辑

### Q: 如何调试API请求？
A:
1. 切换到Development模式
2. 启动本地API服务器
3. 查看网络请求日志
4. 使用开发者工具调试

## 最佳实践

### 1. 开发流程
```
1. 使用Mock模式开发UI
2. 使用Mock模式测试功能
3. 切换到Development模式联调
4. 切换到Production模式测试
```

### 2. 数据管理
- Mock数据要真实可信
- 定期更新Mock数据
- 保持数据结构一致

### 3. 错误处理
- 所有环境都要有错误处理
- Mock模式也要模拟错误情况
- 提供友好的错误提示

## 总结

- 当前使用Mock模式，无需API服务器
- 可以根据需要切换到其他环境
- Mock模式适合大部分开发场景
- 生产环境需要真实的API服务器
