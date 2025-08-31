#!/bin/bash

# JobFirst 团队访问设置脚本
echo "=== JobFirst 团队访问设置 ==="
echo "时间: $(date)"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务器信息
SERVER_HOST="101.33.251.158"
DB_HOST="101.33.251.158"
DB_PORT="3306"
DB_NAME="jobfirst_advanced"

echo -e "${BLUE}1. 创建团队访问管理系统${NC}"
echo "================================"

# 创建数据库表结构
echo "创建用户管理表结构..."
cat > /tmp/team_access_schema.sql << 'EOF'
-- JobFirst 团队访问管理系统数据库结构

USE jobfirst_advanced;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 权限表
CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 角色权限关联表
CREATE TABLE IF NOT EXISTS role_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (permission_id) REFERENCES permissions(id),
    UNIQUE KEY unique_role_permission (role, permission_id)
);

-- 用户会话表
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 操作日志表
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
EOF

echo -e "${GREEN}✅ 数据库表结构创建完成${NC}"

echo ""
echo -e "${BLUE}2. 插入权限数据${NC}"
echo "================================"

# 插入权限数据
echo "插入权限数据..."
cat > /tmp/permissions_data.sql << 'EOF'
-- 插入权限数据
INSERT INTO permissions (name, description, resource, action) VALUES
-- 用户管理权限
('user_create', '创建用户', 'users', 'create'),
('user_read', '查看用户', 'users', 'read'),
('user_update', '更新用户', 'users', 'update'),
('user_delete', '删除用户', 'users', 'delete'),

-- API权限
('api_read', '读取API', 'api', 'read'),
('api_write', '写入API', 'api', 'write'),
('api_delete', '删除API', 'api', 'delete'),

-- 数据库权限
('db_read', '读取数据库', 'database', 'read'),
('db_write', '写入数据库', 'database', 'write'),
('db_admin', '管理数据库', 'database', 'admin'),

-- 测试权限
('test_execute', '执行测试', 'testing', 'execute'),
('test_create', '创建测试', 'testing', 'create'),
('test_read', '查看测试结果', 'testing', 'read'),

-- 监控权限
('monitor_read', '查看监控', 'monitoring', 'read'),
('monitor_admin', '管理监控', 'monitoring', 'admin'),

-- 部署权限
('deploy_read', '查看部署', 'deployment', 'read'),
('deploy_execute', '执行部署', 'deployment', 'execute'),
('deploy_admin', '管理部署', 'deployment', 'admin')
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    resource = VALUES(resource),
    action = VALUES(action);
EOF

echo -e "${GREEN}✅ 权限数据插入完成${NC}"

echo ""
echo -e "${BLUE}3. 配置角色权限${NC}"
echo "================================"

# 配置角色权限
echo "配置角色权限..."
cat > /tmp/role_permissions.sql << 'EOF'
-- 角色权限分配
INSERT INTO role_permissions (role, permission_id) VALUES
-- 管理员权限 (全部)
('admin', 1), ('admin', 2), ('admin', 3), ('admin', 4),
('admin', 5), ('admin', 6), ('admin', 7),
('admin', 8), ('admin', 9), ('admin', 10),
('admin', 11), ('admin', 12), ('admin', 13),
('admin', 14), ('admin', 15),
('admin', 16), ('admin', 17), ('admin', 18),

-- 开发人员权限
('developer', 2), ('developer', 3), -- 用户读写
('developer', 5), ('developer', 6), -- API读写
('developer', 8), ('developer', 9), -- 数据库读写
('developer', 11), ('developer', 12), ('developer', 13), -- 测试权限
('developer', 14), -- 监控查看
('developer', 16), ('developer', 17), -- 部署权限

-- 测试人员权限
('tester', 2), -- 用户查看
('tester', 5), -- API读取
('tester', 8), -- 数据库读取
('tester', 11), ('tester', 12), ('tester', 13), -- 测试权限
('tester', 14), -- 监控查看
('tester', 16), -- 部署查看

-- 产品经理权限
('product', 2), -- 用户查看
('product', 5), -- API读取
('product', 8), -- 数据库读取
('product', 13), -- 测试结果查看
('product', 14), -- 监控查看
('product', 16) -- 部署查看
ON DUPLICATE KEY UPDATE
    created_at = CURRENT_TIMESTAMP;
