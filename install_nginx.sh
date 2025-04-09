#!/bin/bash

# 无root权限Nginx一键安装脚本
# 作者: mobil2723

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 组件版本
PCRE_VERSION="8.45"
ZLIB_VERSION="1.3.1"
NGINX_VERSION="1.24.0"

# 创建日志文件
LOG_FILE="nginx_install_$(date +%Y%m%d%H%M%S).log"
touch "$LOG_FILE"

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# 检测系统
check_system() {
    log "正在检测系统环境..."
    
    # 检查是否已安装必要的工具
    for cmd in wget tar gcc make; do
        if ! command -v $cmd &> /dev/null; then
            error "未找到 $cmd 命令，请确保已安装必要的编译工具"
            exit 1
        fi
    done
    
    success "系统环境检测完成"
}

# 设置安装路径
setup_paths() {
    # 如果提供了参数，使用参数作为安装路径，否则使用默认路径
    if [ -n "$1" ]; then
        INSTALL_DIR="$1"
    else
        INSTALL_DIR="$HOME/nginx_install"
    fi
    
    # 创建各组件安装目录
    PCRE_INSTALL_DIR="$INSTALL_DIR/pcre"
    ZLIB_INSTALL_DIR="$INSTALL_DIR/zlib"
    NGINX_INSTALL_DIR="$INSTALL_DIR/nginx"
    
    # 创建下载和构建临时目录
    BUILD_DIR="$INSTALL_DIR/build"
    
    log "安装路径设置如下:"
    log "  - 安装根目录: $INSTALL_DIR"
    log "  - PCRE 安装目录: $PCRE_INSTALL_DIR"
    log "  - zlib 安装目录: $ZLIB_INSTALL_DIR"
    log "  - Nginx 安装目录: $NGINX_INSTALL_DIR"
    log "  - 构建临时目录: $BUILD_DIR"
    
    # 创建必要的目录
    mkdir -p "$INSTALL_DIR" "$PCRE_INSTALL_DIR" "$ZLIB_INSTALL_DIR" "$NGINX_INSTALL_DIR" "$BUILD_DIR"
    
    if [ $? -ne 0 ]; then
        error "创建目录失败，请检查权限"
        exit 1
    fi
    
    success "目录创建完成"
}

# 下载并安装 PCRE
install_pcre() {
    log "开始安装 PCRE v${PCRE_VERSION}..."
    cd "$BUILD_DIR"
    
    # 下载 PCRE
    log "正在下载 PCRE..."
    wget -q --show-progress "https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz/download" -O "pcre-${PCRE_VERSION}.tar.gz"
    
    if [ $? -ne 0 ]; then
        error "PCRE 下载失败"
        return 1
    fi
    
    # 解压
    log "正在解压 PCRE..."
    tar -zxf "pcre-${PCRE_VERSION}.tar.gz"
    cd "pcre-${PCRE_VERSION}"
    
    # 配置、编译和安装
    log "正在配置 PCRE..."
    ./configure --prefix="$PCRE_INSTALL_DIR" --disable-shared --enable-static --disable-cpp --with-pic >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "PCRE 配置失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在编译 PCRE..."
    make >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "PCRE 编译失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在安装 PCRE..."
    make install >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "PCRE 安装失败，详情请查看日志文件"
        return 1
    fi
    
    # 验证安装
    if [ -f "$PCRE_INSTALL_DIR/bin/pcre-config" ]; then
        PCRE_INSTALLED_VERSION=$("$PCRE_INSTALL_DIR/bin/pcre-config" --version)
        success "PCRE v${PCRE_INSTALLED_VERSION} 安装成功！"
        return 0
    else
        error "PCRE 安装验证失败"
        return 1
    fi
}

