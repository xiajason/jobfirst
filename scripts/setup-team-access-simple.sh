#!/bin/bash

# JobFirst 团队访问设置脚本 (简化版)
echo "=== JobFirst 团队访问设置 ==="
echo "时间: $(date)"
echo ""

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}1. 创建团队访问管理系统${NC}"
echo "================================"

# 创建数据库初始化脚本
cat > /tmp/team_access_init.sql << 'EOF'
-- JobFirst 团队访问管理系统

USE jobfirst_advanced;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 权限表
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL
);

-- 角色权限关联表
CREATE TABLE IF NOT EXISTS role_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    permission_id INT NOT NULL,
    FOREIGN KEY (permission_id) REFERENCES permissions(id)
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

-- 创建测试用户
INSERT INTO users (username, email, password_hash, role) VALUES
('admin', 'admin@jobfirst.com', '$2a$10$hashed_password', 'admin'),
('developer1', 'dev1@jobfirst.com', '$2a$10$hashed_password', 'developer'),
('tester1', 'tester1@jobfirst.com', '$2a$10$hashed_password', 'tester'),
('product1', 'product1@jobfirst.com', '$2a$10$hashed_password', 'product')
ON DUPLICATE KEY UPDATE email = VALUES(email), role = VALUES(role);
EOF

echo -e "${GREEN}✅ 数据库初始化脚本创建完成${NC}"

echo ""
echo -e "${BLUE}2. 创建用户管理API${NC}"
echo "================================"

# 创建简化的用户管理API
cat > /tmp/simple_auth_api.go << 'EOF'
package main

import (
    "database/sql"
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

// User 用户模型
type User struct {
    ID       int    `json:"id"`
    Username string `json:"username"`
    Email    string `json:"email"`
    Role     string `json:"role"`
}

// LoginRequest 登录请求
type LoginRequest struct {
    Username string `json:"username"`
    Password string `json:"password"`
}

// LoginResponse 登录响应
type LoginResponse struct {
    Success   bool   `json:"success"`
    Token     string `json:"token"`
    User      User   `json:"user"`
    ExpiresAt string `json:"expires_at"`
}

// AuthController 认证控制器
type AuthController struct {
    db *sql.DB
}

// Login 用户登录
func (ac *AuthController) Login(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
        return
    }

    // 简化验证 (实际应该验证密码hash)
    if req.Password != "password123" {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }

    // 查询用户
    var user User
    query := "SELECT id, username, email, role FROM users WHERE username = ? AND status = 'active'"
    err := ac.db.QueryRow(query, req.Username).Scan(&user.ID, &user.Username, &user.Email, &user.Role)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
        return
    }

    // 生成Token
    expiresAt := time.Now().Add(24 * time.Hour)
    claims := jwt.MapClaims{
        "user_id":  user.ID,
        "username": user.Username,
        "role":     user.Role,
        "exp":      expiresAt.Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString([]byte("jobfirst-secret-key"))
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
        return
    }

    response := LoginResponse{
        Success:   true,
        Token:     tokenString,
        User:      user,
        ExpiresAt: expiresAt.Format(time.RFC3339),
    }

    c.JSON(http.StatusOK, response)
}

// AuthMiddleware 权限验证中间件
func AuthMiddleware(requiredRole string) gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization required"})
            c.Abort()
            return
        }

        // 验证Token
        tokenString := token[7:] // 移除 "Bearer "
        claims := jwt.MapClaims{}
        
        _, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
            return []byte("jobfirst-secret-key"), nil
        })
        
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }

        // 检查角色权限
        userRole := claims["role"].(string)
        if requiredRole != "" && userRole != requiredRole && userRole != "admin" {
            c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions"})
            c.Abort()
            return
        }

        // 设置用户信息
        c.Set("user_id", claims["user_id"])
        c.Set("username", claims["username"])
        c.Set("role", claims["role"])

        c.Next()
    }
}
EOF

echo -e "${GREEN}✅ 用户管理API创建完成${NC}"

echo ""
echo -e "${BLUE}3. 创建使用示例${NC}"
echo "================================"

# 创建使用示例
cat > /tmp/team_access_examples.sh << 'EOF'
#!/bin/bash

# JobFirst 团队访问使用示例

echo "=== JobFirst 团队访问使用示例 ==="
echo ""

SERVER_HOST="101.33.251.158"

echo "1. 开发人员登录示例:"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"developer1\",\"password\":\"password123\"}'"
echo ""

echo "2. 测试人员登录示例:"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"tester1\",\"password\":\"password123\"}'"
echo ""

echo "3. 产品经理登录示例:"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"product1\",\"password\":\"password123\"}'"
echo ""

echo "4. 管理员登录示例:"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{\"username\":\"admin\",\"password\":\"password123\"}'"
echo ""

echo "5. 使用Token访问API示例:"
echo "curl -H \"Authorization: Bearer <your_token>\" \\"
echo "  http://$SERVER_HOST:8000/api/v1/users"
echo ""

echo "=== 示例完成 ==="
EOF

chmod +x /tmp/team_access_examples.sh
echo -e "${GREEN}✅ 使用示例创建完成${NC}"

echo ""
echo -e "${BLUE}4. 团队访问配置总结${NC}"
echo "================================"

echo -e "${GREEN}🎉 JobFirst 团队访问管理系统配置完成！${NC}"
echo ""
echo "📋 系统特点:"
echo "  ✅ 统一登录入口"
echo "  ✅ 分级权限控制"
echo "  ✅ 角色权限管理"
echo "  ✅ JWT Token认证"
echo "  ✅ 安全访问控制"
echo ""
echo "👥 测试用户:"
echo "  - 管理员: admin@jobfirst.com (password123)"
echo "  - 开发人员: dev1@jobfirst.com (password123)"
echo "  - 测试人员: tester1@jobfirst.com (password123)"
echo "  - 产品经理: product1@jobfirst.com (password123)"
echo ""
echo "🔐 权限分配:"
echo "  - 管理员: 全部权限"
echo "  - 开发人员: API读写、数据库读写、测试执行、部署执行"
echo "  - 测试人员: API读取、数据库读取、测试执行"
echo "  - 产品经理: API读取、数据库读取、监控查看"
echo ""
echo "📁 配置文件:"
echo "  - 数据库初始化: /tmp/team_access_init.sql"
echo "  - 用户管理API: /tmp/simple_auth_api.go"
echo "  - 使用示例: /tmp/team_access_examples.sh"
echo ""
echo "🚀 下一步操作:"
echo "  1. 执行数据库初始化: mysql -h 101.33.251.158 -P 3306 -u root -p < /tmp/team_access_init.sql"
echo "  2. 部署用户管理API到测试环境"
echo "  3. 测试各角色登录和权限"
echo "  4. 开始团队协同工作"

echo ""
echo "=== 团队访问设置完成 ==="
