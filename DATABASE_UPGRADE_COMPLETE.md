# ADIRP数智招聘系统 - 完整数据库升级方案

## 📊 系统分析

### 前端需求
基于小程序API接口，需要支持：
- 用户认证和授权
- 职位搜索和管理
- 简历创建和管理
- 聊天系统
- 积分系统
- 通知系统

### 后端Common模块需求
基于common模块分析，需要支持：
- **用户管理**：多租户用户系统
- **权限控制**：基于角色的访问控制
- **审计日志**：操作审计和追踪
- **缓存管理**：Redis缓存支持
- **文件存储**：文件上传和管理
- **消息队列**：异步任务处理
- **配置管理**：动态配置系统
- **监控统计**：系统监控和统计

## 🎯 数据库架构设计

### 1. 用户认证与权限模块

#### 1.1 users - 用户基础表
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    openid VARCHAR(100) UNIQUE COMMENT '微信openid',
    unionid VARCHAR(100) UNIQUE COMMENT '微信unionid',
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    password_hash VARCHAR(255) COMMENT '密码哈希',
    avatar_url VARCHAR(500) COMMENT '头像URL',
    nickname VARCHAR(50) COMMENT '昵称',
    real_name VARCHAR(50) COMMENT '真实姓名',
    gender ENUM('male', 'female', 'other') COMMENT '性别',
    birth_date DATE COMMENT '出生日期',
    location VARCHAR(100) COMMENT '所在地',
    status ENUM('inactive', 'active', 'suspended', 'deleted') DEFAULT 'inactive' COMMENT '用户状态',
    user_type ENUM('jobseeker', 'recruiter', 'admin') DEFAULT 'jobseeker' COMMENT '用户类型',
    certification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending' COMMENT '认证状态',
    last_login_at DATETIME COMMENT '最后登录时间',
    login_count INT DEFAULT 0 COMMENT '登录次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    INDEX idx_openid (openid),
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_user_type (user_type),
    INDEX idx_created_at (created_at)
);
```

#### 1.2 user_profiles - 用户详细资料表
```sql
CREATE TABLE user_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    education_level ENUM('high_school', 'college', 'bachelor', 'master', 'phd') COMMENT '学历',
    work_experience INT COMMENT '工作年限',
    current_position VARCHAR(100) COMMENT '当前职位',
    expected_salary_min INT COMMENT '期望薪资下限',
    expected_salary_max INT COMMENT '期望薪资上限',
    skills JSON COMMENT '技能标签',
    self_introduction TEXT COMMENT '自我介绍',
    resume_count INT DEFAULT 0 COMMENT '简历数量',
    application_count INT DEFAULT 0 COMMENT '投递次数',
    favorite_count INT DEFAULT 0 COMMENT '收藏数量',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_education_level (education_level),
    INDEX idx_work_experience (work_experience)
);
```

#### 1.3 roles - 角色表
```sql
CREATE TABLE roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL COMMENT '角色名称',
    code VARCHAR(50) UNIQUE NOT NULL COMMENT '角色代码',
    description TEXT COMMENT '角色描述',
    permissions JSON COMMENT '权限列表',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_code (code),
    INDEX idx_status (status)
);
```

#### 1.4 user_roles - 用户角色关联表
```sql
CREATE TABLE user_roles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    role_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_role (user_id, role_id),
    INDEX idx_user_id (user_id),
    INDEX idx_role_id (role_id)
);
```

#### 1.5 permissions - 权限表
```sql
CREATE TABLE permissions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '权限名称',
    code VARCHAR(100) UNIQUE NOT NULL COMMENT '权限代码',
    description TEXT COMMENT '权限描述',
    resource VARCHAR(100) COMMENT '资源',
    action VARCHAR(50) COMMENT '操作',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_code (code),
    INDEX idx_resource (resource),
    INDEX idx_status (status)
);
```

### 2. 企业管理模块

#### 2.1 companies - 企业基础表
```sql
CREATE TABLE companies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL COMMENT '企业名称',
    short_name VARCHAR(100) COMMENT '企业简称',
    logo_url VARCHAR(500) COMMENT '企业logo',
    industry VARCHAR(100) COMMENT '所属行业',
    company_size ENUM('startup', 'small', 'medium', 'large', 'enterprise') COMMENT '企业规模',
    location VARCHAR(200) COMMENT '企业地址',
    website VARCHAR(200) COMMENT '企业官网',
    description TEXT COMMENT '企业描述',
    founded_year INT COMMENT '成立年份',
    business_license VARCHAR(100) COMMENT '营业执照号',
    status ENUM('pending', 'verified', 'rejected', 'suspended') DEFAULT 'pending' COMMENT '认证状态',
    verification_level ENUM('basic', 'premium', 'vip') DEFAULT 'basic' COMMENT '认证等级',
    job_count INT DEFAULT 0 COMMENT '发布职位数',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    INDEX idx_name (name),
    INDEX idx_industry (industry),
    INDEX idx_location (location),
    INDEX idx_status (status),
    INDEX idx_verification_level (verification_level),
    INDEX idx_created_at (created_at)
);
```

#### 2.2 company_profiles - 企业详细资料表
```sql
CREATE TABLE company_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    contact_person VARCHAR(50) COMMENT '联系人',
    contact_phone VARCHAR(20) COMMENT '联系电话',
    contact_email VARCHAR(100) COMMENT '联系邮箱',
    business_scope TEXT COMMENT '经营范围',
    company_culture TEXT COMMENT '企业文化',
    benefits JSON COMMENT '福利待遇',
    photos JSON COMMENT '企业照片',
    social_media JSON COMMENT '社交媒体',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    INDEX idx_company_id (company_id)
);
```

### 3. 职位管理模块

#### 3.1 job_categories - 职位分类表
```sql
CREATE TABLE job_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '分类名称',
    parent_id BIGINT UNSIGNED NULL COMMENT '父分类ID',
    level INT DEFAULT 1 COMMENT '分类层级',
    sort_order INT DEFAULT 0 COMMENT '排序',
    icon VARCHAR(100) COMMENT '分类图标',
    description TEXT COMMENT '分类描述',
    job_count INT DEFAULT 0 COMMENT '职位数量',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_id) REFERENCES job_categories(id) ON DELETE SET NULL,
    INDEX idx_parent_id (parent_id),
    INDEX idx_level (level),
    INDEX idx_sort_order (sort_order),
    INDEX idx_status (status)
);
```

#### 3.2 jobs - 职位表
```sql
CREATE TABLE jobs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company_id BIGINT UNSIGNED NOT NULL,
    category_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(200) NOT NULL COMMENT '职位标题',
    job_type ENUM('full_time', 'part_time', 'internship', 'contract') DEFAULT 'full_time' COMMENT '工作类型',
    location VARCHAR(200) NOT NULL COMMENT '工作地点',
    salary_min INT COMMENT '薪资下限',
    salary_max INT COMMENT '薪资上限',
    salary_type ENUM('monthly', 'yearly', 'hourly') DEFAULT 'monthly' COMMENT '薪资类型',
    experience_required ENUM('entry', 'junior', 'mid', 'senior', 'expert') COMMENT '经验要求',
    education_required ENUM('high_school', 'college', 'bachelor', 'master', 'phd') COMMENT '学历要求',
    description TEXT NOT NULL COMMENT '职位描述',
    requirements TEXT COMMENT '任职要求',
    benefits TEXT COMMENT '福利待遇',
    skills JSON COMMENT '技能要求',
    tags JSON COMMENT '职位标签',
    status ENUM('draft', 'published', 'paused', 'closed') DEFAULT 'draft' COMMENT '职位状态',
    priority INT DEFAULT 0 COMMENT '优先级',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    application_count INT DEFAULT 0 COMMENT '投递次数',
    favorite_count INT DEFAULT 0 COMMENT '收藏次数',
    publish_at DATETIME COMMENT '发布时间',
    expire_at DATETIME COMMENT '过期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES job_categories(id) ON DELETE CASCADE,
    INDEX idx_company_id (company_id),
    INDEX idx_category_id (category_id),
    INDEX idx_location (location),
    INDEX idx_salary_min (salary_min),
    INDEX idx_salary_max (salary_max),
    INDEX idx_experience_required (experience_required),
    INDEX idx_education_required (education_required),
    INDEX idx_status (status),
    INDEX idx_publish_at (publish_at),
    INDEX idx_expire_at (expire_at),
    INDEX idx_created_at (created_at),
    FULLTEXT idx_search (title, description, requirements)
);
```

#### 3.3 job_applications - 职位投递表
```sql
CREATE TABLE job_applications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    job_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    resume_id BIGINT UNSIGNED NOT NULL,
    cover_letter TEXT COMMENT '求职信',
    status ENUM('pending', 'reviewing', 'interview', 'accepted', 'rejected') DEFAULT 'pending' COMMENT '投递状态',
    hr_feedback TEXT COMMENT 'HR反馈',
    interview_time DATETIME COMMENT '面试时间',
    interview_location VARCHAR(200) COMMENT '面试地点',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (resume_id) REFERENCES resumes(id) ON DELETE CASCADE,
    UNIQUE KEY uk_job_user (job_id, user_id),
    INDEX idx_job_id (job_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);