# 下载并安装 zlib
install_zlib() {
    log "开始安装 zlib v${ZLIB_VERSION}..."
    cd "$BUILD_DIR"
    
    # 下载 zlib
    log "正在下载 zlib..."
    wget -q --show-progress "https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
    
    if [ $? -ne 0 ]; then
        error "zlib 下载失败"
        return 1
    fi
    
    # 解压
    log "正在解压 zlib..."
    tar -zxf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"
    
    # 配置、编译和安装
    log "正在配置 zlib..."
    ./configure --prefix="$ZLIB_INSTALL_DIR" >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "zlib 配置失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在编译 zlib..."
    make >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "zlib 编译失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在安装 zlib..."
    make install >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "zlib 安装失败，详情请查看日志文件"
        return 1
    fi
    
    # 验证安装
    if [ -d "$ZLIB_INSTALL_DIR/lib" ]; then
        success "zlib v${ZLIB_VERSION} 安装成功！"
        return 0
    else
        error "zlib 安装验证失败"
        return 1
    fi
}

# 下载并安装 OpenSSL (用于HTTPS支持)
install_openssl() {
    log "开始安装 OpenSSL..."
    cd "$BUILD_DIR"
    
    # 下载 OpenSSL
    OPENSSL_VERSION="1.1.1q"
    log "正在下载 OpenSSL v${OPENSSL_VERSION}..."
    wget -q --show-progress "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    
    if [ $? -ne 0 ]; then
        error "OpenSSL 下载失败"
        return 1
    fi
    
    # 解压
    log "正在解压 OpenSSL..."
    tar -zxf "openssl-${OPENSSL_VERSION}.tar.gz"
    cd "openssl-${OPENSSL_VERSION}"
    
    # 配置、编译和安装
    log "正在配置 OpenSSL..."
    ./config --prefix="$INSTALL_DIR/openssl" --openssldir="$INSTALL_DIR/openssl" no-shared >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "OpenSSL 配置失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在编译 OpenSSL..."
    make >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "OpenSSL 编译失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在安装 OpenSSL..."
    make install_sw >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "OpenSSL 安装失败，详情请查看日志文件"
        return 1
    fi
    
    # 验证安装
    if [ -f "$INSTALL_DIR/openssl/bin/openssl" ]; then
        OPENSSL_INSTALLED_VERSION=$("$INSTALL_DIR/openssl/bin/openssl" version)
        success "OpenSSL ${OPENSSL_INSTALLED_VERSION} 安装成功！"
        return 0
    else
        error "OpenSSL 安装验证失败"
        return 1
    fi
}

# 下载并安装 Nginx
install_nginx() {
    log "开始安装 Nginx v${NGINX_VERSION}..."
    cd "$BUILD_DIR"
    
    # 下载 Nginx
    log "正在下载 Nginx..."
    wget -q --show-progress "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    
    if [ $? -ne 0 ]; then
        error "Nginx 下载失败"
        return 1
    fi
    
    # 解压
    log "正在解压 Nginx..."
    tar -zxf "nginx-${NGINX_VERSION}.tar.gz"
    cd "nginx-${NGINX_VERSION}"
    
    # 配置、编译和安装 - 添加SSL支持
    log "正在配置 Nginx..."
    ./configure \
        --prefix="$NGINX_INSTALL_DIR" \
        --with-zlib="$BUILD_DIR/zlib-${ZLIB_VERSION}" \
        --without-pcre \
        --with-openssl="$BUILD_DIR/openssl-${OPENSSL_VERSION}" \
        --with-http_ssl_module \
        --without-http_rewrite_module 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -ne 0 ]; then
        error "Nginx 配置失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在编译 Nginx..."
    make >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "Nginx 编译失败，详情请查看日志文件"
        return 1
    fi
    
    log "正在安装 Nginx..."
    make install >> "$LOG_FILE" 2>&1
    
    if [ $? -ne 0 ]; then
        error "Nginx 安装失败，详情请查看日志文件"
        return 1
    fi
    
    # 验证安装
    if [ -f "$NGINX_INSTALL_DIR/sbin/nginx" ]; then
        success "Nginx v${NGINX_VERSION} 安装成功！"
        return 0
    else
        error "Nginx 安装验证失败"
        return 1
    fi
}

