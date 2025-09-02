# JobFirst Web 端

基于 Next.js 的多模式智能求职平台，支持基础版、增强版和专业版三种部署模式。

## 🏗️ 架构特性

### 多模式支持
- **基础版 (Basic)**: 核心功能，轻量级部署
- **增强版 (Plus)**: 增加数据分析能力
- **专业版 (Pro)**: 全功能企业级方案

### 技术栈
- **框架**: Next.js 15.3.0 + React 19
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **测试**: Jest + Playwright
- **部署**: Docker + Docker Compose

## 🚀 快速开始

### 开发环境

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 设置模式 (可选)
export NEXT_PUBLIC_MODE=basic  # basic, plus, pro
```

### 构建部署

```bash
# 构建特定模式
./scripts/build-modes.sh basic   # 基础版
./scripts/build-modes.sh plus    # 增强版
./scripts/build-modes.sh pro     # 专业版

# 构建所有模式
./scripts/build-modes.sh all
```

### Docker 部署

```bash
# 构建镜像
docker build -t jobfirst-web .

# 运行容器
docker run -p 3000:3000 -e NEXT_PUBLIC_MODE=basic jobfirst-web
```

## 📁 项目结构

```
frontend/web/
├── app/                    # Next.js App Router
│   ├── layout.tsx         # 根布局
│   ├── page.tsx           # 首页
│   └── dashboard/         # 仪表板
├── components/            # React 组件
│   ├── common/           # 通用组件
│   │   ├── ModeProvider.tsx    # 模式提供者
│   │   └── FeatureGate.tsx     # 特性门控
│   ├── home/             # 首页组件
│   ├── dashboard/        # 仪表板组件
│   └── ui/               # UI 组件库
├── config/               # 配置文件
│   └── modes.ts          # 多模式配置
├── lib/                  # 工具库
│   └── api.ts            # API 客户端
├── scripts/              # 构建脚本
│   └── build-modes.sh    # 多模式构建脚本
└── public/               # 静态资源
```

## 🔧 模式配置

### 环境变量

```bash
# 设置当前模式
NEXT_PUBLIC_MODE=basic    # basic, plus, pro

# API 配置
NEXT_PUBLIC_API_URL=https://api.adirp.com
```

### 模式特性

| 功能 | 基础版 | 增强版 | 专业版 |
|------|--------|--------|--------|
| 用户注册登录 | ✅ | ✅ | ✅ |
| 基础简历管理 | ✅ | ✅ | ✅ |
| 职位搜索 | ✅ | ✅ | ✅ |
| AI简历优化 | ❌ | ✅ | ✅ |
| 智能职位推荐 | ❌ | ✅ | ✅ |
| 积分系统 | ❌ | ✅ | ✅ |
| 企业级管理 | ❌ | ❌ | ✅ |
| 团队协作 | ❌ | ❌ | ✅ |
| API集成 | ❌ | ❌ | ✅ |

## 🎯 核心组件

### ModeProvider
模式状态管理，提供模式切换和特性检查功能。

```tsx
import { useMode } from '@/components/common/ModeProvider';

function MyComponent() {
  const { currentMode, hasFeature, switchMode } = useMode();
  
  return (
    <div>
      <p>当前模式: {currentMode}</p>
      {hasFeature('AI简历优化') && <AIFeature />}
    </div>
  );
}
```

### FeatureGate
条件渲染组件，根据模式特性显示或隐藏功能。

```tsx
import { FeatureGate } from '@/components/common/FeatureGate';

function MyPage() {
  return (
    <div>
      <h1>基础功能</h1>
      
      <FeatureGate feature="AI简历优化">
        <AIFeature />
      </FeatureGate>
      
      <FeatureGate 
        feature="企业级管理" 
        showUpgradePrompt={true}
      >
        <EnterpriseFeature />
      </FeatureGate>
    </div>
  );
}
```

## 🔌 API 集成

### API 客户端
支持多模式权限控制的 API 客户端。

```tsx
import { apiClient, authApi, resumeApi } from '@/lib/api';

// 登录
const response = await authApi.login('13800138000', 'password');

// 获取简历列表
const resumes = await resumeApi.getList();

// 上传文件
const result = await apiClient.upload('/api/v1/resume/upload', file);
```

### 权限控制
API 客户端会自动检查当前模式是否有权限访问特定端点。

```tsx
// 如果当前模式不支持此API，会抛出错误
try {
  const aiResponse = await aiApi.chat('优化简历');
} catch (error) {
  console.log('当前模式不支持AI功能');
}
```

## 🧪 测试

```bash
# 单元测试
npm test

# 集成测试
npm run test:e2e

# 测试覆盖率
npm run test:coverage
```

## 📊 性能优化

### 构建优化
- 代码分割
- 图片优化
- 缓存策略
- 预加载

### 运行时优化
- 组件懒加载
- 虚拟滚动
- 内存管理
- 网络请求优化

## 🔒 安全特性

- JWT 认证
- API 权限控制
- XSS 防护
- CSRF 防护
- 输入验证

## 📈 监控和日志

- 性能监控
- 错误追踪
- 用户行为分析
- 系统健康检查

## 🚀 部署指南

### 生产环境

1. **构建应用**
   ```bash
   ./scripts/build-modes.sh pro
   ```

2. **配置环境变量**
   ```bash
   export NEXT_PUBLIC_MODE=pro
   export NEXT_PUBLIC_API_URL=https://api.adirp.com
   ```

3. **启动服务**
   ```bash
   cd dist/pro_*
   docker-compose up -d
   ```

### 多模式部署

```bash
# 构建所有模式
./scripts/build-modes.sh all

# 部署所有模式
cd dist
./deploy-all.sh
```

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 📄 许可证

MIT License

## 📞 支持

- 文档: [https://docs.jobfirst.com](https://docs.jobfirst.com)
- 邮箱: support@jobfirst.com
- 社区: [https://community.jobfirst.com](https://community.jobfirst.com)

---

**版本**: v2.0  
**更新时间**: 2025年8月31日  
**维护团队**: JobFirst开发团队
