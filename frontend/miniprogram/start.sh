#!/bin/bash

# ADIRP数智招聘小程序快速启动脚本

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

# 检查微信开发者工具
check_wechat_devtools() {
    print_message $BLUE "检查微信开发者工具..."
    
    # macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/Applications/wechatwebdevtools.app" ]; then
            WECHAT_DEVTOOLS="/Applications/wechatwebdevtools.app/Contents/MacOS/cli"
        elif [ -d "/Applications/微信开发者工具.app" ]; then
            WECHAT_DEVTOOLS="/Applications/微信开发者工具.app/Contents/MacOS/cli"
        else
            print_message $YELLOW "未找到微信开发者工具，请手动打开项目"
            return 1
        fi
    # Windows
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        if [ -f "C:/Program Files (x86)/Tencent/微信开发者工具/cli.bat" ]; then
            WECHAT_DEVTOOLS="C:/Program Files (x86)/Tencent/微信开发者工具/cli.bat"
        else
            print_message $YELLOW "未找到微信开发者工具，请手动打开项目"
            return 1
        fi
    # Linux
    else
        print_message $YELLOW "Linux系统请手动打开微信开发者工具"
        return 1
    fi
    
    print_message $GREEN "找到微信开发者工具: $WECHAT_DEVTOOLS"
    return 0
}

# 打开微信开发者工具
open_wechat_devtools() {
    local project_path=$(pwd)
    
    print_message $BLUE "打开微信开发者工具..."
    
    if check_wechat_devtools; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            "$WECHAT_DEVTOOLS" -o "$project_path"
        else
            "$WECHAT_DEVTOOLS" -o "$project_path"
        fi
        print_message $GREEN "微信开发者工具已启动"
    else
        print_message $YELLOW "请手动打开微信开发者工具并导入项目: $project_path"
    fi
}

# 启动开发服务器
start_dev_server() {
    print_message $BLUE "启动开发服务器..."
    
    # 检查是否有package.json
    if [ -f "package.json" ]; then
        if grep -q "dev" package.json; then
            npm run dev
        elif grep -q "start" package.json; then
            npm start
        else
            print_message $YELLOW "未找到开发脚本，跳过服务器启动"
        fi
    else
        print_message $YELLOW "未找到package.json，跳过服务器启动"
    fi
}

# 检查项目配置
check_project_config() {
    print_message $BLUE "检查项目配置..."
    
    local errors=0
    
    # 检查必要文件
    if [ ! -f "app.js" ]; then
        print_message $RED "错误: 缺少 app.js"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "app.json" ]; then
        print_message $RED "错误: 缺少 app.json"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "app.wxss" ]; then
        print_message $RED "错误: 缺少 app.wxss"
        errors=$((errors + 1))
    fi
    
    if [ ! -f "project.config.json" ]; then
        print_message $RED "错误: 缺少 project.config.json"
        errors=$((errors + 1))
    fi
    
    # 检查pages目录
    if [ ! -d "pages" ]; then
        print_message $RED "错误: 缺少 pages 目录"
        errors=$((errors + 1))
    fi
    
    # 检查utils目录
    if [ ! -d "utils" ]; then
        print_message $RED "错误: 缺少 utils 目录"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        print_message $GREEN "项目配置检查通过"
        return 0
    else
        print_message $RED "项目配置检查失败，发现 $errors 个错误"
        return 1
    fi
}

# 显示项目信息
show_project_info() {
    print_message $BLUE "项目信息:"
    echo "  项目名称: ADIRP数智招聘小程序"
    echo "  项目路径: $(pwd)"
    echo "  当前模式: $(grep -o '"mode": "[^"]*"' app.js | cut -d'"' -f4)"
    echo "  页面数量: $(find pages -name "*.js" | wc -l)"
    echo "  工具函数: $(find utils -name "*.js" | wc -l)"
    
    # 显示功能特性
    echo "  功能特性:"
    if grep -q '"analytics": true' app.js; then
        echo "    ✓ 数据分析"
    fi
    if grep -q '"aiChat": true' app.js; then
        echo "    ✓ AI聊天"
    fi
    if grep -q '"enterprise": true' app.js; then
        echo "    ✓ 企业服务"
    fi
    if grep -q '"advancedSearch": true' app.js; then
        echo "    ✓ 高级搜索"
    fi
}

# 显示帮助信息
show_help() {
    echo "ADIRP数智招聘小程序快速启动脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -o, --open          打开微信开发者工具"
    echo "  -s, --server        启动开发服务器"
    echo "  -c, --check         检查项目配置"
    echo "  -i, --info          显示项目信息"
    echo "  -h, --help          显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -o              打开微信开发者工具"
    echo "  $0 -c -i           检查配置并显示信息"
    echo "  $0 -o -s           打开工具并启动服务器"
}

# 主函数
main() {
    local open_tools=false
    local start_server=false
    local check_config=false
    local show_info=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--open)
                open_tools=true
                shift
                ;;
            -s|--server)
                start_server=true
                shift
                ;;
            -c|--check)
                check_config=true
                shift
                ;;
            -i|--info)
                show_info=true
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
    
    # 如果没有参数，显示默认行为
    if [ "$open_tools" = false ] && [ "$start_server" = false ] && [ "$check_config" = false ] && [ "$show_info" = false ]; then
        print_message $GREEN "ADIRP数智招聘小程序启动脚本"
        echo ""
        print_message $BLUE "默认行为: 检查配置 -> 显示信息 -> 打开微信开发者工具"
        echo ""
        check_config=true
        show_info=true
        open_tools=true
    fi
    
    # 检查项目配置
    if [ "$check_config" = true ]; then
        if ! check_project_config; then
            print_message $RED "项目配置检查失败，请修复错误后重试"
            exit 1
        fi
    fi
    
    # 显示项目信息
    if [ "$show_info" = true ]; then
        show_project_info
        echo ""
    fi
    
    # 启动开发服务器
    if [ "$start_server" = true ]; then
        start_dev_server &
    fi
    
    # 打开微信开发者工具
    if [ "$open_tools" = true ]; then
        open_wechat_devtools
    fi
    
    print_message $GREEN "启动完成！"
}

# 运行主函数
main "$@"
