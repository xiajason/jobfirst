-- JobFirst 测试数据脚本 - 简历和积分数据
-- 用于验证业务逻辑和功能

USE jobfirst;

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
SELECT 'Resumes' as table_name, COUNT(*) as record_count FROM resumes
UNION ALL
SELECT 'Points' as table_name, COUNT(*) as record_count FROM points
UNION ALL
SELECT 'Point Records' as table_name, COUNT(*) as record_count FROM point_records
UNION ALL
SELECT 'Banners' as table_name, COUNT(*) as record_count FROM resume_banners;

-- 显示测试简历信息
SELECT 'Test Resumes Info:' as info;
SELECT id, user_id, title, status FROM resumes;

-- 显示测试积分信息
SELECT 'Test Points Info:' as info;
SELECT user_id, points, earned_points, spent_points FROM points;
