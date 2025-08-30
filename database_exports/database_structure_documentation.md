# JobFirst 简历中心系统数据库结构文档

## 数据库概述
- **数据库名称**: jobfirst
- **字符集**: utf8mb4
- **排序规则**: utf8mb4_unicode_ci
- **总表数**: 23个
- **导出时间**: $(date)

## 表结构详细说明

### 1. 用户管理模块

#### 1.1 users - 用户表
**用途**: 存储系统用户的基本信息
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL COMMENT '用户名',
    email VARCHAR(100) UNIQUE NOT NULL COMMENT '邮箱',
    password_hash VARCHAR(255) NOT NULL COMMENT '密码哈希',
    phone VARCHAR(20) COMMENT '手机号',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    status ENUM('active','inactive','banned') DEFAULT 'active' COMMENT '用户状态',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间',
    deleted_at DATETIME(3) COMMENT '删除时间(软删除)'
);
```

#### 1.2 user_behaviors - 用户行为表
**用途**: 记录用户的操作行为，用于分析和统计
```sql
CREATE TABLE user_behaviors (
    id VARCHAR(36) PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    type VARCHAR(50) NOT NULL COMMENT '行为类型',
    reference_id VARCHAR(100) COMMENT '关联ID',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    metadata TEXT COMMENT '元数据',
    created_at DATETIME(3) COMMENT '创建时间'
);
```

### 2. 简历管理模块

#### 2.1 resumes - 简历表
**用途**: 存储用户的简历信息
```sql
CREATE TABLE resumes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    title LONGTEXT NOT NULL COMMENT '简历标题',
    content TEXT COMMENT '简历内容',
    template_id VARCHAR(36) COMMENT '模板ID',
    status VARCHAR(20) DEFAULT 'draft' COMMENT '状态',
    view_count BIGINT DEFAULT 0 COMMENT '浏览次数',
    download_count BIGINT DEFAULT 0 COMMENT '下载次数',
    share_count INT DEFAULT 0 COMMENT '分享次数',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间',
    deleted_at TIMESTAMP COMMENT '删除时间',
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 2.2 resume_templates - 简历模板表
**用途**: 存储简历模板信息
```sql
CREATE TABLE resume_templates (
    id VARCHAR(36) PRIMARY KEY,
    name LONGTEXT NOT NULL COMMENT '模板名称',
    description TEXT COMMENT '模板描述',
    template_data JSON NOT NULL COMMENT '模板数据',
    preview_image VARCHAR(255) COMMENT '预览图',
    category VARCHAR(50) COMMENT '分类',
    is_free TINYINT(1) DEFAULT 1 COMMENT '是否免费',
    price DOUBLE DEFAULT 0 COMMENT '价格',
    status ENUM('active','inactive') DEFAULT 'active' COMMENT '状态',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间',
    preview_url LONGTEXT COMMENT '预览URL',
    is_active TINYINT(1) DEFAULT 1 COMMENT '是否激活'
);
```

