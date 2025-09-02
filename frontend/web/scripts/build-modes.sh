#!/bin/bash

# 多模式构建脚本
# 用法: ./scripts/build-modes.sh [basic|plus|pro|all]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
if [ $# -eq 0 ]; then
    log_error "请指定构建模式: basic, plus, pro, 或 all"
    echo "用法: $0 [basic|plus|pro|all]"
    exit 1
fi

MODE=$1
BUILD_DIR="dist"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 验证模式
valid_modes=("basic" "plus" "pro" "all")
if [[ ! " ${valid_modes[@]} " =~ " ${MODE} " ]]; then
    log_error "无效的模式: $MODE"
    echo "有效模式: ${valid_modes[*]}"
    exit 1
fi

# 构建单个模式
build_mode() {
    local mode=$1
    local output_dir="${BUILD_DIR}/${mode}_${TIMESTAMP}"
    
    log_info "开始构建 $mode 模式..."
    
    # 设置环境变量
    export NEXT_PUBLIC_MODE=$mode
    
    # 清理之前的构建
    if [ -d ".next" ]; then
        log_info "清理之前的构建..."
        rm -rf .next
    fi
    
    # 安装依赖（如果需要）
    if [ ! -d "node_modules" ]; then
        log_info "安装依赖..."
        npm install
    fi
    
    # 构建项目
    log_info "构建 Next.js 项目..."
    npm run build
    
    # 创建输出目录
    mkdir -p "$output_dir"
    
    # 复制构建文件
    log_info "复制构建文件到 $output_dir..."
    cp -r .next "$output_dir/"
    cp -r public "$output_dir/" 2>/dev/null || true
    cp package.json "$output_dir/"
    cp next.config.js "$output_dir/"
    
    # 创建启动脚本
    cat > "$output_dir/start.sh" << EOF
#!/bin/bash
export NEXT_PUBLIC_MODE=$mode
npm start
EOF
    chmod +x "$output_dir/start.sh"
    
    # 创建 Dockerfile
    cat > "$output_dir/Dockerfile" << EOF
FROM node:18-alpine

WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制应用文件
COPY . .

# 设置环境变量
ENV NEXT_PUBLIC_MODE=$mode
ENV NODE_ENV=production

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["npm", "start"]
EOF
    
    # 创建 docker-compose.yml
    cat > "$output_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  jobfirst-$mode:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_MODE=$mode
      - NODE_ENV=production
    restart: unless-stopped
EOF
    
    # 创建 README
    cat > "$output_dir/README.md" << EOF
# JobFirst $mode 模式

## 部署说明

### 使用 Docker
\`\`\`bash
docker-compose up -d
\`\`\`

### 直接运行
\`\`\`bash
npm install
./start.sh
\`\`\`

## 模式特性
$(node -e "
const { MODES } = require('../config/modes');
const mode = MODES['$mode'];
console.log('- ' + mode.features.join('\n- '));
")

## 环境变量
- NEXT_PUBLIC_MODE: $mode
- NODE_ENV: production

## 访问地址
http://localhost:3000
EOF
    
    log_success "$mode 模式构建完成: $output_dir"
    
    # 显示构建信息
    echo ""
    log_info "构建信息:"
    echo "  模式: $mode"
    echo "  输出目录: $output_dir"
    echo "  构建时间: $TIMESTAMP"
    echo "  文件大小: $(du -sh "$output_dir" | cut -f1)"
    echo ""
}

# 主构建逻辑
main() {
    log_info "开始多模式构建..."
    log_info "构建模式: $MODE"
    log_info "时间戳: $TIMESTAMP"
    echo ""
    
    # 创建构建目录
    mkdir -p "$BUILD_DIR"
    
    case $MODE in
        "all")
            log_info "构建所有模式..."
            for mode in "basic" "plus" "pro"; do
                build_mode "$mode"
                echo ""
            done
            log_success "所有模式构建完成!"
            ;;
        *)
            build_mode "$MODE"
            ;;
    esac
    
    # 创建部署脚本
    if [ "$MODE" = "all" ]; then
        cat > "${BUILD_DIR}/deploy-all.sh" << 'EOF'
#!/bin/bash

# 部署所有模式
echo "部署所有 JobFirst 模式..."

# 基础版
echo "启动基础版..."
cd basic_*
docker-compose up -d

# 增强版
echo "启动增强版..."
cd ../plus_*
docker-compose up -d

# 专业版
echo "启动专业版..."
cd ../pro_*
docker-compose up -d

echo "所有模式部署完成!"
echo "基础版: http://localhost:3000"
echo "增强版: http://localhost:3001"
echo "专业版: http://localhost:3002"
EOF
        chmod +x "${BUILD_DIR}/deploy-all.sh"
    fi
    
    log_success "构建完成!"
    echo ""
    log_info "输出目录: $BUILD_DIR"
    
    if [ "$MODE" = "all" ]; then
        echo "  基础版: ${BUILD_DIR}/basic_${TIMESTAMP}"
        echo "  增强版: ${BUILD_DIR}/plus_${TIMESTAMP}"
        echo "  专业版: ${BUILD_DIR}/pro_${TIMESTAMP}"
        echo ""
        echo "使用以下命令部署所有模式:"
        echo "  cd ${BUILD_DIR} && ./deploy-all.sh"
    else
        echo "  ${BUILD_DIR}/${MODE}_${TIMESTAMP}"
        echo ""
        echo "使用以下命令部署:"
        echo "  cd ${BUILD_DIR}/${MODE}_${TIMESTAMP} && docker-compose up -d"
    fi
}

# 运行主函数
main
