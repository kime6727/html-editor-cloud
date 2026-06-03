# 云端发布功能全流程分析报告

## 执行摘要

本报告对 **Code Editor – HTML & Preview**（Bundle ID: `com.niceapp.htmleditor`）的云端发布功能进行了全面的前后端代码审查，发现了**多个严重的逻辑问题和功能缺失**，需要立即修复。

**总体评分**: ⚠️ **2.5/5.0** (存在重大问题)

---

## 一、功能完整性检查

### ✅ 已实现的功能

1. **基础发布流程**
   - ✅ 多文件上传（包括二进制文件）
   - ✅ HMAC-SHA256签名验证
   - ✅ 自定义短链（3-10字符）
   - ✅ 过期时间设置（天/分钟）
   - ✅ 数据库记录

2. **访问统计**
   - ✅ 访问计数
   - ✅ 7日访问趋势
   - ✅ 统计API (stats.php)

3. **过期处理**
   - ✅ 过期检查（redirect.php）
   - ✅ 过期引导页（expired.html）

4. **管理功能**
   - ✅ 后台管理界面（admin.php）
   - ✅ 项目列表/筛选/搜索
   - ✅ 用户管理
   - ✅ 批量操作

### ❌ 功能缺失或不完整

#### 🔴 **严重问题**

1. **CloudProjectManager 完全未实现后端API**
   ```swift
   // iOS端调用的API端点不存在！
   - action=list          // ❌ 后端无此API
   - action=toggle_status // ❌ 后端无此API
   - action=unpublish     // ❌ 后端无此API
   - action=set_password  // ❌ 后端无此API
   - action=remove_password // ❌ 后端无此API
   - action=set_expiry    // ❌ 后端无此API
   - action=stats         // ❌ 后端无此API
   - action=update_content // ❌ 后端无此API
   ```

2. **密码保护功能未实现**
   - ✅ 数据库有字段设计
   - ❌ redirect.php 无密码验证逻辑
   - ❌ 无密码输入页面
   - ❌ 无密码加密存储

3. **更新过期时间功能不完整**
   - ✅ update_expiry.php 存在
   - ❌ iOS端调用的是不存在的API
   - ❌ 前后端接口不匹配

4. **删除功能逻辑不一致**
   - ✅ delete.php 存在
   - ⚠️ 只做软删除（status='deleted'）
   - ❌ 文件未真正删除（仍可访问）
   - ❌ iOS端调用的unpublish API不存在

---

## 二、详细问题分析

### 🔴 问题1: CloudProjectManager API端点缺失

**影响**: 云端项目管理功能完全不可用

**iOS端代码**:
```swift
// CloudProjectManager.swift
func loadPublishedProjects() async {
    // 调用: /publish.php?action=list
    // ❌ 后端publish.php没有处理action=list
}

func toggleProjectStatus() async {
    // 调用: POST /publish.php action=toggle_status
    // ❌ 后端没有此action
}
```

**后端代码**:
```php
// backend/publish.php
// 只处理文件上传，没有处理任何管理action
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit;
}
// 直接进入上传逻辑，没有action分发
```

**修复方案**:
```php
// 需要在publish.php开头添加action分发
$action = $_POST['action'] ?? $_GET['action'] ?? 'upload';

switch ($action) {
    case 'list':
        handleListProjects();
        break;
    case 'toggle_status':
        handleToggleStatus();
        break;
    case 'set_password':
        handleSetPassword();
        break;
    // ... 其他action
    case 'upload':
    default:
        handleUpload();
        break;
}
```

---

### 🔴 问题2: 密码保护功能未实现

**数据库设计**:
```sql
-- projects表有字段，但未使用
ALTER TABLE projects ADD COLUMN access_password VARCHAR(255);
ALTER TABLE projects ADD COLUMN has_password TINYINT(1) DEFAULT 0;
```

**redirect.php缺失验证**:
```php
// redirect.php 当前逻辑
// 1. 检查过期 ✅
// 2. 输出HTML ✅
// 3. 密码验证 ❌ 完全缺失

// 需要添加:
if ($meta && isset($meta['has_password']) && $meta['has_password']) {
    // 检查session或cookie
    if (!isset($_SESSION['project_access_' . $slug])) {
        // 显示密码输入页面
        showPasswordPage($slug);
        exit;
    }
}
```

**需要新增文件**:
```php
// backend/verify_password.php
// 处理密码验证请求
```

---

### 🔴 问题3: 更新过期时间接口不匹配

**iOS端调用**:
```swift
// CloudService.swift
func updateProjectExpiry(cloudId: String, userId: String, expireDays: Int?) async {
    let url = AppConfig.apiBaseURL + "update_expiry.php"
    // ✅ 正确调用update_expiry.php
}
```

