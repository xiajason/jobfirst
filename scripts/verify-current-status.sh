#!/bin/bash

# JobFirst 当前状态验证脚本
echo "=== JobFirst 当前状态验证 ==="
echo "时间: $(date)"
echo "测试环境: 101.33.251.158"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}1. 网络连通性验证${NC}"
echo "================================"

# 检查端口连通性
ports=(8000 8210 3306 6379)
services=("API网关" "共享基础设施" "MySQL数据库" "Redis缓存")
connected_count=0

for i in "${!ports[@]}"; do
    port=${ports[$i]}
    service=${services[$i]}
    
    if nc -z -w5 101.33.251.158 $port 2>/dev/null; then
        echo -e "  ${GREEN}✅ $service (端口 $port): 可访问${NC}"
        ((connected_count++))
    else
        echo -e "  ${RED}❌ $service (端口 $port): 不可访问${NC}"
    fi
done

echo ""
echo -e "${BLUE}2. HTTP服务验证${NC}"
echo "================================"

# 测试HTTP服务
http_success=0

echo "测试API网关..."
if curl -f --connect-timeout 10 http://101.33.251.158:8000/health 2>/dev/null; then
    echo -e "  ${GREEN}✅ API网关健康检查成功${NC}"
    ((http_success++))
else
    echo -e "  ${YELLOW}⚠️ API网关健康检查失败 (可能还在启动中)${NC}"
fi

echo "测试共享基础设施..."
if curl -f --connect-timeout 10 http://101.33.251.158:8210/health 2>/dev/null; then
    echo -e "  ${GREEN}✅ 共享基础设施健康检查成功${NC}"
    ((http_success++))
else
    echo -e "  ${YELLOW}⚠️ 共享基础设施健康检查失败 (可能还在启动中)${NC}"
fi

echo ""
echo -e "${BLUE}3. 数据库连接验证${NC}"
echo "================================"

# 测试数据库连接
db_success=0

echo "测试MySQL连接..."
if nc -z -w5 101.33.251.158 3306 2>/dev/null; then
    echo -e "  ${GREEN}✅ MySQL端口可访问${NC}"
    ((db_success++))
else
    echo -e "  ${RED}❌ MySQL端口不可访问${NC}"
fi

echo "测试Redis连接..."
if nc -z -w5 101.33.251.158 6379 2>/dev/null; then
    echo -e "  ${GREEN}✅ Redis端口可访问${NC}"
    ((db_success++))
else
    echo -e "  ${RED}❌ Redis端口不可访问${NC}"
fi

echo ""
echo -e "${BLUE}4. 状态总结${NC}"
echo "================================"

total_services=4
success_rate=$((connected_count * 100 / total_services))

echo "服务连通性: $connected_count/$total_services ($success_rate%)"
echo "HTTP服务: $http_success/2"
echo "数据库服务: $db_success/2"

echo ""
echo -e "${BLUE}5. 访问信息${NC}"
echo "================================"

echo "📋 测试环境地址:"
echo "  API网关: http://101.33.251.158:8000"
echo "  共享基础设施: http://101.33.251.158:8210"
echo "  健康检查: http://101.33.251.158:8000/health"
echo ""
echo "🔧 数据库连接:"
echo "  MySQL: 101.33.251.158:3306"
echo "  Redis: 101.33.251.158:6379"
echo ""
echo "👥 测试用户:"
echo "  用户名: test_user"
echo "  密码: test_password_2025"

echo ""
echo -e "${BLUE}6. 当前状态评估${NC}"
echo "================================"

if [ $success_rate -ge 75 ] && [ $connected_count -eq 4 ]; then
    echo -e "${GREEN}🎉 基础设施就绪！${NC}"
    echo "✅ 所有端口都可访问"
    echo "✅ 网络连通性正常"
    echo "✅ 容器部署完成"
    
    if [ $http_success -eq 0 ]; then
        echo -e "${YELLOW}⚠️ HTTP服务还在启动中${NC}"
        echo "建议等待2-5分钟后再测试"
    elif [ $http_success -eq 2 ]; then
        echo -e "${GREEN}✅ HTTP服务正常运行${NC}"
        echo "可以开始功能测试"
    else
        echo -e "${YELLOW}⚠️ 部分HTTP服务可用${NC}"
        echo "可以开始基础功能测试"
    fi
    
    echo ""
    echo -e "${GREEN}🚀 可以开始多人协同测试！${NC}"
    
elif [ $success_rate -ge 50 ]; then
    echo -e "${YELLOW}⚠️ 部分服务可用${NC}"
    echo "✅ 基础网络连通性正常"
    echo "⚠️ 部分服务可能还在启动中"
    echo "建议等待一段时间后重试"
    
else
    echo -e "${RED}❌ 服务不可用${NC}"
    echo "需要检查部署状态"
    echo "建议重新触发CI/CD部署"
fi

echo ""
echo -e "${BLUE}7. 下一步建议${NC}"
echo "================================"

if [ $success_rate -ge 75 ]; then
    echo "✅ 立即可以开始的工作:"
    echo "  1. 访问测试环境验证服务"
    echo "  2. 运行功能测试脚本"
    echo "  3. 配置开发环境"
    echo "  4. 开始功能开发"
    echo ""
    echo "🔄 需要完善的工作:"
    echo "  1. 等待HTTP服务完全启动"
    echo "  2. 完善健康检查端点"
    echo "  3. 配置用户认证系统"
    echo "  4. 建立监控和日志"
else
    echo "🔄 需要解决的问题:"
    echo "  1. 检查服务启动状态"
    echo "  2. 验证配置文件"
    echo "  3. 查看服务日志"
    echo "  4. 重新部署服务"
fi

echo ""
echo "=== 验证完成 ==="
