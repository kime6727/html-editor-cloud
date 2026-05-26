<?php
/**
 * HTML Code Editor - Update Expiry API
 * 允许用户修改已发布项目的过期时间
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
    echo json_encode(['status' => 'error', 'message' => 'Only POST requests are allowed']);
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
    echo json_encode(['status' => 'error', 'message' => 'Invalid API key']);
    exit;
}

if (empty($timestamp) || !ctype_digit($timestamp)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Missing timestamp']);
    exit;
}

$ts = (int)$timestamp;
$now = time();
if (abs($now - $ts) > 300) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Request expired']);
    exit;
}

$expectedSignature = hash_hmac('sha256', $api_key . $timestamp, $env['HMAC_SECRET_KEY'] ?? $api_key);
if (!hash_equals($expectedSignature, $signature)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Invalid signature']);
    exit;
}

// 处理请求
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['id'])) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Missing project id']);
    exit;
}

$projectId = $data['id'];
$userId = $data['user_id'] ?? null;
$newExpireDays = isset($data['expire_days']) ? (int)$data['expire_days'] : null;
$newExpireMinutes = isset($data['expire_minutes']) ? (int)$data['expire_minutes'] : null;
$makePermanent = isset($data['make_permanent']) && $data['make_permanent'] === true;
$newPassword = isset($data['access_password']) ? $data['access_password'] : null;
$removePassword = isset($data['remove_password']) && $data['remove_password'] === true;

// 对密码进行哈希存储
$hashedPassword = null;
if (!empty($newPassword)) {
    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
}

require_once __DIR__ . '/database/Database.php';

// 查询项目信息
$project = db()->queryOne(
    "SELECT * FROM projects WHERE project_id = ? AND status != 'deleted' LIMIT 1",
    [$projectId]
);

if (!$project) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'Project not found']);
    exit;
}

// 权限验证：只有项目的创建者可以修改
if ($userId && isset($project['user_id']) && $project['user_id'] !== $userId) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Permission denied']);
    exit;
}

// 计算新的过期时间
$newExpiresAt = null;
$isPro = $project['is_pro'] == 1;

if ($makePermanent) {
    // Pro用户可以设置为永久
    if (!$isPro) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Only Pro users can set permanent links']);
        exit;
    }
    $newExpiresAt = null;
} elseif ($newExpireDays !== null && $newExpireDays > 0) {
    $newExpiresAt = date('Y-m-d H:i:s', strtotime("+$newExpireDays days"));
} elseif ($newExpireMinutes !== null && $newExpireMinutes > 0) {
    $newExpiresAt = date('Y-m-d H:i:s', strtotime("+$newExpireMinutes minutes"));
} else {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid expiry parameters']);
    exit;
}

// 检查是否是已过期项目被恢复
$wasExpired = $project['status'] === 'expired';

// 更新数据库
db()->execute(
    "UPDATE projects SET 
     expire_days = ?, 
     expire_minutes = ?, 
     expires_at = ?, 
     access_password = ?,
     status = 'active',
     updated_at = NOW() 
     WHERE project_id = ?",
    [
        $newExpireDays ?? 0,
        $newExpireMinutes ?? 0,
        $newExpiresAt,
        $removePassword ? null : ($hashedPassword ?? $project['access_password']),
        $projectId
    ]
);

// 如果是从过期状态恢复，从备份还原文件
$uploadDir = __DIR__ . '/pub/';
if ($wasExpired && is_dir($uploadDir . $projectId)) {
    restoreFromBackup($uploadDir . $projectId);
}

// 记录操作日志
try {
    db()->execute(
        "INSERT INTO admin_logs (admin_user, action, target_type, target_id, details, ip_address) VALUES (?, ?, ?, ?, ?, ?)",
        [
            $userId ?? 'unknown',
            'update_expiry',
            'project',
            $projectId,
            json_encode(['expires_at' => $newExpiresAt, 'is_permanent' => $newExpiresAt === null]),
            $_SERVER['REMOTE_ADDR'] ?? 'unknown'
        ]
    );
} catch (Exception $e) {
    error_log("Failed to log action: " . $e->getMessage());
}

echo json_encode([
    'status' => 'success',
    'message' => 'Expiry updated',
    'expires_at' => $newExpiresAt,
    'is_permanent' => $newExpiresAt === null
]);

/**
 * 从备份恢复文件
 */
function restoreFromBackup($targetPath) {
    if (!is_dir($targetPath)) return;
    
    $files = glob($targetPath . '/*');
    $restored = 0;
    
    foreach ($files as $file) {
        if (is_file($file) && substr($file, -4) === '.bak') {
            $originalFile = substr($file, 0, -4);
            rename($file, $originalFile);
            $restored++;
        }
    }
    
    if ($restored > 0) {
        error_log("[UpdateExpiry] Restored {$restored} files from backup for {$targetPath}");
    }
}
