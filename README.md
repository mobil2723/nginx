
## 使用方法

### 安装Nginx

1. 下载安装脚本

```bash
git clone https://github.com/mobil2723/nginx.git
cd nginx
```

2. 运行安装脚本

```bash
# 使用默认安装路径 (~/nginx_install)
bash install_nginx.sh

# 或指定自定义安装路径
bash install_nginx.sh /home/yourusername/custom_path
```

3. 安装完成后，Nginx可以通过以下命令启动：

```bash
~/nginx_install/start_nginx.sh
```

### 配置反向代理

安装完成后，您可以使用提供的反向代理配置向导快速设置反向代理：

```bash
# 使用默认配置
bash setup_proxy.sh

# 指定监听端口
bash setup_proxy.sh -p 8080

# 指定Nginx安装目录
bash setup_proxy.sh -d /path/to/nginx_install
```

配置向导将引导您设置一个或多个反向代理规则，非常简单易用。

您也可以参考 `proxy_example.conf` 文件，手动配置反向代理。

### 管理Nginx

安装完成后，将生成以下便捷管理脚本：

```bash
# 启动Nginx
~/nginx_install/start_nginx.sh

# 停止Nginx
~/nginx_install/stop_nginx.sh

# 重新加载配置
~/nginx_install/reload_nginx.sh

# 查看Nginx状态
~/nginx_install/status_nginx.sh
```

### 卸载Nginx

如果需要卸载Nginx，可以使用提供的卸载脚本：

```bash
# 使用默认安装路径
bash uninstall.sh

# 指定安装路径
bash uninstall.sh -d /home/yourusername/custom_path

# 强制卸载（不进行确认）
bash uninstall.sh -f
```

## 配置说明

安装完成后，可以修改以下配置文件：

- Nginx配置文件：`~/nginx_install/nginx/conf/nginx.conf`

### 默认端口

为了避免需要root权限，脚本已将Nginx默认端口设置为43838。安装完成后，您可以通过以下地址访问：

```
http://您的服务器IP:43838
```

如果需要修改端口，请编辑nginx.conf文件：

```bash
vi ~/nginx_install/nginx/conf/nginx.conf
```

找到`listen 43838;`行并修改为您想要的端口（建议使用1024以上的端口）。

## 默认安装组件版本

- PCRE: 8.45
- zlib: 1.3.1
- Nginx: 1.24.0

## 注意事项

- 确保有足够的磁盘空间用于下载和编译
- 安装过程需要编译源码，可能需要一些时间
- 确保您对指定的安装目录有写权限
- 默认监听端口为43838，确保该端口未被其他程序占用

## 常见问题

详细的常见问题解答请参阅 [FAQ.md](FAQ.md) 文件。

## 贡献

欢迎通过 Issue 和 Pull Request 提交问题和改进建议。 