**CloudProjectManager调用**:
```swift
// CloudProjectManager.swift
func setExpiryDate(projectId: UUID, expiresAt: Date?) async {
    var request = URLRequest(url: URL(string: "\(apiBaseURL)/publish.php")!)
    // ❌ 错误！调用的是publish.php而不是update_expiry.php
    let body: [String: Any] = [
        "action": "set_expiry",  // ❌ publish.php没有此action
    ]
}
```

**修复**: 统一使用update_expiry.php

---

### 🔴 问题4: 删除功能不彻底

**当前逻辑**:
```php
// delete.php
db()->execute("UPDATE projects SET status='deleted' WHERE project_id=?", [$projectId]);
// ✅ 软删除数据库记录

$projectDir = $uploadDir . $projectId;
if (is_dir($projectDir)) {
    safeDeleteDir($projectDir);  // ✅ 删除文件
}
```

**问题**:
1. redirect.php仍会检查文件系统，如果文件存在就显示
2. 软删除后，如果有人保存了链接，可能仍能访问
3. 元数据文件（/tmp/ce_shortlinks/）未删除

**修复**:
```php
// 需要同时删除:
// 1. 数据库记录（软删除）✅
// 2. 文件目录 ✅
// 3. 元数据文件 ❌
$metaFile = sys_get_temp_dir() . '/ce_shortlinks/' . $projectId . '.json';
if (file_exists($metaFile)) unlink($metaFile);

// 4. 别名文件 ❌
if ($customSlug) {
    $aliasFile = sys_get_temp_dir() . '/ce_shortlinks/' . $customSlug . '.alias';
    if (file_exists($aliasFile)) unlink($aliasFile);
}
```

---

### ⚠️ 问题5: 过期时间逻辑混乱

**免费用户限制**:
```php
// publish.php
if (!$is_pro && $expire_days === 0 && $expire_minutes === 0) {
    $expire_minutes = 5; // 强制5分钟过期
}
```

**iOS端配置**:
```swift
// PublishConfigView.swift
var expireOptions: [(Int, String)] {
    if subscriptionManager.isPro {
        return [(0, "never"), (7, "7天"), (30, "30天"), (90, "90天")]
    } else {
        return [(0, "5分钟")]  // ⚠️ 显示"5分钟"但值是0
    }
}
```

**问题**: 
- 免费用户选择的是0天，但后端强制改为5分钟
- UI显示"5分钟"但实际传的是0
- 逻辑不清晰，容易混淆

**修复**:
```swift
// 免费用户应该传递expire_minutes而不是expire_days
if !subscriptionManager.isPro {
    body["expire_minutes"] = 5
    body["expire_days"] = 0
} else {
    body["expire_days"] = config.expireDays
    body["expire_minutes"] = 0
}
```

---

### ⚠️ 问题6: 访问统计不准确

**当前实现**:
```php
// redirect.php
function logVisit($slug) {
    // 1. 写入日志文件 ✅
    $logFile = sys_get_temp_dir() . '/ce_visits/' . date('Y-m-d') . '.jsonl';
    
    // 2. 更新元数据 ✅
    $meta['visit_count'] = ($meta['visit_count'] ?? 0) + 1;
    
    // 3. 更新数据库 ❌ 缺失！
}
```

**问题**: 
- 访问计数只更新元数据文件，不更新数据库
- stats.php从数据库读取，但数据库未更新
- 导致统计数据不一致

**修复**:
```php
function logVisit($slug) {
    // ... 现有逻辑 ...
    
    // 添加数据库更新
    try {
        db()->execute(
            "UPDATE projects SET visit_count = visit_count + 1, last_visited_at = NOW() WHERE project_id = ?",
            [$slug]
        );
    } catch (Exception $e) {
        error_log("Failed to update visit count: " . $e->getMessage());
    }
}
```

---

### ⚠️ 问题7: 自定义短链冲突检测不完整

**当前检查**:
```php
// publish.php
function validateCustomSlug($slug, $config, $uploadDir) {
    // 1. 长度检查 ✅
    // 2. 字符检查 ✅
    // 3. 保留词检查 ✅
    // 4. 文件系统检查 ✅
    $targetPath = $uploadDir . strtolower($slug);
    if (is_dir($targetPath)) {
        return "This slug is already taken";
    }
    
    // 5. 数据库检查 ❌ 缺失！
    // 如果有人删除了文件但数据库记录还在，会冲突
}
```

**修复**:
```php
// 添加数据库检查
$existing = db()->queryOne(
    "SELECT id FROM projects WHERE (project_id = ? OR custom_slug = ?) AND status != 'deleted'",
    [$slug, $slug]
);
if ($existing) {
    return "This slug is already taken";
}
```