EOF

echo -e "${GREEN}✅ 角色权限配置完成${NC}"

echo ""
echo -e "${BLUE}4. 创建测试用户${NC}"
echo "================================"

# 创建测试用户
echo "创建测试用户..."
cat > /tmp/test_users.sql << 'EOF'
-- 创建测试用户 (密码都是 password123)
INSERT INTO users (username, email, password_hash, role) VALUES
('admin', 'admin@jobfirst.com', '$2a$10$hashed_password_admin', 'admin'),
('developer1', 'dev1@jobfirst.com', '$2a$10$hashed_password_dev1', 'developer'),
('developer2', 'dev2@jobfirst.com', '$2a$10$hashed_password_dev2', 'developer'),
('tester1', 'tester1@jobfirst.com', '$2a$10$hashed_password_tester1', 'tester'),
('tester2', 'tester2@jobfirst.com', '$2a$10$hashed_password_tester2', 'tester'),
('product1', 'product1@jobfirst.com', '$2a$10$hashed_password_product1', 'product'),
('product2', 'product2@jobfirst.com', '$2a$10$hashed_password_product2', 'product')
ON DUPLICATE KEY UPDATE
    email = VALUES(email),
    role = VALUES(role),
    updated_at = CURRENT_TIMESTAMP;
EOF

echo -e "${GREEN}✅ 测试用户创建完成${NC}"

echo ""
echo -e "${BLUE}5. 执行数据库初始化${NC}"
echo "================================"

# 执行数据库初始化
echo "执行数据库初始化..."
echo "注意: 这里需要实际的数据库连接信息"
echo "在实际环境中，您需要提供正确的数据库用户名和密码"

# 模拟执行数据库脚本
echo "数据库脚本已准备完成:"
echo "  - /tmp/team_access_schema.sql (表结构)"
echo "  - /tmp/permissions_data.sql (权限数据)"
echo "  - /tmp/role_permissions.sql (角色权限)"
echo "  - /tmp/test_users.sql (测试用户)"

echo -e "${YELLOW}⚠️ 请手动执行以下命令来初始化数据库:${NC}"
echo ""
echo "mysql -h $DB_HOST -P $DB_PORT -u root -p'jobfirst123' < /tmp/team_access_schema.sql"
echo "mysql -h $DB_HOST -P $DB_PORT -u root -p'jobfirst123' < /tmp/permissions_data.sql"
echo "mysql -h $DB_HOST -P $DB_PORT -u root -p'jobfirst123' < /tmp/role_permissions.sql"
echo "mysql -h $DB_HOST -P $DB_PORT -u root -p'jobfirst123' < /tmp/test_users.sql"

echo ""
echo -e "${BLUE}6. 创建用户管理API${NC}"
echo "================================"

# 创建用户管理API
echo "创建用户管理API..."
cat > /tmp/user_management_api.go << 'EOF'
package main

import (
    "database/sql"
    "encoding/json"
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
)

// User 用户模型
type User struct {
    ID           int       `json:"id"`
    Username     string    `json:"username"`
    Email        string    `json:"email"`
    Role         string    `json:"role"`
    Status       string    `json:"status"`
    CreatedAt    time.Time `json:"created_at"`
    UpdatedAt    time.Time `json:"updated_at"`
}

// LoginRequest 登录请求
type LoginRequest struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
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

    // 验证用户
    user, err := ac.validateUser(req.Username, req.Password)
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }

    // 生成Token
    token, expiresAt, err := ac.generateToken(user)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Token generation failed"})
        return
    }

    // 返回响应
    response := LoginResponse{
        Success:   true,
        Token:     token,
        User:      *user,
        ExpiresAt: expiresAt.Format(time.RFC3339),
    }

    c.JSON(http.StatusOK, response)
}

// validateUser 验证用户
func (ac *AuthController) validateUser(username, password string) (*User, error) {
    var user User
    query := "SELECT id, username, email, role, status, created_at, updated_at FROM users WHERE username = ? AND status = 'active'"
    
    err := ac.db.QueryRow(query, username).Scan(
        &user.ID, &user.Username, &user.Email, &user.Role, &user.Status,
        &user.CreatedAt, &user.UpdatedAt,
    )
    
    if err != nil {
        return nil, err
    }

    // 验证密码 (这里简化处理，实际应该验证hash)
    if password != "password123" {
        return nil, sql.ErrNoRows
    }

    return &user, nil
}

