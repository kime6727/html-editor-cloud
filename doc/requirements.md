# Code Editor – HTML & Preview - 完整需求文档

> **本文档为 v3.2.1（2026-06-03）版本**，已与代码、数据库、API 同步。如发现不一致请以代码为准并更新本文档。

## 一、产品概述

**Code Editor – HTML & Preview** 是一款专业的 iOS HTML 编辑与云端发布 App，让开发者、设计师和创作者能够在移动设备上快速编写、预览和发布 HTML 项目。

### 1.1 产品元信息

| 项目 | 值 |
|------|---|
| **App 名称（App Store）** | Code Editor – HTML & Preview |
| **Bundle Identifier** | `com.niceapp.htmleditor` |
| **Apple ID** | `6764022927` |
| **App Store 下载（中国区）** | https://apps.apple.com/CN/app/id6764022927 |
| **App 官网** | https://page.niceapp.eu.cc/apps/code_editor |
| **最低 iOS 版本** | iOS 17.0 |
| **开发语言** | Swift（SwiftUI + UIKit） |
| **Web 渲染引擎** | WKWebView |
| **支持的平台** | iPhone / iPad |
| **本地化** | 中文（简体 / 繁体）、英文 |

### 1.2 后端与基础设施

| 项目 | 值 |
|------|---|
| **后端代码仓库** | https://github.com/kime6727/html-editor-cloud |
| **后端部署方式** | Dokploy |
| **后端生产域名** | https://html.niceapp.eu.cc |
| **后端技术栈** | PHP 7.4+ / MySQL 5.7+（含 MySQL 8.0 兼容） |
| **静态资源托管** | 部署包 `pub/{project_id}/index.html` 目录直出 |
| **鉴权** | HMAC-SHA256 over `apiKey + timestamp`，±300 秒时间窗 |

### 1.3 订阅 / Paywall

| 项目 | 值 |
|------|---|
| **订阅模式** | 一次性买断（Lifetime，非周期订阅） |
| **App Store Product ID** | `CodeEditor_999` |
| **解锁权益** | 解除每月发布次数限制、解除访问密码设置限制、解除到期时间上限、Pro 专属到期行为配置 |

### 1.4 协议与支持

| 项目 | 链接 |
|------|------|
| **用户服务协议** | https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html |
| **隐私政策** | https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html |
| **在线客服** | https://page.niceapp.eu.cc/index.php/archives/13.html |
| **支持邮箱** | fengezhao@hotmail.com |

### 1.5 GitHub Pages 集成（可选发布渠道）

| 项目 | 值 |
|------|---|
| **GitHub 账号** | `@kime6727` |
| **授权 Scope** | `repo`（含 public_repo 即可发布到 public repo） |
| **发布方式** | 客户端直接调用 GitHub Contents API（`PUT /repos/{owner}/{repo}/contents/...`），无需后端代理 |
| **凭证保护** | 🔒 Personal Access Token **必须**存放在 iOS Keychain；不允许写入 Info.plist、`.env`、代码或本文档 |

> ⚠️ **安全策略**：任何 Personal Access Token 都不应出现在仓库 / 文档 / 构建产物中。如不慎泄露，立即到 https://github.com/settings/tokens 撤销。

---

## 二、用户系统

### 2.1 用户ID管理
- **自动生成**：App 首次启动时自动生成唯一用户 ID
- **格式**：`usr_{时间戳后6位}_{UUID前8位}`
- **存储**：UserDefaults（卸载重装会重新生成）
- **用途**：
  - 云端发布时标识用户身份
  - 运营后台追踪用户行为
  - 用户管理（封禁 / 解封）

### 2.2 用户在 App 中查看
- 位置：我的页面 → 用户账户区域
- 功能：查看用户 ID + 一键复制到剪贴板

---

## 三、订阅与发布逻辑

### 3.1 免费用户
- **项目数量**：客户端软上限 **5 个**（`SubscriptionManager.canCreateProject` 检查；服务端不强制）
- **发布次数**：每月 **3 次**（由 `system_config.free_user_monthly_publish_limit` 控制，iOS / PHP 各自读这个值，可调整）
- **发布有效期**：服务端默认强制 **1 小时（60 分钟）** 过期（`publish.php` 中 `if (!$is_pro && $expire_days === 0 && $expire_minutes === 0) { $expire_minutes = 60; }` 兜底）
- **到期后行为**：仅默认 App 引导页（无法自定义 URL / 消息）
- **可设密码**：❌ Pro 专属

### 3.2 Pro 用户
- **项目数量**：无限制
- **发布次数**：无限制
- **发布有效期**：可选择 7 天 / 30 天 / 90 天 / 永不过期
- **额外功能**：
  - 访问密码保护（bcrypt 存储，5 次错误锁定 15 分钟）
  - 自定义到期行为（跳转 URL / 自定义消息 / 默认 App 引导）
  - 批量管理（`batch_operation` API）

### 3.3 订阅类型
- **终身订阅（Lifetime）**：一次性付费，永久 Pro 权限
- **价格**：根据 App Store 配置（Product ID `CodeEditor_999`）

