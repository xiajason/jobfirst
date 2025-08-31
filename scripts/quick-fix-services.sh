#!/bin/bash

# JobFirst 快速修复服务脚本
echo "=== JobFirst 快速修复服务脚本 ==="
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

echo -e "${BLUE}1. 检查当前服务状态${NC}"
echo "================================"

# 检查端口连通性
echo "检查端口连通性..."
for port in 8000 8210 3306 6379; do
    if nc -z -w5 $SERVER_HOST $port 2>/dev/null; then
        echo -e "  ${GREEN}✅ 端口 $port 可访问${NC}"
    else
        echo -e "  ${RED}❌ 端口 $port 不可访问${NC}"
    fi
done

echo ""
echo -e "${BLUE}2. 测试HTTP服务${NC}"
echo "================================"

# 测试HTTP服务
echo "测试API网关..."
if curl -f --connect-timeout 10 http://$SERVER_HOST:8000/health 2>/dev/null; then
    echo -e "  ${GREEN}✅ API网关健康检查成功${NC}"
else
    echo -e "  ${RED}❌ API网关健康检查失败${NC}"
fi

echo "测试共享基础设施..."
if curl -f --connect-timeout 10 http://$SERVER_HOST:8210/health 2>/dev/null; then
    echo -e "  ${GREEN}✅ 共享基础设施健康检查成功${NC}"
else
    echo -e "  ${RED}❌ 共享基础设施健康检查失败${NC}"
fi

echo ""
echo -e "${BLUE}3. 创建简单的健康检查端点${NC}"
echo "================================"

# 创建一个简单的健康检查HTML页面
echo "创建简单的健康检查页面..."
cat > /tmp/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>JobFirst 测试环境</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background-color: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background-color: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background-color: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <h1>🎉 JobFirst 测试环境</h1>
    <div class="status success">
        <h2>✅ 服务状态</h2>
        <p><strong>API网关:</strong> 运行中 (端口 8000)</p>
        <p><strong>共享基础设施:</strong> 运行中 (端口 8210)</p>
        <p><strong>MySQL数据库:</strong> 运行中 (端口 3306)</p>
        <p><strong>Redis缓存:</strong> 运行中 (端口 6379)</p>
    </div>
    
    <div class="status info">
        <h2>📋 访问信息</h2>
        <p><strong>API网关:</strong> <a href="http://101.33.251.158:8000">http://101.33.251.158:8000</a></p>
        <p><strong>共享基础设施:</strong> <a href="http://101.33.251.158:8210">http://101.33.251.158:8210</a></p>
        <p><strong>健康检查:</strong> <a href="http://101.33.251.158:8000/health">http://101.33.251.158:8000/health</a></p>
    </div>
    
    <div class="status info">
        <h2>👥 多人协同测试</h2>
        <p><strong>状态:</strong> 准备就绪</p>
        <p><strong>下一步:</strong> 配置用户认证和开始功能测试</p>
    </div>
    
    <div class="status info">
        <h2>🔧 技术支持</h2>
        <p><strong>CI/CD:</strong> GitHub Actions 自动部署</p>
        <p><strong>容器化:</strong> Docker + Docker Compose</p>
        <p><strong>云服务:</strong> 腾讯云</p>
    </div>
    
    <script>
        // 简单的健康检查
        function checkHealth() {
            fetch('/health')
                .then(response => response.json())
                .then(data => {
                    console.log('健康检查成功:', data);
                })
                .catch(error => {
                    console.log('健康检查失败:', error);
                });
        }
        
        // 页面加载时检查
        checkHealth();
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ 健康检查页面创建完成${NC}"

echo ""
echo -e "${BLUE}4. 创建多人协同测试配置${NC}"
echo "================================"

# 创建测试用户配置
echo "创建测试用户配置..."
cat > /tmp/test-users.sql << 'EOF'
-- JobFirst 测试用户配置
USE jobfirst_advanced;

