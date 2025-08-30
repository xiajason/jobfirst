-- JobFirst 简历中心系统数据库初始化脚本

-- 创建数据库
CREATE DATABASE IF NOT EXISTS jobfirst CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jobfirst;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(255),
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- 简历表
CREATE TABLE IF NOT EXISTS resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    title VARCHAR(100) NOT NULL,
    content JSON,
    template_id VARCHAR(36),
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    view_count INT DEFAULT 0,
    download_count INT DEFAULT 0,
    share_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 积分表
CREATE TABLE IF NOT EXISTS points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    points INT DEFAULT 0,
    earned_points INT DEFAULT 0,
    spent_points INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 积分记录表
CREATE TABLE IF NOT EXISTS point_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    points INT NOT NULL,
    type ENUM('earn', 'spend') NOT NULL,
    reason VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 统计事件表
CREATE TABLE IF NOT EXISTS statistics_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    user_id BIGINT UNSIGNED,
    event_data JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_event_type (event_type),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);

-- 文件存储表
CREATE TABLE IF NOT EXISTS files (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    file_type ENUM('image', 'document', 'video', 'other') NOT NULL,
    status ENUM('uploading', 'completed', 'failed', 'deleted') DEFAULT 'uploading',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 简历模板表
CREATE TABLE IF NOT EXISTS resume_templates (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    template_data JSON NOT NULL,
    preview_image VARCHAR(255),
    category VARCHAR(50),
    is_free BOOLEAN DEFAULT FALSE,
    price DECIMAL(10,2) DEFAULT 0.00,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 插入一些初始数据
INSERT INTO resume_templates (id, name, description, template_data, category, is_free, status) VALUES
('template-001', '经典商务模板', '适合商务人士的经典简历模板', '{"sections": ["basic_info", "experience", "education", "skills"]}', 'business', TRUE, 'active'),
('template-002', '创意设计模板', '适合设计师的创意简历模板', '{"sections": ["basic_info", "portfolio", "experience", "skills"]}', 'creative', TRUE, 'active'),
('template-003', '技术开发模板', '适合程序员的专业简历模板', '{"sections": ["basic_info", "skills", "experience", "projects"]}', 'technology', TRUE, 'active');

-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_resumes_user_id ON resumes(user_id);
CREATE INDEX idx_resumes_status ON resumes(status);
CREATE INDEX idx_points_user_id ON points(user_id);
CREATE INDEX idx_point_records_user_id ON point_records(user_id);
CREATE INDEX idx_files_user_id ON files(user_id);
CREATE INDEX idx_files_status ON files(status);