# 修改Nginx配置文件，将默认的80端口改为43838，同时支持IPv4和IPv6
configure_nginx() {
    log "正在配置Nginx端口..."
    
    # Nginx配置文件路径
    NGINX_CONF="$NGINX_INSTALL_DIR/conf/nginx.conf"
    
    if [ -f "$NGINX_CONF" ]; then
        # 备份原始配置文件
        cp "$NGINX_CONF" "${NGINX_CONF}.backup"
        
        # 将默认的80端口修改为43838
        sed -i 's/listen\s*80;/listen       43838;/g' "$NGINX_CONF"
        
        # 确保pid文件路径设置正确
        if ! grep -q "pid" "$NGINX_CONF"; then
            sed -i '1i pid        logs/nginx.pid;' "$NGINX_CONF"
            log "已添加PID文件设置"
        fi
        
        # 在server块中添加IPv4和IPv6监听
        if grep -q "server {" "$NGINX_CONF"; then
            # 先删除已有的listen行，避免重复
            sed -i '/listen\s*43838;/d' "$NGINX_CONF"
            sed -i '/listen\s*0.0.0.0:43838;/d' "$NGINX_CONF"
            sed -i '/listen\s*\[\:\:\]:43838;/d' "$NGINX_CONF"
            
            # 在server {后添加IPv4和IPv6监听行
            sed -i '/server {/a \        listen       0.0.0.0:43838;\n        listen       [::]:43838;' "$NGINX_CONF"
            
            log "已设置同时监听IPv4和IPv6"
        else
            warning "未找到server块，请手动修改配置文件添加IPv4和IPv6监听"
        fi
        
        if [ $? -eq 0 ]; then
            success "Nginx端口已修改为43838，同时支持IPv4和IPv6"
        else
            warning "Nginx端口修改失败，请手动修改配置文件：$NGINX_CONF"
        fi
    else
        warning "未找到Nginx配置文件，请手动修改端口"
    fi
}

# 清理临时文件
cleanup() {
    log "正在清理临时文件..."
    rm -rf "$BUILD_DIR"
    success "清理完成"
}

# 创建便捷启动脚本
create_helper_scripts() {
    log "正在创建便捷脚本..."
    
    # 创建启动脚本
    cat > "$INSTALL_DIR/start_nginx.sh" << EOF
#!/bin/bash
# 先检查是否已经有Nginx在运行
if pgrep -x nginx > /dev/null; then
    echo "Nginx已经在运行中，先停止它..."
    $INSTALL_DIR/stop_nginx.sh
    sleep 1
fi

# 检查配置文件语法
NGINX_CONF="$NGINX_INSTALL_DIR/conf/nginx.conf"
echo "检查Nginx配置文件语法..."

# 先尝试修复常见的配置错误
if grep -n "listen.*43838" "\$NGINX_CONF" | grep -v "server {" -B 5 | grep -q "^[0-9]"; then
    echo "检测到配置文件中有错误的listen指令位置，尝试修复..."
    # 创建临时文件
    TEMP_CONF="\$(mktemp)"
    # 提取有效的配置部分（移除错误的listen指令）
    awk '
    /^[[:space:]]*server[[:space:]]*{/,/^[[:space:]]*}/ {
        # 保留server块
        print;
        next;
    }
    /^[[:space:]]*listen/ {
        # 跳过server块外的listen指令
        next;
    }
    {
        # 打印其他所有行
        print;
    }
    ' "\$NGINX_CONF" > "\$TEMP_CONF"
    
    # 备份原始文件
    cp "\$NGINX_CONF" "\$NGINX_CONF.broken"
    echo "原始配置已备份为: \$NGINX_CONF.broken"
    
    # 使用修复后的配置
    cp "\$TEMP_CONF" "\$NGINX_CONF"
    rm -f "\$TEMP_CONF"
    echo "配置文件已修复"
fi

# 验证配置文件
$NGINX_INSTALL_DIR/sbin/nginx -t
if [ \$? -ne 0 ]; then
    echo "配置文件有错误，请手动修复，或使用示例配置文件:"
    echo "cp \$PWD/proxy_example.conf $NGINX_INSTALL_DIR/conf/nginx.conf"
    exit 1
fi

# 检查端口占用情况
if netstat -tulpn 2>/dev/null | grep -q ":43838 "; then
    echo "警告：端口43838已被占用，请检查是否有其他进程正在使用该端口"
    netstat -tulpn 2>/dev/null | grep ":43838 "
fi

# 启动Nginx
$NGINX_INSTALL_DIR/sbin/nginx
if [ \$? -eq 0 ]; then
    echo "Nginx 已成功启动"
    echo "==================== 访问地址 ===================="
    
    # 尝试多种方式获取IPv4地址
    IPV4_ADDR=""
    # 方法1: 使用curl查询外部服务
    IPV4_ADDR=\$(curl -s -4 --connect-timeout 2 ifconfig.me 2>/dev/null || echo "")
    
    # 方法2: 如果方法1失败，尝试使用hostname
    if [ -z "\$IPV4_ADDR" ]; then
        IPV4_ADDR=\$(hostname -I | awk '{print \$1}' 2>/dev/null || echo "")
    fi
    
    # 方法3: 如果前两种方法都失败，尝试使用ip命令
    if [ -z "\$IPV4_ADDR" ]; then
        IPV4_ADDR=\$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 2>/dev/null || echo "")
    fi
    
    # 显示IPv4地址
    if [ -n "\$IPV4_ADDR" ]; then
        echo "http://\$IPV4_ADDR:43838"
    else
        echo "未能获取服务器的IPv4地址"
    fi
    
    # 获取IPv6地址
    IPV6_ADDR=""
    # 使用ip命令获取IPv6地址
    IPV6_ADDR=\$(ip -6 addr show scope global | grep -oP '(?<=inet6\s)[\da-f:]+'| head -1 2>/dev/null || echo "")
    
    # 显示IPv6地址
    if [ -n "\$IPV6_ADDR" ]; then
        echo "http://[\$IPV6_ADDR]:43838"
    else
        echo "未能获取服务器的IPv6地址"
    fi
    
    # 添加本地地址
    echo "http://127.0.0.1:43838 (本机访问)"
    echo "================================================="
