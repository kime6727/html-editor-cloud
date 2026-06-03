# Code Editor – HTML & Preview - 完整需求文档

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

### 1.3 订阅 / Paywall

| 项目 | 值 |
|------|---|
| **订阅模式** | 一次性买断（Lifetime，非周期订阅） |
| **App Store Product ID** | `CodeEditor_999` |
| **解锁权益** | 解除每月发布次数限制、解除访问密码设置限制、解除到期时间上限 |

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
- **自动生成**：App首次启动时自动生成唯一用户ID
- **格式**：`usr_{时间戳后6位}_{UUID前8位}`
- **存储**：UserDefaults（卸载重装会重新生成）
- **用途**：
  - 云端发布时标识用户身份
  - 运营后台追踪用户行为
  - 用户管理（封禁/解封）

### 2.2 用户在App中查看
- 位置：我的页面 → 用户账户区域
- 功能：查看用户ID + 一键复制到剪贴板

---

## 三、订阅与发布逻辑

### 3.1 免费用户
- **项目数量限制**：最多创建5个项目
- **发布次数限制**：每月1次免费发布
- **发布有效期**：5分钟
- **到期后行为**：
  - 访问URL显示"页面已到期"
  - 页面引导用户下载App或访问官网

### 3.2 Pro用户
- **项目数量**：无限制
- **发布次数**：无限制
- **发布有效期**：永久（或自定义天数）
- **额外功能**：
  - 高级模板
  - 优先支持

### 3.3 订阅类型
- **终身订阅**：一次性付费，永久Pro权限
- **价格**：根据App Store配置

---

## 四、云端发布系统

### 4.1 发布流程
1. 用户点击"发布"按钮
2. App检查订阅状态
3. 打包项目文件（支持多文件）
4. 发送multipart/form-data到 `/publish.php`
5. 携带参数：
   - `user_id`: 用户ID
   - `is_pro`: 是否Pro用户（0或1）
   - `expire_days`: 过期天数（Pro用户可自定义）
   - `expire_minutes`: 过期分钟数（免费用户强制5分钟）
   - `is_update`: 是否更新已有项目

### 4.2 后端处理（publish.php）
1. **验证API签名**：HMAC-SHA256验证
2. **强制限制免费用户**：
   - 验证后端用户数据中的 `is_pro` 状态
   - 如果免费用户未设置过期时间，强制5分钟过期
   - 不接受客户端伪造的 `is_pro=1`
3. **保存文件**：到 `../pub/{project_id}/` 目录
4. **保存元数据**：到数据库
5. **记录用户活动**：到数据库

### 4.3 访问已发布页面
- URL格式：`https://domain/p/{project_id}`
- 访问计数器：记录到数据库
- 到期检查：访问时检查 `expires_at` 时间
- 到期页面：显示到期提示 + App下载引导

---

## 五、运营后台

### 5.1 登录认证
- URL：`/backend/admin.php`
- 账号密码：从 `.env` 文件读取

### 5.2 项目列表
- **统计卡片**：
  - 总发布链接数
  - 总访问量
  - 今日访问量
  - Pro发布数
- **功能**：
  - 搜索（项目名、ID、用户ID）
  - 排序（最近更新、创建时间、访问量、项目名）
  - 分页（每页50条）
  - 批量删除
  - 导出CSV

### 5.3 高级筛选
- **时间范围**：今日/本周/本月/自定义
- **过期状态**：已过期/即将过期(7天)/永久有效/有效
- **访问热度**：0访问/1-100/100-1000/1000+
- **文件数量**：单文件/2-5/6+
- **用户类型**：Pro用户/免费用户
- **保存筛选**：命名保存，快速加载

### 5.4 用户管理
- **用户列表**：
  - 用户ID（头像 + 缩短显示）
  - 订阅状态（Pro/免费）
  - 发布次数
  - 总访问量
  - 最后活跃时间
  - 注册时间
