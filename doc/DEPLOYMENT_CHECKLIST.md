# 云端发布功能部署检查清单

> ⚠️ 当前主要部署方式为 **GitHub + Dokploy** 自动部署，详见 [README_DEPLOYMENT.md](README_DEPLOYMENT.md)。本文档保留作为手动部署参考。

## 快速部署指南

### 一、后端部署

#### 1. 上传新文件

```bash
# 上传到服务器
scp backend/api/projects.php user@server:/path/to/backend/api/
scp backend/password.html user@server:/path/to/backend/
scp backend/verify_password.php user@server:/path/to/backend/
scp backend/expired.php user@server:/path/to/backend/
```

#### 2. 更新现有文件

```bash
# 备份原文件
cp backend/publish.php backend/publish.php.backup
cp backend/redirect.php backend/redirect.php.backup
cp backend/stats.php backend/stats.php.backup

# 上传更新后的文件
scp backend/publish.php user@server:/path/to/backend/
scp backend/redirect.php user@server:/path/to/backend/
scp backend/stats.php user@server:/path/to/backend/
```

#### 3. 设置文件权限

```bash
# 在服务器上执行
chmod 644 backend/api/projects.php
chmod 644 backend/password.html
chmod 644 backend/verify_password.php
chmod 644 backend/expired.php
chmod 644 backend/publish.php
chmod 644 backend/redirect.php
chmod 644 backend/stats.php

# 确保目录权限
chmod 755 backend/api/
```

#### 4. 验证数据库连接

```bash
# 测试数据库连接
php backend/test/db_test.php
```

### 二、iOS应用部署

#### 1. 更新代码

```bash
# 确保CloudProjectManager.swift已更新
# 所有API调用应指向 /api/projects.php
```

#### 2. 测试构建

```bash
# 在Xcode中
# Product -> Clean Build Folder
# Product -> Build
```

#### 3. 运行测试

```bash
# 测试所有管理功能
# - 列出项目
# - 切换状态
# - 设置密码
# - 修改过期时间
# - 删除项目
```

### 三、功能验证清单

#### 基础功能
- [ ] 发布新项目（免费用户）
- [ ] 发布新项目（Pro用户）
- [ ] 自定义短链
- [ ] 访问已发布项目

#### 管理功能
- [ ] 列出所有项目
- [ ] 启用/停用项目
- [ ] 修改过期时间
- [ ] 设置访问密码
- [ ] 移除访问密码
- [ ] 删除项目

#### 访问功能
- [ ] 正常访问
- [ ] 过期页面显示（多语言）
- [ ] 密码保护访问
- [ ] 访问统计准确性

#### 安全验证
- [ ] API签名验证
- [ ] 密码加密存储
- [ ] Pro状态服务端验证
- [ ] SQL注入防护

### 四、性能检查

#### 1. 统计查询性能

```bash
# 测试stats.php响应时间
time curl "https://your-domain.com/backend/stats.php?id=test_project"

# 应该在100ms以内
```

#### 2. 并发访问测试

```bash
# 使用ab工具测试
ab -n 100 -c 10 https://your-domain.com/p/test_slug

# 检查响应时间和错误率
```

### 五、监控设置

#### 1. 错误日志

```bash
# 检查PHP错误日志
tail -f /var/log/php/error.log

# 检查Nginx/Apache错误日志
tail -f /var/log/nginx/error.log
```

#### 2. 访问日志

```bash
# 检查访问日志
tail -f /tmp/ce_visits/$(date +%Y-%m-%d).jsonl
```

#### 3. 数据库监控

```sql
-- 检查项目数量
SELECT COUNT(*) FROM projects WHERE status != 'deleted';

-- 检查今日访问量
SELECT COUNT(*) FROM visit_logs WHERE DATE(visited_at) = CURDATE();

-- 检查过期项目
SELECT COUNT(*) FROM projects WHERE expires_at < NOW() AND status = 'active';
```

### 六、回滚计划

如果出现问题，执行以下步骤回滚：

#### 1. 后端回滚

```bash
# 恢复备份文件
cp backend/publish.php.backup backend/publish.php
cp backend/redirect.php.backup backend/redirect.php
cp backend/stats.php.backup backend/stats.php

# 删除新文件（如果导致问题）
rm backend/api/projects.php
rm backend/password.html
rm backend/verify_password.php
rm backend/expired.php
```

