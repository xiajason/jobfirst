#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 颜色输出
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// 加载设计令牌
function loadTokens() {
  const tokensDir = path.join(__dirname, '../tokens');
  const tokens = {};
  
  const tokenFiles = ['colors.json', 'spacing.json', 'typography.json', 'components.json'];
  
  tokenFiles.forEach(file => {
    const filePath = path.join(tokensDir, file);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      const data = JSON.parse(content);
      Object.assign(tokens, data);
    }
  });
  
  return tokens;
}

// 生成小程序组件
function generateMiniprogramComponent(componentName, componentDef, tokens) {
  const template = generateMiniprogramTemplate(componentName, componentDef, tokens);
  const script = generateMiniprogramScript(componentName, componentDef);
  const style = generateMiniprogramStyle(componentName, componentDef, tokens);
  
  return { template, script, style };
}

// 生成小程序模板
function generateMiniprogramTemplate(componentName, componentDef, tokens) {
  const props = Object.keys(componentDef.props || {});
  const events = componentDef.events || [];
  
  let template = `<view class="${componentName.toLowerCase()}">\n`;
  
  if (componentName === 'Button') {
    template += `  <button 
    class="btn btn-{{type}} btn-{{size}} {{block ? 'btn-block' : ''}} {{disabled ? 'btn-disabled' : ''}}"
    disabled="{{disabled || loading}}"
    bind:tap="handleClick"
  >
    <view wx:if="{{loading}}" class="loading-spinner"></view>
    <text>{{text}}</text>
  </button>\n`;
  } else if (componentName === 'Input') {
    template += `  <view class="input-wrapper">
    <input 
      class="input {{error ? 'input-error' : ''}} {{disabled ? 'input-disabled' : ''}}"
      value="{{value}}"
      placeholder="{{placeholder}}"
      type="{{type}}"
      disabled="{{disabled}}"
      readonly="{{readonly}}"
      bind:input="handleInput"
      bind:focus="handleFocus"
      bind:blur="handleBlur"
    />
    <view wx:if="{{clearable && value}}" class="clear-btn" bind:tap="handleClear">×</view>
    <view wx:if="{{error}}" class="error-message">{{error}}</view>
  </view>\n`;
  } else if (componentName === 'Card') {
    template += `  <view class="card card-{{shadow}} {{bordered ? 'card-bordered' : ''}}">
    <view wx:if="{{title || subtitle}}" class="card-header">
      <view wx:if="{{title}}" class="card-title">{{title}}</view>
      <view wx:if="{{subtitle}}" class="card-subtitle">{{subtitle}}</view>
    </view>
    <view class="card-body card-padding-{{padding}}">
      <slot></slot>
    </view>
  </view>\n`;
  }
  
  template += '</view>';
  return template;
}

// 生成小程序脚本
function generateMiniprogramScript(componentName, componentDef) {
  const props = componentDef.props || {};
  const events = componentDef.events || [];
  
  let script = `Component({
  properties: {\n`;
  
  Object.entries(props).forEach(([propName, propDef]) => {
    const type = propDef.type === 'boolean' ? 'Boolean' : 'String';
    const defaultValue = propDef.default !== undefined ? `, value: ${JSON.stringify(propDef.default)}` : '';
    script += `    ${propName}: { type: ${type}${defaultValue} },\n`;
  });
  
  script += `  },
  
  methods: {\n`;
  
  if (componentName === 'Button') {
    script += `    handleClick() {
      if (!this.data.disabled && !this.data.loading) {
        this.triggerEvent('click');
      }
    },\n`;
  } else if (componentName === 'Input') {
    script += `    handleInput(e) {
      this.triggerEvent('change', { value: e.detail.value });
    },
    handleFocus() {
      this.triggerEvent('focus');
    },
    handleBlur() {
      this.triggerEvent('blur');
    },
    handleClear() {
      this.triggerEvent('clear');
      this.triggerEvent('change', { value: '' });
    },\n`;
  }
  
  script += `  }
});`;
  
  return script;
}