```

### 4. 简历管理模块

#### 4.1 resume_templates - 简历模板表
```sql
CREATE TABLE resume_templates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    preview_image VARCHAR(500) COMMENT '预览图片',
    template_data JSON NOT NULL COMMENT '模板数据',
    category VARCHAR(50) COMMENT '模板分类',
    is_free BOOLEAN DEFAULT FALSE COMMENT '是否免费',
    price DECIMAL(10,2) DEFAULT 0.00 COMMENT '价格',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    use_count INT DEFAULT 0 COMMENT '使用次数',
    rating DECIMAL(3,2) DEFAULT 0.00 COMMENT '评分',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_is_free (is_free),
    INDEX idx_status (status),
    INDEX idx_rating (rating)
);
```

#### 4.2 resumes - 简历表
```sql
CREATE TABLE resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    template_id BIGINT UNSIGNED NULL,
    title VARCHAR(200) NOT NULL COMMENT '简历标题',
    content JSON NOT NULL COMMENT '简历内容',
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft' COMMENT '简历状态',
    is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认简历',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    share_count INT DEFAULT 0 COMMENT '分享次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES resume_templates(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_template_id (template_id),
    INDEX idx_status (status),
    INDEX idx_is_default (is_default),
    INDEX idx_created_at (created_at)
);
```

### 5. 聊天系统模块

#### 5.1 chats - 聊天会话表
```sql
CREATE TABLE chats (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    company_id BIGINT UNSIGNED NOT NULL,
    job_id BIGINT UNSIGNED NULL,
    chat_type ENUM('job_inquiry', 'application_follow', 'general') DEFAULT 'general' COMMENT '聊天类型',
    status ENUM('active', 'archived', 'blocked') DEFAULT 'active' COMMENT '聊天状态',
    last_message_at DATETIME COMMENT '最后消息时间',
    unread_count INT DEFAULT 0 COMMENT '未读消息数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE SET NULL,
    UNIQUE KEY uk_user_company_job (user_id, company_id, job_id),
    INDEX idx_user_id (user_id),
    INDEX idx_company_id (company_id),
    INDEX idx_job_id (job_id),
    INDEX idx_status (status),
    INDEX idx_last_message_at (last_message_at)
);
```

#### 5.2 messages - 消息表
```sql
CREATE TABLE messages (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    chat_id BIGINT UNSIGNED NOT NULL,
    sender_id BIGINT UNSIGNED NOT NULL,
    sender_type ENUM('user', 'company') NOT NULL COMMENT '发送者类型',
    message_type ENUM('text', 'image', 'file', 'system') DEFAULT 'text' COMMENT '消息类型',
    content TEXT NOT NULL COMMENT '消息内容',
    file_url VARCHAR(500) COMMENT '文件URL',
    file_name VARCHAR(200) COMMENT '文件名',
    file_size BIGINT COMMENT '文件大小',
    is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
    read_at DATETIME COMMENT '阅读时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_chat_id (chat_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_sender_type (sender_type),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);
```

### 6. 积分系统模块

#### 6.1 points - 用户积分表
```sql
CREATE TABLE points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    balance INT DEFAULT 0 COMMENT '积分余额',
    total_earned INT DEFAULT 0 COMMENT '累计获得积分',
    total_spent INT DEFAULT 0 COMMENT '累计消费积分',
    level VARCHAR(20) DEFAULT 'bronze' COMMENT '积分等级',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_balance (balance),
    INDEX idx_level (level)
);
```

#### 6.2 point_records - 积分记录表
```sql
CREATE TABLE point_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    points INT NOT NULL COMMENT '积分变动',
    type ENUM('earn', 'spend') NOT NULL COMMENT '类型',
    reason VARCHAR(100) NOT NULL COMMENT '原因',
    description TEXT COMMENT '详细描述',
    reference_id VARCHAR(100) COMMENT '关联ID',
    reference_type VARCHAR(50) COMMENT '关联类型',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_reason (reason),
    INDEX idx_created_at (created_at)
);
```

### 7. 系统配置模块

#### 7.1 banners - 轮播图表
```sql
CREATE TABLE banners (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL COMMENT '标题',
    image_url VARCHAR(500) NOT NULL COMMENT '图片URL',
    link_url VARCHAR(500) COMMENT '链接URL',
    link_type ENUM('internal', 'external') DEFAULT 'internal' COMMENT '链接类型',
    sort_order INT DEFAULT 0 COMMENT '排序',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    start_time DATETIME COMMENT '开始时间',
    end_time DATETIME COMMENT '结束时间',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    click_count INT DEFAULT 0 COMMENT '点击次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_sort_order (sort_order),
    INDEX idx_status (status),
    INDEX idx_start_time (start_time),
    INDEX idx_end_time (end_time)
);
```

#### 7.2 notifications - 通知表
```sql
CREATE TABLE notifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL COMMENT '用户ID，NULL表示全局通知',
    title VARCHAR(200) NOT NULL COMMENT '通知标题',
    content TEXT NOT NULL COMMENT '通知内容',
    type ENUM('system', 'job', 'application', 'chat') DEFAULT 'system' COMMENT '通知类型',
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal' COMMENT '优先级',
    is_read BOOLEAN DEFAULT FALSE COMMENT '是否已读',
    read_at DATETIME COMMENT '阅读时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_priority (priority),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);
