# 部署指南

> **目标环境**：生产部署 / Dokploy / 手动 fallback
> **代码仓库**：https://github.com/kime6727/html-editor-cloud
> **生产域名**：https://html.niceapp.eu.cc

---

## 一、生产环境信息

| 项目 | 值 |
|------|---|
| 后端域名 | `html.niceapp.eu.cc` |
| 部署平台 | Dokploy（容器化） |
| Web 服务器 | Nginx + PHP-FPM |
| 数据库 | MySQL 8.0+（utf8mb4_unicode_ci） |
| 静态资源托管 | `deploy_package/pub/{project_id}/index.html` |
| TLS 证书 | Let's Encrypt（由 Dokploy 自动签发） |

---

## 二、Dokploy 自动部署（推荐）

### 2.1 触发条件
- 推送到 GitHub `main` 分支 → Dokploy 自动拉取最新代码并重建容器

### 2.2 部署流程
```
本地代码 → git commit → git push origin main → 
  GitHub webhook → Dokploy 检测变更 → 
  拉取最新代码 → 重启 PHP-FPM 容器 → 部署完成
```

### 2.3 Dokploy 必填环境变量

| Key | Value | 备注 |
|-----|-------|------|
| `PUBLISH_API_KEY` | 32+ 位随机字符串 | iOS 上传时鉴权 |
| `HMAC_SECRET_KEY` | 32+ 位随机字符串 | **必须与 API Key 不同** |
| `DB_HOST` | `db` 或 MySQL host | Dokploy 内置 DB |
| `DB_NAME` | `html_editor` | |
| `DB_USER` | `html_editor` | |
| `DB_PASS` | 强密码 | |
| `ADMIN_USER` | 管理员账号 | admin.php 登录 |
| `ADMIN_PASS` | bcrypt 哈希 | admin.php 登录 |

> ⚠️ 这些值**不要**写入 `.env.example`、代码或文档中。Dokploy Secret 只在控制台维护。

### 2.4 部署后必做
1. **跑数据库迁移**（首次部署或 schema 变更时）：
   ```bash
   docker exec -it <php-container> bash
   cd /var/www/html/deploy_package/database
   mysql -h $DB_HOST -u $DB_USER -p$DB_PASS html_editor < migration_v3.2_cleanup.sql
   ```
2. **验证后端健康**：
   ```bash
   curl https://html.niceapp.eu.cc/api/projects.php?action=list
   # 期望: {"code":"missing_auth","success":false,...}  （说明 API 可达但缺鉴权）
   ```
3. **检查 iOS 端**：
   - 设置 → 服务器测试 → 12 项应全绿

---

## 三、手动部署（Fallback）

> 仅在 Dokploy 出问题时使用。建议先把整个 `deploy_package/` rsync 到服务器。

### 3.1 服务器要求
- PHP 7.4+（推荐 8.0+）
- MySQL 5.7+ / MariaDB 10.3+
- Nginx 或 Apache
- 启用 PHP 扩展：`pdo_mysql`, `mbstring`, `json`, `openssl`, `bcmath`

### 3.2 上传代码
```bash
rsync -avz --delete \
  --exclude='.env' --exclude='.git' \
  ./deploy_package/ root@html.niceapp.eu.cc:/var/www/html/
```

### 3.3 配置 .env
```bash
ssh root@html.niceapp.eu.cc
cd /var/www/html
cat > .env <<'EOF'
PUBLISH_API_KEY=<your-api-key>
HMAC_SECRET_KEY=<your-hmac-secret>
DB_HOST=127.0.0.1
DB_NAME=html_editor
DB_USER=html_editor
DB_PASS=<your-password>
EOF
chmod 600 .env
chown -R www-data:www-data /var/www/html
```

### 3.4 初始化数据库
```bash
# 首次部署
mysql -u root -p html_editor < /var/www/html/deploy_package/database/init_mysql84.sql

# 老库升级
mysql -u root -p html_editor < /var/www/html/deploy_package/database/migration_v3.2_cleanup.sql
```

### 3.5 Nginx 配置
```nginx
server {
    listen 443 ssl http2;
    server_name html.niceapp.eu.cc;

    root /var/www/html;
    index index.php;

    ssl_certificate     /etc/letsencrypt/live/html.niceapp.eu.cc/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/html.niceapp.eu.cc/privkey.pem;

    # 安全头
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header Referrer-Policy "no-referrer-when-downgrade";

    # 静态资源（用户发布的项目）直出
    location /pub/ {
        alias /var/www/html/deploy_package/pub/;
        try_files $uri $uri/ =404;
        expires 1h;
        add_header Cache-Control "public, max-age=3600";
    }

    # 公共访问网关
    location / {
        try_files $uri $uri/ /deploy_package/index.php?$query_string;
    }

    # PHP-FPM
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # 禁止访问敏感文件
    location ~ /\.(env|git) { deny all; return 404; }
}
```

### 3.6 重启服务
```bash
nginx -t && systemctl reload nginx
systemctl restart php8.2-fpm
```

---

## 四、数据库迁移历史

| 版本 | 文件 | 说明 |
|------|------|------|
| v3.2 | `migration_v3.2_cleanup.sql` | **必跑**：清理所有未实现的表/视图/字段 |
| v3.0 | `migration_v3_final.sql` | 旧版迁移（含 v_user_stats 等已删除对象，仅供历史参考） |

> 每次 `git push` 后，**如果**代码改动涉及 schema 变更，需手动跑对应 migration。

---

## 五、环境差异

| 项 | Dokploy 生产 | 手动部署 |
|---|---|---|
| TLS | 自动 | 需手动 certbot |
| DB | Dokploy 内置 | 需自建 MySQL |
| 容器重启 | 自动 | `systemctl restart` |
| 健康检查 | Dokploy 自带 | 需配 Nginx + cron |

---

## 六、上线 Checklist

部署完成后逐项勾选：

- [ ] HTTPS 可访问，无证书错误
- [ ] `https://html.niceapp.eu.cc/api/projects.php?action=list` 返回 `missing_auth`（说明 API 可达）
- [ ] `https://html.niceapp.eu.cc/{测试ID}/` 可打开静态页
- [ ] iOS 端 设置 → 服务器测试 12 项全绿
- [ ] iOS 端发布 1 个测试项目 → 浏览器可访问
- [ ] iOS 端设置密码 → 浏览器输入密码可访问
- [ ] iOS 端设置 1 小时过期 → 等 1 小时后 → 显示过期引导页
- [ ] admin.php 登录可访问（用 `ADMIN_USER` / `ADMIN_PASS`）
- [ ] `mysql -e "SHOW TABLES FROM html_editor"` 仅显示 6 个核心表（无 `daily_stats` 等）

---

## 七、回滚

如新版本出严重问题：

```bash
# 1. 在 Dokploy 控制台切换到上一个 commit
git log --oneline -10  # 找到上一个稳定版本 hash
git revert <bad-commit-hash>
git push origin main

# 2. 如需回滚数据库（DANGER）
mysql -u root -p html_editor < /var/www/html/deploy_package/database/migration_v3.2_cleanup.sql
# ⚠️ 注意：v3.2 cleanup 是单向的（删除表/字段），无回滚脚本
```

**强烈建议**：每次 schema 变更前 `mysqldump` 全量备份。

```bash
mysqldump -u root -p html_editor > backup_$(date +%Y%m%d).sql
```
