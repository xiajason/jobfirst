# JobFirst 数据库融合指南

## 概述

本指南将帮助您将JobFirst简历中心系统的数据库与其他数据库系统进行融合，实现数据整合和功能扩展。

## 导出文件说明

### 1. 完整数据库备份
- **文件**: `jobfirst_database.sql`
- **内容**: 包含所有表结构、数据、索引、外键关系
- **用途**: 完整迁移或备份恢复

### 2. 仅结构备份
- **文件**: `jobfirst_schema_only.sql`
- **内容**: 仅包含表结构，不包含数据
- **用途**: 在新环境中创建数据库结构

### 3. 数据库结构文档
- **文件**: `database_structure_documentation.md`
- **内容**: 详细的表结构说明和关系图
- **用途**: 了解数据库设计和业务逻辑

### 4. 迁移脚本
- **文件**: `database_migration_script.sql`
- **内容**: 优化的数据库结构，包含存储过程、触发器、视图
- **用途**: 生产环境部署

## 融合策略

### 策略一：完全替换
适用于：新项目或完全重构

```bash
# 1. 备份现有数据库
mysqldump -u username -p existing_database > existing_backup.sql

# 2. 删除现有数据库
mysql -u username -p -e "DROP DATABASE existing_database;"

# 3. 导入JobFirst数据库
mysql -u username -p < jobfirst_database.sql

# 4. 重命名数据库（可选）
mysql -u username -p -e "RENAME DATABASE jobfirst TO new_database_name;"
```

### 策略二：表级融合
适用于：保留现有数据，添加新功能

```sql
-- 1. 检查表名冲突
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'existing_database' 
AND TABLE_NAME IN (
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'jobfirst'
);

-- 2. 重命名冲突的表
RENAME TABLE existing_table TO existing_table_backup;

-- 3. 导入JobFirst表
-- 使用 jobfirst_schema_only.sql 中的特定表
```

### 策略三：字段级融合
适用于：需要合并相似功能的表

```sql
-- 示例：合并用户表
ALTER TABLE existing_users 
ADD COLUMN avatar_url VARCHAR(255) COMMENT '头像URL' AFTER phone,
ADD COLUMN status ENUM('active','inactive','banned') DEFAULT 'active' COMMENT '用户状态' AFTER avatar_url,
ADD COLUMN deleted_at DATETIME(3) NULL COMMENT '删除时间' AFTER updated_at;

-- 添加索引
CREATE INDEX idx_existing_users_email ON existing_users(email);
CREATE INDEX idx_existing_users_deleted_at ON existing_users(deleted_at);
```

## 数据迁移步骤

### 步骤1：环境准备
```bash
# 创建备份目录
mkdir -p database_backups
cd database_backups

# 备份现有数据库
mysqldump -u username -p existing_database > existing_database_backup_$(date +%Y%m%d_%H%M%S).sql

# 检查磁盘空间
df -h
```

### 步骤2：结构分析
```sql
-- 分析现有数据库结构
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'Size (MB)'
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'existing_database'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- 检查外键关系
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'existing_database' 
AND REFERENCED_TABLE_NAME IS NOT NULL;
```

### 步骤3：冲突解决
```sql
-- 创建表名映射
CREATE TABLE table_mapping (
    old_name VARCHAR(64),
    new_name VARCHAR(64),
    action ENUM('rename', 'merge', 'skip'),
    notes TEXT
);

-- 插入映射关系
INSERT INTO table_mapping VALUES
('old_users', 'users', 'merge', '需要合并字段'),
('old_files', 'files', 'rename', '重命名为 old_files'),
('temp_data', 'temp_data', 'skip', '临时表，跳过');
```

### 步骤4：数据迁移
```sql
-- 创建迁移日志表
CREATE TABLE migration_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(64),
    action VARCHAR(32),
    records_processed INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    status ENUM('success', 'failed', 'partial'),
    error_message TEXT
);

-- 示例：迁移用户数据
INSERT INTO users (username, email, password_hash, phone, created_at)
SELECT 
    old_username,
    old_email,
    old_password_hash,
    old_phone,
    old_created_at
FROM old_users
WHERE old_users.id NOT IN (SELECT id FROM users);
```

