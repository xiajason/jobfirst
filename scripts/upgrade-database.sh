#!/bin/bash

# ADIRP数智招聘系统 - 数据库升级脚本
# 版本: v2.0
# 日期: 2024-08-30

set -e  # 遇到错误立即退出

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

# 配置变量
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"3306"}
DB_USER=${DB_USER:-"root"}
DB_PASS=${DB_PASS:-""}
DB_NAME=${DB_NAME:-"jobfirst"}
BACKUP_DIR="./database_backups"
UPGRADE_SCRIPT="../database_upgrade.sql"

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL客户端未安装，请先安装MySQL客户端"
        exit 1
    fi
    
    if ! command -v mysqldump &> /dev/null; then
        log_error "mysqldump未安装，请先安装MySQL客户端"
        exit 1
    fi
    
    log_success "依赖检查完成"
}

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    mkdir -p "$BACKUP_DIR"
    log_success "备份目录创建完成: $BACKUP_DIR"
}

# 备份当前数据库
backup_database() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/jobfirst_backup_$timestamp.sql"
    
    log_info "备份当前数据库..."
    
    if [ -z "$DB_PASS" ]; then
        mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" > "$backup_file"
    else
        mysqldump -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$backup_file"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库备份完成: $backup_file"
        echo "$backup_file" > "$BACKUP_DIR/latest_backup.txt"
    else
        log_error "数据库备份失败"
        exit 1
    fi
}

# 测试数据库连接
test_connection() {
    log_info "测试数据库连接..."
    
    if [ -z "$DB_PASS" ]; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "SELECT 1;" > /dev/null 2>&1
    else
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库连接测试成功"
    else
        log_error "数据库连接失败，请检查配置"
        exit 1
    fi
}

# 检查数据库是否存在
check_database() {
    log_info "检查数据库是否存在..."
    
    if [ -z "$DB_PASS" ]; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "USE $DB_NAME;" > /dev/null 2>&1
    else
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库 $DB_NAME 存在"
    else
        log_warning "数据库 $DB_NAME 不存在，将创建新数据库"
        create_database
    fi
}

# 创建数据库
create_database() {
    log_info "创建数据库 $DB_NAME..."
    
    if [ -z "$DB_PASS" ]; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    else
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库创建成功"
    else
        log_error "数据库创建失败"
        exit 1
    fi
}

# 执行升级脚本
execute_upgrade() {
    log_info "执行数据库升级脚本..."
    
    if [ ! -f "$UPGRADE_SCRIPT" ]; then
        log_error "升级脚本不存在: $UPGRADE_SCRIPT"
        exit 1
    fi
    
    if [ -z "$DB_PASS" ]; then
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" < "$UPGRADE_SCRIPT"
    else
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$UPGRADE_SCRIPT"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "数据库升级完成"
    else
        log_error "数据库升级失败"
        log_warning "请检查备份文件: $(cat $BACKUP_DIR/latest_backup.txt 2>/dev/null || echo '无')"
        exit 1
    fi
}

# 验证升级结果
verify_upgrade() {
    log_info "验证升级结果..."
    
    local verification_queries=(
        "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = '$DB_NAME';"
        "SELECT COUNT(*) as user_count FROM users;"
        "SELECT COUNT(*) as company_count FROM companies;"
        "SELECT COUNT(*) as job_count FROM jobs;"
        "SELECT COUNT(*) as category_count FROM job_categories;"
        "SELECT version FROM database_version ORDER BY applied_at DESC LIMIT 1;"
    )
    
    for query in "${verification_queries[@]}"; do
        if [ -z "$DB_PASS" ]; then
            result=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" -s -e "$query" 2>/dev/null)
        else
            result=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -s -e "$query" 2>/dev/null)
        fi
        
        if [ $? -eq 0 ]; then
            log_success "查询成功: $result"
        else
            log_warning "查询失败: $query"
        fi
    done
}

# 显示升级摘要
show_summary() {
    log_info "升级摘要:"
    echo "=================================="
    echo "数据库主机: $DB_HOST:$DB_PORT"
    echo "数据库名称: $DB_NAME"
    echo "备份文件: $(cat $BACKUP_DIR/latest_backup.txt 2>/dev/null || echo '无')"
    echo "升级脚本: $UPGRADE_SCRIPT"
    echo "=================================="
}

# 主函数
main() {
    echo "=================================="
    echo "ADIRP数智招聘系统 - 数据库升级"
    echo "版本: v2.0"
    echo "日期: $(date)"
    echo "=================================="
    
    # 检查参数
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help, -h     显示帮助信息"
        echo "  --no-backup    跳过备份步骤"
        echo "  --force        强制升级（跳过确认）"
        echo ""
        echo "环境变量:"
        echo "  DB_HOST        数据库主机 (默认: localhost)"
        echo "  DB_PORT        数据库端口 (默认: 3306)"
        echo "  DB_USER        数据库用户 (默认: root)"
        echo "  DB_PASS        数据库密码 (默认: 空)"
        echo "  DB_NAME        数据库名称 (默认: jobfirst)"
        exit 0
    fi
    
    # 检查是否跳过备份
    SKIP_BACKUP=false
    FORCE=false
    
    for arg in "$@"; do
        case $arg in
            --no-backup)
                SKIP_BACKUP=true
                ;;
            --force)
                FORCE=true
                ;;
        esac
    done
    
    # 确认升级
    if [ "$FORCE" != "true" ]; then
        echo ""
        log_warning "此操作将升级数据库结构，可能会影响现有数据"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "升级已取消"
            exit 0
        fi
    fi
    
    # 执行升级步骤
    check_dependencies
    create_backup_dir
    
    if [ "$SKIP_BACKUP" != "true" ]; then
        backup_database
    else
        log_warning "跳过备份步骤"
    fi
    
    test_connection
    check_database
    execute_upgrade
    verify_upgrade
    show_summary
    
    log_success "数据库升级完成！"
    echo ""
    log_info "下一步操作:"
    echo "1. 重启后端服务以应用新的数据库结构"
    echo "2. 测试小程序前端功能"
    echo "3. 验证API接口正常工作"
    echo "4. 检查数据完整性"
}

# 执行主函数
main "$@"