// 生成小程序样式
function generateMiniprogramStyle(componentName, componentDef, tokens) {
  let style = '';
  
  if (componentName === 'Button') {
    style = `
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  padding: 8px 16px;
}

.btn-primary {
  background-color: ${tokens.colors.primary[500]};
  color: white;
  border-color: ${tokens.colors.primary[500]};
}

.btn-secondary {
  background-color: ${tokens.colors.gray[100]};
  color: ${tokens.colors.gray[700]};
  border-color: ${tokens.colors.gray[300]};
}

.btn-success {
  background-color: ${tokens.colors.success[500]};
  color: white;
  border-color: ${tokens.colors.success[500]};
}

.btn-warning {
  background-color: ${tokens.colors.warning[500]};
  color: white;
  border-color: ${tokens.colors.warning[500]};
}

.btn-danger {
  background-color: ${tokens.colors.danger[500]};
  color: white;
  border-color: ${tokens.colors.danger[500]};
}

.btn-small {
  padding: 4px 12px;
  font-size: 12px;
}

.btn-large {
  padding: 12px 20px;
  font-size: 16px;
}

.btn-block {
  width: 100%;
}

.btn-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 8px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}`;
  } else if (componentName === 'Input') {
    style = `
.input-wrapper {
  position: relative;
}

.input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid ${tokens.colors.gray[300]};
  border-radius: 6px;
  font-size: 14px;
  background-color: white;
  transition: border-color 0.2s;
}

.input:focus {
  outline: none;
  border-color: ${tokens.colors.primary[500]};
}

.input-error {
  border-color: ${tokens.colors.danger[500]};
}

.input-disabled {
  background-color: ${tokens.colors.gray[50]};
  border-color: ${tokens.colors.gray[200]};
  cursor: not-allowed;
}

.clear-btn {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: ${tokens.colors.gray[400]};
  font-size: 16px;
}

.error-message {
  color: ${tokens.colors.danger[500]};
  font-size: 12px;
  margin-top: 4px;
}`;
  } else if (componentName === 'Card') {
    style = `
.card {
  background-color: white;
  border-radius: 8px;
  overflow: hidden;
}

.card-bordered {
  border: 1px solid ${tokens.colors.gray[200]};
}

.card-shadow-small {
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.card-shadow-medium {
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.card-shadow-large {
  box-shadow: 0 10px 15px rgba(0, 0, 0, 0.1);
}

.card-header {
  padding: 16px;
  border-bottom: 1px solid ${tokens.colors.gray[200]};
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: ${tokens.colors.gray[900]};
}

.card-subtitle {
  font-size: 14px;
  color: ${tokens.colors.gray[500]};
  margin-top: 4px;
}

.card-body {
  padding: 16px;
}

.card-padding-none {
  padding: 0;
}

.card-padding-small {
  padding: 8px;
}

.card-padding-large {
  padding: 24px;
}`;
  }
  
  return style;
}

// 生成Web组件
function generateWebComponent(componentName, componentDef, tokens) {
  const component = generateReactComponent(componentName, componentDef, tokens);
  const types = generateTypeScriptTypes(componentName, componentDef);
  const styles = generateWebStyles(componentName, componentDef, tokens);
  
  return { component, types, styles };
}

// 生成React组件
function generateReactComponent(componentName, componentDef, tokens) {
  const props = componentDef.props || {};
  const events = componentDef.events || [];
  
  let component = `import React from 'react';
import './${componentName}.module.css';

export interface ${componentName}Props {\n`;
  
  Object.entries(props).forEach(([propName, propDef]) => {
    const type = propDef.type === 'boolean' ? 'boolean' : 
                 propDef.type === 'enum' ? `'${propDef.values.join("' | '")}'` : 'string';
    const required = propDef.required ? '' : '?';
    component += `  ${propName}${required}: ${type};\n`;
  });
  
  events.forEach(event => {
    component += `  on${event.charAt(0).toUpperCase() + event.slice(1)}?: () => void;\n`;
  });
  
  component += `}

export const ${componentName}: React.FC<${componentName}Props> = ({\n`;
  
  Object.keys(props).forEach(propName => {
    const propDef = props[propName];
    const defaultValue = propDef.default !== undefined ? ` = ${JSON.stringify(propDef.default)}` : '';
    component += `  ${propName}${defaultValue},\n`;
  });
  
  events.forEach(event => {
    component += `  on${event.charAt(0).toUpperCase() + event.slice(1)},\n`;
  });
  
  component += `}) => {\n`;
  
  if (componentName === 'Button') {
    component += `  const handleClick = () => {
    if (!disabled && !loading && on${events[0].charAt(0).toUpperCase() + events[0].slice(1)}) {
      on${events[0].charAt(0).toUpperCase() + events[0].slice(1)}();
    }
  };

  return (
    <button
      className={\`btn btn-\${type} btn-\${size} \${block ? 'btn-block' : ''} \${disabled ? 'btn-disabled' : ''}\`}
      disabled={disabled || loading}
      onClick={handleClick}
    >
      {loading && <div className="loading-spinner" />}
      <span>{text}</span>
    </button>
  );\n`;
  } else if (componentName === 'Input') {
    component += `  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (onChange) {
      onChange(e.target.value);
    }
  };

  const handleClear = () => {
    if (onClear) {
      onClear();
    }
  };

  return (
    <div className="input-wrapper">
      <input
        className={\`input \${error ? 'input-error' : ''} \${disabled ? 'input-disabled' : ''}\`}
        value={value}
        placeholder={placeholder}
        type={type}
        disabled={disabled}
        readOnly={readonly}
        onChange={handleChange}
        onFocus={onFocus}
        onBlur={onBlur}
      />
      {clearable && value && (
        <button className="clear-btn" onClick={handleClear}>
          ×
        </button>
      )}
      {error && <div className="error-message">{error}</div>}
    </div>
  );\n`;
  } else if (componentName === 'Card') {
    component += `  return (
    <div className={\`card card-\${shadow} \${bordered ? 'card-bordered' : ''}\`}>
      {(title || subtitle) && (
        <div className="card-header">
          {title && <div className="card-title">{title}</div>}
          {subtitle && <div className="card-subtitle">{subtitle}</div>}
        </div>
      )}
      <div className={\`card-body card-padding-\${padding}\`}>
        {/* Slot content would go here */}
      </div>
    </div>
  );\n`;
  }
  
  component += `};\n`;
  
  return component;
}

