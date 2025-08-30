-- 添加更多职位数据
-- 只使用现有的企业ID（1-6）

-- ========================================
-- 添加更多热门职位
-- ========================================

-- 插入更多职位数据（从ID 16开始，只使用企业ID 1-6）
INSERT INTO jobs (id, company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, benefits, skills, tags, status, priority, view_count, application_count, favorite_count, publish_at, created_at) VALUES
(16, 1, 6, '高级前端开发工程师', 'full_time', '深圳', 25000, 40000, 'monthly', 'senior', 'bachelor', '负责腾讯核心产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上前端开发经验\n3. 精通React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "TypeScript"]', '["前端", "React", "Vue", "高级"]', 'published', 2, 180, 22, 12, NOW(), NOW()),
(17, 2, 7, '高级后端开发工程师', 'full_time', '杭州', 30000, 50000, 'monthly', 'senior', 'bachelor', '负责阿里巴巴核心产品的后端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上后端开发经验\n3. 精通Java、Go等后端语言', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Java", "Go", "MySQL", "Redis"]', '["后端", "Java", "Go", "高级"]', 'published', 2, 160, 18, 10, NOW(), NOW()),
(18, 3, 8, '算法工程师', 'full_time', '北京', 35000, 60000, 'monthly', 'senior', 'master', '负责字节跳动推荐系统的算法开发工作', '1. 硕士及以上学历，计算机、数学或相关专业\n2. 3年以上机器学习经验\n3. 熟悉推荐算法', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Python", "机器学习", "深度学习", "推荐系统"]', '["算法", "机器学习", "推荐系统"]', 'published', 2, 220, 28, 16, NOW(), NOW()),
(19, 4, 9, '高级产品经理', 'full_time', '北京', 35000, 55000, 'monthly', 'senior', 'bachelor', '负责百度核心产品的产品管理工作', '1. 本科及以上学历，计算机或相关专业\n2. 5年以上产品经理经验\n3. 熟悉产品设计流程', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["产品设计", "数据分析", "用户研究"]', '["产品", "产品经理", "高级"]', 'published', 2, 140, 15, 8, NOW(), NOW()),
(20, 5, 10, 'UI设计师', 'full_time', '北京', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责美团产品的UI设计工作', '1. 本科及以上学历，设计相关专业\n2. 熟悉设计工具如Sketch、Figma等\n3. 有良好的审美能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Sketch", "Figma", "Photoshop", "Illustrator"]', '["UI设计", "用户体验", "界面设计"]', 'published', 1, 95, 12, 6, NOW(), NOW()),
(21, 6, 11, '运营专员', 'full_time', '北京', 8000, 15000, 'monthly', 'entry', 'bachelor', '负责滴滴产品的运营工作', '1. 本科及以上学历，市场营销或相关专业\n2. 熟悉运营工作流程\n3. 有良好的沟通能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["数据分析", "用户运营", "内容运营", "活动运营"]', '["运营", "数据分析", "用户增长"]', 'published', 1, 65, 6, 3, NOW(), NOW()),
(22, 1, 7, '后端开发工程师', 'full_time', '深圳', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责腾讯产品的后端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉Go、Java、Python等后端语言\n3. 熟悉MySQL、Redis等数据库', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Go", "Java", "Python", "MySQL", "Redis"]', '["后端", "Go", "Java", "Python"]', 'published', 1, 95, 12, 6, NOW(), NOW()),
(23, 2, 6, '前端开发工程师', 'full_time', '杭州', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责阿里巴巴产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉HTML、CSS、JavaScript\n3. 熟悉React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "HTML", "CSS"]', '["前端", "React", "Vue", "JavaScript"]', 'published', 1, 120, 15, 8, NOW(), NOW()),
(24, 3, 9, '产品经理', 'full_time', '北京', 25000, 40000, 'monthly', 'mid', 'bachelor', '负责字节跳动产品的产品管理工作', '1. 本科及以上学历，计算机或相关专业\n2. 熟悉产品设计流程\n3. 有良好的沟通能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["产品设计", "数据分析", "用户研究", "项目管理"]', '["产品", "产品经理", "数据分析"]', 'published', 1, 88, 10, 5, NOW(), NOW()),
(25, 4, 7, '后端开发工程师', 'full_time', '北京', 18000, 30000, 'monthly', 'mid', 'bachelor', '负责百度产品的后端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉Java、Python、Go等后端语言\n3. 熟悉MySQL、Redis等数据库', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Java", "Python", "Go", "MySQL", "Redis"]', '["后端", "Java", "Python"]', 'published', 1, 75, 8, 4, NOW(), NOW());

-- ========================================
-- 创建轮播图表（如果不存在）
-- ========================================

-- 创建banners表（如果不存在）
CREATE TABLE IF NOT EXISTS banners (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL COMMENT '轮播图标题',
    image_url VARCHAR(500) NOT NULL COMMENT '图片URL',
    link_url VARCHAR(500) COMMENT '链接URL',
    link_type ENUM('page', 'url', 'none') DEFAULT 'page' COMMENT '链接类型',
    sort_order INT DEFAULT 0 COMMENT '排序',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    start_time DATETIME COMMENT '开始时间',
    end_time DATETIME COMMENT '结束时间',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_status (status),
    INDEX idx_sort_order (sort_order),
    INDEX idx_start_time (start_time),
    INDEX idx_end_time (end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入轮播图数据
INSERT IGNORE INTO banners (id, title, image_url, link_url, link_type, sort_order, status, start_time, end_time, created_at) VALUES
(1, '春季招聘会', '/images/banner1.jpg', '/pages/activity/spring', 'page', 1, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(2, '名企直招', '/images/banner2.jpg', '/pages/activity/companies', 'page', 2, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(3, '应届生专场', '/images/banner3.jpg', '/pages/activity/fresh', 'page', 3, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(4, '技术岗位专场', '/images/banner4.jpg', '/pages/activity/tech', 'page', 4, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(5, '高薪职位推荐', '/images/banner5.jpg', '/pages/activity/salary', 'page', 5, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW());

-- ========================================
-- 更新统计数据
-- ========================================

-- 更新企业职位数量
UPDATE companies SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE company_id = companies.id AND status = 'published'
);

-- 更新职位分类数量
UPDATE job_categories SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE category_id = job_categories.id AND status = 'published'
);

-- ========================================
-- 完成统计
-- ========================================

-- 完成
SELECT '修正的额外模拟数据插入完成！' as message;
SELECT COUNT(*) as total_jobs FROM jobs WHERE status = 'published';
SELECT COUNT(*) as total_banners FROM banners WHERE status = 'active';
SELECT '企业职位数量统计:' as info;
SELECT id, name, job_count FROM companies ORDER BY id;
