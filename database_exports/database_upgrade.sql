-- ADIRP数智招聘系统 - 数据库升级脚本
-- 版本: v2.0
-- 日期: 2024-08-30
-- 说明: 升级现有数据库结构以支持小程序前端需求

-- 使用数据库
USE jobfirst;

-- 设置字符集
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ========================================
-- 1. 用户管理模块升级
-- ========================================

-- 1.1 升级users表
ALTER TABLE users 
ADD COLUMN openid VARCHAR(100) UNIQUE COMMENT '微信openid' AFTER id,
ADD COLUMN unionid VARCHAR(100) UNIQUE COMMENT '微信unionid' AFTER openid,
ADD COLUMN nickname VARCHAR(50) COMMENT '昵称' AFTER avatar_url,
ADD COLUMN real_name VARCHAR(50) COMMENT '真实姓名' AFTER nickname,
ADD COLUMN gender ENUM('male', 'female', 'other') COMMENT '性别' AFTER real_name,
ADD COLUMN birth_date DATE COMMENT '出生日期' AFTER gender,
ADD COLUMN location VARCHAR(100) COMMENT '所在地' AFTER birth_date,
ADD COLUMN user_type ENUM('jobseeker', 'recruiter', 'admin') DEFAULT 'jobseeker' COMMENT '用户类型' AFTER status,
ADD COLUMN certification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending' COMMENT '认证状态' AFTER user_type,
ADD COLUMN last_login_at DATETIME COMMENT '最后登录时间' AFTER certification_status,
ADD INDEX idx_openid (openid),
ADD INDEX idx_phone (phone),
ADD INDEX idx_email (email),
ADD INDEX idx_status (status),
ADD INDEX idx_user_type (user_type),
ADD INDEX idx_created_at (created_at);

-- 1.2 创建user_profiles表
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 2. 企业管理模块
-- ========================================

-- 2.1 创建companies表
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