---

### ⚠️ 问题8: Pro用户验证不安全

**当前逻辑**:
```php
// publish.php
$is_pro = isset($_POST['is_pro']) && $_POST['is_pro'] === '1';

// 客户端可以伪造is_pro参数！
```

**后端验证**:
```php
// 有验证逻辑，但在客户端已经传递后才验证
if (!$is_pro && $user_id) {
    $user = db()->queryOne("SELECT is_pro FROM users WHERE user_id = ?", [$user_id]);
    if ($user && $user['is_pro']) {
        $is_pro = true;  // 以服务端为准
    }
}
```

**问题**: 
- 先信任客户端，后验证
- 如果user_id为空，完全信任客户端
- 应该先验证，后使用

**修复**:
```php
// 始终从数据库验证
$is_pro = false;
if ($user_id) {
    $user = db()->queryOne("SELECT is_pro FROM users WHERE user_id = ?", [$user_id]);
    $is_pro = $user && $user['is_pro'];
}
// 不再信任客户端传递的is_pro参数
```

---

## 三、数据流分析

### 发布流程

```
iOS App (CloudService.swift)
    ↓ POST /publish.php
    ├─ 签名验证 ✅
    ├─ 速率限制 ✅
    ├─ 文件上传 ✅
    ├─ 短码生成 ✅
    ├─ 保存到数据库 ✅
    └─ 保存元数据文件 ✅

访问流程
    ↓ GET /p/{slug}
redirect.php
    ├─ 解析slug ✅
    ├─ 检查别名 ✅
    ├─ 检查过期 ✅
    ├─ 检查密码 ❌ 缺失
    ├─ 记录访问 ⚠️ 不完整
    └─ 输出HTML ✅

管理流程
iOS App (CloudProjectManager.swift)
    ↓ GET /publish.php?action=list
    ❌ 后端无此API
    
iOS App (CloudProjectManager.swift)
    ↓ POST /publish.php action=set_expiry
    ❌ 后端无此API
    
iOS App (CloudService.swift)
    ↓ POST /update_expiry.php
    ✅ 后端存在
    ⚠️ 但CloudProjectManager调用错误的API
```

---

## 四、安全问题

### ✅ 做得好的地方

1. **HMAC-SHA256签名验证** - 防止未授权访问
2. **时间戳防重放** - 300秒窗口
3. **IP速率限制** - 30次/分钟
4. **路径遍历防护** - sanitizePath函数
5. **文件类型白名单** - 防止上传恶意文件
6. **SQL注入防护** - 使用PDO预处理

### ⚠️ 安全隐患

1. **密码未加密存储**
   ```php
   // 如果实现密码功能，应该使用password_hash
   $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
   ```

2. **API Key硬编码**
   ```swift
   // AppConfig.swift
   static let publishAccessKey = "f7a2b9c3e1d6e5f8a0b9c2d1e4f7a2b9"
   // ⚠️ 硬编码在客户端，可被反编译获取
   ```

3. **Pro状态可伪造**
   - 客户端传递is_pro参数
   - 应该完全由服务端验证

4. **Session管理缺失**
   - 密码保护功能需要session
   - 当前无session管理

---

## 五、性能问题

### ⚠️ 潜在性能瓶颈

1. **元数据文件读写**
   ```php
   // redirect.php 每次访问都读写文件
   $metaFile = sys_get_temp_dir() . '/ce_shortlinks/' . $slug . '.json';
   $meta = json_decode(file_get_contents($metaFile), true);
   // 高并发时会有性能问题
   ```

2. **访问日志写入**
   ```php
   // 每次访问都写文件
   file_put_contents($logFile, json_encode($entry) . "\n", FILE_APPEND | LOCK_EX);
   // 建议使用队列或批量写入
   ```

3. **数据库查询未优化**
   ```php
   // stats.php 循环查询7天数据
   for ($i = 6; $i >= 0; $i--) {
       $result = db()->queryOne("SELECT COUNT(*) ...");
   }
   // 应该用一条SQL查询
   ```

---

## 六、用户体验问题

### ⚠️ UX缺陷

1. **过期页面无多语言支持**
   - expired.html 只有中文
   - 应该根据浏览器语言显示

2. **过期后无法续期**
   - 链接过期后完全不可访问
   - 应该提供"续期"选项（Pro用户）

3. **删除无确认**
   - iOS端删除项目无二次确认
   - 容易误删

4. **统计数据延迟**
   - 访问计数不实时更新数据库
   - 用户看到的统计数据不准确

---

## 七、修复优先级

