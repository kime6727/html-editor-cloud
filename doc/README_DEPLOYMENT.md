# 🚀 生产环境部署 - 快速开始

## 📋 概述

本指南帮助你将云端发布功能部署到生产服务器：
- **目标服务器**: https://html.weburl.cloudns.be
- **服务器环境**: PHP + MySQL
- **域名绑定**: `/backend` 目录作为网站根目录

## ✅ 已完成的准备工作

1. ✅ **路径配置已调整** - 所有文件路径已适配线上目录结构
2. ✅ **部署包已生成** - `production_deploy.tar.gz` 可直接上传
3. ✅ **iOS配置已恢复** - 指向线上服务器地址
4. ✅ **所有功能已修复** - 13个问题全部解决

## 🎯 三步快速部署

### 步骤1：配置数据库（1分钟）

```bash
# 编辑数据库配置
nano deploy_package/.env
```

填入你的数据库信息：
```env
DB_HOST=localhost
DB_NAME=你的数据库名
DB_USER=你的数据库用户
DB_PASS=你的数据库密码
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
```

### 步骤2：上传到服务器（2分钟）

```bash
# 使用SCP上传
scp production_deploy.tar.gz user@server:/path/to/html.weburl.cloudns.be/

# 或者使用FTP客户端（FileZilla等）上传
```

### 步骤3：在服务器上部署（3分钟）

SSH登录服务器后执行：

```bash
# 进入网站目录
cd /path/to/html.weburl.cloudns.be/

# 解压文件
tar -xzf production_deploy.tar.gz

# 设置权限
chmod 777 pub/
chmod 600 .env

# 导入数据库（如果需要）
mysql -u user -p database_name < database/schema.sql

# 测试
curl https://html.weburl.cloudns.be/test_publish.php
```

## 🧪 测试验证

### 服务器测试

```bash
# 1. 诊断脚本
curl https://html.weburl.cloudns.be/test_publish.php

# 2. API测试（返回403正常）
curl -I https://html.weburl.cloudns.be/publish.php

# 3. 数据库测试
curl https://html.weburl.cloudns.be/test/db_test.php
```

### iOS应用测试

1. 在Xcode中 Clean Build Folder (`⇧⌘K`)
2. 运行应用 (`⌘R`)
3. 创建测试项目并发布
4. 验证返回的URL可以访问

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `production_deploy.tar.gz` | 生产环境部署包（已调整路径） |
| `deploy_package/` | 解压后的文件目录 |
| `prepare_production.sh` | 自动生成部署包的脚本 |
| `PRODUCTION_DEPLOYMENT_CHECKLIST.md` | 详细部署检查清单 |
| `DEPLOY_TO_PRODUCTION.md` | 完整部署文档 |
| `CLOUD_PUBLISH_FIXES_COMPLETE.md` | 功能修复报告 |

## 🔧 关键修改说明

### 路径调整

由于线上域名绑定到 `/backend` 目录，所有路径已从：
```php
$pubDir = $scriptDir . '/../pub/';  // 本地：上一级目录
```

调整为：
```php
$pubDir = $scriptDir . '/pub/';     // 线上：同级目录
```

### 修改的文件

- ✅ `publish.php` - 发布API
- ✅ `api/projects.php` - 项目管理API
- ✅ `redirect.php` - 短链跳转
- ✅ `delete.php` - 删除功能

### URL结构

部署后的URL结构：
```
https://html.weburl.cloudns.be/
├── publish.php              # 发布API
├── api/projects.php         # 项目管理API
├── redirect.php             # 短链跳转
├── pub/                     # 已发布项目
│   └── {project_id}/
│       └── index.html
└── p/{slug}                 # 短链访问（需要URL重写）
```

## ⚠️ 重要提示

### 必须配置的项

1. **数据库信息** - 编辑 `.env` 文件
2. **pub目录权限** - 必须设置为 `777`
3. **数据库结构** - 导入 `schema.sql`

### 可选配置

1. **URL重写** - 配置短链访问（`.htaccess` 或 Nginx配置）
2. **OPcache** - 提升PHP性能
3. **Gzip压缩** - 减少传输大小
4. **定时清理** - 自动清理过期项目

## 🆘 常见问题

### Q1: 上传后返回500错误

**检查**：
- PHP错误日志
- .env文件格式
- 数据库连接

### Q2: 发布成功但访问404

**检查**：
- pub目录是否存在
- 文件是否真正上传
- 权限是否正确（777）

### Q3: 数据库连接失败

**检查**：
- .env配置是否正确
- 数据库是否已创建
- 用户权限是否足够

### Q4: iOS应用发布失败

**检查**：
- Xcode控制台错误信息
- 网络连接
- API Key是否一致

## 📚 详细文档

- **完整部署流程**: `PRODUCTION_DEPLOYMENT_CHECKLIST.md`
- **部署详细说明**: `DEPLOY_TO_PRODUCTION.md`
- **功能修复报告**: `CLOUD_PUBLISH_FIXES_COMPLETE.md`
- **故障排查指南**: `DEPLOYMENT_CHECKLIST.md`

## 🎉 部署成功标志

当你看到以下情况，说明部署成功：

1. ✅ `test_publish.php` 返回诊断信息
2. ✅ iOS应用发布成功
3. ✅ 返回URL格式：`https://html.weburl.cloudns.be/pub/xxxxx/index.html`
4. ✅ 点击URL能正常访问
5. ✅ 内容和样式都正确显示

## 📞 需要帮助？

如果遇到问题：

1. 查看 `PRODUCTION_DEPLOYMENT_CHECKLIST.md` 中的故障排查部分
2. 检查服务器错误日志
3. 运行诊断脚本：`curl https://html.weburl.cloudns.be/test_publish.php`

---

**准备好了吗？开始部署吧！** 🚀

按照上面的三个步骤，6分钟内即可完成部署！
