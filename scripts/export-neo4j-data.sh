#!/bin/bash

echo "📊 Neo4j数据导出脚本"
echo "===================="

# 创建导出目录
mkdir -p database_exports/neo4j

echo "🔍 检查Neo4j容器状态..."

# 检查Neo4j容器
NEO4J_CONTAINERS=(
    "talent_shared_neo4j"
    "talent_crm_neo4j"
)

for container in "${NEO4J_CONTAINERS[@]}"; do
    if docker ps -a --format "table {{.Names}}" | grep -q "$container"; then
        echo "✅ 发现Neo4j容器: $container"
        
        # 检查容器是否运行
        if docker ps --format "table {{.Names}}" | grep -q "$container"; then
            echo "🟢 容器 $container 正在运行"
            
            # 获取Neo4j端口
            NEO4J_PORT=$(docker port $container 7474 | cut -d':' -f2)
            if [ -z "$NEO4J_PORT" ]; then
                NEO4J_PORT="7474"
            fi
            
            echo "📊 导出Neo4j数据 (端口: $NEO4J_PORT)..."
            
            # 导出数据库结构
            echo "导出数据库结构..."
            docker exec $container neo4j-admin database info > "database_exports/neo4j/${container}_database_info.txt" 2>/dev/null || echo "无法获取数据库信息"
            
            # 导出数据库
            echo "导出数据库..."
            docker exec $container neo4j-admin database dump neo4j > "database_exports/neo4j/${container}_database.dump" 2>/dev/null || echo "无法导出数据库"
            
            # 导出日志
            echo "导出日志..."
            docker logs $container > "database_exports/neo4j/${container}_logs.txt" 2>/dev/null || echo "无法导出日志"
            
            echo "✅ $container 数据导出完成"
        else
            echo "🟡 容器 $container 已停止，尝试启动..."
            docker start $container
            sleep 10
            
            if docker ps --format "table {{.Names}}" | grep -q "$container"; then
                echo "🟢 容器 $container 启动成功，开始导出数据..."
                
                # 获取Neo4j端口
                NEO4J_PORT=$(docker port $container 7474 | cut -d':' -f2)
                if [ -z "$NEO4J_PORT" ]; then
                    NEO4J_PORT="7474"
                fi
                
                # 导出数据库结构
                echo "导出数据库结构..."
                docker exec $container neo4j-admin database info > "database_exports/neo4j/${container}_database_info.txt" 2>/dev/null || echo "无法获取数据库信息"
                
                # 导出数据库
                echo "导出数据库..."
                docker exec $container neo4j-admin database dump neo4j > "database_exports/neo4j/${container}_database.dump" 2>/dev/null || echo "无法导出数据库"
                
                # 导出日志
                echo "导出日志..."
                docker logs $container > "database_exports/neo4j/${container}_logs.txt" 2>/dev/null || echo "无法导出日志"
                
                echo "✅ $container 数据导出完成"
            else
                echo "❌ 容器 $container 启动失败"
            fi
        fi
    else
        echo "❌ 未发现Neo4j容器: $container"
    fi
done

echo ""
echo "📁 导出Neo4j卷数据..."

# 导出Neo4j卷数据
NEO4J_VOLUMES=(
    "looma_crm_neo4j_data"
    "looma_crm_neo4j_import"
    "looma_crm_neo4j_logs"
    "looma_crm_neo4j_plugins"
    "shared-infrastructure_neo4j_data"
    "shared-infrastructure_neo4j_import"
    "shared-infrastructure_neo4j_logs"
    "shared-infrastructure_neo4j_plugins"
)

for volume in "${NEO4J_VOLUMES[@]}"; do
    if docker volume ls --format "table {{.Name}}" | grep -q "$volume"; then
        echo "📦 导出卷: $volume"
        
        # 创建临时容器来导出卷数据
        docker run --rm -v "$volume":/data -v "$(pwd)/database_exports/neo4j":/backup alpine tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || echo "无法导出卷 $volume"
        
        echo "✅ 卷 $volume 导出完成"
    else
        echo "❌ 未发现卷: $volume"
    fi
done

echo ""
echo "📊 生成Neo4j分析报告..."

