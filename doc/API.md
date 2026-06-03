# 后端 API 参考

> **Base URL**: `https://html.niceapp.eu.cc`
> **认证**: HMAC-SHA256（5 分钟时间窗）
> **日期**: 2026-06-03 / v3.2.1
> **统一管理入口**：`/api/projects.php`（13 个 action）

---

## 一、鉴权（所有 API 必须）

### 1.1 HMAC 签名算法

```
stringToSign = apiKey + timestamp
signature    = HMAC-SHA256(stringToSign, secret)
```

### 1.2 必传 Header

| Header | 含义 |
|--------|------|
| `X-API-Key` | PUBLISH_API_KEY |
| `X-Timestamp` | Unix 时间戳（秒），±300 秒有效 |
| `X-Signature` | 上述 signature 的 hex 编码 |

### 1.3 iOS 实现
- [ios/HMACAuth.swift](file:///Volumes/ssd/aicode_new0421/ioscode/zaixianhtml/ios/HMACAuth.swift) — `applyHeaders(to:)`
- [deploy_package/publish.php](file:///Volumes/ssd/aicode_new0421/ioscode/zaixianhtml/deploy_package/publish.php) — 验证逻辑

---

## 二、错误码

| code | 含义 | HTTP | 实际来源 |
|------|------|------|------|
| `ok` / `success` / `status: success` | 成功 | 200 | 所有端点 |
| `invalid_signature` | API Key / 签名错误 | 403 | `publish.php` / `api/projects.php` |
| `timestamp_expired` | 时间戳超出 ±300 秒 | 403 | `publish.php` / `api/projects.php` |
| `rate_limited` | 触发限流（30 req/min） | 429 | `publish.php` |
| `publish_limit_exceeded` | 免费用户每月 3 次已用完 | 403 | `publish.php` |
| `permission_denied` | 非项目所有者 / 用户不一致 | 403 | `publish.php` / `api/projects.php` |
| `project_not_found` | project_id 不存在 | 404 | `api/projects.php` |
| `project_too_large` | 单文件 10MB / 总 50MB 超限 | 413 | `publish.php` |
| `pro_required` | 该功能仅 Pro 可用 | 403 | `api/projects.php` |
| `invalid_request` / `invalid_input` | 字段缺失或格式错误 | 400 | 全部 |
| `operation_failed` | 业务异常（如 DB 错误） | 500 | 全部 |

iOS 端通过 [ServerErrorCode.swift](file:///Volumes/ssd/aicode_new0421/ioscode/zaixianhtml/ios/ServerErrorCode.swift) 翻译为本地化提示。

---

## 三、端点

### 3.1 `POST /publish.php` — 发布新项目

**Headers**:
- 鉴权 3 件套（必须）
- `Content-Type: multipart/form-data`

**Form 字段**:
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 否 | 项目 ID，缺省由服务端生成 8 位随机串 |
| `name` | string | 是 | 项目名称 |
| `user_id` | string | 是 | iOS UserManager 中的 UUID |
| `is_pro` | int (0/1) | 是 | 发布时 Pro 状态（仅作记录，后端以 `users.is_pro` 为准） |
| `expire_minutes` | int | 否 | 过期分钟数（免费用户不传则后端默认 60） |
| `expire_days` | int | 否 | 过期天数（仅 Pro 生效） |
| `access_password` | string | 否 | 访问密码（仅 Pro 生效，bcrypt 存储） |
| `is_update` | int (0/1) | 否 | 1 表示更新已有项目（需要 `id` 字段） |
| `file_count` | int | 是 | 文件数量 |
| `files[]` | file | 是 | 项目文件（multipart） |

**成功响应**:
```json
{
  "status": "success",
  "code": "ok",
  "id": "ce_abc123def",
  "url": "https://html.niceapp.eu.cc/pub/ce_abc123def/index.html",
  "expires_at": "2026-06-03 11:30:00",
  "has_password": false
}
```

**限流**:
- 30 req/min per IP+API Key
- 免费用户每月 3 次发布（`system_config.free_user_monthly_publish_limit`）

---

### 3.2 `POST /api/projects.php?action=unpublish` — 停止分享

**Body (JSON)**:
```json
{
  "action": "unpublish",
  "project_id": "ce_abc123def",
  "user_id": "<uuid>"
}
```

**响应**:
```json
{"success": true, "code": "ok", "message": "Project unpublished"}
```

副作用：删除 `pub/{project_id}/` 目录、删除 `projects` 表记录。

---

### 3.3 `GET /api/projects.php?action=list` — 项目列表

**Query**:
- `user_id` (可选；不传返回全部非 deleted 项目)

**响应**:
```json
{
  "code": "ok",
  "success": true,
  "message": "Projects loaded",
  "projects": [
    {
      "id": "ce_abc123def",
      "projectId": "ce_abc123def",
      "projectName": "My Site",
      "url": "https://html.niceapp.eu.cc/pub/ce_abc123def/index.html",
      "isActive": true,
      "visitCount": 42,
      "uniqueVisitors": 18,
      "todayVisits": 3,
      "publishedAt": 1717000000,
      "expiresAt": 1719592000,
      "lastVisitedAt": 1717500000,
      "hasPassword": false
    }
  ]
}
```

---

### 3.4 `GET /api/projects.php?action=get` — 项目详情

**Query**:
- `project_id` (必填)

**响应**:
```json
{
  "code": "ok",
  "success": true,
  "project": {
    "id": "ce_abc123def",
    "name": "My Site",
    "url": "https://html.niceapp.eu.cc/pub/ce_abc123def/index.html",
    "visitCount": 42,
    "status": "active",
    "expiresAt": "2026-07-01 00:00:00",
    "hasPassword": false
  }
}
```

---

### 3.5 `POST /api/projects.php?action=toggle_status` — 启用 / 停用

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>",
  "is_active": true
}
```

**响应**: `{"success": true, "code": "ok", "message": "Status updated"}`

---

### 3.6 `GET /api/projects.php?action=stats` — 访问统计

**Query**:
- `project_id` (必填)

**响应**:
```json
{
  "totalVisits": 1234,
  "uniqueVisitors": 567,
  "todayVisits": 12,
  "visitsByDay": [
    {"date": "2026-06-01", "count": 100},
    ...
  ],
  "topReferrers": [
    {"source": "google.com", "count": 50},
    ...
  ]
}
```

---

### 3.7 `POST /api/projects.php?action=set_expiry` — 设置过期时间

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>",
  "expires_at": 1719592000  // Unix 秒；null = 永久（清空 expires_at）
}
```

**响应**:
```json
{
  "success": true,
  "code": "ok",
  "expires_at": null,
  "is_permanent": true
}
```

> `expires_at: 0` 或 `null` 都会清空过期时间（视为永久）。

---

### 3.8 `POST /api/projects.php?action=set_password` — 设置访问密码

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>",
  "password": "secret"
}
```

**响应**: `{"success": true, "code": "ok"}`

**仅 Pro 可用**。免费用户访问该端点返回 `pro_required`。

---

### 3.9 `POST /api/projects.php?action=remove_password` — 移除访问密码

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>"
}
```

---

### 3.10 `GET /api/projects.php?action=get_visit_logs` — 访问日志

**Query**:
- `project_id` (必填)
- `page` (默认 1)
- `limit` (默认 50)
- `start_date` / `end_date` (可选，格式 `YYYY-MM-DD`)

**响应**:
```json
{
  "code": "ok",
  "success": true,
  "logs": [
    {
      "id": 12345,
      "ip": "192.168.1.***",
      "device": "mobile",
      "deviceIcon": "mobile",
      "referer": "https://google.com/",
      "source": "google.com",
      "visitedAt": "2026-06-02 10:30:45"
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 50,
  "totalPages": 2
}
```

> 设备类型由 `user_agent` 推断（mobile / tablet / desktop），无需 `device_type` 数据库字段。

---

### 3.11 `POST /api/projects.php?action=update_content` — 更新内容

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>",
  "content": "<!doctype html>..."
}
```

**响应**: `{"success": true, "code": "ok", "message": "Content updated"}`

> 仅覆盖 `index.html` 文件，多文件项目请改用 `/publish.php` 重新发布。

---

### 3.12 `POST /api/projects.php?action=set_redirect_url` — 设置到期后行为

**Body (JSON)**:
```json
{
  "project_id": "ce_abc123def",
  "user_id": "<uuid>",
  "redirect_type": "custom_url",        // app_promotion | custom_url | custom_message
  "redirect_url": "https://mysite.com/landing",   // custom_url 必填
  "custom_message": "项目已迁移到新地址"            // custom_message 必填
}
```

**响应**: `{"success": true, "code": "ok", "message": "Redirect settings updated"}`

> **仅 Pro 可用**。

---

### 3.13 `POST /api/projects.php?action=batch_operation` — 批量操作

**Body (JSON)**:
```json
{
  "operation": "delete",                // delete | extend_expiry | toggle_status
  "project_ids": ["ce_abc123def", "ce_xyz98765"],
  "user_id": "<uuid>",
  "params": { "days": 7 }              // extend_expiry 时必填
}
```

**响应**:
```json
{
  "success": true,
  "code": "ok",
  "message": "Batch operation completed",
  "successCount": 2,
  "failCount": 0,
  "errors": []
}
```

> `extend_expiry` 续期不限用户类型；`delete` 软删除并清空 `pub/{project_id}/`。

---

### 3.14 `GET /stats.php?id={project_id}` — 公共统计

无需鉴权，用于浏览器端或第三方嵌入：

**响应**:
```json
{
  "project_id": "ce_abc123def",
  "visit_count": 1234,
  "is_expired": false,
  "expires_at": "2026-07-01 00:00:00"
}
```

> 这是为浏览器统计面板提供的轻量端点。功能更全的 `api/projects.php?action=stats` 需要鉴权。

---

### 3.15 `POST /sync_user.php` — 同步用户 Pro 状态

**Headers**: 鉴权 3 件套

**Body (JSON)**:
```json
{
  "user_id": "<uuid>",
  "is_pro": true,
  "publish_count": 5,
  "total_visits": 100
}
```

**响应**:
```json
{"success": true, "code": "ok"}
```

> ⚠️ **已知安全风险**：当前实现不强制校验"调用者=该 user_id 本身"，任何人持有 API Key 即可伪造任意 user 为 Pro。建议生产环境改用 App Store 收据校验。

---

## 四、公开访问（无鉴权）

### 4.1 `GET /{project_id}/` — 项目主页

- 项目未过期 → 输出 `pub/{project_id}/index.html`
- 项目已过期 → 根据 `expired_redirect_type` 跳转到引导页 / 自定义 URL / 自定义消息
- 项目有密码 → 输出 `password_prompt.html` 表单

### 4.2 `POST /{project_id}/?action=verify_password`

**Form 字段**:
- `password`

**响应**: 正确 → 200 显示内容 / 错误 → 401 回到表单

---

## 五、运维端点

### 5.1 `GET /admin.php` — 管理员后台

- 登录页（`?action=login`）
- 用户管理、项目管理、封禁
- 凭据：`ADMIN_USER` / `ADMIN_PASS`（在 `.env`）

### 5.2 `GET /expire_cron.php` — 过期清理

- 标记过期项目状态 = `expired`（同时备份原文件为 `.bak`，便于续期恢复）
- 由 `evt_expire_projects` 事件每 5 分钟自动跑（调用 `sp_expire_projects` 存储过程）
- 手动执行：`php /var/www/html/deploy_package/expire_cron.php`

### 5.3 测试端点（开发用，生产可删）

| 文件 | 用途 |
|------|------|
| `test/db_test.php` | 数据库 schema 验证 |
| `test/debug_index.php` | 访问网关调试 |
| `test/debug_pub.php` | 静态资源调试 |
| `test/diag.php` | 系统诊断 |

---

## 六、数据库 schema (v3.2)

> 详细见 [deploy_package/database/init_mysql84.sql](file:///Volumes/ssd/aicode_new0421/ioscode/zaixianhtml/deploy_package/database/init_mysql84.sql)

| 表 | 用途 | 关键字段 |
|---|---|---|
| `users` | 用户 | user_id, is_pro, publish_count, total_visits |
| `projects` | 项目 | project_id, user_id, visit_count, expires_at, access_password |
| `visit_logs` | 访问日志 | project_id, ip_address, ip_hash, user_agent, referer |
| `user_activity_logs` | 用户活动审计 | user_id, action, details |
| `admin_logs` | 管理员审计 | admin_user, action, target_type, target_id |
| `system_config` | 配置 | config_key, config_value |

**已移除**（v3.2 cleanup）：`daily_stats`, `subscription_records`, `temp_access_links`, `project_ip_rules`, `project_comments`, `tags`, `categories`, `project_tags`, 5 个 v_* 视图
