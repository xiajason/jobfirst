# JobFirst 初始数据参考文档

## 概述

本文档详细说明了JobFirst数据库中所有初始数据的结构、内容和用途，供二次开发参考。

## 数据统计

- **有数据的表**: 1个 (resume_templates)
- **总记录数**: 3条
- **数据类型**: 简历模板配置数据

## 简历模板数据 (resume_templates)

### 表结构
```sql
CREATE TABLE resume_templates (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    template_data JSON NOT NULL COMMENT '模板数据',
    preview_image VARCHAR(255) COMMENT '预览图',
    category VARCHAR(50) COMMENT '分类',
    is_free BOOLEAN DEFAULT TRUE COMMENT '是否免费',
    price DECIMAL(10,2) DEFAULT 0.00 COMMENT '价格',
    status ENUM('active','inactive') DEFAULT 'active' COMMENT '状态',
    preview_url VARCHAR(500) COMMENT '预览URL',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间'
);
```

### 数据详情

#### 1. 经典商务模板 (template-001)

```json
{
    "id": "template-001",
    "name": "经典商务模板",
    "description": "适合商务人士的经典简历模板",
    "template_data": {
        "sections": ["basic_info", "experience", "education", "skills"]
    },
    "category": "business",
    "is_free": true,
    "price": 0.00,
    "status": "active",
    "is_active": true,
    "created_at": "2025-08-29 09:16:59.000",
    "updated_at": "2025-08-29 09:16:59.000"
}
```

**特点**:
- **适用人群**: 商务人士、管理人员、销售人员
- **章节结构**: 基本信息 → 工作经验 → 教育背景 → 技能
- **设计风格**: 简洁、专业、正式
- **突出重点**: 工作经验和成就

#### 2. 创意设计模板 (template-002)

```json
{
    "id": "template-002",
    "name": "创意设计模板",
    "description": "适合设计师的创意简历模板",
    "template_data": {
        "sections": ["basic_info", "portfolio", "experience", "skills"]
    },
    "category": "creative",
    "is_free": true,
    "price": 0.00,
    "status": "active",
    "is_active": true,
    "created_at": "2025-08-29 09:16:59.000",
    "updated_at": "2025-08-29 09:16:59.000"
}
```

**特点**:
- **适用人群**: 设计师、创意工作者、艺术家
- **章节结构**: 基本信息 → 作品集 → 工作经验 → 技能
- **设计风格**: 创意、视觉化、个性化
- **突出重点**: 作品集和创意能力

#### 3. 技术开发模板 (template-003)

```json
{
    "id": "template-003",
    "name": "技术开发模板",
    "description": "适合程序员的专业简历模板",
    "template_data": {
        "sections": ["basic_info", "skills", "experience", "projects"]
    },
    "category": "technology",
    "is_free": true,
    "price": 0.00,
    "status": "active",
    "is_active": true,
    "created_at": "2025-08-29 09:16:59.000",
    "updated_at": "2025-08-29 09:16:59.000"
}
```

**特点**:
- **适用人群**: 程序员、开发工程师、技术专家
- **章节结构**: 基本信息 → 技能 → 工作经验 → 项目经验
- **设计风格**: 技术化、结构化、逻辑清晰
- **突出重点**: 技术技能和项目经验

## 模板数据结构分析

### template_data JSON 字段说明

```json
{
    "sections": ["basic_info", "experience", "education", "skills"]
}
```

**支持的章节类型**:
- `basic_info`: 基本信息（姓名、联系方式、个人简介等）
- `experience`: 工作经验（公司、职位、时间、职责等）
- `education`: 教育背景（学校、专业、学历、时间等）
- `skills`: 技能特长（技术技能、软技能、语言能力等）
- `portfolio`: 作品集（设计作品、项目展示等）
- `projects`: 项目经验（项目名称、技术栈、成果等）

### 分类系统 (category)

- `business`: 商务类（适合商务、管理、销售等职位）
- `creative`: 创意类（适合设计、艺术、创意等职位）
- `technology`: 技术类（适合开发、技术、工程等职位）

## 积分规则参考数据

### 建议的积分规则结构

```sql
-- 积分规则表结构
CREATE TABLE points_rules (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '规则名称',
    source VARCHAR(50) UNIQUE NOT NULL COMMENT '来源',
    points BIGINT NOT NULL COMMENT '积分数量',
    description TEXT COMMENT '描述',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    daily_limit BIGINT COMMENT '每日限制',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
);
```

### 推荐的积分规则

