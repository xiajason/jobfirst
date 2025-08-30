-- ADIRP数智招聘系统 - 分阶段数据库升级脚本
-- 阶段一：核心业务表升级

USE jobfirst;

-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ========================================
-- 阶段一：核心业务表升级
-- ========================================

-- 1. 升级用户表（保留原表，创建新表）
CREATE TABLE IF NOT EXISTS users_v2 (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. 创建企业表
CREATE TABLE IF NOT EXISTS companies (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. 创建职位分类表
CREATE TABLE IF NOT EXISTS job_categories (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. 创建职位表
CREATE TABLE IF NOT EXISTS jobs (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. 创建轮播图表
CREATE TABLE IF NOT EXISTS banners (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 插入初始数据
-- ========================================

-- 插入职位分类数据
INSERT INTO job_categories (name, parent_id, level, sort_order, description, status) VALUES
('技术', NULL, 1, 1, '技术类职位', 'active'),
('产品', NULL, 1, 2, '产品类职位', 'active'),
('设计', NULL, 1, 3, '设计类职位', 'active'),
('运营', NULL, 1, 4, '运营类职位', 'active'),
('销售', NULL, 1, 5, '销售类职位', 'active'),
('市场', NULL, 1, 6, '市场类职位', 'active'),
('人事', NULL, 1, 7, '人事类职位', 'active'),
('财务', NULL, 1, 8, '财务类职位', 'active'),
('前端开发', 1, 2, 1, '前端开发工程师', 'active'),
('后端开发', 1, 2, 2, '后端开发工程师', 'active'),
('算法工程师', 1, 2, 3, '算法工程师', 'active'),
('产品经理', 2, 2, 1, '产品经理', 'active'),
('UI设计师', 3, 2, 1, 'UI设计师', 'active'),
('运营专员', 4, 2, 1, '运营专员', 'active');

-- 插入轮播图数据
INSERT INTO banners (title, image_url, link_url, link_type, sort_order, status) VALUES
('春季招聘会', '/images/banner1.jpg', '/pages/activity/spring', 'internal', 1, 'active'),
('名企直招', '/images/banner2.jpg', '/pages/activity/companies', 'internal', 2, 'active'),
('应届生专场', '/images/banner3.jpg', '/pages/activity/fresh', 'internal', 3, 'active');

-- 插入企业数据
INSERT INTO companies (name, short_name, logo_url, industry, company_size, location, description, status, verification_level) VALUES
('腾讯科技有限公司', '腾讯', '/images/company/tencent.png', '互联网', 'enterprise', '深圳', '腾讯是一家以互联网为基础的科技与文化公司', 'verified', 'vip'),
('阿里巴巴集团', '阿里巴巴', '/images/company/alibaba.png', '电商', 'enterprise', '杭州', '阿里巴巴集团是全球领先的电子商务平台', 'verified', 'vip'),
('字节跳动科技有限公司', '字节跳动', '/images/company/bytedance.png', '互联网', 'large', '北京', '字节跳动是一家信息科技公司', 'verified', 'premium');

-- 插入职位数据
INSERT INTO jobs (company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, status, publish_at) VALUES
(1, 9, '前端开发工程师', 'full_time', '深圳', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责腾讯产品的前端开发工作', '熟悉React、Vue等前端框架', 'published', NOW()),
(1, 10, '后端开发工程师', 'full_time', '深圳', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责腾讯产品的后端开发工作', '熟悉Go、Java等后端语言', 'published', NOW()),
(2, 12, '产品经理', 'full_time', '杭州', 25000, 40000, 'monthly', 'mid', 'bachelor', '负责阿里巴巴产品的产品设计', '有3年以上产品经理经验', 'published', NOW()),
(3, 11, '算法工程师', 'full_time', '北京', 30000, 50000, 'monthly', 'senior', 'master', '负责字节跳动推荐算法开发', '熟悉机器学习、深度学习', 'published', NOW());

-- ========================================
-- 创建视图用于数据迁移
-- ========================================

-- 创建用户数据迁移视图
CREATE OR REPLACE VIEW user_migration_view AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.phone,
    u.password_hash,
    u.avatar_url,
    u.nickname,
    u.real_name,
    u.gender,
    u.birth_date,
    u.location,
    CASE 
        WHEN u.status = 'active' THEN 'active'
        WHEN u.status = 'inactive' THEN 'inactive'
        WHEN u.status = 'banned' THEN 'suspended'
        ELSE 'inactive'
    END as status,
    'jobseeker' as user_type,
    'pending' as certification_status,
    u.created_at,
    u.updated_at,
    u.deleted_at
FROM users u;

-- ========================================
-- 设置外键约束
-- ========================================

SET FOREIGN_KEY_CHECKS = 1;

-- 完成阶段一升级
SELECT 'Phase 1 database upgrade completed successfully!' as message;
