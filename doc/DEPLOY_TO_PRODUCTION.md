# 部署到生产环境指南

## 服务器信息

- **域名**: https://html.weburl.cloudns.be
- **绑定目录**: `/backend` (网站根目录)
- **环境**: PHP + MySQL
- **目标**: 真实线上测试全流程

## 重要：目录结构调整

由于域名绑定到 `/backend` 目录，需要调整目录结构：

### 当前结构（本地）
```
项目根目录/
├── backend/          # 后端代码
│   ├── publish.php
│   ├── api/
│   └── ...
└── pub/              # 发布的项目文件
```

### 线上结构（需要调整）
```
服务器根目录/
├── publish.php       # 后端代码直接在根目录
├── api/
├── database/
├── .env
└── pub/              # 发布的项目文件（需要在同级）
```

## 部署步骤

### 步骤1：准备文件

创建部署包，调整路径：

```bash
# 创建部署目录
mkdir -p deploy_package

# 复制后端文件（不包括backend目录本身）
cp -r backend/* deploy_package/

# 创建pub目录
mkdir -p deploy_package/pub

# 复制.htaccess（如果有）
cp backend/pub/.htaccess deploy_package/pub/ 2>/dev/null || true
```

### 步骤2：修改路径配置

由于文件结构变化，需要修改 `publish.php` 中的路径：

**原配置**:
```php
$scriptDir = __DIR__;
$pubDir = $scriptDir . '/../pub/';  // 上一级目录
```

**新配置**（线上）:
```php
$scriptDir = __DIR__;
$pubDir = $scriptDir . '/pub/';     // 同级目录
```

### 步骤3：上传文件

```bash
# 方式1：使用SCP
scp -r deploy_package/* user@server:/path/to/html.weburl.cloudns.be/

# 方式2：使用FTP客户端
# 使用FileZilla等工具上传 deploy_package/* 到服务器根目录

# 方式3：使用rsync
rsync -avz --progress deploy_package/ user@server:/path/to/html.weburl.cloudns.be/
```

### 步骤4：配置.env文件

在服务器上编辑 `.env` 文件：

```bash
# 数据库配置
DB_HOST=localhost
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASS=your_database_password

# API密钥
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
```

### 步骤5：设置权限

```bash
# 在服务器上执行
chmod 755 publish.php
chmod 755 -R api/
chmod 755 -R database/
chmod 777 pub/              # 必须可写
chmod 600 .env              # 保护敏感信息
```

### 步骤6：导入数据库

```bash
# 1. 导出本地数据库结构
mysqldump -u root -p --no-data html_editor > schema.sql

# 2. 上传到服务器
scp schema.sql user@server:/tmp/

# 3. 在服务器上导入
mysql -u your_user -p your_database < /tmp/schema.sql
```

### 步骤7：测试服务器

```bash
# 测试1：检查PHP是否工作
curl https://html.weburl.cloudns.be/test_publish.php

# 测试2：检查API（会返回403，说明工作正常）
curl https://html.weburl.cloudns.be/publish.php

# 测试3：检查数据库连接
curl https://html.weburl.cloudns.be/test/db_test.php
```

## 快速部署脚本

我为你创建了一个自动部署脚本：

```bash
#!/bin/bash
# deploy.sh - 自动部署到生产环境

echo "=== 开始部署到生产环境 ==="

# 1. 创建部署包
echo "1. 创建部署包..."
rm -rf deploy_package
mkdir -p deploy_package/pub

# 复制后端文件
cp -r backend/* deploy_package/
cp backend/pub/.htaccess deploy_package/pub/ 2>/dev/null || true

# 2. 修改路径配置
echo "2. 修改路径配置..."
# 使用sed修改publish.php中的路径
sed -i.bak "s|\$scriptDir . '/../pub/'|\$scriptDir . '/pub/'|g" deploy_package/publish.php
sed -i.bak "s|__DIR__ . '/../pub/'|__DIR__ . '/pub/'|g" deploy_package/api/projects.php
sed -i.bak "s|__DIR__ . '/../../pub/'|__DIR__ . '/pub/'|g" deploy_package/api/projects.php

# 3. 创建.env文件（如果不存在）
if [ ! -f deploy_package/.env ]; then
    echo "3. 创建.env文件..."
    cat > deploy_package/.env << EOF
DB_HOST=localhost
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASS=your_database_password
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
EOF
    echo "   ⚠️  请编辑 deploy_package/.env 填入真实的数据库信息"
fi

# 4. 打包
echo "4. 创建压缩包..."
cd deploy_package
tar -czf ../production_deploy.tar.gz .
cd ..

echo ""
echo "=== 部署包已准备完成 ==="
echo "文件位置: production_deploy.tar.gz"
echo ""
echo "下一步："
echo "1. 上传 production_deploy.tar.gz 到服务器"
echo "2. 在服务器上解压: tar -xzf production_deploy.tar.gz"
echo "3. 编辑 .env 文件配置数据库"
echo "4. 设置权限: chmod 777 pub/"
echo "5. 导入数据库结构"
echo "6. 测试: curl https://html.weburl.cloudns.be/test_publish.php"
```

