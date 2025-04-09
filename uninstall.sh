#!/bin/bash

# Nginx卸载脚本
# 作者: mobil2723

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 默认安装路径
DEFAULT_INSTALL_DIR="$HOME/nginx_install"

# 显示帮助信息
show_help() {
    echo "Nginx卸载脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --directory <目录>   指定Nginx安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  -h, --help               显示帮助信息"
    echo "  -f, --force              强制卸载，不进行确认"
    echo ""
    echo "示例:"
    echo "  $0                       使用默认目录卸载Nginx"
    echo "  $0 -d /path/to/nginx     卸载指定目录中的Nginx"
    echo "  $0 --force               强制卸载，不进行确认"
}

# 处理命令行参数
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
FORCE_UNINSTALL=0

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--directory)
            INSTALL_DIR="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--force)
            FORCE_UNINSTALL=1
            shift
            ;;
        *)
            echo -e "${RED}错误: 未知选项 '$key'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查Nginx安装目录是否存在
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}错误: 安装目录 '$INSTALL_DIR' 不存在${NC}"
    echo "请使用 -d 选项指定正确的Nginx安装目录"
    exit 1
fi

# 检查是否为Nginx安装目录
if [ ! -d "$INSTALL_DIR/nginx" ] || [ ! -f "$INSTALL_DIR/nginx/sbin/nginx" ]; then
    echo -e "${YELLOW}警告: 目录 '$INSTALL_DIR' 似乎不是Nginx安装目录${NC}"
    if [ $FORCE_UNINSTALL -eq 0 ]; then
        read -p "是否继续卸载? [y/N] " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "卸载已取消"
            exit 0
        fi
    fi
fi

# 停止Nginx（如果正在运行）
if [ -f "$INSTALL_DIR/stop_nginx.sh" ]; then
    echo -e "${BLUE}正在停止Nginx...${NC}"
    bash "$INSTALL_DIR/stop_nginx.sh" > /dev/null 2>&1
elif [ -f "$INSTALL_DIR/nginx/sbin/nginx" ]; then
    echo -e "${BLUE}正在停止Nginx...${NC}"
    "$INSTALL_DIR/nginx/sbin/nginx" -s stop > /dev/null 2>&1
fi

# 确认卸载
if [ $FORCE_UNINSTALL -eq 0 ]; then
    echo -e "${YELLOW}警告: 将删除以下目录及其所有内容:${NC}"
    echo -e "  - ${BLUE}$INSTALL_DIR${NC}"
    read -p "是否确认卸载? [y/N] " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "卸载已取消"
        exit 0
    fi
fi

# 执行卸载
echo -e "${BLUE}正在卸载Nginx...${NC}"
rm -rf "$INSTALL_DIR"

# 检查卸载结果
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nginx已成功卸载！${NC}"
    
    # 检查是否有运行中的Nginx进程
    nginx_running=$(ps aux | grep nginx | grep -v grep | wc -l)
    if [ $nginx_running -gt 0 ]; then
        echo -e "${YELLOW}警告: 仍有Nginx进程在运行，建议手动终止:${NC}"
        ps aux | grep nginx | grep -v grep
        echo -e "使用以下命令终止所有Nginx进程:"
        echo -e "${BLUE}  pkill nginx${NC}"
    fi
else
    echo -e "${RED}卸载失败，请检查权限或手动删除目录:${NC}"
    echo -e "${BLUE}  rm -rf $INSTALL_DIR${NC}"
fi

echo -e "${BLUE}感谢使用Nginx一键安装卸载工具！${NC}" 