// 生成TypeScript类型
function generateTypeScriptTypes(componentName, componentDef) {
  const props = componentDef.props || {};
  
  let types = `export interface ${componentName}Props {\n`;
  
  Object.entries(props).forEach(([propName, propDef]) => {
    const type = propDef.type === 'boolean' ? 'boolean' : 
                 propDef.type === 'enum' ? `'${propDef.values.join("' | '")}'` : 'string';
    const required = propDef.required ? '' : '?';
    types += `  ${propName}${required}: ${type};\n`;
  });
  
  types += `}\n`;
  
  return types;
}

// 生成Web样式
function generateWebStyles(componentName, componentDef, tokens) {
  let styles = '';
  
  if (componentName === 'Button') {
    styles = `
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  padding: 8px 16px;
}

.btn-primary {
  background-color: ${tokens.colors.primary[500]};
  color: white;
  border-color: ${tokens.colors.primary[500]};
}

.btn-secondary {
  background-color: ${tokens.colors.gray[100]};
  color: ${tokens.colors.gray[700]};
  border-color: ${tokens.colors.gray[300]};
}

.btn-success {
  background-color: ${tokens.colors.success[500]};
  color: white;
  border-color: ${tokens.colors.success[500]};
}

.btn-warning {
  background-color: ${tokens.colors.warning[500]};
  color: white;
  border-color: ${tokens.colors.warning[500]};
}

.btn-danger {
  background-color: ${tokens.colors.danger[500]};
  color: white;
  border-color: ${tokens.colors.danger[500]};
}

.btn-small {
  padding: 4px 12px;
  font-size: 12px;
}

.btn-large {
  padding: 12px 20px;
  font-size: 16px;
}

.btn-block {
  width: 100%;
}

.btn-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 8px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}`;
  }
  
  return styles;
}

// 写入文件
function writeComponentFiles(componentName, miniprogramComponent, webComponent, outputDir) {
  const miniprogramDir = path.join(outputDir, 'miniprogram', componentName.toLowerCase());
  const webDir = path.join(outputDir, 'web', componentName);
  
  // 创建目录
  fs.mkdirSync(miniprogramDir, { recursive: true });
  fs.mkdirSync(webDir, { recursive: true });
  
  // 写入小程序文件
  fs.writeFileSync(path.join(miniprogramDir, `${componentName.toLowerCase()}.wxml`), miniprogramComponent.template);
  fs.writeFileSync(path.join(miniprogramDir, `${componentName.toLowerCase()}.js`), miniprogramComponent.script);
  fs.writeFileSync(path.join(miniprogramDir, `${componentName.toLowerCase()}.wxss`), miniprogramComponent.style);
  
  // 写入Web文件
  fs.writeFileSync(path.join(webDir, `${componentName}.tsx`), webComponent.component);
  fs.writeFileSync(path.join(webDir, `${componentName}.types.ts`), webComponent.types);
  fs.writeFileSync(path.join(webDir, `${componentName}.module.css`), webComponent.styles);
  
  log(`✅ 生成 ${componentName} 组件完成`, 'green');
}

// 主函数
function main() {
  const args = process.argv.slice(2);
  const componentName = args[0];
  
  if (!componentName) {
    log('❌ 请指定组件名称', 'red');
    log('用法: node index.js <component-name>', 'yellow');
    process.exit(1);
  }
  
  log(`🚀 开始生成 ${componentName} 组件...`, 'blue');
  
  try {
    // 加载设计令牌
    const tokens = loadTokens();
    
    if (!tokens.components || !tokens.components[componentName]) {
      log(`❌ 组件 ${componentName} 未在设计令牌中定义`, 'red');
      process.exit(1);
    }
    
    const componentDef = tokens.components[componentName];
    
    // 生成组件
    const miniprogramComponent = generateMiniprogramComponent(componentName, componentDef, tokens);
    const webComponent = generateWebComponent(componentName, componentDef, tokens);
    
    // 输出目录
    const outputDir = path.join(__dirname, '../../');
    
    // 写入文件
    writeComponentFiles(componentName, miniprogramComponent, webComponent, outputDir);
    
    log(`🎉 ${componentName} 组件生成完成！`, 'green');
    log(`📁 小程序组件: ${outputDir}/miniprogram/${componentName.toLowerCase()}/`, 'cyan');
    log(`📁 Web组件: ${outputDir}/web/${componentName}/`, 'cyan');
    
  } catch (error) {
    log(`❌ 生成失败: ${error.message}`, 'red');
    process.exit(1);
  }
}

// 运行生成器
if (require.main === module) {
  main();
}

module.exports = {
  generateMiniprogramComponent,
  generateWebComponent,
  loadTokens
};
