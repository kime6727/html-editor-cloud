# Nginx 部署说明 - HTML Code Editor 云端发布

## 📋 环境要求

- Nginx 1.18+
- PHP 7.4+ (PHP-FPM)
- MySQL 5.7+ / MariaDB 10.3+
- 域名: https://html.niceapp.eu.cc

---

## 🚀 部署步骤

### 1. 上传文件到服务器

将 `deploy_package` 目录上传到服务器，例如：
```bash
scp -r deploy_package/* user@your-server:/var/www/html/
```

或直接在服务器上创建目录：
```bash
mkdir -p /var/www/html
# 然后将所有文件复制到此目录
```

---

### 2. 配置 Nginx

编辑你的 Nginx 配置文件（通常在 `/etc/nginx/sites-available/` 或 `/etc/nginx/conf.d/`）：

```bash
sudo nano /etc/nginx/sites-available/html-editor
```

复制以下配置并修改路径：

```nginx
server {
    listen 80;
    server_name html.niceapp.eu.cc;
    
    # 网站根目录
    root /var/www/html;  # ← 修改为你的实际路径
    index index.php index.html;
    
    # 客户端上传大小限制
    client_max_body_size 50M;
    
    # ============ pub 目录配置 ============
    location /pub/ {
        alias /var/www/html/pub/;  # ← 修改为你的实际路径
        
        # 禁止目录浏览
        autoindex off;
        
        # 规则1：HTML/HTM文件请求通过PHP网关检查
        location ~ ^/pub/([a-z0-9]+)/([^.]+\.(html|htm))$ {
            rewrite ^/pub/([a-z0-9]+)/([^.]+\.(html|htm))$ /index.php?project_id=$1&file=$2 last;
        }
        
        # 规则2：项目目录根路径默认访问index.html并通过网关
        location ~ ^/pub/([a-z0-9]+)/?$ {
            rewrite ^/pub/([a-z0-9]+)/?$ /index.php?project_id=$1&file=index.html last;
        }
        
        # 规则3：静态资源直接访问（CSS/JS/图片/字体等）
        location ~* \.(css|js|mjs|json|png|jpg|jpeg|gif|svg|webp|bmp|ico|ttf|otf|woff|woff2|eot|xml|yaml|yml|map)$ {
            expires 7d;
            add_header Cache-Control "public";
            access_log off;
        }
        
        # HTML文件不缓存（通过网关动态提供）
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
        }
        
        # 禁止访问PHP文件
        location ~ \.php$ {
            deny all;
        }
        
        # 禁止访问备份文件
        location ~ \.(bak|backup|old|tmp)$ {
            deny all;
        }
    }
    
    # ============ index.php 网关处理 ============
    location = /index.php {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;  # 或 127.0.0.1:9000
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # 安全头
        fastcgi_param HTTP_X_REAL_IP $remote_addr;
        fastcgi_param HTTP_X_FORWARDED_FOR $proxy_add_x_forwarded_for;
        
        # 禁用缓冲以提高响应速度
        fastcgi_buffering off;
    }
    
    # ============ PHP 处理（其他PHP文件） ============
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php-fpm.sock;  # 或 127.0.0.1:9000
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        
        # 安全头
        fastcgi_param HTTP_X_REAL_IP $remote_addr;
        fastcgi_param HTTP_X_FORWARDED_FOR $proxy_add_x_forwarded_for;
    }
    
    # ============ 安全设置 ============
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
    }
    
    # 禁止访问data目录（存储速率限制等数据）
    location /data/ {
        deny all;
    }
    
    # 禁止访问database目录
    location /database/ {
        deny all;
    }
    
    # 日志配置
    access_log /var/log/nginx/html-editor-access.log;
    error_log /var/log/nginx/html-editor-error.log;
}
```

**重要修改**：
1. 将 `/var/www/html` 替换为你的实际路径
2. 如果 PHP-FPM 使用 TCP 而不是 socket，将 `unix:/var/run/php/php-fpm.sock` 改为 `127.0.0.1:9000`

---

### 3. 启用站点并重启 Nginx

```bash
# 启用站点（如果使用 sites-available）
sudo ln -s /etc/nginx/sites-available/html-editor /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

---

### 4. 配置数据库

```bash
# 登录 MySQL
mysql -u root -p

# 执行数据库迁移
mysql -u your_user -p html_editor < /var/www/html/database/migration_v3_free_hour.sql
```

---

### 5. 设置文件权限

```bash
# 设置正确的权限
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 775 /var/www/html/pub
sudo chmod -R 775 /var/www/html/data

# 确保 PHP 文件可执行
sudo find /var/www/html -name "*.php" -exec chmod 644 {} \;
```

---

### 6. 配置 HTTPS（使用 Let's Encrypt）

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d html.niceapp.eu.cc

# 自动续期
sudo crontab -e
# 添加：0 3 * * * certbot renew --quiet
```

---

### 7. 配置定时任务（过期检查）

虽然已有实时过期检查，但定时任务仍用于备份文件处理：

```bash
# 编辑 crontab
crontab -e

# 添加：每5分钟执行一次
*/5 * * * * php /var/www/html/expire_cron.php
```

---

## 🧪 测试清单

### 1. 基础功能测试

