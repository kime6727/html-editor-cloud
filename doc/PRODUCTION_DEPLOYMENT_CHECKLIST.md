# 生产环境部署检查清单

> ⚠️ 当前主要部署方式为 **GitHub + Dokploy** 自动部署，详见 [README_DEPLOYMENT.md](README_DEPLOYMENT.md)。本文档保留作为手动部署参考。

## 📦 已准备好的文件

✅ **production_deploy.tar.gz** - 生产环境部署包（已自动调整路径）  
✅ **deploy_package/** - 解压后的文件目录  
✅ **iOS配置** - 已恢复为线上地址

## 🚀 部署步骤

### 第一步：配置数据库信息

```bash
# 编辑.env文件
nano deploy_package/.env
```

填入你的真实数据库信息：
```env
DB_HOST=localhost
DB_NAME=你的数据库名
DB_USER=你的数据库用户
DB_PASS=你的数据库密码
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
```

### 第二步：上传到服务器

**方式1：使用SCP（推荐）**
```bash
scp production_deploy.tar.gz user@server:/path/to/html.niceapp.eu.cc/
```

**方式2：使用FTP客户端**
- 使用FileZilla、Cyberduck等工具
- 上传 `production_deploy.tar.gz` 到服务器

**方式3：使用服务器面板**
- 如果有cPanel、宝塔等面板
- 直接在面板中上传文件

### 第三步：在服务器上解压

SSH登录服务器后执行：

```bash
# 进入网站目录
cd /path/to/html.niceapp.eu.cc/

# 备份现有文件（如果有）
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz . 2>/dev/null || true

# 解压新文件
tar -xzf production_deploy.tar.gz

# 删除压缩包
rm production_deploy.tar.gz
```

### 第四步：设置权限

```bash
# 设置文件权限
chmod 755 *.php
chmod 755 -R api/
chmod 755 -R database/
chmod 755 -R p/

# pub目录必须可写
chmod 777 pub/

# 保护敏感文件
chmod 600 .env
```

### 第五步：导入数据库

**方式1：使用本地数据库结构**

```bash
# 在本地导出数据库结构
mysqldump -u root -p --no-data html_editor > schema.sql

# 上传到服务器
scp schema.sql user@server:/tmp/

# 在服务器上导入
mysql -u your_user -p your_database < /tmp/schema.sql
```

**方式2：使用已有的schema.sql**

```bash
# 如果backend/database/目录有schema.sql
mysql -u your_user -p your_database < database/schema.sql
```

### 第六步：测试服务器

```bash
# 测试1：诊断脚本
curl https://html.niceapp.eu.cc/test_publish.php

# 测试2：数据库连接
curl https://html.niceapp.eu.cc/test/db_test.php

# 测试3：API端点（返回403正常，说明服务器工作）
curl -I https://html.niceapp.eu.cc/publish.php

# 测试4：项目管理API
curl -I https://html.niceapp.eu.cc/api/projects.php
```

### 第七步：iOS应用测试

1. **重新构建应用**
   - 在Xcode中按 `⇧⌘K` (Clean Build Folder)
   - 按 `⌘R` (Run)

2. **测试发布功能**
   - 创建一个简单的HTML项目
   - 点击"发布"按钮
   - 观察发布过程

3. **验证结果**
   - 检查返回的URL格式：`https://html.niceapp.eu.cc/pub/xxxxx/index.html`
   - 点击URL在应用内预览
   - 复制URL在Safari中打开
   - 验证内容和样式都正确显示

## ✅ 验证清单

### 服务器端验证

- [ ] 文件已上传到正确目录
- [ ] .env文件配置正确
- [ ] pub目录权限为777
- [ ] 数据库已创建并导入结构
- [ ] test_publish.php返回正常诊断信息
- [ ] 数据库连接测试通过

### 功能验证

- [ ] 发布新项目成功
- [ ] 返回的URL可以访问
- [ ] 项目内容显示正确
- [ ] 样式和脚本正常加载
- [ ] 图片（如果有）正常显示
- [ ] 自定义短链功能正常
- [ ] 过期时间设置正常
- [ ] 访问统计正常记录

### 管理功能验证

- [ ] 列出已发布项目
- [ ] 启用/停用项目
- [ ] 修改过期时间
- [ ] 设置访问密码
- [ ] 移除访问密码
- [ ] 查看访问统计
- [ ] 删除项目

## 🔍 故障排查

### 问题1：上传后访问返回500错误

**检查PHP错误日志**：
```bash
tail -f /var/log/php/error.log
# 或
tail -f /var/log/apache2/error.log
# 或
tail -f /var/log/nginx/error.log
```

**常见原因**：
- .env文件格式错误
- 数据库连接失败
- 文件权限不正确

### 问题2：发布成功但访问404

**检查**：
```bash
# 1. 确认文件确实上传了
ls -la pub/

# 2. 检查最新项目
ls -la pub/ | tail -5

# 3. 测试直接访问
curl https://html.niceapp.eu.cc/pub/项目ID/index.html
```

**可能原因**：
- pub目录路径不对
- 文件没有真正上传
- 权限问题

### 问题3：数据库连接失败

**测试数据库连接**：
```bash
mysql -h localhost -u your_user -p your_database -e "SELECT 1"
```

**检查.env配置**：
```bash
cat .env
```

**常见问题**：
- 数据库名错误
- 用户名密码错误
- 数据库服务未启动
- 权限不足

### 问题4：iOS应用发布失败

**检查Xcode控制台输出**，常见错误：

- **403错误**：API签名验证失败
  - 检查API Key是否一致
  - 检查时间戳是否正确

- **413错误**：文件太大
  - 检查PHP配置：`upload_max_filesize` 和 `post_max_size`

- **500错误**：服务器内部错误
  - 查看服务器错误日志

- **网络错误**：无法连接
  - 检查域名是否正确
  - 检查HTTPS证书是否有效

### 问题5：短链访问404

**需要配置URL重写**

创建或编辑 `.htaccess` 文件：

```apache
RewriteEngine On

# 短链重写规则
RewriteRule ^p/([a-zA-Z0-9_-]+)$ redirect.php?slug=$1 [L,QSA]
```

或者在Nginx配置中添加：

```nginx
location /p/ {
    rewrite ^/p/(.+)$ /redirect.php?slug=$1 last;
}
```

## 📊 性能优化建议

部署成功后，建议进行以下优化：

### 1. 启用OPcache

编辑 `php.ini`：
```ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
```

### 2. 数据库索引

```sql
-- 确保关键字段有索引
CREATE INDEX idx_project_id ON projects(project_id);
CREATE INDEX idx_custom_slug ON projects(custom_slug);
CREATE INDEX idx_visited_at ON visit_logs(visited_at);
CREATE INDEX idx_project_visit ON visit_logs(project_id, visited_at);
```

### 3. 启用Gzip压缩

在 `.htaccess` 中添加：
```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>
```

### 4. 设置缓存头

```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
</IfModule>
```

## 🔒 安全检查

- [ ] HTTPS已启用
- [ ] .env文件权限为600
- [ ] 数据库密码强度足够
- [ ] API Key定期更换
- [ ] 错误日志不对外暴露
- [ ] 定期备份数据库和文件
- [ ] 监控异常访问

## 📝 维护建议

### 日常监控

```bash
# 检查磁盘空间
df -h

# 检查pub目录大小
du -sh pub/

# 检查数据库大小
mysql -u user -p -e "SELECT table_schema AS 'Database', 
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' 
    FROM information_schema.TABLES 
    WHERE table_schema = 'your_database' 
    GROUP BY table_schema;"

# 检查最近的错误
tail -50 /var/log/php/error.log | grep -i error
```

### 定期备份

```bash
# 备份数据库
mysqldump -u user -p database_name > backup_$(date +%Y%m%d).sql

# 备份文件
tar -czf backup_files_$(date +%Y%m%d).tar.gz pub/

# 保留最近7天的备份
find . -name "backup_*.sql" -mtime +7 -delete
find . -name "backup_files_*.tar.gz" -mtime +7 -delete
```

### 清理过期项目

```bash
# 创建清理脚本
cat > cleanup_expired.php << 'EOF'
<?php
require_once 'database/Database.php';

// 查找过期项目
$expired = db()->query(
    "SELECT project_id FROM projects 
     WHERE expires_at < NOW() 
     AND status = 'active'"
);

foreach ($expired as $project) {
    echo "Cleaning up: {$project['project_id']}\n";
    
    // 删除文件
    $dir = __DIR__ . '/pub/' . $project['project_id'];
    if (is_dir($dir)) {
        exec("rm -rf " . escapeshellarg($dir));
    }
    
    // 更新状态
    db()->execute(
        "UPDATE projects SET status = 'expired' WHERE project_id = ?",
        [$project['project_id']]
    );
}

echo "Done!\n";
?>
EOF

# 设置定时任务
crontab -e
# 添加：每天凌晨2点清理
0 2 * * * php /path/to/cleanup_expired.php
```

## 🎉 部署完成

完成所有步骤后，你的云端发布功能应该已经在线上正常运行了！

**测试URL示例**：
- API: https://html.niceapp.eu.cc/publish.php
- 项目: https://html.niceapp.eu.cc/pub/xxxxx/index.html
- 短链: https://html.niceapp.eu.cc/p/xxxxx

有任何问题随时查看错误日志或联系技术支持！

---

**部署日期**: ___________  
**部署人**: ___________  
**服务器**: https://html.niceapp.eu.cc  
**状态**: ⬜ 待部署 / ⬜ 部署中 / ⬜ 已完成