```

### 8. Common模块专用表

#### 8.1 audit_logs - 审计日志表
```sql
CREATE TABLE audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL COMMENT '用户ID',
    username VARCHAR(50) COMMENT '用户名',
    action VARCHAR(100) NOT NULL COMMENT '操作',
    resource VARCHAR(100) COMMENT '资源',
    resource_id VARCHAR(100) COMMENT '资源ID',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    status INT DEFAULT 200 COMMENT '状态码',
    message TEXT COMMENT '消息',
    request_data JSON COMMENT '请求数据',
    response_data JSON COMMENT '响应数据',
    execution_time INT COMMENT '执行时间(ms)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_resource (resource),
    INDEX idx_ip (ip),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);
```

#### 8.2 system_configs - 系统配置表
```sql
CREATE TABLE system_configs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL COMMENT '配置键',
    config_value TEXT COMMENT '配置值',
    config_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '配置类型',
    description TEXT COMMENT '配置描述',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    is_encrypted BOOLEAN DEFAULT FALSE COMMENT '是否加密',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_config_key (config_key),
    INDEX idx_is_public (is_public)
);
```

#### 8.3 file_records - 文件记录表
```sql
CREATE TABLE file_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    file_name VARCHAR(255) NOT NULL COMMENT '文件名',
    original_name VARCHAR(255) NOT NULL COMMENT '原始文件名',
    file_type VARCHAR(50) NOT NULL COMMENT '文件类型',
    mime_type VARCHAR(100) COMMENT 'MIME类型',
    size BIGINT NOT NULL COMMENT '文件大小',
    extension VARCHAR(20) COMMENT '文件扩展名',
    storage_type ENUM('local', 's3', 'oss', 'cos') DEFAULT 'local' COMMENT '存储类型',
    storage_path VARCHAR(500) NOT NULL COMMENT '存储路径',
    storage_url VARCHAR(500) COMMENT '访问URL',
    md5_hash VARCHAR(32) UNIQUE COMMENT 'MD5哈希',
    sha256_hash VARCHAR(64) COMMENT 'SHA256哈希',
    status ENUM('uploading', 'completed', 'failed', 'deleted') DEFAULT 'uploading' COMMENT '状态',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    download_count BIGINT DEFAULT 0 COMMENT '下载次数',
    view_count BIGINT DEFAULT 0 COMMENT '浏览次数',
    metadata JSON COMMENT '元数据',
    expires_at DATETIME COMMENT '过期时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_file_type (file_type),
    INDEX idx_storage_type (storage_type),
    INDEX idx_status (status),
    INDEX idx_md5_hash (md5_hash),
    INDEX idx_created_at (created_at)
);
```

#### 8.4 message_queue - 消息队列表
```sql
CREATE TABLE message_queue (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    topic VARCHAR(100) NOT NULL COMMENT '主题',
    message_id VARCHAR(100) UNIQUE NOT NULL COMMENT '消息ID',
    data JSON NOT NULL COMMENT '消息数据',
    status ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending' COMMENT '状态',
    retry_count INT DEFAULT 0 COMMENT '重试次数',
    max_retries INT DEFAULT 3 COMMENT '最大重试次数',
    scheduled_at DATETIME COMMENT '计划执行时间',
    processed_at DATETIME COMMENT '处理时间',
    error_message TEXT COMMENT '错误信息',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_topic (topic),
    INDEX idx_status (status),
    INDEX idx_scheduled_at (scheduled_at),
    INDEX idx_created_at (created_at)
);
```

#### 8.5 cache_records - 缓存记录表
```sql
CREATE TABLE cache_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cache_key VARCHAR(255) UNIQUE NOT NULL COMMENT '缓存键',
    cache_value LONGTEXT COMMENT '缓存值',
    cache_type ENUM('redis', 'memory', 'local') DEFAULT 'redis' COMMENT '缓存类型',
    ttl INT DEFAULT 3600 COMMENT '过期时间(秒)',
    hits INT DEFAULT 0 COMMENT '命中次数',
    misses INT DEFAULT 0 COMMENT '未命中次数',
    size BIGINT DEFAULT 0 COMMENT '大小(字节)',
    is_compressed BOOLEAN DEFAULT FALSE COMMENT '是否压缩',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at DATETIME COMMENT '过期时间',
    
    INDEX idx_cache_key (cache_key),
    INDEX idx_cache_type (cache_type),
    INDEX idx_expires_at (expires_at),
    INDEX idx_created_at (created_at)
);
```

#### 8.6 session_records - 会话记录表
```sql
CREATE TABLE session_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(100) UNIQUE NOT NULL COMMENT '会话ID',
    user_id BIGINT UNSIGNED NULL COMMENT '用户ID',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    data JSON COMMENT '会话数据',
    status ENUM('active', 'expired', 'terminated') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at DATETIME COMMENT '过期时间',
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_expires_at (expires_at),
    INDEX idx_created_at (created_at)
);
```

## 🚀 性能优化策略

### 1. 索引优化
- **复合索引**：针对常用查询组合
- **覆盖索引**：减少回表查询
- **前缀索引**：优化长字符串字段
- **全文索引**：支持职位搜索

### 2. 分表策略
- **按时间分表**：audit_logs、messages表按月分表
- **按用户分表**：user_behaviors表按用户ID分表
- **按公司分表**：company_jobs表按公司ID分表

### 3. 缓存策略
- **Redis缓存**：热点数据缓存
- **CDN加速**：静态资源加速
- **数据库缓存**：查询结果缓存

### 4. 读写分离
- **主从复制**：读写分离架构
- **读写权重**：智能路由
- **故障转移**：自动切换

## 📋 升级实施计划

### 阶段一：基础架构升级（1-2周）
1. **数据库设计**：完成新表结构设计
2. **索引优化**：创建必要的索引
3. **数据迁移**：迁移现有数据
4. **API适配**：更新后端API

### 阶段二：性能优化（1周）
1. **缓存部署**：Redis缓存配置
2. **读写分离**：主从数据库配置
3. **监控部署**：性能监控系统
4. **压力测试**：性能测试验证

### 阶段三：功能完善（1周）
1. **数据填充**：填充测试数据
2. **功能测试**：完整功能测试
3. **性能调优**：根据测试结果调优
4. **文档完善**：更新技术文档

## 🔧 技术栈升级

### 数据库技术
- **主数据库**：MySQL 8.0+
- **缓存数据库**：Redis 6.0+
- **搜索引擎**：Elasticsearch 7.x
- **监控工具**：Prometheus + Grafana

### 后端技术
- **框架升级**：Go 1.21+
- **ORM优化**：GORM v2
- **API网关**：Kong 3.x
- **消息队列**：RabbitMQ

### 部署架构
- **容器化**：Docker + Kubernetes
- **CI/CD**：GitHub Actions
- **监控告警**：Prometheus + AlertManager
- **日志管理**：ELK Stack

## 📊 预期效果

### 性能提升
- **查询速度**：提升80%以上
- **并发能力**：支持1000+并发用户
- **响应时间**：平均响应时间<100ms
- **系统稳定性**：99.9%可用性

### 功能完善
- **数据完整性**：支持所有前端功能
- **实时性**：实时数据更新
- **扩展性**：支持业务快速扩展
- **可维护性**：代码结构清晰

---

**升级计划制定时间：** 2024-08-30  
**预计完成时间：** 4-5周  
**负责人：** 后端开发团队  
**状态：** 🚀 准备开始实施