else
    echo "Nginx 启动失败，请检查错误日志："
    echo "  $NGINX_INSTALL_DIR/logs/error.log"
fi
EOF
    
    # 创建停止脚本
    cat > "$INSTALL_DIR/stop_nginx.sh" << EOF
#!/bin/bash
# 尝试正常停止
if [ -f "$NGINX_INSTALL_DIR/logs/nginx.pid" ]; then
    $NGINX_INSTALL_DIR/sbin/nginx -s stop
    echo "Nginx 已停止"
else
    # 如果pid文件不存在，尝试查找进程并终止
    nginx_pids=\$(pgrep -f "$NGINX_INSTALL_DIR/sbin/nginx")
    if [ -n "\$nginx_pids" ]; then
        echo "正在终止Nginx进程: \$nginx_pids"
        kill \$nginx_pids
        sleep 1
        # 检查是否仍在运行
        if pgrep -f "$NGINX_INSTALL_DIR/sbin/nginx" > /dev/null; then
            echo "强制终止Nginx进程..."
            pkill -9 -f "$NGINX_INSTALL_DIR/sbin/nginx"
        fi
        echo "Nginx 已停止"
    else
        echo "未找到Nginx进程"
    fi
fi
EOF
    
    # 创建重新加载脚本
    cat > "$INSTALL_DIR/reload_nginx.sh" << EOF
#!/bin/bash
# 检查配置是否有效
$NGINX_INSTALL_DIR/sbin/nginx -t
if [ \$? -ne 0 ]; then
    echo "Nginx 配置无效，请修复错误后再尝试重新加载"
    exit 1
fi

# 尝试重新加载
if [ -f "$NGINX_INSTALL_DIR/logs/nginx.pid" ]; then
    $NGINX_INSTALL_DIR/sbin/nginx -s reload
    echo "Nginx 配置已重新加载"
else
    echo "Nginx PID文件不存在，可能没有正在运行"
    echo "正在尝试启动Nginx..."
    $INSTALL_DIR/start_nginx.sh
fi
EOF
    
    # 创建检查状态脚本
    cat > "$INSTALL_DIR/status_nginx.sh" << EOF
