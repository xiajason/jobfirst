-- 完整的前端模拟数据 - 第一部分
-- 包含所有前端页面需要的数据表和数据

-- ========================================
-- 1. 用户相关数据
-- ========================================

-- 插入用户数据
INSERT INTO users (id, username, email, phone, avatar_url, real_name, gender, birth_date, location, education, experience_years, skills, status, created_at, updated_at) VALUES
(1, 'test_user', 'test@example.com', '13800138000', '/images/avatar/user1.jpg', '张三', 'male', '1995-01-15', '深圳', 'bachelor', 3, '["JavaScript", "React", "Vue", "Node.js"]', 'active', NOW(), NOW()),
(2, 'demo_user', 'demo@example.com', '13800138001', '/images/avatar/user2.jpg', '李四', 'female', '1993-05-20', '北京', 'master', 5, '["Java", "Spring", "MySQL", "Redis"]', 'active', NOW(), NOW()),
(3, 'sample_user', 'sample@example.com', '13800138002', '/images/avatar/user3.jpg', '王五', 'male', '1990-08-10', '上海', 'bachelor', 8, '["Python", "Django", "PostgreSQL", "Docker"]', 'active', NOW(), NOW());

-- ========================================
-- 2. 企业数据
-- ========================================

-- 插入企业数据
INSERT INTO companies (id, name, short_name, logo_url, industry, company_size, location, website, description, founded_year, business_license, status, verification_level, job_count, view_count, created_at) VALUES
(1, '腾讯科技有限公司', '腾讯', '/images/company/tencent.png', '互联网', 'enterprise', '深圳', 'https://www.tencent.com', '腾讯是一家以互联网为基础的科技与文化公司，通过技术丰富互联网用户的生活，助力企业数字化升级。', 1998, '91440300708461136T', 'verified', 'premium', 50, 10000, NOW()),
(2, '阿里巴巴集团', '阿里巴巴', '/images/company/alibaba.png', '电子商务', 'enterprise', '杭州', 'https://www.alibaba.com', '阿里巴巴集团旨在赋能企业，帮助其变革营销、销售和经营的方式。', 1999, '91330000710930241C', 'verified', 'premium', 45, 9500, NOW()),
(3, '字节跳动科技有限公司', '字节跳动', '/images/company/bytedance.png', '互联网', 'enterprise', '北京', 'https://www.bytedance.com', '字节跳动是一家全球领先的科技公司，致力于用创新技术丰富人们的生活。', 2012, '91110105MA00B8Y3X4L', 'verified', 'premium', 60, 12000, NOW()),
(4, '百度在线网络技术（北京）有限公司', '百度', '/images/company/baidu.png', '互联网', 'enterprise', '北京', 'https://www.baidu.com', '百度是全球最大的中文搜索引擎，致力于为用户提供最便捷的信息获取方式。', 2000, '91110108700003808G', 'verified', 'premium', 40, 8500, NOW()),
(5, '美团点评集团', '美团', '/images/company/meituan.png', '互联网', 'enterprise', '北京', 'https://www.meituan.com', '美团是一家科技零售公司，致力于帮助大家吃得更好，生活更好。', 2010, '91110105MA00C9LB0U', 'verified', 'premium', 35, 7800, NOW()),
(6, '滴滴出行科技有限公司', '滴滴', '/images/company/didi.png', '互联网', 'enterprise', '北京', 'https://www.didiglobal.com', '滴滴是全球领先的移动出行平台，致力于为全球用户提供安全、便捷、绿色的出行服务。', 2012, '91110105MA00C9LB0U', 'verified', 'premium', 30, 6500, NOW()),
(7, '小米集团', '小米', '/images/company/xiaomi.png', '消费电子', 'enterprise', '北京', 'https://www.mi.com', '小米是一家专注于智能硬件和电子产品研发的全球化移动互联网企业。', 2010, '91110105MA00C9LB0U', 'verified', 'premium', 25, 5500, NOW()),
(8, '华为技术有限公司', '华为', '/images/company/huawei.png', '通信设备', 'enterprise', '深圳', 'https://www.huawei.com', '华为是全球领先的ICT基础设施和智能终端提供商。', 1987, '91440300192181458C', 'verified', 'premium', 55, 11000, NOW());

-- ========================================
-- 3. 职位分类数据
-- ========================================

-- 插入职位分类数据
INSERT INTO job_categories (id, name, parent_id, level, sort_order, icon, description, job_count, status, created_at) VALUES
(1, '技术', NULL, 1, 1, 'tech', '技术类职位', 0, 'active', NOW()),
(2, '产品', NULL, 1, 2, 'product', '产品类职位', 0, 'active', NOW()),
(3, '设计', NULL, 1, 3, 'design', '设计类职位', 0, 'active', NOW()),
(4, '运营', NULL, 1, 4, 'operation', '运营类职位', 0, 'active', NOW()),
(5, '销售', NULL, 1, 5, 'sales', '销售类职位', 0, 'active', NOW()),
(6, '前端开发', 1, 2, 1, 'frontend', '前端开发工程师', 0, 'active', NOW()),
(7, '后端开发', 1, 2, 2, 'backend', '后端开发工程师', 0, 'active', NOW()),
(8, '算法工程师', 1, 2, 3, 'algorithm', '算法工程师', 0, 'active', NOW()),
(9, '产品经理', 2, 2, 1, 'pm', '产品经理', 0, 'active', NOW()),
(10, 'UI设计师', 3, 2, 1, 'ui', 'UI设计师', 0, 'active', NOW()),
(11, '运营专员', 4, 2, 1, 'operation', '运营专员', 0, 'active', NOW()),
(12, '销售代表', 5, 2, 1, 'sales', '销售代表', 0, 'active', NOW());
