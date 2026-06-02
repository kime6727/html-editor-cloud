<?php
/**
 * verify_password.php 已废弃 (deprecated)
 *
 * 旧的独立密码验证端点已由 index.php 网关 + password_prompt.html 取代。
 * index.php 统一使用：
 *   - $_SESSION['ce_project_access_xxx'] 标记已通过验证
 *   - 5 次错误锁定 15 分钟（更强的安全策略）
 *
 * 旧端点存在的风险：
 *   - 两套独立限流（10/5min vs 5/15min），安全策略不一致
 *   - 双实现导致后续维护容易遗漏
 *
 * 2026-05-30 迁移：所有密码验证统一走 index.php 网关
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

http_response_code(410); // Gone
echo json_encode([
    'status' => 'error',
    'code' => 'endpoint_removed',
    'message' => 'verify_password.php is deprecated. Please submit the password form to /{project_id} (handled by index.php)',
    'new_endpoint' => 'index.php (with password form POST)',
    'migration_date' => '2026-05-30'
]);
