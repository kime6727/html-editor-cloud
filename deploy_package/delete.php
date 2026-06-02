<?php
/**
 * HTML Code Editor - Delete API (MySQL版本)
 * 允许用户删除已发布的项目（软删除）
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Only POST requests are allowed']);
    exit;
}

// 加载配置
function loadEnv($path) {
    if (!file_exists($path)) return [];
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $env = [];
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        $parts = explode('=', $line, 2);
        if (count($parts) === 2) {
            $env[trim($parts[0])] = trim($parts[1]);
        }
    }
    return $env;
}

$env = loadEnv(__DIR__ . '/.env');

// HMAC-SHA256 签名验证
$api_key = $_SERVER['HTTP_X_API_KEY'] ?? '';
$timestamp = $_SERVER['HTTP_X_TIMESTAMP'] ?? '';
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';

$config_api_keys = [$env['PUBLISH_API_KEY'] ?? ''];

if (empty($api_key) || !in_array($api_key, $config_api_keys)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Invalid API key']);
    exit;
}

if (empty($timestamp) || !ctype_digit($timestamp)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Missing timestamp']);
    exit;
}

$ts = (int)$timestamp;
$now = time();
if (abs($now - $ts) > 300) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'timestamp_expired', 'message' => 'Request expired']);
    exit;
}

$expectedSignature = hash_hmac('sha256', $api_key . $timestamp, $env['HMAC_SECRET_KEY'] ?? $api_key);
if (!hash_equals($expectedSignature, $signature)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Invalid signature']);
    exit;
}

// 处理删除请求
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['id'])) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Missing project id']);
    exit;
}

$projectId = $data['id'];
$userId = $data['user_id'] ?? null;

// 强制验证用户身份
if (empty($userId)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'permission_denied', 'message' => 'User ID is required']);
    exit;
}

// 验证用户ID格式，防止注入攻击
if (!preg_match('/^[a-zA-Z0-9_-]+$/', $userId)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Invalid user ID format']);
    exit;
}

require_once __DIR__ . '/database/Database.php';
$uploadDir = __DIR__ . '/pub/';

// 查询项目信息
$project = db()->queryOne(
    "SELECT * FROM projects WHERE project_id = ? AND status != 'deleted' LIMIT 1",
    [$projectId]
);

if (!$project) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'code' => 'project_not_found', 'message' => 'Project not found']);
    exit;
}

// 权限验证：只有项目的创建者可以删除
// 使用严格比较防止类型转换攻击
if (isset($project['user_id']) && (string)$project['user_id'] !== (string)$userId) {
    error_log("[DELETE] Permission denied: user_id={$userId}, project_owner={$project['user_id']}, project_id={$projectId}, ip=" . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'permission_denied', 'message' => 'Permission denied']);
    exit;
}

// 删除项目文件
$projectDir = $uploadDir . $projectId;
if (is_dir($projectDir)) {
    safeDeleteDir($projectDir);
}

// 使用事务进行数据库操作
try {
    db()->beginTransaction();
    
    // 软删除：更新数据库状态
    db()->execute(
        "UPDATE projects SET status = 'deleted', updated_at = NOW() WHERE project_id = ?",
        [$projectId]
    );
    
    // 记录管理员操作日志
    db()->execute(
        "INSERT INTO admin_logs (admin_user, action, target_type, target_id, details, ip_address) VALUES (?, ?, ?, ?, ?, ?)",
        [$userId, 'delete_project', 'project', $projectId, json_encode(['action' => 'delete']), $_SERVER['REMOTE_ADDR'] ?? 'unknown']
    );
    
    db()->commit();
} catch (Exception $e) {
    try {
        db()->rollBack();
    } catch (Exception $rollbackEx) {
        error_log("Failed to rollback: " . $rollbackEx->getMessage());
    }
    http_response_code(500);
    echo json_encode(['status' => 'error', 'code' => 'operation_failed', 'message' => 'Failed to delete project']);
    exit;
}

echo json_encode(['status' => 'success', 'code' => 'ok', 'message' => 'Project deleted']);

function safeDeleteDir($dir) {
    if (!is_dir($dir)) return;
    $items = scandir($dir);
    foreach ($items as $item) {
        if ($item === '.' || $item === '..') continue;
        $path = $dir . '/' . $item;
        if (is_dir($path)) {
            safeDeleteDir($path);
        } else {
            unlink($path);
        }
    }
    rmdir($dir);
}
