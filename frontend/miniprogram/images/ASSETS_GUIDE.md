# 图片资源说明

## 概述

本目录包含小程序使用的所有图片资源文件。

## 当前资源

### 轮播图
- **banner1.svg** - 智能招聘轮播图
- **banner2.svg** - AI助手轮播图

### 行业图标
- **industry/internet.svg** - 互联网行业图标
- **industry/finance.svg** - 金融行业图标
- **industry/education.svg** - 教育行业图标

## 文件格式

### SVG格式优势
- **矢量图形**: 无损缩放
- **文件小**: 比位图更小
- **可编辑**: 易于修改颜色和样式
- **兼容性好**: 现代浏览器都支持

### 设计规范
- **轮播图**: 400x200px
- **行业图标**: 64x64px
- **颜色方案**: 使用项目主题色

## 使用方法

### 在WXML中使用
```xml
<image src="/images/banner1.svg" mode="aspectFit"></image>
```

### 在JS中引用
```javascript
const imagePath = '/images/industry/internet.svg'
```

### 在WXSS中引用
```css
.background {
  background-image: url('/images/banner1.svg');
}
```

## 添加新图片

### 1. 创建SVG文件
```svg
<svg width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="32" r="30" fill="#667eea"/>
  <text x="32" y="38" text-anchor="middle" fill="white" font-size="12">
    图标文字
  </text>
</svg>
```

### 2. 更新代码引用
```javascript
// 在 config/api.js 中更新Mock数据
banners: [
  {
    id: 3,
    image: '/images/banner3.svg',
    title: '新轮播图',
    link: '/pages/new/new'
  }
]
```

### 3. 更新默认数据
```javascript
// 在页面JS中更新默认数据
getDefaultBanners() {
  return [
    {
      id: 1,
      image: '/images/banner1.svg',
      title: '轮播图1'
    }
  ]
}
```

## 最佳实践

### 1. 文件命名
- 使用小写字母
- 用连字符分隔单词
- 使用描述性名称

### 2. 文件组织
- 按功能分类存放
- 使用子目录组织
- 保持目录结构清晰

### 3. 性能优化
- 使用SVG格式
- 控制文件大小
- 避免重复资源

## 颜色方案

### 主题色
- **主色**: #667eea (蓝色)
- **辅色**: #764ba2 (紫色)
- **成功色**: #28a745 (绿色)
- **警告色**: #ffc107 (黄色)

### 使用示例
```svg
<rect fill="#667eea"/>  <!-- 主色 -->
<rect fill="#764ba2"/>  <!-- 辅色 -->
<rect fill="#28a745"/>  <!-- 成功色 -->
<rect fill="#ffc107"/>  <!-- 警告色 -->
```

## 注意事项

1. **文件路径**: 确保路径正确
2. **文件格式**: 优先使用SVG
3. **文件大小**: 控制单个文件大小
4. **兼容性**: 测试不同设备显示效果

## 总结

- 当前使用SVG格式图片
- 文件结构清晰，易于维护
- 支持无损缩放和颜色修改
- 符合项目设计规范
