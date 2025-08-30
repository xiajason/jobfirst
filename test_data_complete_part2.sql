-- 完整的前端模拟数据 - 第二部分
-- 继续添加职位、轮播图、简历等数据

-- ========================================
-- 4. 职位数据
-- ========================================

-- 插入职位数据
INSERT INTO jobs (id, company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, benefits, skills, tags, status, priority, view_count, application_count, favorite_count, publish_at, created_at) VALUES
(1, 1, 6, '前端开发工程师', 'full_time', '深圳', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责腾讯产品的前端开发工作，包括但不限于：\n1. 负责公司产品的前端开发\n2. 与产品、设计、后端工程师协作\n3. 优化前端性能，提升用户体验', '1. 本科及以上学历，计算机相关专业\n2. 熟悉HTML、CSS、JavaScript\n3. 熟悉React、Vue等前端框架\n4. 有良好的代码风格和团队协作能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["JavaScript", "React", "Vue", "HTML", "CSS"]', '["前端", "React", "Vue", "JavaScript"]', 'published', 1, 120, 15, 8, NOW(), NOW()),
(2, 1, 7, '后端开发工程师', 'full_time', '深圳', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责腾讯产品的后端开发工作，包括但不限于：\n1. 负责公司产品的后端开发\n2. 设计并实现高可用、高性能的系统架构\n3. 与前端、产品、测试工程师协作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉Go、Java、Python等后端语言\n3. 熟悉MySQL、Redis等数据库\n4. 有良好的代码风格和团队协作能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Go", "Java", "Python", "MySQL", "Redis"]', '["后端", "Go", "Java", "Python"]', 'published', 1, 95, 12, 6, NOW(), NOW()),
(3, 2, 9, '产品经理', 'full_time', '杭州', 25000, 40000, 'monthly', 'mid', 'bachelor', '负责阿里巴巴产品的产品管理工作，包括但不限于：\n1. 负责产品规划和需求分析\n2. 与设计、开发、测试团队协作\n3. 跟踪产品数据，持续优化产品', '1. 本科及以上学历，计算机或相关专业\n2. 熟悉产品设计流程\n3. 有良好的沟通能力和团队协作能力\n4. 有互联网产品经验优先', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["产品设计", "数据分析", "用户研究", "项目管理"]', '["产品", "产品经理", "数据分析"]', 'published', 1, 88, 10, 5, NOW(), NOW()),
(4, 3, 8, '算法工程师', 'full_time', '北京', 30000, 50000, 'monthly', 'senior', 'master', '负责字节跳动产品的算法开发工作，包括但不限于：\n1. 负责推荐算法、搜索算法的开发\n2. 优化算法性能，提升用户体验\n3. 与产品、工程团队协作', '1. 硕士及以上学历，计算机、数学或相关专业\n2. 熟悉机器学习、深度学习算法\n3. 熟悉Python、C++等编程语言\n4. 有推荐系统、搜索系统经验优先', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Python", "C++", "机器学习", "深度学习", "推荐系统"]', '["算法", "机器学习", "深度学习"]', 'published', 1, 156, 20, 12, NOW(), NOW()),
(5, 4, 7, '后端开发工程师', 'full_time', '北京', 18000, 30000, 'monthly', 'mid', 'bachelor', '负责百度产品的后端开发工作，包括但不限于：\n1. 负责公司产品的后端开发\n2. 设计并实现高可用、高性能的系统架构\n3. 与前端、产品、测试工程师协作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉Java、Python、Go等后端语言\n3. 熟悉MySQL、Redis、MongoDB等数据库\n4. 有良好的代码风格和团队协作能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Java", "Python", "Go", "MySQL", "Redis"]', '["后端", "Java", "Python"]', 'published', 1, 75, 8, 4, NOW(), NOW()),
(6, 5, 11, '运营专员', 'full_time', '北京', 8000, 15000, 'monthly', 'entry', 'bachelor', '负责美团产品的运营工作，包括但不限于：\n1. 负责产品运营策略制定\n2. 用户增长和活跃度提升\n3. 数据分析，持续优化运营效果', '1. 本科及以上学历，市场营销或相关专业\n2. 熟悉运营工作流程\n3. 有良好的沟通能力和数据分析能力\n4. 有互联网运营经验优先', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["数据分析", "用户运营", "内容运营", "活动运营"]', '["运营", "数据分析", "用户增长"]', 'published', 1, 65, 6, 3, NOW(), NOW()),
(7, 6, 7, '后端开发工程师', 'full_time', '北京', 20000, 35000, 'monthly', 'senior', 'bachelor', '负责滴滴产品的后端开发工作，包括但不限于：\n1. 负责公司产品的后端开发\n2. 设计并实现高可用、高性能的系统架构\n3. 与前端、产品、测试工程师协作', '1. 本科及以上学历，计算机相关专业\n2. 熟悉Java、Go、Python等后端语言\n3. 熟悉MySQL、Redis、Kafka等中间件\n4. 有良好的代码风格和团队协作能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Java", "Go", "Python", "MySQL", "Redis"]', '["后端", "Java", "Go"]', 'published', 1, 85, 10, 5, NOW(), NOW()),
(8, 7, 6, '前端开发工程师', 'full_time', '北京', 12000, 20000, 'monthly', 'junior', 'bachelor', '负责小米产品的前端开发工作，包括但不限于：\n1. 负责公司产品的前端开发\n2. 与产品、设计、后端工程师协作\n3. 优化前端性能，提升用户体验', '1. 本科及以上学历，计算机相关专业\n2. 熟悉HTML、CSS、JavaScript\n3. 熟悉React、Vue等前端框架\n4. 有良好的代码风格和团队协作能力', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["JavaScript", "React", "Vue", "HTML", "CSS"]', '["前端", "React", "Vue", "JavaScript"]', 'published', 1, 70, 8, 4, NOW(), NOW()),
(9, 8, 8, '算法工程师', 'full_time', '深圳', 35000, 60000, 'monthly', 'expert', 'phd', '负责华为产品的算法开发工作，包括但不限于：\n1. 负责AI算法、通信算法的开发\n2. 优化算法性能，提升产品竞争力\n3. 与产品、工程团队协作', '1. 博士学历，计算机、数学或相关专业\n2. 熟悉机器学习、深度学习算法\n3. 熟悉Python、C++等编程语言\n4. 有AI、通信算法经验优先', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Python", "C++", "机器学习", "深度学习", "AI算法"]', '["算法", "AI", "机器学习"]', 'published', 1, 200, 25, 15, NOW(), NOW()),
(10, 1, 10, 'UI设计师', 'full_time', '深圳', 12000, 20000, 'monthly', 'mid', 'bachelor', '负责腾讯产品的UI设计工作，包括但不限于：\n1. 负责产品界面设计\n2. 与产品、开发团队协作\n3. 优化用户体验，提升产品美观度', '1. 本科及以上学历，设计相关专业\n2. 熟悉设计工具如Sketch、Figma等\n3. 有良好的审美能力和设计能力\n4. 有互联网产品设计经验优先', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金\n4. 带薪年假\n5. 免费工作餐', '["Sketch", "Figma", "Photoshop", "Illustrator"]', '["UI设计", "用户体验", "界面设计"]', 'published', 1, 60, 5, 3, NOW(), NOW());

-- 插入更多热门职位
INSERT INTO jobs (id, company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, benefits, skills, tags, status, priority, view_count, application_count, favorite_count, publish_at, created_at) VALUES
(11, 2, 6, '高级前端开发工程师', 'full_time', '杭州', 25000, 40000, 'monthly', 'senior', 'bachelor', '负责阿里巴巴核心产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上前端开发经验\n3. 精通React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "TypeScript"]', '["前端", "React", "Vue", "高级"]', 'published', 2, 180, 22, 12, NOW(), NOW()),
(12, 3, 7, '高级后端开发工程师', 'full_time', '北京', 30000, 50000, 'monthly', 'senior', 'bachelor', '负责字节跳动核心产品的后端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上后端开发经验\n3. 精通Go、Java等后端语言', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Go", "Java", "MySQL", "Redis"]', '["后端", "Go", "Java", "高级"]', 'published', 2, 160, 18, 10, NOW(), NOW()),
(13, 4, 9, '高级产品经理', 'full_time', '北京', 35000, 55000, 'monthly', 'senior', 'bachelor', '负责百度核心产品的产品管理工作', '1. 本科及以上学历，计算机或相关专业\n2. 5年以上产品经理经验\n3. 熟悉产品设计流程', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["产品设计", "数据分析", "用户研究"]', '["产品", "产品经理", "高级"]', 'published', 2, 140, 15, 8, NOW(), NOW()),
(14, 5, 8, '机器学习工程师', 'full_time', '北京', 40000, 60000, 'monthly', 'senior', 'master', '负责美团推荐系统的算法开发工作', '1. 硕士及以上学历，计算机、数学或相关专业\n2. 3年以上机器学习经验\n3. 熟悉推荐算法', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Python", "机器学习", "深度学习", "推荐系统"]', '["算法", "机器学习", "推荐系统"]', 'published', 2, 220, 28, 16, NOW(), NOW()),
(15, 6, 6, '前端开发工程师', 'full_time', '北京', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责滴滴产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 3年以上前端开发经验\n3. 熟悉React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "TypeScript"]', '["前端", "React", "Vue"]', 'published', 2, 110, 12, 7, NOW(), NOW());

-- ========================================
-- 5. 轮播图数据
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
INSERT INTO banners (id, title, image_url, link_url, link_type, sort_order, status, start_time, end_time, created_at) VALUES
(1, '春季招聘会', '/images/banner1.jpg', '/pages/activity/spring', 'page', 1, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(2, '名企直招', '/images/banner2.jpg', '/pages/activity/companies', 'page', 2, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(3, '应届生专场', '/images/banner3.jpg', '/pages/activity/fresh', 'page', 3, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(4, '技术岗位专场', '/images/banner4.jpg', '/pages/activity/tech', 'page', 4, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW()),
(5, '高薪职位推荐', '/images/banner5.jpg', '/pages/activity/salary', 'page', 5, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), NOW());

-- ========================================
-- 6. 简历数据
-- ========================================

-- 创建resume_templates表（如果不存在）
CREATE TABLE IF NOT EXISTS resume_templates (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    template_data JSON NOT NULL COMMENT '模板数据',
    category VARCHAR(50) COMMENT '模板分类',
    preview_image VARCHAR(500) COMMENT '预览图片',
    is_free BOOLEAN DEFAULT TRUE COMMENT '是否免费',
    price DECIMAL(10,2) DEFAULT 0.00 COMMENT '价格',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    use_count INT DEFAULT 0 COMMENT '使用次数',
    rating DECIMAL(3,2) DEFAULT 0.00 COMMENT '评分',
    status ENUM('active', 'inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_is_free (is_free),
    INDEX idx_rating (rating),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入简历模板数据
INSERT INTO resume_templates (id, name, description, template_data, category, preview_image, is_free, price, download_count, use_count, rating, status, created_at) VALUES
(1, '标准模板', '通用简历模板，适合大多数职位', '{"sections": ["basic_info", "education", "experience", "skills"]}', 'standard', '/images/templates/standard.jpg', TRUE, 0.00, 150, 89, 4.5, 'active', NOW()),
(2, '技术模板', '专为技术岗位设计的简历模板', '{"sections": ["basic_info", "education", "experience", "skills", "projects"]}', 'technical', '/images/templates/technical.jpg', TRUE, 0.00, 120, 67, 4.3, 'active', NOW()),
(3, '设计模板', '适合设计类岗位的简历模板', '{"sections": ["basic_info", "education", "experience", "skills", "portfolio"]}', 'design', '/images/templates/design.jpg', FALSE, 9.90, 80, 45, 4.7, 'active', NOW()),
(4, '管理模板', '适合管理岗位的简历模板', '{"sections": ["basic_info", "education", "experience", "achievements", "leadership"]}', 'management', '/images/templates/management.jpg', FALSE, 12.90, 60, 32, 4.6, 'active', NOW());

-- 创建resumes表（如果不存在）
CREATE TABLE IF NOT EXISTS resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    template_id BIGINT UNSIGNED NULL COMMENT '模板ID',
    title VARCHAR(200) NOT NULL COMMENT '简历标题',
    content JSON NOT NULL COMMENT '简历内容',
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft' COMMENT '状态',
    is_default BOOLEAN DEFAULT FALSE COMMENT '是否默认简历',
    view_count INT DEFAULT 0 COMMENT '浏览次数',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    share_count INT DEFAULT 0 COMMENT '分享次数',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES resume_templates(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_template_id (template_id),
    INDEX idx_is_default (is_default),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入简历数据
INSERT INTO resumes (id, user_id, template_id, title, content, status, is_default, view_count, download_count, share_count, created_at) VALUES
(1, 1, 1, '我的简历', '{"basic_info": {"name": "张三", "email": "zhangsan@example.com", "phone": "13800138000"}, "education": [{"school": "清华大学", "degree": "计算机科学学士", "year": "2018"}], "experience": [{"company": "腾讯", "position": "前端开发工程师", "duration": "2020-2023"}]}', 'published', TRUE, 25, 3, 1, NOW()),
(2, 2, 2, '技术简历', '{"basic_info": {"name": "李四", "email": "lisi@example.com", "phone": "13800138001"}, "education": [{"school": "北京大学", "degree": "软件工程硕士", "year": "2019"}], "experience": [{"company": "阿里巴巴", "position": "后端开发工程师", "duration": "2019-2023"}]}', 'published', TRUE, 18, 2, 0, NOW()),
(3, 3, 3, '设计简历', '{"basic_info": {"name": "王五", "email": "wangwu@example.com", "phone": "13800138002"}, "education": [{"school": "中央美术学院", "degree": "视觉传达设计学士", "year": "2017"}], "experience": [{"company": "字节跳动", "position": "UI设计师", "duration": "2018-2023"}]}', 'published', TRUE, 30, 5, 2, NOW());

-- ========================================
-- 7. 职位申请数据
-- ========================================

-- 插入职位申请数据
INSERT INTO job_applications (id, job_id, user_id, resume_id, cover_letter, status, hr_feedback, interview_time, interview_location, created_at) VALUES
(1, 1, 1, 1, '我对前端开发有浓厚的兴趣，希望能在腾讯这样的大公司工作。', 'pending', NULL, NULL, NULL, NOW()),
(2, 2, 2, 2, '我有丰富的后端开发经验，希望能加入腾讯团队。', 'reviewing', '简历已通过初筛，等待面试安排', NULL, NULL, NOW()),
(3, 3, 1, 1, '我对产品管理有深入的理解，希望能加入阿里巴巴。', 'interview', '请于下周三下午2点参加面试', '2024-01-15 14:00:00', '杭州市余杭区文一西路969号', NOW()),
(4, 4, 3, 3, '我在算法领域有丰富的研究经验，希望能加入字节跳动。', 'accepted', '恭喜您通过面试，欢迎加入我们！', NULL, NULL, NOW()),
(5, 5, 2, 2, '我对百度的发展前景很看好，希望能加入百度团队。', 'rejected', '很抱歉，您的经验与岗位要求不完全匹配', NULL, NULL, NOW());

-- ========================================
-- 8. 更新统计数据
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
-- 9. 企业详情数据
-- ========================================

-- 插入企业详情数据
INSERT INTO company_profiles (company_id, contact_person, contact_phone, contact_email, business_scope, company_culture, benefits, photos, social_media, created_at) VALUES
(1, '张先生', '0755-12345678', 'hr@tencent.com', '互联网技术开发、网络游戏、社交媒体、数字内容等', '以用户价值为依归，发展安全健康活跃平台', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/tencent1.jpg", "/images/company/tencent2.jpg"]', '{"weibo": "腾讯招聘", "wechat": "腾讯招聘"}', NOW()),
(2, '李女士', '0571-87654321', 'hr@alibaba.com', '电子商务、云计算、数字媒体和娱乐、创新业务等', '让天下没有难做的生意', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/alibaba1.jpg", "/images/company/alibaba2.jpg"]', '{"weibo": "阿里巴巴招聘", "wechat": "阿里巴巴招聘"}', NOW()),
(3, '王先生', '010-12345678', 'hr@bytedance.com', '短视频、直播、教育、游戏、企业服务等', '激发创造，丰富生活', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/bytedance1.jpg", "/images/company/bytedance2.jpg"]', '{"weibo": "字节跳动招聘", "wechat": "字节跳动招聘"}', NOW()),
(4, '赵女士', '010-87654321', 'hr@baidu.com', '搜索引擎、人工智能、自动驾驶、云计算等', '用科技让复杂的世界更简单', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/baidu1.jpg", "/images/company/baidu2.jpg"]', '{"weibo": "百度招聘", "wechat": "百度招聘"}', NOW()),
(5, '孙先生', '010-12345679', 'hr@meituan.com', '外卖、酒店、旅游、出行等生活服务', '帮大家吃得更好，生活更好', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/meituan1.jpg", "/images/company/meituan2.jpg"]', '{"weibo": "美团招聘", "wechat": "美团招聘"}', NOW());

-- ========================================
-- 完成统计
-- ========================================

-- 完成
SELECT '第二部分模拟数据插入完成！' as message;
SELECT COUNT(*) as total_jobs FROM jobs WHERE status = 'published';
SELECT COUNT(*) as total_banners FROM banners WHERE status = 'active';
SELECT COUNT(*) as total_resumes FROM resumes WHERE status = 'published';
SELECT COUNT(*) as total_applications FROM job_applications;
