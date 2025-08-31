# 👥 JobFirst 团队访问管理系统

## 🎯 **系统概述**

### 设计理念
**统一登录，分级权限** - 所有团队成员使用同一个测试环境，通过角色和权限系统实现差异化访问控制。

## 🏗️ **系统架构**

### 1. **统一认证系统**
```
所有用户 → 统一登录入口 → 角色验证 → 权限分配 → 功能访问
```

### 2. **权限层级结构**
```
管理员 (Admin)
├── 开发人员 (Developer)
├── 测试人员 (Tester)
└── 产品经理 (Product Manager)
```

## 👥 **用户角色定义**

### 1. **管理员 (Admin)**
- **权限范围**: 全部权限
- **职责**: 环境管理、用户管理、系统配置
- **访问范围**: 所有服务和功能

### 2. **开发人员 (Developer)**
- **权限范围**: 读写权限
- **职责**: 功能开发、API测试、数据库操作
- **访问范围**: API、数据库、代码仓库

### 3. **测试人员 (Tester)**
- **权限范围**: 只读权限 + 测试权限
- **职责**: 功能测试、性能测试、用户体验测试
- **访问范围**: 测试环境、测试工具、测试数据

### 4. **产品经理 (Product Manager)**
- **权限范围**: 只读权限 + 需求管理权限
- **职责**: 功能验证、需求管理、进度跟踪
- **访问范围**: 功能界面、需求系统、进度报告

## 🔐 **权限管理系统**

### 1. **数据库权限设计**

```sql
-- 用户表
CREATE TABLE users (
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
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 角色权限关联表
CREATE TABLE role_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role ENUM('admin', 'developer', 'tester', 'product') NOT NULL,
    permission_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (permission_id) REFERENCES permissions(id),
    UNIQUE KEY unique_role_permission (role, permission_id)
);

-- 用户会话表
CREATE TABLE user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 2. **权限配置**

```sql
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
('deploy_admin', '管理部署', 'deployment', 'admin');

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
('product', 16); -- 部署查看
```

## 🚀 **统一登录系统**

### 1. **登录流程**

```bash
# 统一登录API
POST /api/v1/auth/login
Content-Type: application/json

{
    "username": "developer1",
    "password": "password123"
}

# 响应
{
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 2,
        "username": "developer1",
        "email": "dev1@jobfirst.com",
        "role": "developer",
        "permissions": ["api_read", "api_write", "db_read", "db_write"]
    },
    "expires_at": "2025-09-01T15:43:57Z"
}
```

### 2. **权限验证中间件**

```go
// 权限验证中间件
func AuthMiddleware(requiredPermissions ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 获取Token
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(401, gin.H{"error": "Authorization required"})
            c.Abort()
            return
        }

        // 验证Token
        claims, err := validateToken(token)
        if err != nil {
            c.JSON(401, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }

        // 检查权限
        if !hasPermissions(claims.UserID, requiredPermissions...) {
            c.JSON(403, gin.H{"error": "Insufficient permissions"})
            c.Abort()
            return
        }

        // 设置用户信息到上下文
        c.Set("user_id", claims.UserID)
        c.Set("username", claims.Username)
        c.Set("role", claims.Role)
        c.Set("permissions", claims.Permissions)

        c.Next()
    }
}
```

## 📋 **用户管理界面**

### 1. **管理员界面**

```html
<!-- 用户管理界面 -->
<div class="user-management">
    <h2>用户管理</h2>
    
    <!-- 用户列表 -->
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
                <td>活跃</td>
                <td>
                    <button onclick="editUser(1)">编辑</button>
                    <button onclick="resetPassword(1)">重置密码</button>
                </td>
            </tr>
            <tr>
                <td>developer1</td>
                <td>dev1@jobfirst.com</td>
                <td>开发人员</td>
                <td>活跃</td>
                <td>
                    <button onclick="editUser(2)">编辑</button>
                    <button onclick="resetPassword(2)">重置密码</button>
                </td>
            </tr>
        </tbody>
    </table>
    
    <!-- 添加用户 -->
    <button onclick="showAddUserForm()">添加用户</button>
</div>
```

### 2. **角色权限配置**

```html
<!-- 角色权限配置 -->
<div class="role-permissions">
    <h2>角色权限配置</h2>
    
    <div class="role-section">
        <h3>管理员 (Admin)</h3>
        <ul>
            <li>✅ 用户管理</li>
            <li>✅ API管理</li>
            <li>✅ 数据库管理</li>
            <li>✅ 测试管理</li>
            <li>✅ 监控管理</li>
            <li>✅ 部署管理</li>
        </ul>
    </div>
    
    <div class="role-section">
        <h3>开发人员 (Developer)</h3>
        <ul>
            <li>✅ 用户查看</li>
            <li>✅ API读写</li>
            <li>✅ 数据库读写</li>
            <li>✅ 测试执行</li>
            <li>✅ 监控查看</li>
            <li>✅ 部署执行</li>
        </ul>
    </div>
    
    <div class="role-section">
        <h3>测试人员 (Tester)</h3>
        <ul>
            <li>✅ 用户查看</li>
            <li>✅ API读取</li>
            <li>✅ 数据库读取</li>
            <li>✅ 测试执行</li>
            <li>✅ 监控查看</li>
            <li>❌ 部署管理</li>
        </ul>
    </div>
    
    <div class="role-section">
        <h3>产品经理 (Product Manager)</h3>
        <ul>
            <li>✅ 用户查看</li>
            <li>✅ API读取</li>
            <li>✅ 数据库读取</li>
            <li>✅ 测试结果查看</li>
            <li>✅ 监控查看</li>
            <li>❌ 部署管理</li>
        </ul>
    </div>
