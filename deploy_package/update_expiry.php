<?php
/**
 * update_expiry.php 已废弃 (deprecated)
 *
 * 旧的独立端点已合并到 /api/projects.php?action=set_expiry
 * 为防止旧客户端误调后静默失败，此处返回 HTTP 410 Gone + 明确升级指引
 *
 * 旧端点存在的安全风险：
 *   - 空 userId 时跳过权限校验
 *   - 与 api/projects.php 维护两套相同业务逻辑
 *   - 容易在迭代中遗漏
 *
 * 2026-05-30 迁移：所有 iOS 客户端已切换至 set_expiry action
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

http_response_code(410); // Gone
echo json_encode([
    'status' => 'error',
    'code' => 'endpoint_removed',
    'message' => 'update_expiry.php is deprecated. Please use /api/projects.php with action=set_expiry',
    'new_endpoint' => '/api/projects.php',
    'new_action' => 'set_expiry',
    'migration_date' => '2026-05-30'
]);
