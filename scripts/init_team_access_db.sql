-- JobFirst 团队访问管理系统数据库初始化脚本

USE jobfirst_advanced;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 创建权限表
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建角色权限关联表
CREATE TABLE IF NOT EXISTS role_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (permission_id) REFERENCES permissions(id),
    UNIQUE KEY unique_role_permission (role, permission_id)
);

-- 插入权限数据
INSERT INTO permissions (name, description, resource, action) VALUES
('user_manage', '用户管理', 'users', 'manage'),
('api_read', 'API读取', 'api', 'read'),
('api_write', 'API写入', 'api', 'write'),
('db_read', '数据库读取', 'database', 'read'),
('db_write', '数据库写入', 'database', 'write'),
('test_execute', '测试执行', 'testing', 'execute'),
('monitor_read', '监控查看', 'monitoring', 'read'),
('deploy_execute', '部署执行', 'deployment', 'execute')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- 角色权限分配
INSERT INTO role_permissions (role, permission_id) VALUES
-- 管理员 (全部权限)
('admin', 1), ('admin', 2), ('admin', 3), ('admin', 4), ('admin', 5), ('admin', 6), ('admin', 7), ('admin', 8),
-- 开发人员
('developer', 2), ('developer', 3), ('developer', 4), ('developer', 5), ('developer', 6), ('developer', 7), ('developer', 8),
-- 测试人员
('tester', 2), ('tester', 4), ('tester', 6), ('tester', 7),
-- 产品经理
('product', 2), ('product', 4), ('product', 6), ('product', 7)
ON DUPLICATE KEY UPDATE role = VALUES(role);

-- 创建测试用户 (密码都是 password123)
INSERT INTO users (username, email, password, role) VALUES
('admin', 'admin@jobfirst.com', '$2a$10$hashed_password', 'admin'),
('developer1', 'dev1@jobfirst.com', '$2a$10$hashed_password', 'developer'),
('developer2', 'dev2@jobfirst.com', '$2a$10$hashed_password', 'developer'),
('tester1', 'tester1@jobfirst.com', '$2a$10$hashed_password', 'tester'),
('tester2', 'tester2@jobfirst.com', '$2a$10$hashed_password', 'tester'),
('product1', 'product1@jobfirst.com', '$2a$10$hashed_password', 'product'),
('product2', 'product2@jobfirst.com', '$2a$10$hashed_password', 'product')
ON DUPLICATE KEY UPDATE email = VALUES(email), role = VALUES(role);

-- 创建用户会话表
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 创建操作日志表
CREATE TABLE IF NOT EXISTS operation_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 显示创建结果
SELECT 'Database initialization completed successfully!' as status;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_permissions FROM permissions;
SELECT COUNT(*) as total_role_permissions FROM role_permissions;