- **用户详情**：
  - 基本信息
  - 所有发布项目列表
  - 活动记录（最近100条）
  - 封禁/解封操作
- **封禁功能**：
  - 选择封禁原因
  - 存储到 `/tmp/ce_banned_users.json`

### 5.5 数据持久化
**当前问题**：所有数据存储在 `/tmp/` 目录，服务器重启后会丢失！

**需要改进**：
- 用户数据：使用SQLite数据库或持久化目录
- 元数据：使用MySQL/SQLite
- 访问日志：定期归档到持久化存储

---

## 六、访问页面到期逻辑

### 6.1 未到期页面
正常渲染HTML内容

### 6.2 已到期页面
```html
<!DOCTYPE html>
<html>
<head>
  <title>页面已到期</title>
  <style>
    /* 美观的到期提示页面 */
  </style>
</head>
<body>
  <div class="expired-container">
    <h1>⏰ 页面已到期</h1>
    <p>此HTML页面的有效期已过</p>
    <a href="https://apps.apple.com/app/id{appStoreID}" class="download-btn">
      下载App永久保存
    </a>
    <a href="https://html.niceapp.eu.cc/" class="website-btn">
      访问官网
    </a>
  </div>
</body>
</html>
```

---

## 七、已发现问题与待修复

### 7.1 当前存在的问题

#### 🔴 严重问题
1. **运营后台无用户数据**
   - 原因：客户端发送 `user_id` 但后端可能未正确接收
   - 影响：无法追踪用户行为
   - 优先级：P0

2. **到期页面未实现**
   - 原因：访问页面时未检查过期状态
   - 影响：到期页面仍可访问，失去限制意义
   - 优先级：P0

3. **数据存储位置不安全**
   - 所有数据在 `/tmp/` 目录
   - 服务器重启后丢失
   - 优先级：P1

#### 🟡 中等问题
4. **免费用户发布限制可能被绕过**
   - 客户端发送 `is_pro` 可能被伪造
   - 后端需要强制验证

5. **发布成功后未同步统计**
   - 已发布列表不会立即更新

---

## 八、技术栈

### 8.1 iOS客户端
- **框架**：SwiftUI
- **部署目标**：iOS 16+
- **关键库**：
  - StoreKit2（订阅管理）
  - WebKit（预览）
  - ZIPFoundation（ZIP处理）

### 8.2 后端
- **语言**：PHP 7.4+
- **服务器**：Apache/Nginx
- **存储**：文件系统 + JSON文件（待改进为数据库）

---

## 九、文件结构

```
项目根目录/
├── ios/                          # iOS客户端代码
│   ├── AppConfig.swift
│   ├── CloudService.swift        # 云端服务
│   ├── DocumentManager.swift     # 项目管理
│   ├── Models.swift              # 数据模型
│   ├── LanguageManager.swift     # 多语言
│   ├── PublishedProjectsManager.swift
│   ├── SubscriptionManager.swift # 订阅管理
│   ├── UserManager.swift         # 用户管理
│   └── ...
├── backend/                      # 后端代码
│   ├── .env                      # 环境变量
│   ├── admin.php                 # 运营后台
│   ├── publish.php               # 发布API
│   ├── stats.php                 # 统计API
│   └── delete.php                # 删除API
└── pub/                          # 发布文件存储目录
```

---

## 十、下一步计划

### 10.1 立即修复（本次）
- [ ] 修复运营后台无用户数据问题
- [ ] 实现到期页面显示逻辑
- [ ] 完善免费用户5分钟过期限制

### 10.2 短期优化
- [ ] 迁移数据存储到持久化目录
- [ ] 添加数据库支持（SQLite/MySQL）
- [ ] 完善错误处理和日志

### 10.3 长期规划
- [ ] 用户数据仪表盘
- [ ] 访问分析（地域、设备、时段）
- [ ] 自动化运营工具

---

**文档版本**：v1.0  
**最后更新**：2026-05-06  
**维护者**：开发团队