#### 2.3 resume_banners - 简历横幅表
**用途**: 存储首页横幅信息
```sql
CREATE TABLE resume_banners (
    id VARCHAR(36) PRIMARY KEY,
    title LONGTEXT NOT NULL COMMENT '标题',
    content TEXT COMMENT '内容',
    image_url LONGTEXT COMMENT '图片URL',
    link_url LONGTEXT COMMENT '链接URL',
    `order` BIGINT DEFAULT 0 COMMENT '排序',
    is_active TINYINT(1) DEFAULT 1 COMMENT '是否激活',
    start_time DATETIME(3) COMMENT '开始时间',
    end_time DATETIME(3) COMMENT '结束时间',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

### 3. 积分系统模块

#### 3.1 points - 积分表
**用途**: 存储用户积分信息
```sql
CREATE TABLE points (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    points INT DEFAULT 0 COMMENT '当前积分',
    earned_points INT DEFAULT 0 COMMENT '累计获得积分',
    spent_points INT DEFAULT 0 COMMENT '累计消费积分',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3.2 point_records - 积分记录表
**用途**: 记录积分变动历史
```sql
CREATE TABLE point_records (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    points INT NOT NULL COMMENT '积分数量',
    type ENUM('earn','spend') NOT NULL COMMENT '类型：获得/消费',
    reason VARCHAR(100) NOT NULL COMMENT '原因',
    description TEXT COMMENT '描述',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3.3 points_rules - 积分规则表
**用途**: 定义积分获取和消费规则
```sql
CREATE TABLE points_rules (
    id VARCHAR(36) PRIMARY KEY,
    name LONGTEXT NOT NULL COMMENT '规则名称',
    source VARCHAR(50) UNIQUE NOT NULL COMMENT '来源',
    points BIGINT NOT NULL COMMENT '积分数量',
    description TEXT COMMENT '描述',
    is_active TINYINT(1) DEFAULT 1 COMMENT '是否激活',
    daily_limit BIGINT COMMENT '每日限制',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

### 4. 文件存储模块

#### 4.1 files - 文件表
**用途**: 存储文件基本信息
```sql
CREATE TABLE files (
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
    deleted_at TIMESTAMP COMMENT '删除时间',
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 4.2 file_shares - 文件分享表
**用途**: 管理文件分享功能
```sql
CREATE TABLE file_shares (
    id VARCHAR(36) PRIMARY KEY,
    file_id VARCHAR(36) NOT NULL COMMENT '文件ID',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    share_token VARCHAR(64) UNIQUE COMMENT '分享令牌',
    password VARCHAR(100) COMMENT '密码',
    is_public TINYINT(1) DEFAULT 0 COMMENT '是否公开',
    max_downloads BIGINT COMMENT '最大下载次数',
    download_count BIGINT DEFAULT 0 COMMENT '下载次数',
    expires_at DATETIME(3) COMMENT '过期时间',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

#### 4.3 file_versions - 文件版本表
**用途**: 管理文件版本控制
```sql
CREATE TABLE file_versions (
    id VARCHAR(36) PRIMARY KEY,
    file_id VARCHAR(36) NOT NULL COMMENT '文件ID',
    version BIGINT NOT NULL COMMENT '版本号',
    file_name LONGTEXT NOT NULL COMMENT '文件名',
    size BIGINT NOT NULL COMMENT '文件大小',
    storage_path VARCHAR(500) NOT NULL COMMENT '存储路径',
    md5_hash VARCHAR(32) COMMENT 'MD5哈希',
    status VARCHAR(20) DEFAULT 'uploaded' COMMENT '状态',
    created_at DATETIME(3) COMMENT '创建时间'
);
```

#### 4.4 file_access_logs - 文件访问日志表
**用途**: 记录文件访问日志
```sql
CREATE TABLE file_access_logs (
    id VARCHAR(36) PRIMARY KEY,
    file_id VARCHAR(36) NOT NULL COMMENT '文件ID',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    action VARCHAR(20) NOT NULL COMMENT '操作',
    ip VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    referer VARCHAR(500) COMMENT '来源',
    created_at DATETIME(3) COMMENT '创建时间'
);
```

#### 4.5 storage_quota - 存储配额表
**用途**: 管理用户存储配额
```sql
CREATE TABLE storage_quota (
    id VARCHAR(36) PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE NOT NULL COMMENT '用户ID',
    total_quota BIGINT NOT NULL COMMENT '总配额',
    used_quota BIGINT DEFAULT 0 COMMENT '已使用配额',
    file_count BIGINT DEFAULT 0 COMMENT '文件数量',
    last_reset_at DATETIME(3) COMMENT '最后重置时间',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

### 5. 统计分析模块

#### 5.1 statistics - 统计表
**用途**: 存储各种统计数据
```sql
CREATE TABLE statistics (
    id VARCHAR(36) PRIMARY KEY,
    type VARCHAR(50) NOT NULL COMMENT '统计类型',
    period VARCHAR(20) NOT NULL COMMENT '统计周期',
    date DATETIME(3) NOT NULL COMMENT '统计日期',
    value BIGINT DEFAULT 0 COMMENT '统计值',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    reference_id VARCHAR(100) COMMENT '关联ID',
    metadata TEXT COMMENT '元数据',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

#### 5.2 statistics_events - 统计事件表
**用途**: 记录统计事件
```sql
CREATE TABLE statistics_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL COMMENT '事件类型',
    user_id BIGINT UNSIGNED COMMENT '用户ID',
    event_data JSON COMMENT '事件数据',
    ip_address VARCHAR(45) COMMENT 'IP地址',
    user_agent TEXT COMMENT '用户代理',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
);
```

#### 5.3 real_time_stats - 实时统计表
**用途**: 存储实时统计数据
```sql
CREATE TABLE real_time_stats (
    id VARCHAR(36) PRIMARY KEY,
    type VARCHAR(50) UNIQUE NOT NULL COMMENT '类型',
    value BIGINT DEFAULT 0 COMMENT '值',
    last_updated DATETIME(3) COMMENT '最后更新时间',
    created_at DATETIME(3) COMMENT '创建时间',
    updated_at DATETIME(3) COMMENT '更新时间'
);
```

### 6. 系统配置模块

#### 6.1 storage_configs - 存储配置表
#### 6.2 file_process_tasks - 文件处理任务表
#### 6.3 file_records - 文件记录表
#### 6.4 file_tags - 文件标签表
#### 6.5 statistics_reports - 统计报告表
#### 6.6 user_points - 用户积分表（可能是重复表）
#### 6.7 points_records - 积分记录表（可能是重复表）

## 外键关系图

```
users (1) ←→ (N) resumes
users (1) ←→ (N) points
users (1) ←→ (N) point_records
users (1) ←→ (N) files
users (1) ←→ (N) user_behaviors
users (1) ←→ (1) storage_quota
```

## 索引信息

### 主要索引
- users.email (UNIQUE)
- users.username (UNIQUE)
- resumes.user_id
- resumes.status
- points.user_id
- point_records.user_id
- files.user_id
- files.status

## 数据统计

- **总表数**: 23个
- **有数据的表**: 1个（resume_templates有3条初始数据）
- **空表**: 22个（等待业务数据填充）

## 导出文件列表

1. `jobfirst_database.sql` - 完整数据库备份（包含结构和数据）
2. `jobfirst_schema_only.sql` - 仅数据库结构
3. `jobfirst_schema_info.txt` - 数据库结构信息
4. `database_structure_documentation.md` - 数据库结构文档

## 使用说明

### 导入数据库
```bash
# 导入完整数据库
mysql -u username -p database_name < jobfirst_database.sql

# 导入仅结构
mysql -u username -p database_name < jobfirst_schema_only.sql
```

### 数据库融合建议
1. 检查表名冲突
2. 统一字段命名规范
3. 合并相似功能的表
4. 优化索引结构
5. 统一数据类型和长度
