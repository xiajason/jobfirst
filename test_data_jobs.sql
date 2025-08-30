-- 职位和企业模拟数据
-- 用于解决前端加载热门职位404问题

-- 1. 插入企业数据
INSERT INTO companies (id, name, short_name, logo_url, industry, company_size, location, website, description, founded_year, business_license, status, verification_level, job_count, view_count, created_at) VALUES
(1, '腾讯科技有限公司', '腾讯', '/images/company/tencent.png', '互联网', 'enterprise', '深圳', 'https://www.tencent.com', '腾讯是一家以互联网为基础的科技与文化公司，通过技术丰富互联网用户的生活，助力企业数字化升级。', 1998, '91440300708461136T', 'verified', 'premium', 50, 10000, NOW()),
(2, '阿里巴巴集团', '阿里巴巴', '/images/company/alibaba.png', '电子商务', 'enterprise', '杭州', 'https://www.alibaba.com', '阿里巴巴集团旨在赋能企业，帮助其变革营销、销售和经营的方式。', 1999, '91330000710930241C', 'verified', 'premium', 45, 9500, NOW()),
(3, '字节跳动科技有限公司', '字节跳动', '/images/company/bytedance.png', '互联网', 'enterprise', '北京', 'https://www.bytedance.com', '字节跳动是一家全球领先的科技公司，致力于用创新技术丰富人们的生活。', 2012, '91110105MA00B8Y3X4L', 'verified', 'premium', 60, 12000, NOW()),
(4, '百度在线网络技术（北京）有限公司', '百度', '/images/company/baidu.png', '互联网', 'enterprise', '北京', 'https://www.baidu.com', '百度是全球最大的中文搜索引擎，致力于为用户提供最便捷的信息获取方式。', 2000, '91110108700003808G', 'verified', 'premium', 40, 8500, NOW()),
(5, '美团点评集团', '美团', '/images/company/meituan.png', '互联网', 'enterprise', '北京', 'https://www.meituan.com', '美团是一家科技零售公司，致力于帮助大家吃得更好，生活更好。', 2010, '91110105MA00C9LB0U', 'verified', 'premium', 35, 7800, NOW()),
(6, '滴滴出行科技有限公司', '滴滴', '/images/company/didi.png', '互联网', 'enterprise', '北京', 'https://www.didiglobal.com', '滴滴是全球领先的移动出行平台，致力于为全球用户提供安全、便捷、绿色的出行服务。', 2012, '91110105MA00C9LB0U', 'verified', 'premium', 30, 6500, NOW()),
(7, '小米集团', '小米', '/images/company/xiaomi.png', '消费电子', 'enterprise', '北京', 'https://www.mi.com', '小米是一家专注于智能硬件和电子产品研发的全球化移动互联网企业。', 2010, '91110105MA00C9LB0U', 'verified', 'premium', 25, 5500, NOW()),
(8, '华为技术有限公司', '华为', '/images/company/huawei.png', '通信设备', 'enterprise', '深圳', 'https://www.huawei.com', '华为是全球领先的ICT基础设施和智能终端提供商。', 1987, '91440300192181458C', 'verified', 'premium', 55, 11000, NOW());

-- 2. 插入职位分类数据
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

-- 3. 插入职位数据
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

-- 4. 更新企业职位数量
UPDATE companies SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE company_id = companies.id AND status = 'published'
);

-- 5. 更新职位分类数量
UPDATE job_categories SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE category_id = job_categories.id AND status = 'published'
);

