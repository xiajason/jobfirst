# ADIRP数智招聘小程序

基于多模式架构的智能招聘小程序，支持基础版、增强版和专业版三种模式。

## 项目结构

```
miniprogram/
├── app.js                 # 小程序入口文件
├── app.json              # 小程序配置文件
├── app.wxss              # 全局样式文件
├── project.config.json   # 项目配置文件
├── pages/                # 页面目录
│   ├── index/           # 首页
│   ├── login/           # 登录页
│   ├── register/        # 注册页
│   ├── profile/         # 个人中心
│   ├── jobs/            # 职位列表
│   ├── chat/            # 聊天页面
│   ├── resume/          # 简历管理
│   ├── analytics/       # 数据分析
│   ├── enterprise/      # 企业服务
│   └── settings/        # 设置页面
├── utils/               # 工具函数
│   ├── api.js          # API接口封装
│   └── util.js         # 通用工具函数
├── components/          # 自定义组件
├── images/             # 图片资源
└── styles/             # 样式文件
```

## 多模式架构

### 基础版 (Basic)
- 核心功能：职位浏览、简历投递、基础聊天
- 适用场景：个人求职者
- 功能限制：无高级分析、无AI助手

### 增强版 (Plus)
- 包含基础版所有功能
- 新增功能：数据分析、AI聊天助手、高级搜索
- 适用场景：求职者、小型企业

### 专业版 (Pro)
- 包含增强版所有功能
- 新增功能：企业级服务、高级分析、定制化功能
- 适用场景：大型企业、HR部门

## 技术特性

### 1. 模块化设计
- 按功能模块组织代码
- 支持条件编译和按需加载
- 便于维护和扩展

### 2. 多模式支持
- 通过环境变量控制功能开关
- 动态加载不同模式的功能
- 统一的API接口设计

### 3. 性能优化
- 图片懒加载
- 数据缓存机制
- 请求防抖和节流

### 4. 用户体验
- 响应式设计
- 流畅的动画效果
- 友好的错误提示

## 开发指南

### 环境要求
- 微信开发者工具 1.06.0+
- Node.js 14.0+
- 小程序基础库 2.19.4+

### 安装依赖
```bash
# 安装微信开发者工具
# 下载地址：https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html

# 克隆项目
git clone <repository-url>
cd frontend/miniprogram
```

### 开发配置
1. 打开微信开发者工具
2. 导入项目，选择 `frontend/miniprogram` 目录
3. 配置AppID（在 `project.config.json` 中修改）
4. 配置服务器域名（在微信公众平台后台配置）

### 模式切换
在 `app.js` 中修改 `mode` 配置：
```javascript
globalData: {
  mode: 'basic', // 'basic' | 'plus' | 'pro'
  // ...
}
```

### 功能开发
1. **新增页面**：在 `pages` 目录下创建页面文件
2. **新增组件**：在 `components` 目录下创建组件
3. **API接口**：在 `utils/api.js` 中添加接口定义
4. **工具函数**：在 `utils/util.js` 中添加通用函数

### 构建部署
1. 在微信开发者工具中点击"上传"
2. 填写版本号和项目备注
3. 提交审核
4. 审核通过后发布

## API接口

### 基础接口
- `POST /auth/login` - 用户登录
- `POST /auth/register` - 用户注册
- `GET /user/info` - 获取用户信息

### 职位接口
- `GET /job/list` - 获取职位列表
- `GET /job/detail/:id` - 获取职位详情
- `POST /job/apply` - 投递简历

### 简历接口
- `GET /resume/list` - 获取简历列表
- `POST /resume/create` - 创建简历
- `PUT /resume/update` - 更新简历

### 聊天接口
- `GET /chat/list` - 获取聊天列表
- `POST /chat/send` - 发送消息
- `POST /chat/ai` - AI聊天

### 统计接口
- `GET /statistics/market` - 市场数据
- `GET /statistics/personal` - 个人数据
- `GET /statistics/enterprise` - 企业数据

## 组件说明

### 通用组件
- `JobCard` - 职位卡片组件
- `UserAvatar` - 用户头像组件
- `LoadingSpinner` - 加载动画组件
- `EmptyState` - 空状态组件

### 业务组件
- `JobFilter` - 职位筛选组件
- `ResumeForm` - 简历表单组件
- `ChatBubble` - 聊天气泡组件
- `AnalyticsChart` - 数据图表组件

## 样式规范

### 颜色规范
- 主色调：`#3cc51f` (绿色)
- 辅助色：`#667eea` (蓝色)
- 警告色：`#ff4757` (红色)
- 文字色：`#333` (深灰)

### 字体规范
- 标题：32rpx, 600
- 正文：28rpx, 400
- 说明：24rpx, 400
- 标签：20rpx, 400

### 间距规范
- 页面边距：20rpx
- 卡片内边距：30rpx
- 元素间距：20rpx
- 小间距：12rpx

## 测试指南

### 单元测试
```bash
# 运行测试
npm test

# 生成测试报告
npm run test:coverage
```

### 集成测试
1. 在微信开发者工具中打开调试模式
2. 使用真机预览功能测试
3. 检查网络请求和页面跳转

### 性能测试
1. 使用微信开发者工具的性能面板
2. 检查页面加载时间
3. 监控内存使用情况

## 部署说明

### 开发环境
- API地址：`https://dev-api.adirp.com`
- 环境标识：`development`

### 测试环境
- API地址：`https://test-api.adirp.com`
- 环境标识：`testing`

### 生产环境
- API地址：`https://api.adirp.com`
- 环境标识：`production`

## 常见问题

### Q: 如何切换模式？
A: 在 `app.js` 中修改 `globalData.mode` 的值。

### Q: 如何添加新功能？
A: 在对应目录下创建文件，并在 `app.json` 中注册页面。

### Q: 如何处理网络错误？
A: 使用 `utils/api.js` 中的统一错误处理机制。

### Q: 如何优化性能？
A: 使用懒加载、缓存机制和代码分割。

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 支持基础版功能
- 完成核心页面开发

### v1.1.0 (2024-01-15)
- 新增增强版功能
- 添加AI聊天助手
- 优化用户体验

### v1.2.0 (2024-02-01)
- 新增专业版功能
- 添加企业级服务
- 完善数据分析功能

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交代码
4. 创建 Pull Request

## 许可证

MIT License

## 联系方式

- 项目地址：https://github.com/your-org/adirp-miniprogram
- 问题反馈：https://github.com/your-org/adirp-miniprogram/issues
- 邮箱：support@adirp.com
