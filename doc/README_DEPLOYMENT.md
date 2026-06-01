# 🚀 生产环境部署指南

## 📋 概述

本项目后端采用 **GitHub + Dokploy** 自动化部署方案，推送代码到 GitHub 后 Dokploy 自动检测变更并完成部署。

| 项目 | 说明 |
|------|------|
| **GitHub 仓库** | [kime6727/html-editor-cloud](https://github.com/kime6727/html-editor-cloud) |
| **目标服务器** | https://html.weburl.cloudns.be |
| **服务器环境** | PHP + MySQL |
| **部署平台** | Dokploy（自动检测 GitHub 更新） |
| **后端目录** | `deploy_package/`（网站根目录） |

---

## 🔄 部署架构

```
开发者本地
    │
    │ git push
    ▼
GitHub (main 分支)
    │
    │ Dokploy 自动检测
    ▼
Dokploy 部署平台
    │
    │ 拉取最新代码 → 同步到服务器
    ▼
https://html.weburl.cloudns.be
```

---

## 🎯 日常部署流程（推荐）

### 后端代码变更后，只需一步：

```bash
# 1. 提交后端代码
git add deploy_package/
git commit -m "feat(api): 描述你的修改"
git push origin main
```

Dokploy 会自动检测到 GitHub 仓库有新的推送，然后自动拉取最新代码并部署到服务器。**无需手动 SCP、FTP 或 SSH 登录服务器。**

### 部署触发时机

- ✅ 任何推送到 `main` 分支的提交都会触发 Dokploy 自动部署
- ✅ Dokploy 轮询 GitHub 仓库，检测到新 commit 后自动拉取
- ✅ 部署完成后即可通过 https://html.weburl.cloudns.be 验证

---

## 📂 目录结构（线上）

```
服务器根目录 (deploy_package/)
├── .env                       # 环境变量（数据库配置、API Key）
├── .htaccess                  # Apache URL 重写规则
├── publish.php                # 发布 API
├── delete.php                 # 删除 API
├── redirect.php               # 短链跳转
├── index.php                  # 发布页面入口
├── test_publish.php           # 诊断脚本
├── api/
│   └── projects.php           # 项目管理 API
├── pub/                       # 已发布项目（需 777 权限）
│   └── {project_id}/
│       └── index.html
├── test/                      # 测试脚本
│   └── db_test.php
├── database/
│   └── schema.sql
└── expire_cron.php            # 过期项目清理定时任务
```

---

## ⚙️ 首次部署配置

### 1. 环境变量（.env）

在服务器上配置 `deploy_package/.env`：

```env
DB_HOST=localhost
DB_NAME=html_editor
DB_USER=your_db_user
DB_PASS=your_db_password
PUBLISH_API_KEY=f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9
```

> ⚠️ `.env` 文件包含敏感信息，已在 `.gitignore` 中排除，不会推送到 GitHub。首次部署需手动在服务器上创建。

### 2. 目录权限

```bash
chmod 777 pub/          # 发布目录必须可写
chmod 600 .env          # 保护敏感配置
```

### 3. 数据库初始化

```bash
mysql -u user -p html_editor < database/schema.sql
```

### 4. Dokploy 配置

在 Dokploy 管理面板中：

1. 创建新应用，选择 **GitHub** 作为源
2. 关联仓库 `kime6727/html-editor-cloud`
3. 设置分支：`main`
4. 配置服务器路径指向 `deploy_package/`
5. 开启自动部署（Auto Deploy）

---

## 🧪 部署后验证

```bash
# 1. 诊断脚本
curl https://html.weburl.cloudns.be/test_publish.php

# 2. API 测试（返回 403 表示安全机制正常）
curl -I https://html.weburl.cloudns.be/publish.php

# 3. 数据库连接测试
curl https://html.weburl.cloudns.be/test/db_test.php

# 4. 访问已发布页面
curl -I https://html.weburl.cloudns.be/pub/{project_id}/index.html
```

---

## 🔑 关键配置说明

### 路径配置

由于线上域名绑定到 `deploy_package/` 目录作为网站根目录，所有 PHP 文件中的路径已适配：

```php
// 线上路径（同级）
$pubDir = $scriptDir . '/pub/';

// 本地开发路径（上一级）
// $pubDir = $scriptDir . '/../pub/';
```

### URL 结构

```
https://html.weburl.cloudns.be/
├── publish.php              # 发布 API
├── api/projects.php         # 项目管理 API
├── redirect.php             # 短链跳转
├── pub/                     # 已发布项目
│   └── {project_id}/
│       └── index.html
└── p/{slug}                 # 短链访问（需 URL 重写）
```

### iOS 客户端配置

iOS 客户端的 API 地址指向线上服务器（`CloudService.swift`）：

```swift
static let baseURL = "https://html.weburl.cloudns.be"
```

---

## 🔄 过期项目清理

服务器配置了定时任务自动清理过期项目：

```bash
# 每隔 5 分钟执行一次
*/5 * * * * php /path/to/deploy_package/expire_cron.php
```

`expire_cron.php` 会：
1. 查找 `expires_at < NOW()` 且状态为 `active` 的项目
2. 备份原始 HTML 文件为 `.bak`
3. 替换为过期提示页面
4. 更新数据库状态为 `expired`

> 访问层面由 `index.php` 实时拦截过期链接，返回 HTTP 410。

---

## 🆘 常见问题

### Q1: 推送后 Dokploy 没有自动部署

**检查**：
- Dokploy 面板中 Auto Deploy 是否开启
- GitHub Webhook 是否配置正确
- Dokploy 与 GitHub 的连接是否正常

### Q2: 部署后 API 返回 500

**检查**：
- 服务器上 `.env` 文件是否存在且格式正确
- 数据库连接是否正常
- PHP 错误日志

### Q3: 发布成功但页面访问 404

**检查**：
- `pub/` 目录权限是否为 `777`
- 文件是否真正写入到 `pub/` 目录
- 服务器磁盘空间是否充足

### Q4: 数据库连接失败

**检查**：
- `.env` 配置与服务器数据库是否一致
- 数据库用户权限是否足够

### Q5: iOS 应用发布失败

**检查**：
- Xcode 控制台错误信息
- API Key 是否与服务器 `.env` 中的 `PUBLISH_API_KEY` 一致
- 网络是否能访问 `https://html.weburl.cloudns.be`

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| `DEPLOY_TO_PRODUCTION.md` | 手动部署详细步骤（备用方案） |
| `PRODUCTION_DEPLOYMENT_CHECKLIST.md` | 部署检查清单 |
| `CLOUD_PUBLISH_FIXES_COMPLETE.md` | 云端发布功能修复报告 |
| `产品前后端功能完整性分析.md` | 功能完整性分析 |

---

## 🎉 部署成功标志

1. ✅ `test_publish.php` 返回诊断信息
2. ✅ iOS 应用发布成功并返回 URL
3. ✅ 返回 URL 格式：`https://html.weburl.cloudns.be/pub/{project_id}/index.html`
4. ✅ 点击 URL 正常访问，内容和样式正确
5. ✅ Dokploy 面板显示部署成功