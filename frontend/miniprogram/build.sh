#!/bin/bash

# ADIRP数智招聘小程序构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查依赖
check_dependencies() {
    print_message $BLUE "检查依赖..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        print_message $RED "错误: 未找到Node.js，请先安装Node.js"
        exit 1
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        print_message $RED "错误: 未找到npm，请先安装npm"
        exit 1
    fi
    
    print_message $GREEN "依赖检查完成"
}

# 清理构建目录
clean_build() {
    print_message $BLUE "清理构建目录..."
    
    if [ -d "dist" ]; then
        rm -rf dist
    fi
    
    if [ -d "node_modules" ]; then
        rm -rf node_modules
    fi
    
    print_message $GREEN "清理完成"
}

# 安装依赖
install_dependencies() {
    print_message $BLUE "安装依赖..."
    
    if [ -f "package.json" ]; then
        npm install
    else
        print_message $YELLOW "未找到package.json，跳过依赖安装"
    fi
    
    print_message $GREEN "依赖安装完成"
}

# 代码检查
lint_code() {
    print_message $BLUE "代码检查..."
    
    if [ -f ".eslintrc.js" ]; then
        npx eslint . --ext .js,.wxml,.wxss
        print_message $GREEN "代码检查完成"
    else
        print_message $YELLOW "未找到ESLint配置，跳过代码检查"
    fi
}

# 构建项目
build_project() {
    print_message $BLUE "构建项目..."
    
    # 创建构建目录
    mkdir -p dist
    
    # 复制文件
    cp -r app.* dist/
    cp -r pages dist/
    cp -r utils dist/
    cp -r components dist/ 2>/dev/null || true
    cp -r images dist/ 2>/dev/null || true
    cp -r styles dist/ 2>/dev/null || true
    cp project.config.json dist/
    cp README.md dist/
    
    # 处理不同模式的配置
    process_mode_config
    
    print_message $GREEN "项目构建完成"
}

# 处理模式配置
process_mode_config() {
    local mode=${BUILD_MODE:-"basic"}
    
    print_message $BLUE "处理模式配置: $mode"
    
    # 根据模式修改配置
    case $mode in
        "basic")
            # 基础版配置
            sed -i 's/"mode": ".*"/"mode": "basic"/' dist/app.js
            ;;
        "plus")
            # 增强版配置
            sed -i 's/"mode": ".*"/"mode": "plus"/' dist/app.js
            ;;
        "pro")
            # 专业版配置
            sed -i 's/"mode": ".*"/"mode": "pro"/' dist/app.js
            ;;
        *)
            print_message $YELLOW "未知模式: $mode，使用基础版"
            sed -i 's/"mode": ".*"/"mode": "basic"/' dist/app.js
            ;;
    esac
}

# 压缩资源
compress_assets() {
    print_message $BLUE "压缩资源..."
    
    # 压缩图片（如果安装了imagemin）
    if command -v imagemin &> /dev/null; then
        find dist/images -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" | xargs imagemin --out-dir=dist/images
    else
        print_message $YELLOW "未找到imagemin，跳过图片压缩"
    fi
    
    print_message $GREEN "资源压缩完成"
}

# 生成版本信息
generate_version() {
    print_message $BLUE "生成版本信息..."
    
    local version=$(date +"%Y%m%d_%H%M%S")
    local commit_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    cat > dist/version.json << EOF
{
    "version": "$version",
    "commit": "$commit_hash",
    "buildTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "mode": "${BUILD_MODE:-basic}"
}
EOF
    
    print_message $GREEN "版本信息生成完成: $version"
}

# 运行测试
run_tests() {
    print_message $BLUE "运行测试..."
    
    if [ -f "package.json" ] && grep -q "test" package.json; then
        npm test
        print_message $GREEN "测试完成"
    else
        print_message $YELLOW "未找到测试配置，跳过测试"
    fi
}

# 部署准备
prepare_deploy() {
    print_message $BLUE "准备部署..."
    
    # 创建部署包
    local deploy_name="adirp-miniprogram-${BUILD_MODE:-basic}-$(date +%Y%m%d_%H%M%S).zip"
    
    cd dist
    zip -r "../$deploy_name" .
    cd ..
    
    print_message $GREEN "部署包创建完成: $deploy_name"
}

# 显示帮助信息
show_help() {
    echo "ADIRP数智招聘小程序构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -m, --mode MODE     构建模式 (basic|plus|pro) [默认: basic]"
    echo "  -c, --clean         清理构建目录"
    echo "  -t, --test          运行测试"
    echo "  -d, --deploy        准备部署包"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "环境变量:"
    echo "  BUILD_MODE          构建模式"
    echo "  NODE_ENV            环境变量 (development|production)"
    echo ""
    echo "示例:"
    echo "  $0 -m pro -t -d    构建专业版，运行测试，准备部署"
    echo "  $0 --mode plus     构建增强版"
}

# 主函数
main() {
    local clean=false
    local test=false
    local deploy=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                BUILD_MODE="$2"
                shift 2
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -t|--test)
                test=true
                shift
                ;;
            -d|--deploy)
                deploy=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_message $RED "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_message $GREEN "开始构建 ADIRP数智招聘小程序"
    print_message $BLUE "构建模式: ${BUILD_MODE:-basic}"
    print_message $BLUE "环境: ${NODE_ENV:-development}"
    
    # 检查依赖
    check_dependencies
    
    # 清理
    if [ "$clean" = true ]; then
        clean_build
    fi
    
    # 安装依赖
    install_dependencies
    
    # 代码检查
    lint_code
    
    # 运行测试
    if [ "$test" = true ]; then
        run_tests
    fi
    
    # 构建项目
    build_project
    
    # 压缩资源
    compress_assets
    
    # 生成版本信息
    generate_version
    
    # 准备部署
    if [ "$deploy" = true ]; then
        prepare_deploy
    fi
    
    print_message $GREEN "构建完成！"
    print_message $BLUE "构建目录: dist/"
    
    if [ "$deploy" = true ]; then
        print_message $BLUE "部署包已创建"
    fi
}

# 运行主函数
main "$@"