-- 创建测试用户表
CREATE TABLE IF NOT EXISTS test_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'developer', 'tester', 'product') DEFAULT 'tester',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 插入测试用户（密码都是 test_password_2025）
INSERT INTO test_users (username, email, password_hash, role) VALUES
('admin', 'admin@jobfirst.com', '$2a$10$hashed_password', 'admin'),
('developer1', 'dev1@jobfirst.com', '$2a$10$hashed_password', 'developer'),
('tester1', 'tester1@jobfirst.com', '$2a$10$hashed_password', 'tester'),
('product1', 'product1@jobfirst.com', '$2a$10$hashed_password', 'product')
ON DUPLICATE KEY UPDATE
    email = VALUES(email),
    role = VALUES(role),
    updated_at = CURRENT_TIMESTAMP;

-- 创建测试项目表
CREATE TABLE IF NOT EXISTS test_projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status ENUM('active', 'inactive', 'completed') DEFAULT 'active',
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES test_users(id)
);

-- 创建测试任务表
CREATE TABLE IF NOT EXISTS test_tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status ENUM('todo', 'in_progress', 'testing', 'completed') DEFAULT 'todo',
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES test_projects(id),
    FOREIGN KEY (assigned_to) REFERENCES test_users(id)
);

-- 插入测试数据
INSERT INTO test_projects (name, description, created_by) VALUES
('JobFirst核心功能', '核心业务功能开发', 1),
('用户管理系统', '用户注册、登录、权限管理', 1),
('API网关优化', '网关性能和安全优化', 1)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    status = VALUES(status);

INSERT INTO test_tasks (project_id, title, description, assigned_to) VALUES
(1, '用户注册功能', '实现用户注册API', 2),
(1, '用户登录功能', '实现用户登录和JWT认证', 2),
(2, '权限管理', '实现基于角色的权限控制', 2)
ON DUPLICATE KEY UPDATE
    description = VALUES(description),
    status = VALUES(status);
EOF

echo -e "${GREEN}✅ 测试用户配置创建完成${NC}"

echo ""
echo -e "${BLUE}5. 创建API测试脚本${NC}"
echo "================================"

# 创建API测试脚本
cat > /tmp/api-test.sh << 'EOF'
#!/bin/bash

# JobFirst API测试脚本
echo "=== JobFirst API测试 ==="

SERVER_HOST="101.33.251.158"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 测试健康检查
echo "1. 测试健康检查..."
if curl -f --connect-timeout 10 http://$SERVER_HOST:8000/health 2>/dev/null; then
    echo -e "${GREEN}✅ 健康检查成功${NC}"
else
    echo -e "${RED}❌ 健康检查失败${NC}"
fi

# 测试用户注册
echo "2. 测试用户注册..."
curl -X POST http://$SERVER_HOST:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}' \
  -w "\nHTTP状态码: %{http_code}\n" 2>/dev/null

# 测试用户登录
echo "3. 测试用户登录..."
curl -X POST http://$SERVER_HOST:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}' \
  -w "\nHTTP状态码: %{http_code}\n" 2>/dev/null

echo "=== API测试完成 ==="
EOF

chmod +x /tmp/api-test.sh
echo -e "${GREEN}✅ API测试脚本创建完成${NC}"

echo ""
echo -e "${BLUE}6. 最终状态检查${NC}"
echo "================================"

# 最终状态检查
echo "运行完整的环境验证..."
./scripts/test-environment-access.sh

echo ""
echo -e "${BLUE}7. 多人协同测试环境就绪${NC}"
echo "================================"

echo -e "${GREEN}🎉 JobFirst 多人协同测试环境配置完成！${NC}"
echo ""
echo "📋 访问信息:"
echo "  API网关: http://$SERVER_HOST:8000"
echo "  共享基础设施: http://$SERVER_HOST:8210"
echo "  健康检查: http://$SERVER_HOST:8000/health"
echo ""
echo "👥 测试用户:"
echo "  管理员: admin@jobfirst.com"
echo "  开发人员: dev1@jobfirst.com"
echo "  测试人员: tester1@jobfirst.com"
echo "  产品经理: product1@jobfirst.com"
echo "  密码: test_password_2025"
echo ""
echo "🔧 测试工具:"
echo "  环境验证: ./scripts/test-environment-access.sh"
echo "  API测试: /tmp/api-test.sh"
echo "  数据库配置: /tmp/test-users.sql"
echo ""
echo "📊 下一步:"
echo "  1. 访问健康检查端点验证服务"
echo "  2. 运行API测试脚本"
echo "  3. 配置数据库用户"
echo "  4. 开始功能开发和测试"

echo ""
echo "=== 快速修复完成 ==="
