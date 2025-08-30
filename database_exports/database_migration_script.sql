-- JobFirst 数据库迁移脚本
-- 用于将JobFirst数据库结构迁移到其他数据库系统
-- 创建时间: $(date)

-- =====================================================
-- 数据库迁移脚本
-- =====================================================

-- 1. 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS jobfirst_new CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jobfirst_new;

-- 2. 用户管理模块
-- =====================================================

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    phone VARCHAR(20) COMMENT '手机号',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    status ENUM('active','inactive','banned') DEFAULT 'active' COMMENT '用户状态',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    deleted_at DATETIME(3) NULL COMMENT '删除时间(软删除)',
    INDEX idx_users_email (email),
    INDEX idx_users_username (username),
    INDEX idx_users_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 用户行为表
CREATE TABLE IF NOT EXISTS user_behaviors (
    id VARCHAR(36) PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    type VARCHAR(50) NOT NULL COMMENT '行为类型',
    reference_id VARCHAR(100) COMMENT '关联ID',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    metadata JSON COMMENT '元数据',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    INDEX idx_user_behaviors_user_id (user_id),
    INDEX idx_user_behaviors_type (type),
    INDEX idx_user_behaviors_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户行为表';

-- 3. 简历管理模块
-- =====================================================

-- 简历表
CREATE TABLE IF NOT EXISTS resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    title VARCHAR(255) NOT NULL COMMENT '简历标题',
    content JSON COMMENT '简历内容',
    template_id VARCHAR(36) COMMENT '模板ID',
    status ENUM('draft','published','archived') DEFAULT 'draft' COMMENT '状态',
    view_count BIGINT DEFAULT 0 COMMENT '浏览次数',
    download_count BIGINT DEFAULT 0 COMMENT '下载次数',
    share_count INT DEFAULT 0 COMMENT '分享次数',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    deleted_at DATETIME(3) NULL COMMENT '删除时间',
    INDEX idx_resumes_user_id (user_id),
    INDEX idx_resumes_status (status),
    INDEX idx_resumes_deleted_at (deleted_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历表';

-- 简历模板表
CREATE TABLE IF NOT EXISTS resume_templates (
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
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    INDEX idx_resume_templates_category (category),
    INDEX idx_resume_templates_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历模板表';

-- 简历横幅表
CREATE TABLE IF NOT EXISTS resume_banners (
    id VARCHAR(36) PRIMARY KEY,
    title VARCHAR(255) NOT NULL COMMENT '标题',
    content TEXT COMMENT '内容',
    image_url VARCHAR(500) COMMENT '图片URL',
    link_url VARCHAR(500) COMMENT '链接URL',
    `order` INT DEFAULT 0 COMMENT '排序',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    start_time DATETIME(3) COMMENT '开始时间',
    end_time DATETIME(3) COMMENT '结束时间',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    INDEX idx_resume_banners_order (`order`),
    INDEX idx_resume_banners_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历横幅表';

-- 4. 积分系统模块
-- =====================================================

-- 积分表
CREATE TABLE IF NOT EXISTS points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    points INT DEFAULT 0 COMMENT '当前积分',
    earned_points INT DEFAULT 0 COMMENT '累计获得积分',
    spent_points INT DEFAULT 0 COMMENT '累计消费积分',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_points_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分表';

-- 积分记录表
CREATE TABLE IF NOT EXISTS point_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    points INT NOT NULL COMMENT '积分数量',
    type ENUM('earn','spend') NOT NULL COMMENT '类型：获得/消费',
    reason VARCHAR(100) NOT NULL COMMENT '原因',
    description TEXT COMMENT '描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_point_records_user_id (user_id),
    INDEX idx_point_records_type (type),
    INDEX idx_point_records_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分记录表';

-- 积分规则表
CREATE TABLE IF NOT EXISTS points_rules (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '规则名称',
    source VARCHAR(50) UNIQUE NOT NULL COMMENT '来源',
    points BIGINT NOT NULL COMMENT '积分数量',
    description TEXT COMMENT '描述',
    is_active BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    daily_limit BIGINT COMMENT '每日限制',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    INDEX idx_points_rules_source (source),
    INDEX idx_points_rules_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分规则表';

-- 5. 文件存储模块
-- =====================================================

-- 文件表
CREATE TABLE IF NOT EXISTS files (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    filename VARCHAR(255) NOT NULL COMMENT '文件名',
    original_name VARCHAR(255) NOT NULL COMMENT '原始文件名',
    file_path VARCHAR(500) NOT NULL COMMENT '文件路径',
    file_size BIGINT NOT NULL COMMENT '文件大小',
    mime_type VARCHAR(100) COMMENT 'MIME类型',
    file_type ENUM('image','document','video','other') NOT NULL COMMENT '文件类型',
    status ENUM('uploading','completed','failed','deleted') DEFAULT 'uploading' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at TIMESTAMP NULL COMMENT '删除时间',
    INDEX idx_files_user_id (user_id),
    INDEX idx_files_status (status),
    INDEX idx_files_type (file_type),
    INDEX idx_files_deleted_at (deleted_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件表';

-- 文件分享表
CREATE TABLE IF NOT EXISTS file_shares (
    id VARCHAR(36) PRIMARY KEY,
    file_id BIGINT UNSIGNED NOT NULL COMMENT '文件ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    share_token VARCHAR(64) UNIQUE COMMENT '分享令牌',
    password VARCHAR(100) COMMENT '密码',
    is_public BOOLEAN DEFAULT FALSE COMMENT '是否公开',
    max_downloads BIGINT COMMENT '最大下载次数',
    download_count BIGINT DEFAULT 0 COMMENT '下载次数',
    expires_at DATETIME(3) COMMENT '过期时间',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    INDEX idx_file_shares_file_id (file_id),
    INDEX idx_file_shares_user_id (user_id),
    INDEX idx_file_shares_token (share_token),
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件分享表';

-- 文件版本表
CREATE TABLE IF NOT EXISTS file_versions (
    id VARCHAR(36) PRIMARY KEY,
    file_id BIGINT UNSIGNED NOT NULL COMMENT '文件ID',
    version BIGINT NOT NULL COMMENT '版本号',
    file_name VARCHAR(255) NOT NULL COMMENT '文件名',
    size BIGINT NOT NULL COMMENT '文件大小',
    storage_path VARCHAR(500) NOT NULL COMMENT '存储路径',
    md5_hash VARCHAR(32) COMMENT 'MD5哈希',
    status VARCHAR(20) DEFAULT 'uploaded' COMMENT '状态',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    INDEX idx_file_versions_file_id (file_id),
    INDEX idx_file_versions_version (version),
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件版本表';

-- 文件访问日志表
CREATE TABLE IF NOT EXISTS file_access_logs (
    id VARCHAR(36) PRIMARY KEY,
    file_id BIGINT UNSIGNED NOT NULL COMMENT '文件ID',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    action VARCHAR(20) NOT NULL COMMENT '操作',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    referer VARCHAR(500) COMMENT '来源',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    INDEX idx_file_access_logs_file_id (file_id),
    INDEX idx_file_access_logs_user_id (user_id),
    INDEX idx_file_access_logs_action (action),
    INDEX idx_file_access_logs_created_at (created_at),
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文件访问日志表';

-- 存储配额表
CREATE TABLE IF NOT EXISTS storage_quota (
    id VARCHAR(36) PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE NOT NULL COMMENT '用户ID',
    total_quota BIGINT NOT NULL COMMENT '总配额',
    used_quota BIGINT DEFAULT 0 COMMENT '已使用配额',
    file_count BIGINT DEFAULT 0 COMMENT '文件数量',
    last_reset_at DATETIME(3) COMMENT '最后重置时间',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='存储配额表';

-- 6. 统计分析模块
-- =====================================================

-- 统计表
CREATE TABLE IF NOT EXISTS statistics (
    id VARCHAR(36) PRIMARY KEY,
    type VARCHAR(50) NOT NULL COMMENT '统计类型',
    period VARCHAR(20) NOT NULL COMMENT '统计周期',
    date DATETIME(3) NOT NULL COMMENT '统计日期',
    value BIGINT DEFAULT 0 COMMENT '统计值',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    reference_id VARCHAR(100) COMMENT '关联ID',
    metadata JSON COMMENT '元数据',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    INDEX idx_statistics_type (type),
    INDEX idx_statistics_period (period),
    INDEX idx_statistics_date (date),
    INDEX idx_statistics_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统计表';

-- 统计事件表
CREATE TABLE IF NOT EXISTS statistics_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL COMMENT '事件类型',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    event_data JSON COMMENT '事件数据',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX idx_statistics_events_event_type (event_type),
    INDEX idx_statistics_events_user_id (user_id),
    INDEX idx_statistics_events_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='统计事件表';

-- 实时统计表
CREATE TABLE IF NOT EXISTS real_time_stats (
    id VARCHAR(36) PRIMARY KEY,
    type VARCHAR(50) UNIQUE NOT NULL COMMENT '类型',
    value BIGINT DEFAULT 0 COMMENT '值',
    last_updated DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '最后更新时间',
    created_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实时统计表';

-- 7. 插入初始数据
-- =====================================================

-- 插入简历模板初始数据
INSERT INTO resume_templates (id, name, description, template_data, category, is_free, status) VALUES
('template-001', '经典商务模板', '适合商务人士的经典简历模板', '{"sections": ["basic_info", "experience", "education", "skills"]}', 'business', TRUE, 'active'),
('template-002', '创意设计模板', '适合设计师的创意简历模板', '{"sections": ["basic_info", "portfolio", "experience", "skills"]}', 'creative', TRUE, 'active'),
('template-003', '技术开发模板', '适合程序员的专业简历模板', '{"sections": ["basic_info", "skills", "experience", "projects"]}', 'technology', TRUE, 'active');

-- 插入积分规则初始数据
INSERT INTO points_rules (id, name, source, points, description, is_active, daily_limit) VALUES
('rule-001', '注册奖励', 'register', 100, '新用户注册奖励', TRUE, 1),
('rule-002', '每日登录', 'daily_login', 10, '每日登录奖励', TRUE, 1),
('rule-003', '创建简历', 'create_resume', 50, '创建新简历奖励', TRUE, 5),
('rule-004', '分享简历', 'share_resume', 20, '分享简历奖励', TRUE, 10),
('rule-005', '下载模板', 'download_template', -10, '下载付费模板消费', TRUE, NULL);

-- 8. 创建视图
-- =====================================================

-- 用户统计视图
CREATE OR REPLACE VIEW v_user_stats AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.status,
    COUNT(r.id) as resume_count,
    COALESCE(p.points, 0) as current_points,
    COALESCE(sq.used_quota, 0) as used_storage,
    COALESCE(sq.total_quota, 0) as total_storage,
    u.created_at
FROM users u
LEFT JOIN resumes r ON u.id = r.user_id AND r.deleted_at IS NULL
LEFT JOIN points p ON u.id = p.user_id
LEFT JOIN storage_quota sq ON u.id = sq.user_id
WHERE u.deleted_at IS NULL
GROUP BY u.id;

-- 简历统计视图
CREATE OR REPLACE VIEW v_resume_stats AS
SELECT 
    r.id,
    r.title,
    r.status,
    r.view_count,
    r.download_count,
    r.share_count,
    u.username,
    rt.name as template_name,
    r.created_at
FROM resumes r
JOIN users u ON r.user_id = u.id
LEFT JOIN resume_templates rt ON r.template_id = rt.id
WHERE r.deleted_at IS NULL AND u.deleted_at IS NULL;

-- 9. 创建存储过程
-- =====================================================

DELIMITER //

-- 用户注册存储过程
CREATE PROCEDURE sp_register_user(
    IN p_username VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_password_hash VARCHAR(255),
    IN p_phone VARCHAR(20),
    OUT p_user_id BIGINT UNSIGNED
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 插入用户
    INSERT INTO users (username, email, password_hash, phone) 
    VALUES (p_username, p_email, p_password_hash, p_phone);
    
    SET p_user_id = LAST_INSERT_ID();
    
    -- 初始化积分
    INSERT INTO points (user_id, points, earned_points, spent_points) 
    VALUES (p_user_id, 100, 100, 0);
    
    -- 初始化存储配额
    INSERT INTO storage_quota (id, user_id, total_quota, used_quota, file_count) 
    VALUES (UUID(), p_user_id, 1073741824, 0, 0); -- 1GB
    
    -- 记录注册奖励
    INSERT INTO point_records (user_id, points, type, reason, description) 
    VALUES (p_user_id, 100, 'earn', 'register', '新用户注册奖励');
    
    COMMIT;
END //

-- 积分变动存储过程
CREATE PROCEDURE sp_change_points(
    IN p_user_id BIGINT UNSIGNED,
    IN p_points INT,
    IN p_type ENUM('earn','spend'),
    IN p_reason VARCHAR(100),
    IN p_description TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 更新积分表
    IF p_type = 'earn' THEN
        UPDATE points 
        SET points = points + p_points, 
            earned_points = earned_points + p_points,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id;
    ELSE
        UPDATE points 
        SET points = points - p_points, 
            spent_points = spent_points + p_points,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = p_user_id;
    END IF;
    
    -- 记录积分变动
    INSERT INTO point_records (user_id, points, type, reason, description) 
    VALUES (p_user_id, p_points, p_type, p_reason, p_description);
    
    COMMIT;
END //

DELIMITER ;

-- 10. 创建触发器
-- =====================================================

-- 用户删除时清理相关数据
DELIMITER //
CREATE TRIGGER tr_users_before_delete
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    -- 删除用户相关数据
    DELETE FROM points WHERE user_id = OLD.id;
    DELETE FROM storage_quota WHERE user_id = OLD.id;
    DELETE FROM user_behaviors WHERE user_id = OLD.id;
    DELETE FROM file_access_logs WHERE user_id = OLD.id;
    DELETE FROM statistics WHERE user_id = OLD.id;
    DELETE FROM statistics_events WHERE user_id = OLD.id;
END //
DELIMITER ;

-- 文件删除时更新存储配额
DELIMITER //
CREATE TRIGGER tr_files_after_delete
AFTER DELETE ON files
FOR EACH ROW
BEGIN
    UPDATE storage_quota 
    SET used_quota = used_quota - OLD.file_size,
        file_count = file_count - 1,
        updated_at = CURRENT_TIMESTAMP(3)
    WHERE user_id = OLD.user_id;
END //
DELIMITER ;

-- 文件插入时更新存储配额
DELIMITER //
CREATE TRIGGER tr_files_after_insert
AFTER INSERT ON files
FOR EACH ROW
BEGIN
    UPDATE storage_quota 
    SET used_quota = used_quota + NEW.file_size,
        file_count = file_count + 1,
        updated_at = CURRENT_TIMESTAMP(3)
    WHERE user_id = NEW.user_id;
END //
DELIMITER ;

-- 11. 创建事件
-- =====================================================

-- 每日统计事件
DELIMITER //
CREATE EVENT ev_daily_statistics
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- 插入每日用户统计
    INSERT INTO statistics (id, type, period, date, value)
    SELECT 
        UUID(),
        'daily_active_users',
        'daily',
        DATE(NOW()),
        COUNT(DISTINCT user_id)
    FROM user_behaviors 
    WHERE DATE(created_at) = DATE(NOW());
    
    -- 插入每日简历创建统计
    INSERT INTO statistics (id, type, period, date, value)
    SELECT 
        UUID(),
        'daily_resume_created',
        'daily',
        DATE(NOW()),
        COUNT(*)
    FROM resumes 
    WHERE DATE(created_at) = DATE(NOW()) AND deleted_at IS NULL;
END //
DELIMITER ;

-- 12. 权限设置
-- =====================================================

-- 创建应用用户
CREATE USER IF NOT EXISTS 'jobfirst_app'@'%' IDENTIFIED BY 'jobfirst_app_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON jobfirst_new.* TO 'jobfirst_app'@'%';

-- 创建只读用户
CREATE USER IF NOT EXISTS 'jobfirst_readonly'@'%' IDENTIFIED BY 'jobfirst_readonly_password';
GRANT SELECT ON jobfirst_new.* TO 'jobfirst_readonly'@'%';

FLUSH PRIVILEGES;

-- 13. 完成迁移
-- =====================================================

-- 显示迁移结果
SELECT 'Database migration completed successfully!' as status;
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = 'jobfirst_new';
SELECT table_name FROM information_schema.tables WHERE table_schema = 'jobfirst_new' ORDER BY table_name;