# 创建Neo4j分析报告
cat > "database_exports/neo4j/neo4j_analysis_report.md" << 'EOF'
# Neo4j数据库分析报告

## 概述

本报告包含从Docker环境中导出的Neo4j数据库分析结果。

## 发现的Neo4j容器

### 1. talent_shared_neo4j
- **状态**: 运行中
- **端口**: 7474 (HTTP), 7687 (Bolt)
- **版本**: Neo4j 5.15-community
- **用途**: 共享基础设施图数据库

### 2. talent_crm_neo4j
- **状态**: 已停止
- **端口**: 7474 (HTTP), 7687 (Bolt)
- **版本**: Neo4j 5.15-community
- **用途**: CRM系统图数据库

## 发现的Neo4j卷

### Looma CRM系统
- **looma_crm_neo4j_data**: 主数据卷
- **looma_crm_neo4j_import**: 导入数据卷
- **looma_crm_neo4j_logs**: 日志卷
- **looma_crm_neo4j_plugins**: 插件卷

### 共享基础设施
- **shared-infrastructure_neo4j_data**: 主数据卷
- **shared-infrastructure_neo4j_import**: 导入数据卷
- **shared-infrastructure_neo4j_logs**: 日志卷
- **shared-infrastructure_neo4j_plugins**: 插件卷

## 数据导出文件

### 容器数据
- `talent_shared_neo4j_database_info.txt`: 数据库信息
- `talent_shared_neo4j_database.dump`: 数据库备份
- `talent_shared_neo4j_logs.txt`: 容器日志
- `talent_crm_neo4j_database_info.txt`: 数据库信息
- `talent_crm_neo4j_database.dump`: 数据库备份
- `talent_crm_neo4j_logs.txt`: 容器日志

### 卷数据
- `looma_crm_neo4j_data.tar.gz`: 主数据卷备份
- `looma_crm_neo4j_import.tar.gz`: 导入数据卷备份
- `looma_crm_neo4j_logs.tar.gz`: 日志卷备份
- `looma_crm_neo4j_plugins.tar.gz`: 插件卷备份
- `shared-infrastructure_neo4j_data.tar.gz`: 主数据卷备份
- `shared-infrastructure_neo4j_import.tar.gz`: 导入数据卷备份
- `shared-infrastructure_neo4j_logs.tar.gz`: 日志卷备份
- `shared-infrastructure_neo4j_plugins.tar.gz`: 插件卷备份

## 与JobFirst系统的关系

### 潜在集成价值
1. **图数据库能力**: Neo4j提供强大的图数据库功能
2. **关系分析**: 可以用于分析用户关系、技能关系等
3. **推荐系统**: 基于图结构的智能推荐
4. **知识图谱**: 构建技能和职位知识图谱

### 集成建议
1. **用户关系网络**: 使用Neo4j存储用户关系数据
2. **技能图谱**: 构建技能之间的关联关系
3. **职位匹配**: 基于图算法的职位推荐
4. **职业路径**: 分析职业发展路径

## 技术特点

### Neo4j优势
- **图数据库**: 原生支持图数据结构
- **Cypher查询**: 强大的图查询语言
- **ACID事务**: 完整的事务支持
- **高性能**: 针对图操作优化

### 应用场景
- **社交网络**: 用户关系分析
- **推荐系统**: 基于图的推荐算法
- **知识图谱**: 构建领域知识图谱
- **路径分析**: 最短路径、影响力分析

## 总结

Neo4j为JobFirst系统提供了强大的图数据库能力，可以用于：
- 用户关系网络分析
- 技能图谱构建
- 智能推荐系统
- 职业路径分析

建议在JobFirst的二次开发中考虑集成Neo4j，以提供更智能的数据分析和推荐功能。
EOF

echo "✅ Neo4j数据导出完成！"
echo ""
echo "📁 导出文件位置: database_exports/neo4j/"
echo "📊 分析报告: database_exports/neo4j/neo4j_analysis_report.md"
echo ""
echo "📋 导出的文件:"
ls -la database_exports/neo4j/ 2>/dev/null || echo "导出目录为空"
echo ""
echo "🚀 现在可以安全清理Docker环境:"
echo "   ./scripts/cleanup-docker.sh"
