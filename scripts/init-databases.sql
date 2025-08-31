-- JobFirst数据库初始化脚本
-- 用于创建和初始化所有数据库表结构

-- ========================================
-- MySQL 核心业务数据库初始化
-- ========================================

USE jobfirst;

-- 1. 用户管理模块
CREATE TABLE IF NOT EXISTS users (
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
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active' COMMENT '用户状态',
    user_type ENUM('jobseeker', 'recruiter', 'admin') DEFAULT 'jobseeker' COMMENT '用户类型',
    certification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending' COMMENT '认证状态',
    last_login_at DATETIME COMMENT '最后登录时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    INDEX idx_openid (openid),
    INDEX idx_phone (phone),
    INDEX idx_email (email),
    INDEX idx_status (status),
    INDEX idx_user_type (user_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 2. 用户详细资料表
CREATE TABLE IF NOT EXISTS user_profiles (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户详细资料表';

-- 3. 简历管理模块
CREATE TABLE IF NOT EXISTS resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL COMMENT '简历标题',
    content JSON COMMENT '简历内容',
    template_id BIGINT UNSIGNED COMMENT '模板ID',
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft' COMMENT '简历状态',
    is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认简历',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历表';

-- 4. 简历模板表
CREATE TABLE IF NOT EXISTS resume_templates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    template_data JSON NOT NULL COMMENT '模板数据',
    preview_image VARCHAR(500) COMMENT '预览图片',
    category VARCHAR(50) COMMENT '模板分类',
    is_free BOOLEAN DEFAULT TRUE COMMENT '是否免费',
    price DECIMAL(10,2) DEFAULT 0.00 COMMENT '价格',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历模板表';

-- 5. 职位管理模块
CREATE TABLE IF NOT EXISTS jobs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL COMMENT '职位标题',
    company_id BIGINT UNSIGNED COMMENT '公司ID',
    company_name VARCHAR(200) COMMENT '公司名称',
    description TEXT COMMENT '职位描述',
    requirements JSON COMMENT '职位要求',
    salary_min INT COMMENT '最低薪资',
    salary_max INT COMMENT '最高薪资',
    salary_type ENUM('monthly', 'yearly', 'hourly') DEFAULT 'monthly' COMMENT '薪资类型',
    location VARCHAR(100) COMMENT '工作地点',
    job_type ENUM('full_time', 'part_time', 'internship', 'contract') DEFAULT 'full_time' COMMENT '工作类型',
    experience_level ENUM('entry', 'junior', 'mid', 'senior', 'lead') COMMENT '经验要求',
    education_level ENUM('high_school', 'college', 'bachelor', 'master', 'phd') COMMENT '学历要求',
    skills JSON COMMENT '技能要求',
    benefits JSON COMMENT '福利待遇',
    status ENUM('active', 'closed', 'draft') DEFAULT 'active' COMMENT '职位状态',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    application_count INT DEFAULT 0 COMMENT '申请次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    
    INDEX idx_company_id (company_id),
    INDEX idx_location (location),
    INDEX idx_status (status),
    INDEX idx_salary_min (salary_min),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='职位表';

-- 6. 积分系统模块
CREATE TABLE IF NOT EXISTS points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    balance INT DEFAULT 0 COMMENT '积分余额',
    total_earned INT DEFAULT 0 COMMENT '累计获得积分',
    total_spent INT DEFAULT 0 COMMENT '累计消费积分',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_user_id (user_id),
    INDEX idx_balance (balance)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户积分表';

-- 7. 积分记录表
CREATE TABLE IF NOT EXISTS point_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    type ENUM('earn', 'spend') NOT NULL COMMENT '积分类型',
    amount INT NOT NULL COMMENT '积分数量',
    reason VARCHAR(100) NOT NULL COMMENT '积分原因',
    description TEXT COMMENT '详细描述',
    related_id BIGINT UNSIGNED COMMENT '关联ID',
    related_type VARCHAR(50) COMMENT '关联类型',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分记录表';

-- 8. 文件存储模块
CREATE TABLE IF NOT EXISTS files (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    filename VARCHAR(255) NOT NULL COMMENT '文件名',
    original_filename VARCHAR(255) NOT NULL COMMENT '原始文件名',
    file_path VARCHAR(500) NOT NULL COMMENT '文件路径',
    file_size BIGINT NOT NULL COMMENT '文件大小(字节)',
    mime_type VARCHAR(100) COMMENT 'MIME类型',
    file_type ENUM('image', 'document', 'video', 'audio', 'other') COMMENT '文件类型',
    status ENUM('active', 'deleted') DEFAULT 'active' COMMENT '文件状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_file_type (file_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件表';

-- 9. 统计分析模块
CREATE TABLE IF NOT EXISTS statistics (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL COMMENT '统计日期',
    user_count INT DEFAULT 0 COMMENT '用户数量',
    resume_count INT DEFAULT 0 COMMENT '简历数量',
    job_count INT DEFAULT 0 COMMENT '职位数量',
    application_count INT DEFAULT 0 COMMENT '申请数量',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uk_date (date),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统计数据表';

-- 10. 用户行为表
CREATE TABLE IF NOT EXISTS user_behaviors (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    action VARCHAR(50) NOT NULL COMMENT '行为类型',
    target_type VARCHAR(50) COMMENT '目标类型',
    target_id BIGINT UNSIGNED COMMENT '目标ID',
    metadata JSON COMMENT '元数据',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_target (target_type, target_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户行为表';

-- 插入初始数据
INSERT INTO resume_templates (name, description, template_data, category, is_free) VALUES
('经典商务', '适合传统行业的商务简历模板', '{"sections": ["basic_info", "education", "experience", "skills"]}', 'business', TRUE),
('创意设计', '适合设计创意行业的简历模板', '{"sections": ["basic_info", "portfolio", "experience", "skills"]}', 'creative', TRUE),
('技术开发', '适合IT技术行业的简历模板', '{"sections": ["basic_info", "skills", "projects", "experience"]}', 'technical', TRUE);

-- 插入积分规则
INSERT INTO point_records (user_id, type, amount, reason, description) VALUES
(1, 'earn', 100, '注册奖励', '新用户注册奖励'),
(1, 'earn', 50, '完善资料', '完善个人资料奖励'),
(1, 'earn', 200, '创建简历', '创建第一份简历奖励');

-- ========================================
-- PostgreSQL 高级功能数据库初始化
-- ========================================

-- 连接到PostgreSQL数据库
\c jobfirst_advanced;

-- 1. AI模型配置表
CREATE TABLE IF NOT EXISTS ai_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'embedding', 'classification', 'recommendation', 'generation'
    provider VARCHAR(50) NOT NULL, -- 'openai', 'huggingface', 'custom'
    config JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 向量化数据存储表
CREATE TABLE IF NOT EXISTS embeddings (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL, -- 'user', 'resume', 'job', 'skill'
    entity_id BIGINT NOT NULL,
    embedding_vector REAL[] NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(entity_type, entity_id)
);

-- 3. 系统配置管理表
CREATE TABLE IF NOT EXISTS system_configs (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    config_type VARCHAR(20) DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. 高级分析表
CREATE TABLE IF NOT EXISTS advanced_analytics (
    id SERIAL PRIMARY KEY,
    analysis_type VARCHAR(50) NOT NULL,
    data JSONB NOT NULL,
    result JSONB,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- 插入初始AI模型配置
INSERT INTO ai_models (name, type, provider, config) VALUES
('text-embedding-ada-002', 'embedding', 'openai', '{"model": "text-embedding-ada-002", "dimensions": 1536}'),
('gpt-4', 'generation', 'openai', '{"model": "gpt-4", "max_tokens": 1000}'),
('sentence-transformers', 'embedding', 'huggingface', '{"model": "all-MiniLM-L6-v2", "dimensions": 384}');

-- 插入系统配置
INSERT INTO system_configs (config_key, config_value, config_type, description) VALUES
('ai_enabled', 'true', 'boolean', '是否启用AI功能'),
('max_search_results', '100', 'number', '最大搜索结果数'),
('cache_ttl_default', '3600', 'number', '默认缓存生存时间(秒)'),
('recommendation_threshold', '0.7', 'number', '推荐相似度阈值');

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_embeddings_entity ON embeddings(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_embeddings_vector ON embeddings USING ivfflat (embedding_vector vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_analytics_type ON advanced_analytics(analysis_type);
CREATE INDEX IF NOT EXISTS idx_analytics_status ON advanced_analytics(status);

-- 创建向量扩展（如果不存在）
CREATE EXTENSION IF NOT EXISTS vector;

-- ========================================
-- 完成初始化
-- ========================================

SELECT 'JobFirst数据库初始化完成！' as message;
