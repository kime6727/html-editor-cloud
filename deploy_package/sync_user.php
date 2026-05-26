<?php
/**
 * HTML Code Editor - User Sync API
 * iOS客户端调用此接口同步用户Pro状态到服务端
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
    echo json_encode(['success' => false, 'message' => 'Only POST requests are allowed']);
    exit;
}

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

$api_key = $_SERVER['HTTP_X_API_KEY'] ?? '';
$timestamp = $_SERVER['HTTP_X_TIMESTAMP'] ?? '';
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';

$config_api_keys = [$env['PUBLISH_API_KEY'] ?? ''];

if (empty($api_key) || !in_array($api_key, $config_api_keys)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Invalid API key']);
    exit;
}

if (empty($timestamp) || !ctype_digit($timestamp)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Missing timestamp']);
    exit;
}

$ts = (int)$timestamp;
$now = time();
if (abs($now - $ts) > 300) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Request expired']);
    exit;
}

$expectedSignature = hash_hmac('sha256', $api_key . $timestamp, $env['HMAC_SECRET_KEY'] ?? $api_key);
if (!hash_equals($expectedSignature, $signature)) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Invalid signature']);
    exit;
}

$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['user_id'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing user_id']);
    exit;
}

$userId = $data['user_id'];
$isPro = isset($data['is_pro']) && $data['is_pro'] === true;

require_once __DIR__ . '/database/Database.php';

try {
    $db = db();
    
    $existing = $db->queryOne("SELECT id, is_pro FROM users WHERE user_id = ?", [$userId]);
    
    if ($existing) {
        // Security: Only allow upgrading is_pro to true via this endpoint.
        // Downgrading is_pro from true to false is NOT allowed here to prevent
        // client-side downgrade attacks. Only Apple receipt verification should
        // be able to revoke pro status.
        if ($isPro && !$existing['is_pro']) {
            $db->execute(
                "UPDATE users SET is_pro = 1, pro_activated_at = NOW(), last_active_at = NOW() WHERE user_id = ?",
                [$userId]
            );
        } else {
            $db->execute("UPDATE users SET last_active_at = NOW() WHERE user_id = ?", [$userId]);
        }
    } else {
        $db->execute(
            "INSERT INTO users (user_id, is_pro, publish_count, created_at, last_active_at) VALUES (?, ?, 0, NOW(), NOW())",
            [$userId, $isPro ? 1 : 0]
        );
    }
    
    $updatedUser = $db->queryOne("SELECT is_pro, publish_count FROM users WHERE user_id = ?", [$userId]);
    
    echo json_encode([
        'success' => true,
        'message' => 'User synced',
        'is_pro' => (bool)$updatedUser['is_pro'],
        'publish_count' => (int)$updatedUser['publish_count']
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