---

## 四、云端发布系统

### 4.1 发布流程
1. 用户点击「发布」按钮
2. App 检查订阅状态
3. 打包项目文件（支持多文件 / 二进制 / 嵌套目录）
4. 发送 `multipart/form-data` 到 `/publish.php`
5. 携带参数：
   - `user_id`：用户 ID
   - `is_pro`：是否 Pro 用户（仅作记录，后端会二次校验 `users.is_pro`）
   - `expire_days` / `expire_minutes`：过期时间（Pro 可自定义；免费用户不传则后端强制 60 分钟）
   - `access_password`：访问密码（Pro 可选，bcrypt 存储）
   - `is_update`：是否更新已有项目（`id` 同 `project_id`）

### 4.2 后端处理（`publish.php`）
1. **HMAC 验证**：X-API-Key / X-Timestamp / X-Signature 三件套
2. **速率限制**：30 req/min per IP+API Key
3. **强制限制免费用户**：
   - 不接受客户端伪造的 `is_pro=1`（以 `users` 表为准）
   - 月度发布次数检查（`system_config.free_user_monthly_publish_limit`）
4. **保存文件**：到 `pub/{project_id}/` 目录（临时 staging → 原子 rename）
5. **保存元数据**：到 `projects` 表（事务）
6. **记录用户活动**：到 `user_activity_logs` 表

### 4.3 访问已发布页面

- **访问入口**：`https://html.niceapp.eu.cc/pub/{project_id}/index.html`
- **访问网关**：`index.php`
  - 检查 `status`（`deleted` / `banned` → 404 + 过期模板）
  - 检查 `expires_at`（过期 → 410 + 到期模板 / 跳转 / 自定义消息）
  - 检查 `access_password`（bcrypt 校验；session 缓存；5 次错误锁定 15 分钟）
  - 写入 `visit_logs`（脱敏 IP + IP hash + UA + Referer）
  - 自增 `projects.visit_count`

### 4.4 已移除 / 未实现
- ❌ 自定义短链（`custom_slug` 字段保留在 schema，但 API 未暴露路由）
- ❌ 临时访问链接
- ❌ 短链接生成（链接就是 `pub/{project_id}/index.html`）
- ❌ 自定义域名

---

## 五、运营后台

### 5.1 登录认证
- URL：`/admin.php`
- 账号密码：从 `.env` 文件读取（`ADMIN_USER` / `ADMIN_PASS`）

### 5.2 项目列表
- **统计卡片**：总发布链接数 / 总访问量 / 今日访问量 / Pro 发布数
- **功能**：搜索 / 排序 / 分页 / 批量删除 / 导出 CSV

### 5.3 高级筛选
- 时间范围 / 过期状态 / 访问热度 / 文件数量 / 用户类型 / 保存筛选

### 5.4 用户管理
- 用户列表 + 详情 + 封禁 / 解封（写入 `users.is_banned`）

### 5.5 数据持久化
- **数据库**：MySQL 5.7+ / 8.0（utf8mb4_unicode_ci，pconnect 长连接）
- **核心表**：`users` / `projects` / `visit_logs` / `user_activity_logs` / `admin_logs` / `system_config`
- **审计日志**：`admin_logs` 记录管理员操作

---

## 六、访问页面到期逻辑

### 6.1 未到期页面
- 正常渲染 `pub/{project_id}/index.html`（Cache-Control: no-cache）

### 6.2 已到期页面
- **默认**：显示 `expired_template.html`（含 App 下载引导 + 官网链接）
- **Pro 自定义**：
  - `expired_redirect_type = custom_url` → 302 跳转到 `expired_redirect_url`
  - `expired_redirect_type = custom_message` → 渲染 `expired_custom_message`
  - `expired_redirect_type = app_promotion` → 默认引导

### 6.3 密码保护页面
- 显示 `password_prompt.html`（POST 到自身 `?action=verify_password`）
- 错误密码计数（session）：5 次 → 锁定 15 分钟

---

## 七、数据库 Schema（v3.2）

