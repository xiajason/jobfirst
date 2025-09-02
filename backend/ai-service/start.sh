#!/bin/bash

# JobFirst AI Service 启动脚本
# 基于Python Sanic的高性能异步AI服务

set -e

echo "🚀 启动JobFirst AI服务..."

# 检查Python版本
python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
required_version="3.11"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "❌ 需要Python 3.11或更高版本，当前版本: $python_version"
    exit 1
fi

echo "✅ Python版本检查通过: $python_version"

# 检查虚拟环境
if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python3 -m venv venv
fi

# 激活虚拟环境
echo "🔧 激活虚拟环境..."
source venv/bin/activate

# 安装依赖
echo "📚 安装Python依赖..."
pip install --upgrade pip
pip install -r requirements.txt

# 检查环境变量
echo "🔍 检查环境变量..."

required_vars=("OPENAI_API_KEY" "DB_PASSWORD")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "⚠️  缺少必要的环境变量: ${missing_vars[*]}"
    echo "请设置以下环境变量:"
    for var in "${missing_vars[@]}"; do
        case $var in
            "OPENAI_API_KEY")
                echo "  export OPENAI_API_KEY='your-openai-api-key'"
                ;;
            "DB_PASSWORD")
                echo "  export DB_PASSWORD='your-database-password'"
                ;;
        esac
    done
    echo ""
    echo "或者创建 .env 文件并设置这些变量"
    exit 1
fi

echo "✅ 环境变量检查通过"

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p logs uploads

# 检查数据库连接
echo "🔗 检查数据库连接..."
python3 -c "
import asyncio
import asyncpg
import os

async def check_db():
    try:
        conn = await asyncpg.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '5432')),
            user=os.getenv('DB_USER', 'postgres'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME', 'jobfirst')
        )
        await conn.execute('SELECT 1')
        await conn.close()
        print('✅ 数据库连接成功')
    except Exception as e:
        print(f'❌ 数据库连接失败: {e}')
        exit(1)

asyncio.run(check_db())
"

if [ $? -ne 0 ]; then
    echo "❌ 数据库连接检查失败，请检查数据库配置"
    exit 1
fi

# 启动服务
echo "🎯 启动AI服务..."
echo "📍 服务地址: http://localhost:8001"
echo "📍 健康检查: http://localhost:8001/health"
echo "📍 监控指标: http://localhost:8001/metrics"
echo ""

# 使用uvicorn启动（如果安装了）或者直接使用python
if command -v uvicorn &> /dev/null; then
    echo "🚀 使用uvicorn启动服务..."
    uvicorn main:app --host 0.0.0.0 --port 8001 --workers 4 --reload
else
    echo "🚀 使用Python直接启动服务..."
    python3 main.py
fi