| 规则ID | 规则名称 | 来源 | 积分 | 描述 | 每日限制 |
|--------|----------|------|------|------|----------|
| rule-001 | 注册奖励 | register | 100 | 新用户注册奖励 | 1 |
| rule-002 | 每日登录 | daily_login | 10 | 每日登录奖励 | 1 |
| rule-003 | 创建简历 | create_resume | 50 | 创建新简历奖励 | 5 |
| rule-004 | 分享简历 | share_resume | 20 | 分享简历奖励 | 10 |
| rule-005 | 下载模板 | download_template | -10 | 下载付费模板消费 | 无限制 |

## 数据使用建议

### 1. 模板扩展建议

#### 添加新模板
```sql
INSERT INTO resume_templates (id, name, description, template_data, category, is_free, price, status) VALUES
('template-004', '学术研究模板', '适合学术研究人员的专业简历模板', '{"sections": ["basic_info", "education", "research", "publications", "skills"]}', 'academic', 1, 0, 'active');
```

#### 模板分类扩展
- `academic`: 学术类（研究人员、教师、学者）
- `medical`: 医疗类（医生、护士、医疗工作者）
- `legal`: 法律类（律师、法务、法律工作者）
- `finance`: 金融类（金融分析师、会计师、投资顾问）

### 2. 章节类型扩展

#### 新增章节类型
```json
{
    "sections": [
        "basic_info",
        "experience", 
        "education",
        "skills",
        "certifications",  // 新增：证书认证
        "languages",       // 新增：语言能力
        "volunteer",       // 新增：志愿服务
        "awards"           // 新增：获奖情况
    ]
}
```

### 3. 数据迁移建议

#### 保留现有数据
```sql
-- 备份现有模板数据
CREATE TABLE resume_templates_backup AS SELECT * FROM resume_templates;

-- 导入新模板数据
INSERT INTO resume_templates (id, name, description, template_data, category, is_free, price, status)
SELECT id, name, description, template_data, category, is_free, price, status
FROM resume_templates_backup
WHERE id NOT IN (SELECT id FROM resume_templates);
```

#### 数据验证
```sql
-- 验证模板数据完整性
SELECT 
    id,
    name,
    JSON_VALID(template_data) as is_valid_json,
    JSON_LENGTH(template_data, '$.sections') as sections_count
FROM resume_templates
WHERE status = 'active' AND is_active = 1;
```

## 开发参考

### 1. 前端模板渲染

```javascript
// 根据模板数据渲染简历
function renderResume(templateData, userData) {
    const sections = templateData.sections;
    let html = '';
    
    sections.forEach(section => {
        switch(section) {
            case 'basic_info':
                html += renderBasicInfo(userData.basicInfo);
                break;
            case 'experience':
                html += renderExperience(userData.experience);
                break;
            case 'education':
                html += renderEducation(userData.education);
                break;
            case 'skills':
                html += renderSkills(userData.skills);
                break;
            // ... 其他章节
        }
    });
    
    return html;
}
```

### 2. 模板选择逻辑

```javascript
// 根据用户职业推荐模板
function recommendTemplate(userProfession) {
    const professionMap = {
        'developer': 'technology',
        'designer': 'creative',
        'manager': 'business',
        'researcher': 'academic'
    };
    
    const category = professionMap[userProfession] || 'business';
    
    return resumeTemplates.find(template => 
        template.category === category && 
        template.is_active && 
        template.status === 'active'
    );
}
```

### 3. 积分系统集成

```javascript
// 积分规则应用
function applyPointsRule(userId, action) {
    const rule = pointsRules.find(r => r.source === action && r.is_active);
    
    if (rule) {
        // 检查每日限制
        if (rule.daily_limit) {
            const todayUsage = getTodayUsage(userId, action);
            if (todayUsage >= rule.daily_limit) {
                return { success: false, message: '今日已达到限制' };
            }
        }
        
        // 应用积分
        return addPoints(userId, rule.points, action, rule.description);
    }
    
    return { success: false, message: '未找到对应规则' };
}
```

## 总结

这些初始数据为JobFirst简历中心系统提供了：

1. **基础模板框架**: 3个不同风格的简历模板
2. **分类体系**: 商务、创意、技术三大分类
3. **章节结构**: 灵活可配置的简历章节
4. **积分规则**: 完整的用户激励体系

在二次开发中，您可以：
- 基于这些模板扩展更多样式
- 根据业务需求调整章节结构
- 扩展积分规则和奖励机制
- 添加更多分类和模板类型

这些数据为系统的核心功能提供了良好的起点，支持灵活的定制和扩展。
