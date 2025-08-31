// JobFirst Neo4j图数据库初始化脚本
// 用于创建图数据模型和初始数据

// ========================================
// 创建约束和索引
// ========================================

// 用户节点约束
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.id IS UNIQUE;
CREATE CONSTRAINT user_email IF NOT EXISTS FOR (u:User) REQUIRE u.email IS UNIQUE;

// 技能节点约束
CREATE CONSTRAINT skill_name IF NOT EXISTS FOR (s:Skill) REQUIRE s.name IS UNIQUE;

// 公司节点约束
CREATE CONSTRAINT company_name IF NOT EXISTS FOR (c:Company) REQUIRE c.name IS UNIQUE;

// 职位节点约束
CREATE CONSTRAINT job_id IF NOT EXISTS FOR (j:Job) REQUIRE j.id IS UNIQUE;

// 创建索引
CREATE INDEX user_username IF NOT EXISTS FOR (u:User) ON (u.username);
CREATE INDEX user_type IF NOT EXISTS FOR (u:User) ON (u.user_type);
CREATE INDEX skill_category IF NOT EXISTS FOR (s:Skill) ON (s.category);
CREATE INDEX company_industry IF NOT EXISTS FOR (c:Company) ON (c.industry);
CREATE INDEX job_title IF NOT EXISTS FOR (j:Job) ON (j.title);
CREATE INDEX job_location IF NOT EXISTS FOR (j:Job) ON (j.location);

// ========================================
// 创建示例数据
// ========================================

// 创建用户节点
CREATE (u1:User {
    id: 1,
    username: "zhangsan",
    email: "zhangsan@example.com",
    user_type: "jobseeker",
    nickname: "张三",
    location: "北京"
});

CREATE (u2:User {
    id: 2,
    username: "lisi",
    email: "lisi@example.com",
    user_type: "jobseeker",
    nickname: "李四",
    location: "上海"
});

CREATE (u3:User {
    id: 3,
    username: "wangwu",
    email: "wangwu@example.com",
    user_type: "recruiter",
    nickname: "王五",
    location: "深圳"
});

// 创建技能节点
CREATE (s1:Skill {name: "Java", category: "programming"});
CREATE (s2:Skill {name: "Spring Boot", category: "framework"});
CREATE (s3:Skill {name: "MySQL", category: "database"});
CREATE (s4:Skill {name: "Redis", category: "database"});
CREATE (s5:Skill {name: "Docker", category: "devops"});
CREATE (s6:Skill {name: "Kubernetes", category: "devops"});
CREATE (s7:Skill {name: "React", category: "frontend"});
CREATE (s8:Skill {name: "Vue.js", category: "frontend"});
CREATE (s9:Skill {name: "Python", category: "programming"});
CREATE (s10:Skill {name: "Machine Learning", category: "ai"});

// 创建公司节点
CREATE (c1:Company {
    name: "腾讯科技",
    industry: "互联网",
    location: "深圳",
    size: "大型企业"
});

CREATE (c2:Company {
    name: "阿里巴巴",
    industry: "电商",
    location: "杭州",
    size: "大型企业"
});

CREATE (c3:Company {
    name: "字节跳动",
    industry: "互联网",
    location: "北京",
    size: "大型企业"
});

CREATE (c4:Company {
    name: "美团",
    industry: "本地生活",
    location: "北京",
    size: "大型企业"
});

// 创建职位节点
CREATE (j1:Job {
    id: 1,
    title: "Java开发工程师",
    company: "腾讯科技",
    location: "深圳",
    salary_min: 15000,
    salary_max: 25000,
    experience_level: "mid"
});

CREATE (j2:Job {
    id: 2,
    title: "前端开发工程师",
    company: "阿里巴巴",
    location: "杭州",
    salary_min: 12000,
    salary_max: 20000,
    experience_level: "junior"
});

CREATE (j3:Job {
    id: 3,
    title: "Python算法工程师",
    company: "字节跳动",
    location: "北京",
    salary_min: 20000,
    salary_max: 35000,
    experience_level: "senior"
});

