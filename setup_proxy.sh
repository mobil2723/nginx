#!/bin/bash

# Nginx反向代理配置辅助脚本
# 作者: mobil2723

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 默认安装路径
DEFAULT_INSTALL_DIR="$HOME/nginx_install"
NGINX_CONF=""
PORT=43838

# 显示帮助信息
show_help() {
    echo "Nginx反向代理配置辅助脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --directory <目录>   指定Nginx安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  -h, --help               显示帮助信息"
    echo "  -p, --port <端口>        指定监听端口 (默认: 43838)"
    echo ""
    echo "示例:"
    echo "  $0                       使用默认设置配置反向代理"
    echo "  $0 -p 8080               使用8080端口配置反向代理"
    echo "  $0 -d /path/to/nginx     指定Nginx安装目录"
}

# 处理命令行参数
INSTALL_DIR="$DEFAULT_INSTALL_DIR"

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
        -p|--port)
            PORT="$2"
            shift
            shift
            ;;
        *)
            echo -e "${RED}错误: 未知选项 '$key'${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查Nginx安装
NGINX_INSTALL_DIR="$INSTALL_DIR/nginx"
NGINX_CONF="$NGINX_INSTALL_DIR/conf/nginx.conf"

if [ ! -d "$NGINX_INSTALL_DIR" ] || [ ! -f "$NGINX_INSTALL_DIR/sbin/nginx" ]; then
    echo -e "${RED}错误: 未找到Nginx安装，请先安装Nginx${NC}"
    echo "安装命令: bash install_nginx.sh"
    exit 1
fi

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      Nginx反向代理配置向导                        ${NC}"
echo -e "${BLUE}====================================================${NC}"

echo -e "${YELLOW}本向导将帮助您快速配置Nginx反向代理${NC}"
echo ""

# 询问代理路径和目标
setup_proxy() {
    echo -e "${BLUE}开始配置反向代理...${NC}"
    
    # 备份原始配置文件
    cp "$NGINX_CONF" "${NGINX_CONF}.backup"
    
    # 创建新的配置文件
    cat > "$NGINX_CONF" << EOF
# 由setup_proxy.sh生成的配置文件
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    # 配置反向代理服务器
    server {
        # 同时监听IPv4和IPv6
        listen       0.0.0.0:$PORT;
        listen       [::]:$PORT;
        server_name  localhost;

EOF
    
    # 获取用户输入以添加代理配置
    CONTINUE="y"
    COUNT=0
    
    while [[ "$CONTINUE" == "y" ]]; do
        COUNT=$((COUNT+1))
        echo -e "${YELLOW}配置第 $COUNT 个反向代理:${NC}"
        
        read -p "请输入本地访问路径 (例如: /api/ 或 /site1/): " LOCAL_PATH
        # 确保路径以/开头和结尾
        [[ "$LOCAL_PATH" != /* ]] && LOCAL_PATH="/$LOCAL_PATH"
        [[ "$LOCAL_PATH" != */ ]] && LOCAL_PATH="$LOCAL_PATH/"
        
        read -p "请输入目标服务器URL (例如: http://example.com/ 或 http://192.168.1.100:8080/): " TARGET_URL
        # 确保URL以/结尾
        [[ "$TARGET_URL" != */ ]] && TARGET_URL="$TARGET_URL/"
        
        # 添加代理配置
        cat >> "$NGINX_CONF" << EOF
        # 代理配置 $COUNT
        location $LOCAL_PATH {
            proxy_pass $TARGET_URL;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

EOF
        
        echo -e "${GREEN}已添加反向代理：${NC}"
        echo -e "  访问地址：http://您的服务器:$PORT$LOCAL_PATH"
        echo -e "  代理到：$TARGET_URL"
        echo ""
        
        read -p "是否继续添加另一个反向代理？ [y/N]: " CONTINUE
        CONTINUE=${CONTINUE:-n}
        echo ""
    done
    
    # 添加默认路由和结束配置
    cat >> "$NGINX_CONF" << EOF
        # 默认页面
        location / {
            root   html;
            index  index.html index.htm;
        }

        # 错误页面
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
EOF
    
    echo -e "${GREEN}配置文件已生成: $NGINX_CONF${NC}"
}

# 执行配置
setup_proxy

# 重新加载Nginx配置
echo -e "${BLUE}正在重新加载Nginx配置...${NC}"
"$INSTALL_DIR/reload_nginx.sh"

echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}      反向代理配置完成！                          ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Nginx已重新加载，您的反向代理已经生效！"
echo -e ""
echo -e "您可以使用以下命令查看可访问的地址:"
echo -e "${YELLOW}$INSTALL_DIR/start_nginx.sh${NC}"
echo -e ""
echo -e "如需修改配置，可以:"
echo -e "1. 再次运行此脚本: ${YELLOW}bash setup_proxy.sh${NC}"
echo -e "2. 手动编辑配置文件: ${YELLOW}vi $NGINX_CONF${NC}"
echo -e "3. 重新加载配置: ${YELLOW}$INSTALL_DIR/reload_nginx.sh${NC}"
echo -e "${GREEN}====================================================${NC}" 