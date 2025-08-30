-- ========================================
-- ADIRP数智招聘系统 - 第三阶段数据库升级
-- 功能完善升级：聊天系统、积分系统、通知系统
-- ========================================

USE jobfirst;

-- ========================================
-- 1. 聊天系统相关表
-- ========================================

-- 聊天会话表
CREATE TABLE IF NOT EXISTS chat_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(64) UNIQUE NOT NULL COMMENT '会话ID',
    session_type ENUM('job_apply', 'hr_chat', 'system_notice', 'group_chat') NOT NULL COMMENT '会话类型',
    title VARCHAR(255) NOT NULL COMMENT '会话标题',
    description TEXT COMMENT '会话描述',
    participants JSON COMMENT '参与者列表',
    last_message_id BIGINT COMMENT '最后消息ID',
    last_message_time TIMESTAMP NULL COMMENT '最后消息时间',
    unread_count INT DEFAULT 0 COMMENT '未读消息数',
    status ENUM('active', 'archived', 'deleted') DEFAULT 'active' COMMENT '会话状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_session_id (session_id),
    INDEX idx_session_type (session_type),
    INDEX idx_last_message_time (last_message_time),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天会话表';

-- 聊天消息表
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(64) NOT NULL COMMENT '会话ID',
    sender_id BIGINT UNSIGNED NOT NULL COMMENT '发送者ID',
    sender_type ENUM('user', 'hr', 'system') NOT NULL COMMENT '发送者类型',
    message_type ENUM('text', 'image', 'file', 'system', 'job_card', 'resume_card') NOT NULL COMMENT '消息类型',
    content TEXT NOT NULL COMMENT '消息内容',
    attachment_url VARCHAR(500) COMMENT '附件URL',
    attachment_name VARCHAR(255) COMMENT '附件名称',
    attachment_size BIGINT COMMENT '附件大小(字节)',
    read_status JSON COMMENT '已读状态 {user_id: timestamp}',
    reply_to_id BIGINT COMMENT '回复消息ID',
    job_id BIGINT COMMENT '关联职位ID',
    resume_id BIGINT COMMENT '关联简历ID',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (session_id) REFERENCES chat_sessions(session_id) ON DELETE CASCADE,
    INDEX idx_session_id (session_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_message_type (message_type),
    INDEX idx_created_at (created_at),
    INDEX idx_job_id (job_id),
    INDEX idx_resume_id (resume_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天消息表';

-- 聊天参与者表
CREATE TABLE IF NOT EXISTS chat_participants (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(64) NOT NULL COMMENT '会话ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    user_type ENUM('jobseeker', 'hr', 'admin') NOT NULL COMMENT '用户类型',
    role ENUM('owner', 'admin', 'member') DEFAULT 'member' COMMENT '角色',
    join_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    last_read_time TIMESTAMP NULL COMMENT '最后阅读时间',
    unread_count INT DEFAULT 0 COMMENT '未读消息数',
    status ENUM('active', 'muted', 'left') DEFAULT 'active' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (session_id) REFERENCES chat_sessions(session_id) ON DELETE CASCADE,
    UNIQUE KEY uk_session_user (session_id, user_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天参与者表';

-- ========================================
-- 2. 积分系统相关表
-- ========================================

-- 积分账户表
CREATE TABLE IF NOT EXISTS points_accounts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE COMMENT '用户ID',
    balance INT DEFAULT 0 COMMENT '积分余额',
    total_earned INT DEFAULT 0 COMMENT '累计获得积分',
    total_spent INT DEFAULT 0 COMMENT '累计消费积分',
    level ENUM('bronze', 'silver', 'gold', 'platinum', 'diamond') DEFAULT 'bronze' COMMENT '等级',
    level_points INT DEFAULT 0 COMMENT '当前等级积分',
    next_level_points INT DEFAULT 100 COMMENT '下一等级所需积分',
    last_activity_time TIMESTAMP NULL COMMENT '最后活动时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_id (user_id),
    INDEX idx_level (level),
    INDEX idx_balance (balance)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分账户表';

-- 积分规则表
CREATE TABLE IF NOT EXISTS points_rules (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    rule_code VARCHAR(50) UNIQUE NOT NULL COMMENT '规则代码',
    rule_name VARCHAR(100) NOT NULL COMMENT '规则名称',
    rule_type ENUM('earn', 'spend') NOT NULL COMMENT '规则类型',
    points INT NOT NULL COMMENT '积分数量',
    description TEXT COMMENT '规则描述',
    conditions JSON COMMENT '触发条件',
    daily_limit INT DEFAULT 0 COMMENT '每日限制次数',
    total_limit INT DEFAULT 0 COMMENT '总限制次数',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    start_time TIMESTAMP NULL COMMENT '开始时间',
    end_time TIMESTAMP NULL COMMENT '结束时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_rule_code (rule_code),
    INDEX idx_rule_type (rule_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分规则表';

-- 积分记录表
CREATE TABLE IF NOT EXISTS points_records (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    rule_id BIGINT NOT NULL COMMENT '规则ID',
    rule_code VARCHAR(50) NOT NULL COMMENT '规则代码',
    points INT NOT NULL COMMENT '积分数量',
    balance_before INT NOT NULL COMMENT '操作前余额',
    balance_after INT NOT NULL COMMENT '操作后余额',
    record_type ENUM('earn', 'spend', 'expire', 'adjust') NOT NULL COMMENT '记录类型',
    source_type ENUM('job_apply', 'resume_view', 'daily_checkin', 'invite_friend', 'exchange', 'system') NOT NULL COMMENT '来源类型',
    source_id BIGINT COMMENT '来源ID',
    description VARCHAR(255) COMMENT '描述',
    metadata JSON COMMENT '元数据',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES points_accounts(user_id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES points_rules(id),
    INDEX idx_user_id (user_id),
    INDEX idx_rule_code (rule_code),
    INDEX idx_record_type (record_type),
    INDEX idx_source_type (source_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分记录表';

-- 积分兑换表
CREATE TABLE IF NOT EXISTS points_exchanges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    exchange_code VARCHAR(50) NOT NULL COMMENT '兑换码',
    item_name VARCHAR(100) NOT NULL COMMENT '兑换物品名称',
    item_type ENUM('coupon', 'vip', 'gift', 'service') NOT NULL COMMENT '物品类型',
    points_cost INT NOT NULL COMMENT '消耗积分',
    item_value DECIMAL(10,2) COMMENT '物品价值',
    status ENUM('pending', 'completed', 'failed', 'expired') DEFAULT 'pending' COMMENT '状态',
    exchange_time TIMESTAMP NULL COMMENT '兑换时间',
    expire_time TIMESTAMP NULL COMMENT '过期时间',
    description TEXT COMMENT '描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES points_accounts(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_exchange_code (exchange_code),
    INDEX idx_status (status),
    INDEX idx_exchange_time (exchange_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='积分兑换表';

-- ========================================
-- 3. 通知系统相关表
-- ========================================

-- 通知模板表
CREATE TABLE IF NOT EXISTS notification_templates (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    template_code VARCHAR(50) UNIQUE NOT NULL COMMENT '模板代码',
    template_name VARCHAR(100) NOT NULL COMMENT '模板名称',
    template_type ENUM('email', 'sms', 'push', 'in_app') NOT NULL COMMENT '模板类型',
    title VARCHAR(255) NOT NULL COMMENT '标题模板',
    content TEXT NOT NULL COMMENT '内容模板',
    variables JSON COMMENT '变量定义',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_template_code (template_code),
    INDEX idx_template_type (template_type),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知模板表';

-- 通知记录表
CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    template_id BIGINT NOT NULL COMMENT '模板ID',
    notification_type ENUM('job_apply', 'resume_view', 'chat_message', 'system_announcement', 'points_earned', 'points_spent') NOT NULL COMMENT '通知类型',
    title VARCHAR(255) NOT NULL COMMENT '标题',
    content TEXT NOT NULL COMMENT '内容',
    data JSON COMMENT '相关数据',
    read_status ENUM('unread', 'read') DEFAULT 'unread' COMMENT '阅读状态',
    read_time TIMESTAMP NULL COMMENT '阅读时间',
    send_status ENUM('pending', 'sent', 'failed') DEFAULT 'pending' COMMENT '发送状态',
    send_time TIMESTAMP NULL COMMENT '发送时间',
    expire_time TIMESTAMP NULL COMMENT '过期时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users_v2(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES notification_templates(id),
    INDEX idx_user_id (user_id),
    INDEX idx_notification_type (notification_type),
    INDEX idx_read_status (read_status),
    INDEX idx_send_status (send_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知记录表';

-- 用户通知设置表
CREATE TABLE IF NOT EXISTS user_notification_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL UNIQUE COMMENT '用户ID',
    email_notifications BOOLEAN DEFAULT TRUE COMMENT '邮件通知',
    sms_notifications BOOLEAN DEFAULT TRUE COMMENT '短信通知',
    push_notifications BOOLEAN DEFAULT TRUE COMMENT '推送通知',
    in_app_notifications BOOLEAN DEFAULT TRUE COMMENT '应用内通知',
    job_apply_notifications BOOLEAN DEFAULT TRUE COMMENT '职位申请通知',
    resume_view_notifications BOOLEAN DEFAULT TRUE COMMENT '简历查看通知',
    chat_notifications BOOLEAN DEFAULT TRUE COMMENT '聊天通知',
    system_notifications BOOLEAN DEFAULT TRUE COMMENT '系统通知',
    points_notifications BOOLEAN DEFAULT TRUE COMMENT '积分通知',
    quiet_hours_start TIME DEFAULT '22:00:00' COMMENT '免打扰开始时间',
    quiet_hours_end TIME DEFAULT '08:00:00' COMMENT '免打扰结束时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users_v2(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户通知设置表';

-- ========================================
-- 4. 插入初始数据
-- ========================================

-- 插入积分规则
INSERT IGNORE INTO points_rules (rule_code, rule_name, rule_type, points, description, conditions, daily_limit, total_limit) VALUES
('DAILY_CHECKIN', '每日签到', 'earn', 10, '每日签到获得积分', '{"action": "daily_checkin"}', 1, 0),
('JOB_APPLY', '投递简历', 'earn', 5, '投递简历获得积分', '{"action": "job_apply"}', 10, 0),
('RESUME_VIEW', '简历被查看', 'earn', 2, '简历被HR查看获得积分', '{"action": "resume_view"}', 0, 0),
('INVITE_FRIEND', '邀请好友', 'earn', 50, '邀请好友注册获得积分', '{"action": "invite_friend"}', 0, 0),
('COMPLETE_PROFILE', '完善资料', 'earn', 20, '完善个人资料获得积分', '{"action": "complete_profile"}', 0, 1),
('EXCHANGE_COUPON', '兑换优惠券', 'spend', 100, '兑换优惠券消耗积分', '{"action": "exchange_coupon"}', 0, 0),
('EXCHANGE_VIP', '兑换VIP', 'spend', 500, '兑换VIP会员消耗积分', '{"action": "exchange_vip"}', 0, 0);

-- 插入通知模板
INSERT IGNORE INTO notification_templates (template_code, template_name, template_type, title, content, variables) VALUES
('JOB_APPLY_SUCCESS', '职位申请成功', 'in_app', '申请成功', '您申请的职位"{job_title}"已成功提交，我们会尽快为您安排面试。', '{"job_title": "职位名称"}'),
('RESUME_VIEWED', '简历被查看', 'in_app', '简历被查看', '您的简历被"{company_name}"查看，请保持电话畅通。', '{"company_name": "公司名称"}'),
('CHAT_MESSAGE', '新消息提醒', 'in_app', '新消息', '您收到来自"{sender_name}"的新消息：{message_preview}', '{"sender_name": "发送者姓名", "message_preview": "消息预览"}'),
('POINTS_EARNED', '获得积分', 'in_app', '获得积分', '恭喜您获得{points}积分！{reason}', '{"points": "积分数量", "reason": "获得原因"}'),
('POINTS_SPENT', '消费积分', 'in_app', '消费积分', '您消费了{points}积分，用于{reason}。', '{"points": "积分数量", "reason": "消费原因"}'),
('SYSTEM_ANNOUNCEMENT', '系统公告', 'in_app', '系统公告', '{title}\n\n{content}', '{"title": "公告标题", "content": "公告内容"}');

-- 为现有用户创建积分账户
INSERT INTO points_accounts (user_id, balance, total_earned, total_spent, level, level_points, next_level_points)
SELECT 
    id,
    100,  -- 初始积分
    100,  -- 初始获得积分
    0,    -- 初始消费积分
    'bronze',
    100,
    200
FROM users_v2
WHERE id NOT IN (SELECT user_id FROM points_accounts);

-- 为现有用户创建通知设置
INSERT INTO user_notification_settings (user_id)
SELECT id FROM users_v2
WHERE id NOT IN (SELECT user_id FROM user_notification_settings);

-- ========================================
-- 5. 创建索引优化
-- ========================================

-- 聊天系统索引
-- CREATE INDEX idx_chat_sessions_participants ON chat_sessions((CAST(participants AS CHAR(1000))));
CREATE INDEX idx_chat_messages_session_time ON chat_messages(session_id, created_at);

-- 积分系统索引
CREATE INDEX idx_points_records_user_time ON points_records(user_id, created_at);
CREATE INDEX idx_points_exchanges_user_status ON points_exchanges(user_id, status);

-- 通知系统索引
CREATE INDEX idx_notifications_user_read ON notifications(user_id, read_status);
CREATE INDEX idx_notifications_type_time ON notifications(notification_type, created_at);

-- ========================================
-- 6. 创建视图
-- ========================================

-- 用户积分统计视图
CREATE OR REPLACE VIEW user_points_summary AS
SELECT 
    pa.user_id,
    u.username,
    pa.balance,
    pa.total_earned,
    pa.total_spent,
    pa.level,
    pa.level_points,
    pa.next_level_points,
    (pa.next_level_points - pa.level_points) as points_needed_for_next_level,
    COUNT(pr.id) as total_records,
    MAX(pr.created_at) as last_activity
FROM points_accounts pa
LEFT JOIN users_v2 u ON pa.user_id = u.id
LEFT JOIN points_records pr ON pa.user_id = pr.user_id
GROUP BY pa.user_id, u.username, pa.balance, pa.total_earned, pa.total_spent, pa.level, pa.level_points, pa.next_level_points;

-- 聊天统计视图
CREATE OR REPLACE VIEW chat_summary AS
SELECT 
    cs.session_id,
    cs.session_type,
    cs.title,
    cs.participants,
    cs.last_message_time,
    cs.unread_count,
    COUNT(cm.id) as total_messages,
    COUNT(DISTINCT cm.sender_id) as unique_senders,
    COUNT(CASE WHEN cm.read_status IS NULL OR JSON_LENGTH(cm.read_status) = 0 THEN 1 END) as unread_messages
FROM chat_sessions cs
LEFT JOIN chat_messages cm ON cs.session_id = cm.session_id
GROUP BY cs.session_id, cs.session_type, cs.title, cs.participants, cs.last_message_time, cs.unread_count;

-- 通知统计视图
CREATE OR REPLACE VIEW notification_summary AS
SELECT 
    user_id,
    notification_type,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN read_status = 'unread' THEN 1 END) as unread_count,
    COUNT(CASE WHEN send_status = 'sent' THEN 1 END) as sent_count,
    MAX(created_at) as last_notification_time
FROM notifications
GROUP BY user_id, notification_type;

-- ========================================
-- 升级完成
-- ========================================

SELECT 'Phase 3 Database Upgrade Completed Successfully!' as status;
