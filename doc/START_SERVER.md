# 启动本地开发服务器

## 方法1：使用PHP内置服务器（推荐）

```bash
# 在项目根目录执行
php -S localhost:8080

# 或者指定public目录
php -S localhost:8080 -t .
```

访问测试：
- 主页: http://localhost:8080/
- 发布API: http://localhost:8080/backend/publish.php
- 项目管理API: http://localhost:8080/backend/api/projects.php
- 已发布项目: http://localhost:8080/pub/1c906161/index.html
- 短链访问: http://localhost:8080/p/1c906161

## 方法2：使用ServBay（你当前使用的）

如果你已经在使用ServBay，需要配置虚拟主机：

1. 在ServBay中添加站点
2. 设置文档根目录为项目根目录
3. 配置域名（如 htmleditor.local）
4. 修改 `/etc/hosts` 添加：
   ```
   127.0.0.1 htmleditor.local
   ```

然后修改 `ios/AppConfig.swift`:
```swift
static let apiBaseURL = "http://htmleditor.local/backend/"
static let publishAPIBaseURL = "http://htmleditor.local"
```

## 方法3：使用Nginx/Apache

### Nginx配置示例

```nginx
server {
    listen 8080;
    server_name localhost;
    root /path/to/your/project;
    index index.html index.php;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 短链重写规则
    location /p/ {
        rewrite ^/p/(.+)$ /backend/p/index.php?slug=$1 last;
    }
}
```

### Apache配置示例

```apache
<VirtualHost *:8080>
    ServerName localhost
    DocumentRoot "/path/to/your/project"
    
    <Directory "/path/to/your/project">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # 启用PHP
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>
</VirtualHost>
```

## 测试服务器是否正常

```bash
# 测试PHP是否工作
curl http://localhost:8080/backend/test_publish.php

# 测试发布API（需要签名，会返回403但说明服务器工作）
curl http://localhost:8080/backend/publish.php

# 测试已发布项目
curl http://localhost:8080/pub/1c906161/index.html

# 测试短链（需要配置路由）
curl http://localhost:8080/p/1c906161
```

## iOS模拟器访问本地服务器

iOS模拟器可以直接访问 `localhost` 或 `127.0.0.1`。

如果使用真机测试，需要：
1. 确保手机和电脑在同一WiFi
2. 使用电脑的局域网IP（如 192.168.1.100）
3. 修改AppConfig:
   ```swift
   static let apiBaseURL = "http://192.168.1.100:8080/backend/"
   ```

## 当前推荐配置

由于你已经有ServBay环境，最简单的方法是：

```bash
# 1. 启动PHP内置服务器
php -S localhost:8080

# 2. 在另一个终端测试
curl http://localhost:8080/pub/1c906161/index.html

# 3. 重新构建iOS应用
# 在Xcode中: Product -> Clean Build Folder
# 然后: Product -> Run
```

## 验证配置

启动服务器后，在浏览器访问：
- http://localhost:8080/pub/1c906161/index.html （应该显示你的HTML项目）
- http://localhost:8080/backend/test_publish.php （应该显示诊断信息）

如果都能访问，说明服务器配置正确！

## 常见问题

### 问题1: 端口被占用
```bash
# 查看8080端口占用
lsof -i :8080

# 使用其他端口
php -S localhost:8081
```

### 问题2: 权限问题
```bash
# 确保pub目录可写
chmod -R 755 pub/
```

### 问题3: PHP版本
```bash
# 检查PHP版本（需要7.4+）
php -v
```

### 问题4: 数据库连接失败
```bash
# 检查MySQL是否运行
mysql -u root -p -e "SELECT 1"

# 检查.env配置
cat backend/.env
```