-- 2.2 创建company_profiles表
CREATE TABLE IF NOT EXISTS company_profiles (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 3. 职位管理模块
-- ========================================

-- 3.1 创建job_categories表
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

-- 3.2 创建jobs表
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

-- 3.3 创建job_applications表
CREATE TABLE IF NOT EXISTS job_applications (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 4. 简历管理模块升级
-- ========================================

-- 4.1 升级resumes表
ALTER TABLE resumes 
ADD COLUMN template_id BIGINT UNSIGNED NULL COMMENT '模板ID' AFTER user_id,
ADD COLUMN is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认简历' AFTER status,
ADD COLUMN share_count INT DEFAULT 0 COMMENT '分享次数' AFTER download_count,
ADD INDEX idx_template_id (template_id),
ADD INDEX idx_is_default (is_default);

-- 4.2 升级resume_templates表
ALTER TABLE resume_templates 
ADD COLUMN category VARCHAR(50) COMMENT '模板分类' AFTER template_data,
ADD COLUMN download_count INT DEFAULT 0 COMMENT '下载次数' AFTER price,
ADD COLUMN use_count INT DEFAULT 0 COMMENT '使用次数' AFTER download_count,
ADD COLUMN rating DECIMAL(3,2) DEFAULT 0.00 COMMENT '评分' AFTER use_count,
ADD INDEX idx_category (category),
ADD INDEX idx_is_free (is_free),
ADD INDEX idx_rating (rating);

-- ========================================
-- 5. 聊天系统模块
-- ========================================

-- 5.1 创建chats表
CREATE TABLE IF NOT EXISTS chats (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5.2 创建messages表
CREATE TABLE IF NOT EXISTS messages (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 6. 积分系统模块升级
-- ========================================

-- 6.1 升级points表
ALTER TABLE points 
ADD COLUMN level VARCHAR(20) DEFAULT 'bronze' COMMENT '积分等级' AFTER total_spent,
ADD INDEX idx_balance (balance),
ADD INDEX idx_level (level);

-- 6.2 升级point_records表
ALTER TABLE point_records 
ADD COLUMN reference_id VARCHAR(100) COMMENT '关联ID' AFTER description,
ADD COLUMN reference_type VARCHAR(50) COMMENT '关联类型' AFTER reference_id,
ADD INDEX idx_reason (reason);

-- ========================================
-- 7. 系统配置模块
-- ========================================

-- 7.1 创建banners表
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

-- 7.2 创建notifications表
CREATE TABLE IF NOT EXISTS notifications (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================
-- 8. 插入初始数据
-- ========================================

-- 8.1 插入职位分类数据
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

-- 8.2 插入轮播图数据
INSERT INTO banners (title, image_url, link_url, link_type, sort_order, status) VALUES
('春季招聘会', '/images/banner1.jpg', '/pages/activity/spring', 'internal', 1, 'active'),
('名企直招', '/images/banner2.jpg', '/pages/activity/companies', 'internal', 2, 'active'),
('应届生专场', '/images/banner3.jpg', '/pages/activity/fresh', 'internal', 3, 'active');

-- 8.3 插入企业数据
INSERT INTO companies (name, short_name, logo_url, industry, company_size, location, description, status, verification_level) VALUES
('腾讯科技有限公司', '腾讯', '/images/company/tencent.png', '互联网', 'enterprise', '深圳', '腾讯是一家以互联网为基础的科技与文化公司', 'verified', 'vip'),
('阿里巴巴集团', '阿里巴巴', '/images/company/alibaba.png', '电商', 'enterprise', '杭州', '阿里巴巴集团是全球领先的电子商务平台', 'verified', 'vip'),
('字节跳动科技有限公司', '字节跳动', '/images/company/bytedance.png', '互联网', 'large', '北京', '字节跳动是一家信息科技公司', 'verified', 'premium');

-- 8.4 插入职位数据
INSERT INTO jobs (company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, status, publish_at) VALUES
(1, 9, '前端开发工程师', 'full_time', '深圳', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责腾讯产品的前端开发工作', '熟悉React、Vue等前端框架', 'published', NOW()),
(1, 10, '后端开发工程师', 'full_time', '深圳', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责腾讯产品的后端开发工作', '熟悉Go、Java等后端语言', 'published', NOW()),
(2, 12, '产品经理', 'full_time', '杭州', 25000, 40000, 'monthly', 'mid', 'bachelor', '负责阿里巴巴产品的产品设计', '有3年以上产品经理经验', 'published', NOW()),
(3, 11, '算法工程师', 'full_time', '北京', 30000, 50000, 'monthly', 'senior', 'master', '负责字节跳动推荐算法开发', '熟悉机器学习、深度学习', 'published', NOW());

-- ========================================
-- 9. 创建视图
-- ========================================

-- 9.1 职位统计视图
CREATE OR REPLACE VIEW job_stats AS
SELECT 
    c.id as company_id,
    c.name as company_name,
    COUNT(j.id) as total_jobs,
    COUNT(CASE WHEN j.status = 'published' THEN 1 END) as active_jobs,
    AVG(j.salary_min) as avg_salary_min,
    AVG(j.salary_max) as avg_salary_max
FROM companies c
LEFT JOIN jobs j ON c.id = j.company_id
GROUP BY c.id, c.name;

-- 9.2 用户统计视图
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id as user_id,
    u.username,
    up.resume_count,
    up.application_count,
    up.favorite_count,
    p.balance as points_balance
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN points p ON u.id = p.user_id;

-- ========================================
-- 10. 创建存储过程
-- ========================================

-- 10.1 更新职位统计
DELIMITER //
CREATE PROCEDURE UpdateJobStats()
BEGIN
    UPDATE companies c 
    SET job_count = (
        SELECT COUNT(*) 
        FROM jobs j 
        WHERE j.company_id = c.id AND j.status = 'published'
    );
END //
DELIMITER ;

-- 10.2 更新分类统计
DELIMITER //
CREATE PROCEDURE UpdateCategoryStats()
BEGIN
    UPDATE job_categories jc 
    SET job_count = (
        SELECT COUNT(*) 
        FROM jobs j 
        WHERE j.category_id = jc.id AND j.status = 'published'
    );
END //
DELIMITER ;

-- ========================================
-- 11. 创建触发器
-- ========================================

-- 11.1 职位状态变更触发器
DELIMITER //
CREATE TRIGGER after_job_status_change
AFTER UPDATE ON jobs
FOR EACH ROW
BEGIN
    IF NEW.status != OLD.status THEN
        CALL UpdateJobStats();
        CALL UpdateCategoryStats();
    END IF;
END //
DELIMITER ;

-- 11.2 职位创建触发器
DELIMITER //
CREATE TRIGGER after_job_insert
AFTER INSERT ON jobs
FOR EACH ROW
BEGIN
    CALL UpdateJobStats();
    CALL UpdateCategoryStats();
END //
DELIMITER ;

-- ========================================
-- 12. 设置外键约束
-- ========================================

SET FOREIGN_KEY_CHECKS = 1;

-- ========================================
-- 13. 更新数据库版本
-- ========================================

-- 创建版本表（如果不存在）
CREATE TABLE IF NOT EXISTS database_version (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 插入当前版本
INSERT INTO database_version (version, description) VALUES 
('2.0.0', 'ADIRP数智招聘系统数据库升级 - 支持小程序前端需求');

-- 完成升级
SELECT 'Database upgrade completed successfully!' as message;