-- 6. 插入一些热门职位（用于首页展示）
INSERT INTO jobs (id, company_id, category_id, title, job_type, location, salary_min, salary_max, salary_type, experience_required, education_required, description, requirements, benefits, skills, tags, status, priority, view_count, application_count, favorite_count, publish_at, created_at) VALUES
(11, 2, 6, '高级前端开发工程师', 'full_time', '杭州', 25000, 40000, 'monthly', 'senior', 'bachelor', '负责阿里巴巴核心产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上前端开发经验\n3. 精通React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "TypeScript"]', '["前端", "React", "Vue", "高级"]', 'published', 2, 180, 22, 12, NOW(), NOW()),
(12, 3, 7, '高级后端开发工程师', 'full_time', '北京', 30000, 50000, 'monthly', 'senior', 'bachelor', '负责字节跳动核心产品的后端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 5年以上后端开发经验\n3. 精通Go、Java等后端语言', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Go", "Java", "MySQL", "Redis"]', '["后端", "Go", "Java", "高级"]', 'published', 2, 160, 18, 10, NOW(), NOW()),
(13, 4, 9, '高级产品经理', 'full_time', '北京', 35000, 55000, 'monthly', 'senior', 'bachelor', '负责百度核心产品的产品管理工作', '1. 本科及以上学历，计算机或相关专业\n2. 5年以上产品经理经验\n3. 熟悉产品设计流程', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["产品设计", "数据分析", "用户研究"]', '["产品", "产品经理", "高级"]', 'published', 2, 140, 15, 8, NOW(), NOW()),
(14, 5, 8, '机器学习工程师', 'full_time', '北京', 40000, 60000, 'monthly', 'senior', 'master', '负责美团推荐系统的算法开发工作', '1. 硕士及以上学历，计算机、数学或相关专业\n2. 3年以上机器学习经验\n3. 熟悉推荐算法', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["Python", "机器学习", "深度学习", "推荐系统"]', '["算法", "机器学习", "推荐系统"]', 'published', 2, 220, 28, 16, NOW(), NOW()),
(15, 6, 6, '前端开发工程师', 'full_time', '北京', 15000, 25000, 'monthly', 'mid', 'bachelor', '负责滴滴产品的前端开发工作', '1. 本科及以上学历，计算机相关专业\n2. 3年以上前端开发经验\n3. 熟悉React、Vue等前端框架', '1. 具有竞争力的薪资待遇\n2. 完善的五险一金\n3. 年终奖金', '["JavaScript", "React", "Vue", "TypeScript"]', '["前端", "React", "Vue"]', 'published', 2, 110, 12, 7, NOW(), NOW());

-- 7. 再次更新企业职位数量
UPDATE companies SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE company_id = companies.id AND status = 'published'
);

-- 8. 再次更新职位分类数量
UPDATE job_categories SET job_count = (
    SELECT COUNT(*) FROM jobs WHERE category_id = job_categories.id AND status = 'published'
);

-- 9. 插入一些企业详情数据
INSERT INTO company_profiles (company_id, contact_person, contact_phone, contact_email, business_scope, company_culture, benefits, photos, social_media, created_at) VALUES
(1, '张先生', '0755-12345678', 'hr@tencent.com', '互联网技术开发、网络游戏、社交媒体、数字内容等', '以用户价值为依归，发展安全健康活跃平台', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/tencent1.jpg", "/images/company/tencent2.jpg"]', '{"weibo": "腾讯招聘", "wechat": "腾讯招聘"}', NOW()),
(2, '李女士', '0571-87654321', 'hr@alibaba.com', '电子商务、云计算、数字媒体和娱乐、创新业务等', '让天下没有难做的生意', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/alibaba1.jpg", "/images/company/alibaba2.jpg"]', '{"weibo": "阿里巴巴招聘", "wechat": "阿里巴巴招聘"}', NOW()),
(3, '王先生', '010-12345678', 'hr@bytedance.com', '短视频、直播、教育、游戏、企业服务等', '激发创造，丰富生活', '["五险一金", "年终奖金", "带薪年假", "免费工作餐", "健身房", "班车"]', '["/images/company/bytedance1.jpg", "/images/company/bytedance2.jpg"]', '{"weibo": "字节跳动招聘", "wechat": "字节跳动招聘"}', NOW());

-- 完成
SELECT '模拟数据插入完成！' as message;
SELECT COUNT(*) as total_companies FROM companies;
SELECT COUNT(*) as total_jobs FROM jobs WHERE status = 'published';
SELECT COUNT(*) as total_categories FROM job_categories;