### 🔴 P0 - 立即修复（功能完全不可用）

1. **实现CloudProjectManager后端API**
   - 创建新的API端点或扩展publish.php
   - 实现所有管理功能

2. **修复删除功能**
   - 删除元数据文件
   - 删除别名文件

3. **统一过期时间接口**
   - CloudProjectManager使用正确的API
   - 或者在publish.php实现set_expiry action

### 🟠 P1 - 高优先级（影响核心功能）

4. **实现密码保护功能**
   - redirect.php添加密码验证
   - 创建密码输入页面
   - 实现密码加密存储

5. **修复访问统计**
   - redirect.php更新数据库
   - 优化stats.php查询

6. **完善自定义短链验证**
   - 添加数据库冲突检查

7. **修复Pro用户验证**
   - 服务端验证，不信任客户端

### 🟡 P2 - 中优先级（改进体验）

8. **优化过期时间逻辑**
   - 统一免费用户的过期参数传递

9. **添加过期页面多语言**
   - 根据Accept-Language显示

10. **性能优化**
    - 访问日志批量写入
    - 统计查询优化

---

## 八、建议的API设计

### 新增API端点: `/api/projects.php`

```php
<?php
// 统一的项目管理API

$action = $_POST['action'] ?? $_GET['action'] ?? '';

switch ($action) {
    case 'list':
        // 列出用户的所有项目
        listUserProjects($userId);
        break;
        
    case 'get':
        // 获取单个项目详情
        getProjectDetail($projectId);
        break;
        
    case 'update_status':
        // 启用/停用项目
        updateProjectStatus($projectId, $isActive);
        break;
        
    case 'update_expiry':
        // 修改过期时间
        updateProjectExpiry($projectId, $expiresAt);
        break;
        
    case 'set_password':
        // 设置访问密码
        setProjectPassword($projectId, $password);
        break;
        
    case 'remove_password':
        // 移除访问密码
        removeProjectPassword($projectId);
        break;
        
    case 'delete':
        // 删除项目
        deleteProject($projectId);
        break;
        
    case 'stats':
        // 获取统计数据
        getProjectStats($projectId);
        break;
        
    default:
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
}
```

---

## 九、测试建议

### 需要测试的场景

1. **发布流程**
   - [ ] 免费用户发布（5分钟过期）
   - [ ] Pro用户发布（自定义过期）
   - [ ] 自定义短链（成功/冲突）
   - [ ] 多文件上传（包括图片）
   - [ ] 更新已发布项目

2. **访问流程**
   - [ ] 正常访问
   - [ ] 过期访问（显示引导页）
   - [ ] 自定义短链访问
   - [ ] 密码保护访问（待实现）
   - [ ] 访问计数准确性

3. **管理功能**
   - [ ] 列出已发布项目
   - [ ] 修改过期时间
   - [ ] 设置/移除密码
   - [ ] 启用/停用项目
   - [ ] 删除项目
   - [ ] 查看统计

4. **安全测试**
   - [ ] 签名验证
   - [ ] 速率限制
   - [ ] SQL注入
   - [ ] 路径遍历
   - [ ] Pro状态伪造

---

## 十、总结

### 当前状态

- **基础发布功能**: ✅ 完整可用
- **访问和过期**: ✅ 基本可用，⚠️ 统计不准确
- **管理功能**: ❌ 大部分不可用
- **密码保护**: ❌ 完全未实现
- **安全性**: ⚠️ 有隐患但可接受
- **性能**: ⚠️ 有优化空间

### 建议

1. **立即修复P0问题** - 否则管理功能完全不可用
2. **重新设计API架构** - 统一管理端点
3. **完善测试** - 添加自动化测试
4. **改进文档** - API文档和错误处理
5. **性能监控** - 添加日志和监控

### 风险评估

- **高风险**: CloudProjectManager功能完全不可用，用户无法管理已发布项目
- **中风险**: 访问统计不准确，影响用户决策
- **低风险**: 性能问题在低并发下不明显

---

## 附录: 快速修复清单

```bash
# 1. 创建统一管理API
touch backend/api/projects.php

# 2. 实现密码验证页面
touch backend/password.html
touch backend/verify_password.php

# 3. 修复redirect.php
# - 添加密码验证
# - 更新数据库访问计数
# - 删除元数据文件

# 4. 修复delete.php
# - 删除元数据文件
# - 删除别名文件

# 5. 优化stats.php
# - 单条SQL查询7天数据

# 6. 修复CloudProjectManager.swift
# - 使用正确的API端点
```

---

**报告生成时间**: 2026-05-08  
**审查人**: AI Code Reviewer  
**严重程度**: 🔴 高 - 需要立即处理