</div>
```

## 🔧 **API权限控制**

### 1. **API路由权限配置**

```go
// API路由配置
func setupAPIRoutes(router *gin.Engine) {
    // 公开路由
    router.POST("/api/v1/auth/login", authController.Login)
    router.POST("/api/v1/auth/register", authController.Register)
    
    // 需要认证的路由
    api := router.Group("/api/v1")
    api.Use(AuthMiddleware())
    
    // 用户管理 (管理员)
    api.GET("/users", AuthMiddleware("user_read"), userController.GetUsers)
    api.POST("/users", AuthMiddleware("user_create"), userController.CreateUser)
    api.PUT("/users/:id", AuthMiddleware("user_update"), userController.UpdateUser)
    api.DELETE("/users/:id", AuthMiddleware("user_delete"), userController.DeleteUser)
    
    // API管理 (开发人员)
    api.GET("/apis", AuthMiddleware("api_read"), apiController.GetAPIs)
    api.POST("/apis", AuthMiddleware("api_write"), apiController.CreateAPI)
    api.PUT("/apis/:id", AuthMiddleware("api_write"), apiController.UpdateAPI)
    api.DELETE("/apis/:id", AuthMiddleware("api_delete"), apiController.DeleteAPI)
    
    // 数据库操作 (开发人员)
    api.GET("/database/tables", AuthMiddleware("db_read"), dbController.GetTables)
    api.POST("/database/query", AuthMiddleware("db_write"), dbController.ExecuteQuery)
    
    // 测试管理 (测试人员)
    api.GET("/tests", AuthMiddleware("test_read"), testController.GetTests)
    api.POST("/tests", AuthMiddleware("test_create"), testController.CreateTest)
    api.POST("/tests/execute", AuthMiddleware("test_execute"), testController.ExecuteTest)
    
    // 监控查看 (所有角色)
    api.GET("/monitoring", AuthMiddleware("monitor_read"), monitorController.GetMetrics)
    
    // 部署管理 (管理员和开发人员)
    api.GET("/deployment", AuthMiddleware("deploy_read"), deployController.GetDeployments)
    api.POST("/deployment", AuthMiddleware("deploy_execute"), deployController.Deploy)
}
```

### 2. **权限检查函数**

```go
// 权限检查函数
func hasPermissions(userID int, requiredPermissions ...string) bool {
    // 获取用户权限
    userPermissions := getUserPermissions(userID)
    
    // 检查是否有所需权限
    for _, required := range requiredPermissions {
        found := false
        for _, userPerm := range userPermissions {
            if userPerm == required {
                found = true
                break
            }
        }
        if !found {
            return false
        }
    }
    
    return true
}

// 获取用户权限
func getUserPermissions(userID int) []string {
    // 从数据库获取用户权限
    var permissions []string
    
    query := `
        SELECT p.name 
        FROM permissions p
        JOIN role_permissions rp ON p.id = rp.permission_id
        JOIN users u ON u.role = rp.role
        WHERE u.id = ?
    `
    
    rows, err := db.Query(query, userID)
    if err != nil {
        return permissions
    }
    defer rows.Close()
    
    for rows.Next() {
        var perm string
        if err := rows.Scan(&perm); err == nil {
            permissions = append(permissions, perm)
        }
    }
    
    return permissions
}
```

## 📊 **使用示例**

### 1. **开发人员登录和操作**

```bash
# 1. 登录
curl -X POST http://101.33.251.158:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "developer1",
    "password": "password123"
  }'

# 响应
{
    "success": true,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
        "id": 2,
        "username": "developer1",
        "role": "developer",
        "permissions": ["api_read", "api_write", "db_read", "db_write"]
    }
}

# 2. 使用Token访问API
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://101.33.251.158:8000/api/v1/apis

# 3. 执行数据库操作
curl -X POST http://101.33.251.158:8000/api/v1/database/query \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "query": "SELECT * FROM users WHERE role = \"developer\""
  }'
```

### 2. **测试人员登录和操作**

```bash
# 1. 登录
curl -X POST http://101.33.251.158:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tester1",
    "password": "password123"
  }'

# 2. 执行测试
curl -X POST http://101.33.251.158:8000/api/v1/tests/execute \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "test_type": "api",
    "endpoint": "/api/v1/users",
    "method": "GET"
  }'

# 3. 查看测试结果
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://101.33.251.158:8000/api/v1/tests
```

### 3. **产品经理登录和操作**

```bash
# 1. 登录
curl -X POST http://101.33.251.158:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "product1",
    "password": "password123"
  }'

# 2. 查看功能状态
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://101.33.251.158:8000/api/v1/monitoring

# 3. 查看测试结果
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  http://101.33.251.158:8000/api/v1/tests
```

## 🔒 **安全措施**

### 1. **Token安全**
- JWT Token过期时间设置
- Token刷新机制
- Token黑名单管理

### 2. **权限审计**
- 操作日志记录
- 权限变更审计
- 异常访问监控

### 3. **数据保护**
- 敏感数据加密
- 数据库访问控制
- API访问频率限制

## 📋 **管理流程**

### 1. **用户添加流程**
1. 管理员创建用户账号
2. 分配角色和权限
3. 发送登录凭据
4. 用户首次登录修改密码

### 2. **权限变更流程**
1. 管理员申请权限变更
2. 审核权限变更请求
3. 执行权限变更
4. 通知相关用户
5. 记录变更日志

### 3. **用户离职流程**
1. 暂停用户账号
2. 备份用户数据
3. 撤销用户权限
4. 删除用户会话
5. 记录操作日志

---

**🎯 总结：通过统一登录系统和分级权限管理，所有团队成员都可以安全地访问同一个测试环境，同时确保每个角色只能访问其权限范围内的功能和数据。**