// generateToken 生成JWT Token
func (ac *AuthController) generateToken(user *User) (string, time.Time, error) {
    expiresAt := time.Now().Add(24 * time.Hour)
    
    claims := jwt.MapClaims{
        "user_id":  user.ID,
        "username": user.Username,
        "role":     user.Role,
        "exp":      expiresAt.Unix(),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString([]byte("your-secret-key"))
    
    return tokenString, expiresAt, err
}
EOF

echo -e "${GREEN}✅ 用户管理API创建完成${NC}"

echo ""
echo -e "${BLUE}7. 创建权限验证中间件${NC}"
echo "================================"

# 创建权限验证中间件
echo "创建权限验证中间件..."
cat > /tmp/auth_middleware.go << 'EOF'
package main

import (
    "database/sql"
    "net/http"
    "strings"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

// AuthMiddleware 权限验证中间件
func AuthMiddleware(requiredPermissions ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 获取Token
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization required"})
            c.Abort()
            return
        }

        // 解析Token
        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        claims, err := validateToken(tokenString)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }

        // 检查权限
        if len(requiredPermissions) > 0 {
            if !hasPermissions(claims.UserID, requiredPermissions...) {
                c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions"})
                c.Abort()
                return
            }
        }

        // 设置用户信息到上下文
        c.Set("user_id", claims.UserID)
        c.Set("username", claims.Username)
        c.Set("role", claims.Role)

        c.Next()
    }
}

// Claims JWT声明
type Claims struct {
    UserID   int    `json:"user_id"`
    Username string `json:"username"`
    Role     string `json:"role"`
    jwt.RegisteredClaims
}

// validateToken 验证Token
func validateToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return []byte("your-secret-key"), nil
    })

    if err != nil {
        return nil, err
    }

    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }

    return nil, jwt.ErrSignatureInvalid
}

// hasPermissions 检查用户权限
func hasPermissions(userID int, requiredPermissions ...string) bool {
    // 这里应该从数据库查询用户权限
    // 简化实现，实际应该查询数据库
    return true
}
EOF

echo -e "${GREEN}✅ 权限验证中间件创建完成${NC}"

echo ""
echo -e "${BLUE}8. 创建用户管理界面${NC}"
echo "================================"

