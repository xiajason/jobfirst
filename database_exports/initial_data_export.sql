-- JobFirst 数据库初始数据导出
-- 导出时间: $(date)
-- 说明: 此文件包含数据库中所有初始数据，用于参考和迁移

USE jobfirst;

-- =====================================================
-- 简历模板初始数据
-- =====================================================

-- 清空现有数据（可选）
-- DELETE FROM resume_templates;

-- 插入简历模板数据
INSERT INTO resume_templates (id, name, description, template_data, category, is_free, price, status, created_at, updated_at, preview_url, is_active) VALUES
('template-001', '经典商务模板', '适合商务人士的经典简历模板', '{"sections": ["basic_info", "experience", "education", "skills"]}', 'business', 1, 0, 'active', '2025-08-29 09:16:59.000', '2025-08-29 09:16:59.000', NULL, 1),
('template-002', '创意设计模板', '适合设计师的创意简历模板', '{"sections": ["basic_info", "portfolio", "experience", "skills"]}', 'creative', 1, 0, 'active', '2025-08-29 09:16:59.000', '2025-08-29 09:16:59.000', NULL, 1),
('template-003', '技术开发模板', '适合程序员的专业简历模板', '{"sections": ["basic_info", "skills", "experience", "projects"]}', 'technology', 1, 0, 'active', '2025-08-29 09:16:59.000', '2025-08-29 09:16:59.000', NULL, 1);

-- =====================================================
-- 积分规则初始数据（来自迁移脚本）
-- =====================================================

-- 插入积分规则数据
INSERT INTO points_rules (id, name, source, points, description, is_active, daily_limit, created_at, updated_at) VALUES
('rule-001', '注册奖励', 'register', 100, '新用户注册奖励', 1, 1, NOW(), NOW()),
('rule-002', '每日登录', 'daily_login', 10, '每日登录奖励', 1, 1, NOW(), NOW()),
('rule-003', '创建简历', 'create_resume', 50, '创建新简历奖励', 1, 5, NOW(), NOW()),
('rule-004', '分享简历', 'share_resume', 20, '分享简历奖励', 1, 10, NOW(), NOW()),
('rule-005', '下载模板', 'download_template', -10, '下载付费模板消费', 1, NULL, NOW(), NOW());

-- =====================================================
-- 数据说明
-- =====================================================

/*
简历模板数据结构说明：

1. 经典商务模板 (template-001)
   - 分类: business
   - 适用人群: 商务人士
   - 包含章节: 基本信息、工作经验、教育背景、技能
   - 价格: 免费

2. 创意设计模板 (template-002)
   - 分类: creative
   - 适用人群: 设计师
   - 包含章节: 基本信息、作品集、工作经验、技能
   - 价格: 免费

3. 技术开发模板 (template-003)
   - 分类: technology
   - 适用人群: 程序员
   - 包含章节: 基本信息、技能、工作经验、项目经验
   - 价格: 免费

积分规则说明：

1. 注册奖励: 新用户注册获得100积分
2. 每日登录: 每日登录获得10积分
3. 创建简历: 创建新简历获得50积分
4. 分享简历: 分享简历获得20积分
5. 下载模板: 下载付费模板消费10积分

使用说明：
1. 直接执行此SQL文件可以插入初始数据
2. 可以根据需要修改模板内容和积分规则
3. 建议在导入前备份现有数据
*/

-- 验证数据插入
SELECT 'Resume Templates' as table_name, COUNT(*) as record_count FROM resume_templates
UNION ALL
SELECT 'Points Rules' as table_name, COUNT(*) as record_count FROM points_rules;