### 步骤5：数据验证
```sql
-- 验证数据完整性
SELECT 
    'users' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT email) as unique_emails
FROM users
UNION ALL
SELECT 
    'resumes' as table_name,
    COUNT(*) as record_count,
    COUNT(DISTINCT user_id) as unique_users
FROM resumes;

-- 检查外键完整性
SELECT 
    'users' as table_name,
    COUNT(*) as total_users
FROM users
UNION ALL
SELECT 
    'resumes' as table_name,
    COUNT(*) as resumes_with_valid_users
FROM resumes r
JOIN users u ON r.user_id = u.id;
```

## 性能优化建议

### 1. 索引优化
```sql
-- 分析查询性能
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';

-- 添加复合索引
CREATE INDEX idx_users_status_created ON users(status, created_at);
CREATE INDEX idx_resumes_user_status ON resumes(user_id, status);

-- 删除无用索引
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    CARDINALITY
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'jobfirst'
ORDER BY CARDINALITY;
```

### 2. 分区策略
```sql
-- 按时间分区（适用于大表）
ALTER TABLE user_behaviors 
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

### 3. 存储优化
```sql
-- 压缩表
ALTER TABLE file_access_logs ROW_FORMAT=COMPRESSED;

-- 优化字段类型
ALTER TABLE users MODIFY COLUMN phone VARCHAR(20) CHARACTER SET utf8mb4;
```

## 安全考虑

### 1. 数据脱敏
```sql
-- 创建脱敏视图
CREATE VIEW v_users_public AS
SELECT 
    id,
    username,
    SUBSTRING(email, 1, 3) || '***' || SUBSTRING(email, LOCATE('@', email)) as email_masked,
    status,
    created_at
FROM users
WHERE deleted_at IS NULL;
```

### 2. 权限控制
```sql
-- 创建应用用户
CREATE USER 'app_user'@'%' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON jobfirst.* TO 'app_user'@'%';

-- 创建只读用户
CREATE USER 'readonly_user'@'%' IDENTIFIED BY 'readonly_password';
GRANT SELECT ON jobfirst.* TO 'readonly_user'@'%';
```

### 3. 审计日志
```sql
-- 启用审计日志
SET GLOBAL audit_log = ON;
SET GLOBAL audit_log_file = '/var/log/mysql/audit.log';
```

## 监控和维护

### 1. 性能监控
```sql
-- 创建性能监控视图
CREATE VIEW v_performance_metrics AS
SELECT 
    'table_size' as metric,
    TABLE_NAME,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS size_mb
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'jobfirst'
UNION ALL
SELECT 
    'record_count' as metric,
    TABLE_NAME,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'jobfirst';
```

### 2. 备份策略
```bash
#!/bin/bash
# 自动备份脚本
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/mysql"
mysqldump -u backup_user -p'backup_password' jobfirst > $BACKUP_DIR/jobfirst_backup_$DATE.sql
gzip $BACKUP_DIR/jobfirst_backup_$DATE.sql

# 保留最近30天的备份
find $BACKUP_DIR -name "jobfirst_backup_*.sql.gz" -mtime +30 -delete
```

### 3. 维护计划
```sql
-- 定期维护任务
-- 1. 分析表
ANALYZE TABLE users, resumes, files;

-- 2. 优化表
OPTIMIZE TABLE user_behaviors, file_access_logs;

-- 3. 清理过期数据
DELETE FROM user_behaviors WHERE created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
DELETE FROM file_access_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);
```

## 故障排除

### 常见问题

1. **字符集冲突**
```sql
-- 统一字符集
ALTER DATABASE jobfirst CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE users CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. **外键约束错误**
```sql
-- 临时禁用外键检查
SET FOREIGN_KEY_CHECKS = 0;
-- 执行迁移操作
SET FOREIGN_KEY_CHECKS = 1;
```

3. **存储空间不足**
```sql
-- 检查表大小
SELECT 
    TABLE_NAME,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'Size (MB)'
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'jobfirst'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;
```

## 联系支持

如果在融合过程中遇到问题，请：

1. 检查错误日志
2. 备份当前状态
3. 记录详细的操作步骤
4. 联系技术支持团队

---

**注意**: 在生产环境中执行任何数据库操作前，请务必进行充分测试和备份。
