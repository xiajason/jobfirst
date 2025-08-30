-- JobFirst 测试数据脚本
-- 用于验证业务逻辑和功能

USE jobfirst;

-- =====================================================
-- 测试用户数据
-- =====================================================

-- 插入测试用户
INSERT INTO users (username, email, password_hash, phone, avatar_url, status, created_at, updated_at) VALUES
('testuser1', 'test1@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '13800138001', 'https://via.placeholder.com/150', 'active', NOW(), NOW()),
('testuser2', 'test2@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '13800138002', 'https://via.placeholder.com/150', 'active', NOW(), NOW()),
('testuser3', 'test3@example.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '13800138003', 'https://via.placeholder.com/150', 'active', NOW(), NOW()),
('admin', 'admin@jobfirst.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '13800138000', 'https://via.placeholder.com/150', 'active', NOW(), NOW());

-- =====================================================
-- 测试简历数据
-- =====================================================

-- 插入测试简历
INSERT INTO resumes (user_id, title, content, template_id, status, created_at, updated_at) VALUES
(1, '张三的简历', '{"basic_info": {"name": "张三", "phone": "13800138001", "email": "zhangsan@example.com", "address": "北京市朝阳区"}, "experience": [{"company": "腾讯科技", "position": "高级工程师", "duration": "2020-2023", "description": "负责微信小程序开发"}], "education": [{"school": "清华大学", "major": "计算机科学", "degree": "本科", "graduation": "2020"}], "skills": ["JavaScript", "Go", "MySQL", "Redis"]}', 1, 'published', NOW(), NOW()),
(1, '张三的备用简历', '{"basic_info": {"name": "张三", "phone": "13800138001", "email": "zhangsan@example.com", "address": "北京市朝阳区"}, "experience": [{"company": "阿里巴巴", "position": "前端工程师", "duration": "2018-2020", "description": "负责淘宝前端开发"}], "education": [{"school": "清华大学", "major": "计算机科学", "degree": "本科", "graduation": "2020"}], "skills": ["Vue.js", "React", "Node.js"]}', 2, 'draft', NOW(), NOW()),
(2, '李四的简历', '{"basic_info": {"name": "李四", "phone": "13800138002", "email": "lisi@example.com", "address": "上海市浦东新区"}, "experience": [{"company": "字节跳动", "position": "产品经理", "duration": "2021-2023", "description": "负责抖音产品设计"}], "education": [{"school": "复旦大学", "major": "工商管理", "degree": "硕士", "graduation": "2021"}], "skills": ["产品设计", "数据分析", "项目管理"]}', 1, 'published', NOW(), NOW()),
(3, '王五的简历', '{"basic_info": {"name": "王五", "phone": "13800138003", "email": "wangwu@example.com", "address": "深圳市南山区"}, "experience": [{"company": "华为", "position": "硬件工程师", "duration": "2019-2023", "description": "负责手机硬件设计"}], "education": [{"school": "华南理工大学", "major": "电子工程", "degree": "本科", "graduation": "2019"}], "skills": ["电路设计", "PCB设计", "嵌入式开发"]}', 3, 'published', NOW(), NOW());

-- =====================================================
-- 测试积分数据
-- =====================================================

-- 插入测试积分
INSERT INTO points (user_id, points, earned_points, spent_points, created_at, updated_at) VALUES
(1, 850, 1000, 150, NOW(), NOW()),
(2, 420, 500, 80, NOW(), NOW()),
(3, 200, 300, 100, NOW(), NOW()),
(4, 1000, 1000, 0, NOW(), NOW());

-- 插入积分记录
INSERT INTO point_records (user_id, points, type, reason, description, created_at) VALUES
(1, 100, 'earn', 'register', '新用户注册奖励', NOW()),
(1, 50, 'earn', 'create_resume', '创建简历奖励', NOW()),
(1, 20, 'earn', 'share_resume', '分享简历奖励', NOW()),
(1, -10, 'spend', 'download_template', '下载付费模板', NOW()),
(2, 100, 'earn', 'register', '新用户注册奖励', NOW()),
(2, 50, 'earn', 'create_resume', '创建简历奖励', NOW()),
(2, -10, 'spend', 'download_template', '下载付费模板', NOW()),
(3, 100, 'earn', 'register', '新用户注册奖励', NOW()),
(3, 50, 'earn', 'create_resume', '创建简历奖励', NOW()),
(4, 1000, 'earn', 'admin_bonus', '管理员奖励', NOW());

-- =====================================================
-- 测试文件数据
-- =====================================================

-- 插入测试文件
INSERT INTO files (user_id, filename, original_name, file_path, file_size, mime_type, file_type, status, created_at, updated_at) VALUES
(1, 'avatar_1.jpg', 'avatar.jpg', '/uploads/avatars/avatar_1.jpg', 102400, 'image/jpeg', 'image', 'completed', NOW(), NOW()),
(1, 'resume_1.pdf', '张三简历.pdf', '/uploads/resumes/resume_1.pdf', 512000, 'application/pdf', 'document', 'completed', NOW(), NOW()),
(2, 'avatar_2.jpg', 'avatar.jpg', '/uploads/avatars/avatar_2.jpg', 98304, 'image/jpeg', 'image', 'completed', NOW(), NOW()),
(3, 'avatar_3.jpg', 'avatar.jpg', 'avatar.jpg', '/uploads/avatars/avatar_3.jpg', 115200, 'image/jpeg', 'image', 'completed', NOW(), NOW());

-- =====================================================
-- 测试统计事件数据
-- =====================================================

-- 插入测试统计事件
INSERT INTO statistics_events (event_type, user_id, event_data, ip_address, user_agent, created_at) VALUES
('user_login', 1, '{"login_method": "phone", "success": true}', '192.168.1.100', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW()),
('resume_view', 1, '{"resume_id": 1, "viewer_id": 2}', '192.168.1.101', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW()),
('resume_download', 1, '{"resume_id": 1, "downloader_id": 3}', '192.168.1.102', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW()),
('resume_share', 1, '{"resume_id": 1, "share_method": "wechat"}', '192.168.1.100', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW()),
('user_login', 2, '{"login_method": "phone", "success": true}', '192.168.1.103', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW()),
('resume_view', 2, '{"resume_id": 3, "viewer_id": 1}', '192.168.1.100', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)', NOW());

-- =====================================================
-- 测试Banner数据
-- =====================================================

-- 插入测试Banner
INSERT INTO resume_banners (title, image_url, link_url, sort, status, created_at, updated_at) VALUES
('新用户注册送积分', 'https://via.placeholder.com/800x300', '/pages/register/register', 1, 'active', NOW(), NOW()),
('精选简历模板', 'https://via.placeholder.com/800x300', '/pages/templates/templates', 2, 'active', NOW(), NOW()),
('简历优化服务', 'https://via.placeholder.com/800x300', '/pages/services/services', 3, 'active', NOW(), NOW());

-- =====================================================
-- 数据验证
-- =====================================================

-- 验证数据插入结果
SELECT 'Users' as table_name, COUNT(*) as record_count FROM users
UNION ALL
SELECT 'Resumes' as table_name, COUNT(*) as record_count FROM resumes
UNION ALL
SELECT 'Points' as table_name, COUNT(*) as record_count FROM points
UNION ALL
SELECT 'Point Records' as table_name, COUNT(*) as record_count FROM point_records
UNION ALL
SELECT 'Files' as table_name, COUNT(*) as record_count FROM files
UNION ALL
SELECT 'Statistics Events' as table_name, COUNT(*) as record_count FROM statistics_events
UNION ALL
SELECT 'Banners' as table_name, COUNT(*) as record_count FROM resume_banners;

-- 显示测试用户信息
SELECT 'Test Users Info:' as info;
SELECT id, username, email, phone, status FROM users;

-- 显示测试简历信息
SELECT 'Test Resumes Info:' as info;
SELECT id, user_id, title, status FROM resumes;

-- 显示测试积分信息
SELECT 'Test Points Info:' as info;
SELECT user_id, points, earned_points, spent_points FROM points;