```bash
# 测试发布 API
curl -X POST https://html.niceapp.eu.cc/publish.php \
  -H "X-API-Key: your_api_key" \
  -H "X-Timestamp: $(date +%s)" \
  -H "X-Signature: your_signature" \
  -F "name=Test Project" \
  -F "files[]=@index.html"

# 测试统计 API
curl https://html.niceapp.eu.cc/stats.php?id=abc12345

# 访问发布的项目（应该通过网关）
curl -I https://html.niceapp.eu.cc/pub/abc12345/index.html
```

### 2. 过期检查测试

```bash
# 访问项目（未过期）→ 应返回 200
curl -I https://html.niceapp.eu.cc/pub/abc12345/index.html

# 修改数据库使项目过期
mysql -u your_user -p -e "UPDATE html_editor.projects SET expires_at = NOW() - INTERVAL 1 HOUR WHERE project_id = 'abc12345';"

# 再次访问 → 应返回 410 (Gone) 并显示过期页面
curl -I https://html.niceapp.eu.cc/pub/abc12345/index.html
```

### 3. 密码保护测试

```bash
# 发布带密码的项目
curl -X POST https://html.niceapp.eu.cc/publish.php \
  -H "X-API-Key: your_api_key" \
  -H "X-Timestamp: $(date +%s)" \
  -H "X-Signature: your_signature" \
  -F "name=Password Protected" \
  -F "access_password=secret123" \
  -F "files[]=@index.html"

# 访问项目 → 应显示密码输入页面
curl https://html.niceapp.eu.cc/pub/abc12345/index.html

# POST 密码访问
curl -X POST https://html.niceapp.eu.cc/pub/abc12345/index.html \
  -d "password=secret123" \
  -c cookies.txt

# 使用已验证的 cookie 访问
curl -b cookies.txt https://html.niceapp.eu.cc/pub/abc12345/index.html
```

---

## ⚠️ 常见问题

### 1. 502 Bad Gateway

**原因**: PHP-FPM 未运行或配置错误

**解决**:
```bash
# 检查 PHP-FPM 状态
sudo systemctl status php7.4-fpm

# 检查 socket 路径
ls -la /var/run/php/

# 修改 Nginx 配置中的 fastcgi_pass
# 如果使用 TCP: fastcgi_pass 127.0.0.1:9000;
# 如果使用 socket: fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
```

### 2. 访问项目返回 404

**原因**: Nginx rewrite 规则未生效

**解决**:
```bash
# 检查 Nginx 配置
sudo nginx -t

# 检查 rewrite 日志
sudo tail -f /var/log/nginx/error.log

# 确保 location 块顺序正确（正则 location 优先于前缀 location）
```

### 3. 密码验证后仍然显示密码页面

**原因**: PHP Session 配置问题

**解决**:
```bash
# 检查 PHP Session 配置
php -i | grep session

# 确保 session.save_path 可写
sudo chmod 777 /var/lib/php/sessions

# 检查 cookie 设置
# 在 index.php 开头添加：
ini_set('session.cookie_httponly', 1);
ini_set('session.use_only_cookies', 1);
ini_set('session.cookie_secure', 1);  # 仅 HTTPS
```

### 4. 访问统计无数据

**原因**: 数据库写入失败

**解决**:
```bash
# 检查数据库连接
php /var/www/html/test_db_connection.php

# 检查 visit_logs 表权限
mysql -u your_user -p -e "GRANT INSERT ON html_editor.visit_logs TO 'your_user'@'localhost';"
```

---

## 📊 性能优化建议

### 1. PHP-FPM 优化

编辑 `/etc/php/7.4/fpm/pool.d/www.conf`:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

### 2. Nginx 优化

在 `http` 块中添加：
```nginx
# 启用 gzip 压缩
gzip on;
gzip_types text/html text/css application/javascript application/json image/svg+xml;
gzip_min_length 1024;

# 启用 HTTP/2
listen 443 ssl http2;

# 连接优化
keepalive_timeout 65;
keepalive_requests 100;
```

### 3. MySQL 优化

编辑 `/etc/mysql/mysql.conf.d/mysqld.cnf`:
```ini
innodb_buffer_pool_size = 256M
query_cache_size = 64M
max_connections = 200
```

---

## 🔒 安全加固

### 1. 修改 API 密钥

编辑 `.env` 文件：
```env
PUBLISH_API_KEY=your_new_random_api_key_here
HMAC_SECRET_KEY=your_new_random_hmac_secret_here
```

### 2. 限制上传目录

确保 `pub` 目录没有执行权限：
```bash
# 在 Nginx 配置中已设置
location ~ \.php$ {
    deny all;
}
```

### 3. 配置防火墙

```bash
# 只开放必要端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

---

## 📝 维护日志

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-05-15 | 部署 v3 | 免费用户过期改为1小时，添加实时过期检查 |
| 2026-05-15 | 数据库迁移 | 执行 migration_v3_free_hour.sql |
| 2026-05-15 | Nginx 配置 | 更新 rewrite 规则，添加网关支持 |

---

## 📞 技术支持

如有问题，请检查：
1. Nginx 错误日志: `/var/log/nginx/html-editor-error.log`
2. PHP 错误日志: `/var/log/php7.4-fpm.log`
3. 应用日志: PHP 代码中的 `error_log()` 输出

祝部署顺利！🚀