CREATE (j4:Job {
    id: 4,
    title: "DevOps工程师",
    company: "美团",
    location: "北京",
    salary_min: 18000,
    salary_max: 30000,
    experience_level: "mid"
});

// ========================================
// 创建关系
// ========================================

// 用户-技能关系
CREATE (u1)-[:HAS_SKILL]->(s1);
CREATE (u1)-[:HAS_SKILL]->(s2);
CREATE (u1)-[:HAS_SKILL]->(s3);
CREATE (u2)-[:HAS_SKILL]->(s7);
CREATE (u2)-[:HAS_SKILL]->(s8);
CREATE (u2)-[:HAS_SKILL]->(s9);

// 技能-技能关系（相关技能）
CREATE (s1)-[:RELATED_TO]->(s2);
CREATE (s1)-[:RELATED_TO]->(s3);
CREATE (s3)-[:RELATED_TO]->(s4);
CREATE (s5)-[:RELATED_TO]->(s6);
CREATE (s7)-[:RELATED_TO]->(s8);
CREATE (s9)-[:RELATED_TO]->(s10);

// 职位-技能关系（职位要求）
CREATE (j1)-[:REQUIRES]->(s1);
CREATE (j1)-[:REQUIRES]->(s2);
CREATE (j1)-[:REQUIRES]->(s3);
CREATE (j2)-[:REQUIRES]->(s7);
CREATE (j2)-[:REQUIRES]->(s8);
CREATE (j3)-[:REQUIRES]->(s9);
CREATE (j3)-[:REQUIRES]->(s10);
CREATE (j4)-[:REQUIRES]->(s5);
CREATE (j4)-[:REQUIRES]->(s6);

// 用户-职位关系（申请记录）
CREATE (u1)-[:APPLIED_TO {applied_at: datetime()}]->(j1);
CREATE (u1)-[:APPLIED_TO {applied_at: datetime()}]->(j4);
CREATE (u2)-[:APPLIED_TO {applied_at: datetime()}]->(j2);
CREATE (u2)-[:APPLIED_TO {applied_at: datetime()}]->(j3);

// 用户-公司关系（工作经历）
CREATE (u1)-[:WORKED_AT {position: "Java开发工程师", start_date: "2020-01-01", end_date: "2022-12-31"}]->(c1);
CREATE (u2)-[:WORKED_AT {position: "前端开发工程师", start_date: "2021-03-01", end_date: "2023-06-30"}]->(c2);

// 用户-用户关系（协作关系）
CREATE (u1)-[:COLLABORATED_WITH {project: "电商平台开发"}]->(u2);
CREATE (u1)-[:FOLLOWS]->(u3);

// 公司-公司关系（合作关系）
CREATE (c1)-[:PARTNERS_WITH]->(c2);
CREATE (c2)-[:PARTNERS_WITH]->(c3);

// ========================================
// 创建推荐算法相关的图模式
// ========================================

// 创建技能相似性关系
CREATE (s1)-[:SIMILAR_TO {similarity: 0.8}]->(s9);
CREATE (s2)-[:SIMILAR_TO {similarity: 0.7}]->(s7);
CREATE (s3)-[:SIMILAR_TO {similarity: 0.9}]->(s4);

// 创建职位相似性关系
CREATE (j1)-[:SIMILAR_TO {similarity: 0.6}]->(j4);
CREATE (j2)-[:SIMILAR_TO {similarity: 0.5}]->(j3);

// ========================================
// 验证数据
// ========================================

// 返回创建的节点数量
MATCH (n) RETURN labels(n) as NodeType, count(n) as Count ORDER BY Count DESC;

// 返回创建的关系数量
MATCH ()-[r]->() RETURN type(r) as RelationshipType, count(r) as Count ORDER BY Count DESC;

// 返回用户技能分布
MATCH (u:User)-[:HAS_SKILL]->(s:Skill) 
RETURN u.username as User, collect(s.name) as Skills;

// 返回职位技能要求
MATCH (j:Job)-[:REQUIRES]->(s:Skill) 
RETURN j.title as Job, collect(s.name) as RequiredSkills;
