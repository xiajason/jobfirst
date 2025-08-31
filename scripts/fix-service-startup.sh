#!/bin/bash

# JobFirst 服务启动修复脚本
echo "=== JobFirst 服务启动修复脚本 ==="
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
SERVER_USER="root"

echo -e "${BLUE}1. 检查服务器连接${NC}"
echo "================================"

# 测试SSH连接
if ssh -o ConnectTimeout=10 $SERVER_USER@$SERVER_HOST "echo 'SSH连接成功'" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH连接成功${NC}"
else
    echo -e "${RED}❌ SSH连接失败，请检查网络和SSH密钥${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}2. 检查Docker容器状态${NC}"
echo "================================"

# 检查Docker容器状态
echo "检查所有容器状态..."
ssh $SERVER_USER@$SERVER_HOST "docker ps -a"

echo ""
echo "检查Docker Compose状态..."
ssh $SERVER_USER@$SERVER_HOST "docker-compose ps"

echo ""
echo -e "${BLUE}3. 查看服务日志${NC}"
echo "================================"

# 查看关键服务日志
echo "查看API网关日志..."
ssh $SERVER_USER@$SERVER_HOST "docker logs jobfirst-gateway --tail 20" 2>/dev/null || echo "API网关容器不存在或未运行"

echo ""
echo "查看共享基础设施日志..."
ssh $SERVER_USER@$SERVER_HOST "docker logs jobfirst-shared-infra --tail 20" 2>/dev/null || echo "共享基础设施容器不存在或未运行"

echo ""
echo "查看MySQL日志..."
ssh $SERVER_USER@$SERVER_HOST "docker logs jobfirst-mysql --tail 10" 2>/dev/null || echo "MySQL容器不存在或未运行"

echo ""
echo "查看Redis日志..."
ssh $SERVER_USER@$SERVER_HOST "docker logs jobfirst-redis --tail 10" 2>/dev/null || echo "Redis容器不存在或未运行"

echo ""
echo -e "${BLUE}4. 重启服务${NC}"
echo "================================"

# 重启所有服务
echo "重启所有Docker Compose服务..."
ssh $SERVER_USER@$SERVER_HOST "cd /root/jobfirst && docker-compose down"
ssh $SERVER_USER@$SERVER_HOST "cd /root/jobfirst && docker-compose up -d"

echo ""
echo "等待服务启动..."
sleep 30

echo ""
echo -e "${BLUE}5. 验证服务状态${NC}"
echo "================================"

# 验证服务状态
echo "检查容器运行状态..."
ssh $SERVER_USER@$SERVER_HOST "docker ps"

echo ""
echo "检查端口监听状态..."
ssh $SERVER_USER@$SERVER_HOST "netstat -tlnp | grep -E '8000|8210|3306|6379'"

echo ""
echo -e "${BLUE}6. 测试服务可用性${NC}"
echo "================================"

# 测试服务可用性
echo "测试API网关健康检查..."
if curl -f --connect-timeout 10 http://$SERVER_HOST:8000/health 2>/dev/null; then
    echo -e "${GREEN}✅ API网关健康检查成功${NC}"
else
    echo -e "${RED}❌ API网关健康检查失败${NC}"
fi

echo ""
echo "测试共享基础设施健康检查..."
if curl -f --connect-timeout 10 http://$SERVER_HOST:8210/health 2>/dev/null; then
    echo -e "${GREEN}✅ 共享基础设施健康检查成功${NC}"
else
    echo -e "${RED}❌ 共享基础设施健康检查失败${NC}"
fi

echo ""
echo "测试MySQL连接..."
if nc -z -w5 $SERVER_HOST 3306 2>/dev/null; then
    echo -e "${GREEN}✅ MySQL端口可访问${NC}"
else
    echo -e "${RED}❌ MySQL端口不可访问${NC}"
fi

echo ""
echo "测试Redis连接..."
if nc -z -w5 $SERVER_HOST 6379 2>/dev/null; then
    echo -e "${GREEN}✅ Redis端口可访问${NC}"
else
    echo -e "${RED}❌ Redis端口不可访问${NC}"
fi

echo ""
echo -e "${BLUE}7. 创建测试用户和配置${NC}"
echo "================================"

# 创建测试用户
echo "创建测试用户..."
ssh $SERVER_USER@$SERVER_HOST "mysql -h localhost -P 3306 -u root -p'jobfirst123' -e \"CREATE USER IF NOT EXISTS 'test_user'@'%' IDENTIFIED BY 'test_password_2025'; GRANT SELECT, INSERT, UPDATE, DELETE ON jobfirst_advanced.* TO 'test_user'@'%'; FLUSH PRIVILEGES;\" 2>/dev/null" && echo -e "${GREEN}✅ 测试用户创建成功${NC}" || echo -e "${YELLOW}⚠️ 测试用户创建失败或已存在${NC}"

# 生成JWT密钥
echo ""
echo "生成JWT密钥..."
JWT_SECRET=$(ssh $SERVER_USER@$SERVER_HOST "openssl rand -base64 32 2>/dev/null")
if [ ! -z "$JWT_SECRET" ]; then
    echo -e "${GREEN}✅ JWT密钥生成成功${NC}"
    echo "JWT密钥: $JWT_SECRET"
else
    echo -e "${YELLOW}⚠️ JWT密钥生成失败${NC}"
fi

echo ""
echo -e "${BLUE}8. 最终状态检查${NC}"
echo "================================"

# 最终状态检查
echo "运行完整的环境验证..."
./scripts/test-environment-access.sh

echo ""
echo -e "${BLUE}9. 访问信息${NC}"
echo "================================"

echo -e "${GREEN}🎉 服务修复完成！${NC}"
echo ""
echo "访问地址:"
echo "  API网关: http://$SERVER_HOST:8000"
echo "  共享基础设施: http://$SERVER_HOST:8210"
echo "  健康检查: http://$SERVER_HOST:8000/health"
echo ""
echo "数据库连接:"
echo "  MySQL: $SERVER_HOST:3306"
echo "  Redis: $SERVER_HOST:6379"
echo ""
echo "测试用户:"
echo "  用户名: test_user"
echo "  密码: test_password_2025"
echo ""
echo "下一步:"
echo "  1. 访问健康检查端点验证服务"
echo "  2. 配置API认证系统"
echo "  3. 开始功能开发和测试"

echo ""
echo "=== 修复完成 ==="