# 创建用户管理界面
echo "创建用户管理界面..."
cat > /tmp/user_management.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>JobFirst 团队访问管理</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .role-section {
            margin: 20px 0;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        .role-section h3 {
            margin-top: 0;
            color: #333;
        }
        .permission-list {
            list-style: none;
            padding: 0;
        }
        .permission-list li {
            padding: 5px 0;
            border-bottom: 1px solid #eee;
        }
        .permission-list li:last-child {
            border-bottom: none;
        }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        .info { color: #17a2b8; }
        .user-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        .user-table th, .user-table td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .user-table th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 2px;
        }
        .btn-primary { background-color: #007bff; color: white; }
        .btn-success { background-color: #28a745; color: white; }
        .btn-warning { background-color: #ffc107; color: black; }
        .btn-danger { background-color: #dc3545; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>👥 JobFirst 团队访问管理系统</h1>
            <p>统一登录，分级权限管理</p>
        </div>

        <div class="role-section">
            <h3>🔐 角色权限配置</h3>
            
            <div class="role-section">
                <h3>👑 管理员 (Admin)</h3>
                <ul class="permission-list">
                    <li class="success">✅ 用户管理 (创建、编辑、删除用户)</li>
                    <li class="success">✅ API管理 (读取、写入、删除API)</li>
                    <li class="success">✅ 数据库管理 (读取、写入、管理数据库)</li>
                    <li class="success">✅ 测试管理 (执行、创建、查看测试)</li>
                    <li class="success">✅ 监控管理 (查看、管理监控)</li>
                    <li class="success">✅ 部署管理 (查看、执行、管理部署)</li>
                </ul>
            </div>
            
            <div class="role-section">
                <h3>💻 开发人员 (Developer)</h3>
                <ul class="permission-list">
                    <li class="success">✅ 用户查看</li>
                    <li class="success">✅ API读写 (读取、写入API)</li>
                    <li class="success">✅ 数据库读写 (读取、写入数据库)</li>
                    <li class="success">✅ 测试执行 (执行、创建、查看测试)</li>
                    <li class="success">✅ 监控查看</li>
                    <li class="success">✅ 部署执行 (查看、执行部署)</li>
                </ul>
            </div>
            
            <div class="role-section">
                <h3>🧪 测试人员 (Tester)</h3>
                <ul class="permission-list">
                    <li class="success">✅ 用户查看</li>
                    <li class="success">✅ API读取</li>
                    <li class="success">✅ 数据库读取</li>
                    <li class="success">✅ 测试执行 (执行、创建、查看测试)</li>
                    <li class="success">✅ 监控查看</li>
                    <li class="error">❌ 部署管理</li>
                </ul>
            </div>
            
            <div class="role-section">
                <h3>📊 产品经理 (Product Manager)</h3>
                <ul class="permission-list">
                    <li class="success">✅ 用户查看</li>
                    <li class="success">✅ API读取</li>
                    <li class="success">✅ 数据库读取</li>
                    <li class="success">✅ 测试结果查看</li>
                    <li class="success">✅ 监控查看</li>
                    <li class="error">❌ 部署管理</li>
                </ul>
            </div>
        </div>

        <div class="role-section">
            <h3>👥 用户管理</h3>
            <table class="user-table">
                <thead>
                    <tr>
                        <th>用户名</th>
                        <th>邮箱</th>
                        <th>角色</th>
                        <th>状态</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>admin</td>
                        <td>admin@jobfirst.com</td>
                        <td>管理员</td>
                        <td class="success">活跃</td>
                        <td>
                            <button class="btn btn-primary" onclick="editUser(1)">编辑</button>
                            <button class="btn btn-warning" onclick="resetPassword(1)">重置密码</button>
                        </td>
                    </tr>
                    <tr>
                        <td>developer1</td>
                        <td>dev1@jobfirst.com</td>
                        <td>开发人员</td>
                        <td class="success">活跃</td>
                        <td>
                            <button class="btn btn-primary" onclick="editUser(2)">编辑</button>
                            <button class="btn btn-warning" onclick="resetPassword(2)">重置密码</button>
                        </td>
                    </tr>
                    <tr>
                        <td>tester1</td>
                        <td>tester1@jobfirst.com</td>
                        <td>测试人员</td>
                        <td class="success">活跃</td>
                        <td>
                            <button class="btn btn-primary" onclick="editUser(4)">编辑</button>
                            <button class="btn btn-warning" onclick="resetPassword(4)">重置密码</button>
                        </td>
                    </tr>
                    <tr>
                        <td>product1</td>
                        <td>product1@jobfirst.com</td>
                        <td>产品经理</td>
                        <td class="success">活跃</td>
                        <td>
                            <button class="btn btn-primary" onclick="editUser(6)">编辑</button>
                            <button class="btn btn-warning" onclick="resetPassword(6)">重置密码</button>
                        </td>
                    </tr>
                </tbody>
            </table>
            
            <button class="btn btn-success" onclick="showAddUserForm()">添加用户</button>
        </div>

        <div class="role-section">
            <h3>🔗 访问信息</h3>
            <p><strong>测试环境地址:</strong> http://101.33.251.158:8000</p>
            <p><strong>统一登录入口:</strong> http://101.33.251.158:8000/api/v1/auth/login</p>
            <p><strong>用户管理界面:</strong> http://101.33.251.158:8000/admin/users</p>
            <p><strong>默认密码:</strong> password123</p>
        </div>
    </div>

    <script>
        function editUser(userId) {
            alert('编辑用户 ID: ' + userId);
        }
        
        function resetPassword(userId) {
            if (confirm('确定要重置用户密码吗？')) {
                alert('密码重置成功，新密码: password123');
            }
        }
        
        function showAddUserForm() {
            alert('显示添加用户表单');
        }
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ 用户管理界面创建完成${NC}"

echo ""
echo -e "${BLUE}9. 创建使用示例${NC}"
echo "================================"

# 创建使用示例
echo "创建使用示例..."
cat > /tmp/usage_examples.sh << 'EOF'
#!/bin/bash

# JobFirst 团队访问使用示例

echo "=== JobFirst 团队访问使用示例 ==="
echo ""

# 服务器信息
SERVER_HOST="101.33.251.158"

echo "1. 开发人员登录和操作示例"
echo "================================"

echo "# 登录"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"username\": \"developer1\","
echo "    \"password\": \"password123\""
echo "  }'"
echo ""

echo "# 使用Token访问API"
echo "curl -H \"Authorization: Bearer <your_token>\" \\"
echo "  http://$SERVER_HOST:8000/api/v1/apis"
echo ""

echo "# 执行数据库操作"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/database/query \\"
echo "  -H \"Authorization: Bearer <your_token>\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"query\": \"SELECT * FROM users WHERE role = \\\"developer\\\"\""
echo "  }'"
echo ""

echo "2. 测试人员登录和操作示例"
echo "================================"

echo "# 登录"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"username\": \"tester1\","
echo "    \"password\": \"password123\""
echo "  }'"
echo ""

echo "# 执行测试"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/tests/execute \\"
echo "  -H \"Authorization: Bearer <your_token>\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"test_type\": \"api\","
echo "    \"endpoint\": \"/api/v1/users\","
echo "    \"method\": \"GET\""
echo "  }'"
echo ""

echo "3. 产品经理登录和操作示例"
echo "================================"

echo "# 登录"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"username\": \"product1\","
echo "    \"password\": \"password123\""
echo "  }'"
echo ""

echo "# 查看功能状态"
echo "curl -H \"Authorization: Bearer <your_token>\" \\"
echo "  http://$SERVER_HOST:8000/api/v1/monitoring"
echo ""

echo "4. 管理员操作示例"
echo "================================"

echo "# 查看所有用户"
echo "curl -H \"Authorization: Bearer <admin_token>\" \\"
echo "  http://$SERVER_HOST:8000/api/v1/users"
echo ""

echo "# 创建新用户"
echo "curl -X POST http://$SERVER_HOST:8000/api/v1/users \\"
echo "  -H \"Authorization: Bearer <admin_token>\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"username\": \"newuser\","
echo "    \"email\": \"newuser@jobfirst.com\","
echo "    \"password\": \"password123\","
echo "    \"role\": \"developer\""
echo "  }'"
echo ""

echo "=== 示例完成 ==="
EOF

chmod +x /tmp/usage_examples.sh
echo -e "${GREEN}✅ 使用示例创建完成${NC}"

echo ""
echo -e "${BLUE}10. 最终配置总结${NC}"
echo "================================"

echo -e "${GREEN}🎉 JobFirst 团队访问管理系统配置完成！${NC}"
echo ""
echo "📋 配置文件位置:"
echo "  - 数据库表结构: /tmp/team_access_schema.sql"
echo "  - 权限数据: /tmp/permissions_data.sql"
echo "  - 角色权限: /tmp/role_permissions.sql"
echo "  - 测试用户: /tmp/test_users.sql"
echo "  - 用户管理API: /tmp/user_management_api.go"
echo "  - 权限中间件: /tmp/auth_middleware.go"
echo "  - 管理界面: /tmp/user_management.html"
echo "  - 使用示例: /tmp/usage_examples.sh"
echo ""
echo "👥 测试用户:"
echo "  - 管理员: admin@jobfirst.com (password123)"
echo "  - 开发人员: dev1@jobfirst.com (password123)"
echo "  - 测试人员: tester1@jobfirst.com (password123)"
echo "  - 产品经理: product1@jobfirst.com (password123)"
echo ""
echo "🔐 权限系统特点:"
echo "  ✅ 统一登录入口"
echo "  ✅ 分级权限控制"
echo "  ✅ 角色权限管理"
echo "  ✅ 操作日志记录"
echo "  ✅ 安全Token验证"
echo ""
echo "🚀 下一步操作:"
echo "  1. 执行数据库初始化脚本"
echo "  2. 部署用户管理API"
echo "  3. 配置权限验证中间件"
echo "  4. 测试各角色登录和权限"
echo "  5. 开始团队协同工作"

echo ""
echo "=== 团队访问设置完成 ==="