#!/bin/bash
if pgrep -f "$NGINX_INSTALL_DIR/sbin/nginx" > /dev/null; then
    echo "Nginx 正在运行"
    ps aux | grep "$NGINX_INSTALL_DIR/sbin/nginx" | grep -v grep
    echo ""
    echo "监听端口："
    netstat -tulpn 2>/dev/null | grep nginx
    
    echo ""
    echo "IPv4和IPv6连接状态："
    netstat -an | grep 43838
else
    echo "Nginx 未运行"
fi
EOF
    
    # 添加执行权限
    chmod +x "$INSTALL_DIR/start_nginx.sh" "$INSTALL_DIR/stop_nginx.sh" "$INSTALL_DIR/reload_nginx.sh" "$INSTALL_DIR/status_nginx.sh"
    
    success "便捷脚本创建完成"
}

# 安装总流程
install() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${BLUE}      无root权限Nginx一键安装脚本 v1.0           ${NC}"
    echo -e "${BLUE}====================================================${NC}"
    
    # 设置安装路径
    setup_paths "$1"
    
    # 检测系统
    check_system
    
    # 安装PCRE (可选)
    install_pcre
    if [ $? -ne 0 ]; then
        warning "PCRE 安装失败，将在Nginx中禁用PCRE功能"
        # 不终止安装，继续安装其他组件
    fi
    
    install_zlib
    if [ $? -ne 0 ]; then
        error "zlib 安装失败，安装过程终止"
        exit 1
    fi
    
    # 安装OpenSSL
    install_openssl
    if [ $? -ne 0 ]; then
        error "OpenSSL 安装失败，HTTPS功能将不可用"
        exit 1
    fi
    
    install_nginx
    if [ $? -ne 0 ]; then
        error "Nginx 安装失败，安装过程终止"
        exit 1
    fi
    
    # 配置Nginx端口
    configure_nginx
    
    # 创建便捷脚本
    create_helper_scripts
    
    # 清理临时文件
    cleanup
    
    echo -e "${GREEN}====================================================${NC}"
    echo -e "${GREEN}      Nginx 安装成功！                            ${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "安装信息:"
    echo -e "  - Nginx 安装目录: ${BLUE}$NGINX_INSTALL_DIR${NC}"
    echo -e "  - 启动 Nginx: ${YELLOW}$INSTALL_DIR/start_nginx.sh${NC}"
    echo -e "  - 停止 Nginx: ${YELLOW}$INSTALL_DIR/stop_nginx.sh${NC}"
    echo -e "  - 重载配置: ${YELLOW}$INSTALL_DIR/reload_nginx.sh${NC}"
    echo -e "  - 查看状态: ${YELLOW}$INSTALL_DIR/status_nginx.sh${NC}"
    echo -e "  - 配置文件: ${BLUE}$NGINX_INSTALL_DIR/conf/nginx.conf${NC}"
    echo -e "  - 日志文件: ${BLUE}$LOG_FILE${NC}"
    echo -e "${GREEN}====================================================${NC}"
    echo -e "现在您可以使用以下命令启动Nginx:"
    echo -e "${YELLOW}$INSTALL_DIR/start_nginx.sh${NC}"
    echo -e ""
    echo -e "启动后，您将看到可用的访问地址列表"
    echo -e ""
    echo -e "如需配置反向代理，请运行:"
    echo -e "${YELLOW}bash setup_proxy.sh${NC}"
    echo -e ""
    echo -e "如果遇到端口占用问题，请运行清理脚本:"
    echo -e "${YELLOW}bash cleanup_nginx.sh${NC}"
    echo -e ""
    echo -e "安装日志已保存到: ${BLUE}$LOG_FILE${NC}"
    
    # 提示功能特性
    echo -e "${GREEN}已启用功能：${NC}"
    echo -e "  - 基本HTTP服务"
    echo -e "  - HTTPS支持（SSL）"
    echo -e "  - 反向代理"
    if [ -f "$INSTALL_DIR/pcre/bin/pcre-config" ]; then
        echo -e "  - 正则表达式支持"
    else
        echo -e "${YELLOW}未启用功能：${NC}"
        echo -e "  - 正则表达式支持"
    fi
}

# 开始安装
install "$1" 
