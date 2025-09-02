# JobFirst 设计系统

## 🎯 设计系统概述

JobFirst 设计系统采用 **设计令牌 (Design Tokens)** + **代码生成** 的方式实现跨平台组件共享。

### 核心理念
- **设计统一**: 通过设计令牌确保视觉一致性
- **代码生成**: 基于设计令牌自动生成各平台代码
- **API统一**: 通过统一的组件API确保功能一致性

## 🏗️ 架构设计

```
设计令牌 (Design Tokens)
        ↓
   代码生成器
        ↓
┌─────────────┬─────────────┐
│  小程序端   │   Web端     │
│  (WXML)     │  (React)    │
└─────────────┴─────────────┘
```

## 📋 设计令牌定义

### 1. 颜色系统
```json
{
  "colors": {
    "primary": {
      "50": "#eff6ff",
      "500": "#3b82f6",
      "600": "#2563eb",
      "700": "#1d4ed8"
    },
    "gray": {
      "50": "#f9fafb",
      "100": "#f3f4f6",
      "500": "#6b7280",
      "900": "#111827"
    }
  }
}
```

### 2. 间距系统
```json
{
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px",
    "lg": "24px",
    "xl": "32px"
  }
}
```

### 3. 字体系统
```json
{
  "typography": {
    "h1": {
      "fontSize": "32px",
      "fontWeight": "600",
      "lineHeight": "1.2"
    },
    "body": {
      "fontSize": "16px",
      "fontWeight": "400",
      "lineHeight": "1.5"
    }
  }
}
```

## 🔧 组件API规范

### 统一组件接口
```typescript
// 按钮组件API
interface ButtonProps {
  // 通用属性
  text: string;
  type: 'primary' | 'secondary' | 'danger';
  size: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  
  // 事件处理
  onClick?: () => void;
  
  // 样式定制
  className?: string;
  style?: object;
}

// 输入框组件API
interface InputProps {
  // 通用属性
  value: string;
  placeholder?: string;
  type: 'text' | 'password' | 'email' | 'number';
  disabled?: boolean;
  
  // 事件处理
  onChange?: (value: string) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  
  // 验证
  required?: boolean;
  error?: string;
}
```

## 🚀 代码生成策略

### 1. 小程序端生成
```javascript
// 生成的按钮组件 (小程序)
Component({
  properties: {
    text: { type: String, value: '' },
    type: { type: String, value: 'primary' },
    size: { type: String, value: 'medium' },
    disabled: { type: Boolean, value: false },
    loading: { type: Boolean, value: false }
  },
  
  methods: {
    handleClick() {
      if (!this.data.disabled && !this.data.loading) {
        this.triggerEvent('click');
      }
    }
  }
});
```

### 2. Web端生成
```typescript
// 生成的按钮组件 (React)
export const Button: React.FC<ButtonProps> = ({
  text,
  type = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  onClick,
  className,
  style
}) => {
  const handleClick = () => {
    if (!disabled && !loading && onClick) {
      onClick();
    }
  };

  return (
    <button
      className={`btn btn-${type} btn-${size} ${className || ''}`}
      style={style}
      disabled={disabled || loading}
      onClick={handleClick}
    >
      {loading ? <Spinner /> : text}
    </button>
  );
};
```

## 📁 项目结构

```
frontend/shared/
├── design-system/
│   ├── tokens/              # 设计令牌
│   │   ├── colors.json
│   │   ├── spacing.json
│   │   ├── typography.json
│   │   └── components.json
│   ├── generators/          # 代码生成器
│   │   ├── miniprogram/     # 小程序代码生成
│   │   ├── web/            # Web代码生成
│   │   └── index.js        # 生成器入口
│   ├── templates/          # 代码模板
│   │   ├── miniprogram/    # 小程序模板
│   │   └── web/           # Web模板
│   └── components/         # 组件定义
│       ├── Button/
│       ├── Input/
│       └── Card/
├── miniprogram/            # 生成的小程序组件
└── web/                   # 生成的Web组件
```

## 🛠️ 实现步骤

### 步骤1: 设计令牌定义
```bash
# 创建设计令牌
mkdir -p frontend/shared/design-system/tokens
touch frontend/shared/design-system/tokens/{colors,spacing,typography,components}.json
```

### 步骤2: 代码生成器
```bash
# 创建代码生成器
mkdir -p frontend/shared/design-system/generators
touch frontend/shared/design-system/generators/index.js
```

### 步骤3: 组件模板
```bash
# 创建组件模板
mkdir -p frontend/shared/design-system/templates/{miniprogram,web}
```

### 步骤4: 自动化脚本
```bash
# 创建生成脚本
touch frontend/shared/scripts/generate-components.sh
```

## 📝 使用示例

### 1. 定义组件
```json
// components.json
{
  "Button": {
    "props": {
      "text": { "type": "string", "required": true },
      "type": { "type": "enum", "values": ["primary", "secondary", "danger"], "default": "primary" },
      "size": { "type": "enum", "values": ["small", "medium", "large"], "default": "medium" }
    },
    "events": ["click"],
    "styles": {
      "primary": { "backgroundColor": "colors.primary.500" },
      "secondary": { "backgroundColor": "colors.gray.100" }
    }
  }
}
```

### 2. 生成代码
```bash
# 生成所有组件
npm run generate:components

# 生成特定组件
npm run generate:component Button
```

### 3. 使用组件
```typescript
// Web端使用
import { Button } from '@/shared/web/components/Button';

<Button text="提交" type="primary" onClick={handleSubmit} />

// 小程序端使用
<button text="提交" type="primary" bind:click="handleSubmit" />
```

## 🎯 优势

### 1. 设计一致性
- 统一的设计令牌确保视觉一致性
- 自动生成的样式避免手动维护

### 2. 开发效率
- 一次定义，多端生成
- 减少重复开发工作

### 3. 维护性
- 集中管理组件定义
- 统一的API规范

### 4. 扩展性
- 易于添加新平台支持
- 灵活的模板系统

## 🔄 工作流程

1. **设计阶段**: 定义设计令牌和组件API
2. **生成阶段**: 运行代码生成器
3. **集成阶段**: 将生成的组件集成到各平台
4. **测试阶段**: 验证各平台功能一致性
5. **迭代阶段**: 根据需求调整设计令牌

---

**设计系统状态**: 🚀 准备实施  
**下一步**: 创建设计令牌和代码生成器