#### 2. iOS回滚

```bash
# 使用Git回滚
git checkout HEAD~1 ios/CloudProjectManager.swift

# 重新构建
```

### 七、常见问题排查

#### 问题1: API返回403错误

**原因**: 签名验证失败

**检查**:
```bash
# 检查API Key配置
grep PUBLISH_API_KEY backend/.env

# 检查时间戳
date +%s
```

**解决**:
- 确保iOS和后端使用相同的API Key
- 检查服务器时间是否准确

#### 问题2: 密码验证失败

**原因**: Session未启动或密码哈希不匹配

**检查**:
```bash
# 检查PHP Session配置
php -i | grep session

# 检查密码哈希
php -r "echo password_hash('test', PASSWORD_BCRYPT);"
```

**解决**:
- 确保redirect.php中调用了session_start()
- 检查密码是否使用bcrypt加密

#### 问题3: 统计数据不更新

**原因**: 数据库连接失败或权限问题

**检查**:
```bash
# 测试数据库连接
php backend/test/db_test.php

# 检查数据库权限
mysql -u user -p -e "SHOW GRANTS;"
```

**解决**:
- 检查数据库配置
- 确保用户有INSERT和UPDATE权限

#### 问题4: 删除后仍可访问

**原因**: 文件未完全删除

**检查**:
```bash
# 检查文件是否存在
ls -la pub/project_id/

# 检查元数据文件
ls -la /tmp/ce_shortlinks/project_id.json
```

**解决**:
- 手动删除残留文件
- 检查unpublish函数是否正确执行

### 八、性能优化建议

#### 1. 启用OPcache

```ini
; php.ini
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000
```

#### 2. 数据库索引

```sql
-- 确保关键字段有索引
CREATE INDEX idx_project_id ON projects(project_id);
CREATE INDEX idx_custom_slug ON projects(custom_slug);
CREATE INDEX idx_visited_at ON visit_logs(visited_at);
CREATE INDEX idx_project_visit ON visit_logs(project_id, visited_at);
```

#### 3. 缓存配置

```php
// 考虑使用Redis缓存热门项目
// 减少数据库查询
```

### 九、安全加固

#### 1. HTTPS强制

```nginx
# nginx.conf
server {
    listen 80;
    return 301 https://$server_name$request_uri;
}
```

#### 2. 速率限制

```nginx
# nginx.conf
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /backend/api/ {
    limit_req zone=api burst=20;
}
```

#### 3. 防火墙规则

```bash
# 限制API访问
iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/minute -j ACCEPT
```

### 十、部署完成确认

完成以下所有检查后，部署即可上线：

- [ ] 所有文件已上传
- [ ] 文件权限正确
- [ ] 数据库连接正常
- [ ] iOS应用构建成功
- [ ] 基础功能测试通过
- [ ] 管理功能测试通过
- [ ] 安全验证通过
- [ ] 性能测试通过
- [ ] 错误日志监控已设置
- [ ] 回滚计划已准备

---

## 快速命令参考

### 检查服务状态

```bash
# 检查PHP-FPM
systemctl status php-fpm

# 检查Nginx
systemctl status nginx

# 检查MySQL
systemctl status mysql
```

### 重启服务

```bash
# 重启PHP-FPM
systemctl restart php-fpm

# 重启Nginx
systemctl restart nginx

# 重载Nginx配置
nginx -s reload
```

### 查看日志

```bash
# PHP错误日志
tail -f /var/log/php-fpm/error.log

# Nginx访问日志
tail -f /var/log/nginx/access.log

# Nginx错误日志
tail -f /var/log/nginx/error.log

# 应用访问日志
tail -f /tmp/ce_visits/$(date +%Y-%m-%d).jsonl
```

### 数据库操作

```bash
# 连接数据库
mysql -u user -p database_name

# 导出数据库
mysqldump -u user -p database_name > backup.sql

# 导入数据库
mysql -u user -p database_name < backup.sql
```

---

**部署文档版本**: 1.0  
**最后更新**: 2026-05-08  
**维护人**: DevOps Team