详细 DDL 见 [`deploy_package/database/init_mysql84.sql`](file:///Volumes/ssd/aicode_new0421/ioscode/zaixianhtml/deploy_package/database/init_mysql84.sql)。

| 表 | 用途 | 关键字段 |
|---|---|---|
| `users` | 用户 | user_id, is_pro, publish_count, total_visits, is_banned |
| `projects` | 项目 | project_id, user_id, project_name, visit_count, expires_at, access_password, expired_redirect_type |
| `visit_logs` | 访问日志 | project_id, ip_address (脱敏), ip_hash, user_agent, referer, visited_at |
| `user_activity_logs` | 用户活动审计 | user_id, action, details, project_id |
| `admin_logs` | 管理员审计 | admin_user, action, target_type, target_id |
| `system_config` | 配置 | config_key, config_value, description |

### 7.1 关键 system_config 项

| config_key | 默认值 | 用途 |
|---|---|---|
| `free_user_monthly_publish_limit` | `3` | 免费用户每月发布次数 |

### 7.2 v3.2 已清理（迁移脚本：`migration_v3.2_cleanup.sql`）
- ❌ `daily_stats` / `subscription_records` / `temp_access_links` / `project_ip_rules` / `project_comments` / `tags` / `categories` / `project_tags`
- ❌ 视图 `v_user_stats` / `v_project_stats` / `v_project_full` / `v_daily_summary` / `v_referrer_stats`
- ❌ 存储过程 / 事件
- ❌ `visit_logs.country / city / device_type / browser / os`
- ❌ `projects.thumbnail / thumbnail_url / temp_link_*`

---

## 八、技术栈

### 8.1 iOS 客户端
- **框架**：SwiftUI + UIKit（MVVM + Combine + ObservableObject）
- **部署目标**：iOS 17.0+
- **关键库**：
  - WebKit（WKWebView 预览）
  - CryptoKit（HMAC-SHA256）
  - StoreKit（订阅）
  - LocalAuthentication（Keychain 守卫）
  - ZIPFoundation（Zip 导出）
- **网络**：URLSession + Network.framework

### 8.2 后端
- **语言**：PHP 7.4+（推荐 8.0+）
- **服务器**：Nginx + PHP-FPM（Dokploy 容器化）
- **存储**：MySQL 5.7+（utf8mb4_unicode_ci，pconnect 长连接）+ 文件系统（`pub/{project_id}/`）
- **静态资源**：Nginx `alias` 直出 `deploy_package/pub/`

---

## 九、文件结构

```
zaixianhtml/
├── 📱 iOS 客户端
│   └── ios/                        # Swift 工程（HTMLPreview.xcodeproj）
│       ├── AppConfig.swift
│       ├── CloudService.swift      # 云端 API 客户端
│       ├── CloudProjectManager.swift
│       ├── DocumentManager.swift
│       ├── Models.swift
│       ├── LanguageManager.swift
│       ├── PublishedProjectsManager.swift
│       ├── SubscriptionManager.swift
│       ├── UserManager.swift
│       ├── GitHubPublishService.swift
│       ├── HMACAuth.swift
│       └── ...
│
├── 🖥️ 后端部署包
│   └── deploy_package/             # 同步到 Dokploy
│       ├── api/
│       │   └── projects.php        # 统一项目管理 API（13 个 action）
│       ├── database/
│       │   ├── Database.php
│       │   ├── init.sql            # 通用初始化
│       │   ├── init_mysql57.sql    # MySQL 5.7 兼容
│       │   ├── init_mysql84.sql    # MySQL 8.0 初始化
│       │   ├── init_external.sql   # 已有库的增量更新
│       │   ├── migration_v3_final.sql
│       │   └── migration_v3.2_cleanup.sql
│       ├── pub/                    # 用户发布的项目（直出静态资源）
│       ├── test/                   # 测试脚本
│       ├── publish.php             # 上传 / 发布 API
│       ├── index.php               # 项目访问网关
│       ├── admin.php               # 运营后台
│       ├── stats.php               # 公共统计
│       ├── sync_user.php           # iOS → 后端同步 Pro 状态
│       ├── expire_cron.php         # 过期清理 cron
│       ├── expired.php
│       ├── expired_template.html
│       ├── password_prompt.html
│       ├── delete.php
│       ├── nginx.conf
│       ├── .env.example
│       └── DEPLOY_INSTRUCTIONS.txt
│
├── 🐳 容器化
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose-external.yml
│   ├── docker/
│   ├── nginx/default.conf
│   └── .env.docker
│
├── 📚 文档
│   ├── README.md
│   ├── doc/
│   │   ├── CHANGELOG.md
│   │   ├── QUICK_START.md
│   │   ├── SHARING_GUIDE.md
│   │   ├── PROJECT_SUMMARY.md
│   │   ├── requirements.md   # 本文件
│   │   ├── DEPLOYMENT.md
│   │   └── API.md
│   └── web/
│
└── 🏗️ 配置
    ├── .env.example
    ├── .gitignore
    └── test_publish_api.sh
```

---

## 十、变更记录

| 版本 | 日期 | 摘要 |
|---|---|---|
| v3.2.2 | 2026-06-03 | 文档补完：README 新增"前后端 API 衔接"全量映射表，订阅章节细化免费三段限制 |
| v3.2.1 | 2026-06-03 | 文档同步：移除已实现的"5 项目 / 1 次 / 5 分钟"等过时描述，统一为"3 次 / 月 + 1 小时"；删除 CLOUD_PUBLISH_ANALYSIS.md |
| v3.2.0 | 2026-06-02 | 数据库 / API / iOS 死代码清理（详见 CHANGELOG） |
| v3.0.0 | 2026-05-20 | HMAC 鉴权 / MySQL 持久化 / IP 匿名化 / bcrypt 密码 |
| v2.0.0 | 2026-05-15 | 云端发布 / 访问统计 / 访问密码 / 订阅 / GitHub Pages |
| v1.0.0 | 2024-04-22 | 初版：本地编辑 + 实时预览 |

---

**文档版本**：v3.2.1  
**最后更新**：2026-06-03  
**维护者**：开发团队