## 关键路径修改

需要修改以下文件中的路径：

### 1. backend/publish.php

**查找**:
```php
$pubDir = $scriptDir . '/../pub/';
```

**替换为**:
```php
$pubDir = $scriptDir . '/pub/';
```

### 2. backend/api/projects.php

**查找**:
```php
$uploadDir = __DIR__ . '/../../pub/';
```

**替换为**:
```php
$uploadDir = __DIR__ . '/../pub/';
```

### 3. backend/redirect.php

**查找**:
```php
$config = [
    'upload_dir' => __DIR__ . '/../pub/',
```

**替换为**:
```php
$config = [
    'upload_dir' => __DIR__ . '/pub/',
```

### 4. backend/delete.php

**查找**:
```php
$uploadDir = __DIR__ . '/../pub/';
```

**替换为**:
```php
$uploadDir = __DIR__ . '/pub/';
```

## URL结构

部署后的URL结构：

- **API端点**: https://html.weburl.cloudns.be/publish.php
- **项目管理**: https://html.weburl.cloudns.be/api/projects.php
- **已发布项目**: https://html.weburl.cloudns.be/pub/{project_id}/index.html
- **短链访问**: https://html.weburl.cloudns.be/p/{slug}

## 验证清单

部署完成后，逐项验证：

### 服务器端验证

```bash
# 1. 检查文件结构
ls -la /path/to/html.weburl.cloudns.be/
# 应该看到: publish.php, api/, database/, pub/, .env

# 2. 检查pub目录权限
ls -ld /path/to/html.weburl.cloudns.be/pub/
# 应该是: drwxrwxrwx

# 3. 测试PHP
curl https://html.weburl.cloudns.be/test_publish.php

# 4. 测试数据库连接
curl https://html.weburl.cloudns.be/test/db_test.php

# 5. 测试API（返回403正常）
curl -I https://html.weburl.cloudns.be/publish.php
```

### iOS应用验证

1. ✅ 重新构建应用（Clean Build Folder）
2. ✅ 创建测试项目
3. ✅ 点击发布
4. ✅ 检查返回的URL格式
5. ✅ 访问URL验证内容

### 功能验证

- [ ] 发布新项目
- [ ] 更新已发布项目
- [ ] 自定义短链
- [ ] 设置过期时间
- [ ] 设置访问密码
- [ ] 查看访问统计
- [ ] 删除项目
- [ ] 短链访问

## 常见问题

### Q1: 上传后返回500错误

**检查**:
```bash
# 查看PHP错误日志
tail -f /var/log/php/error.log

# 检查.env文件格式
cat .env
```

**解决**: 确保.env文件格式正确，没有多余空格

### Q2: 文件上传失败

**检查**:
```bash
# 检查pub目录权限
ls -ld pub/
chmod 777 pub/
```

### Q3: 数据库连接失败

**检查**:
```bash
# 测试数据库连接
mysql -h localhost -u user -p database_name -e "SELECT 1"

# 检查.env配置
cat .env
```

### Q4: 短链访问404

**原因**: 需要配置URL重写

**解决**: 创建 `.htaccess` 文件：

```apache
# .htaccess
RewriteEngine On

# 短链重写规则
RewriteRule ^p/([a-zA-Z0-9_-]+)$ p/index.php?slug=$1 [L,QSA]

# 或者使用redirect.php
RewriteRule ^p/([a-zA-Z0-9_-]+)$ redirect.php?slug=$1 [L,QSA]
```

### Q5: CORS错误

**解决**: 在 `publish.php` 顶部确保有：

```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');
```

## 安全建议

1. **HTTPS**: 已使用 ✅
2. **API密钥**: 定期更换
3. **.env保护**: `chmod 600 .env`
4. **目录权限**: 最小权限原则
5. **错误日志**: 不要暴露给公众
6. **备份**: 定期备份数据库和文件

## 回滚计划

如果部署出现问题：

```bash
# 1. 备份当前文件
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz .

# 2. 恢复之前的版本
tar -xzf previous_version.tar.gz

# 3. 恢复数据库
mysql -u user -p database_name < backup.sql
```

## 监控

部署后建议设置监控：

```bash
# 创建健康检查端点
# health.php
<?php
echo json_encode([
    'status' => 'ok',
    'timestamp' => time(),
    'php_version' => PHP_VERSION
]);
?>

# 定期检查
curl https://html.weburl.cloudns.be/health.php
```

---

**准备好部署了吗？**

1. 先运行我提供的部署脚本
2. 或者手动执行上述步骤
3. 有问题随时告诉我！
