<?php
/**
 * HTML Code Editor - Password Verification API
 * 验证受密码保护的项目访问权限
 */

session_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Only POST allowed']);
    exit;
}

require_once __DIR__ . '/database/Database.php';

// Rate limiting for password verification (max 10 attempts per 5 minutes)
$clientIP = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$rateLimitKey = 'pwd_verify_' . md5($clientIP);
$rateLimitFile = __DIR__ . '/data/rate_limit_' . $rateLimitKey . '.json';

$attempts = 0;
$now = time();
if (file_exists($rateLimitFile)) {
    $data = json_decode(file_get_contents($rateLimitFile), true);
    if ($data && isset($data['attempts']) && isset($data['reset_at'])) {
        if ($now < $data['reset_at']) {
            $attempts = $data['attempts'];
        } else {
            $attempts = 0;
        }
    }
}

if ($attempts >= 10) {
    http_response_code(429);
    echo json_encode(['success' => false, 'message' => 'Too many attempts, please try again later']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$projectId = $input['project_id'] ?? ($input['slug'] ?? '');
$password = $input['password'] ?? '';

if (empty($projectId) || empty($password)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => '参数缺失']);
    exit;
}

try {
    // 查询项目
    $project = db()->queryOne(
        "SELECT * FROM projects WHERE project_id = ? AND status != 'deleted' LIMIT 1",
        [$projectId]
    );
    
    if (!$project) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => '项目不存在']);
        exit;
    }
    
    if (empty($project['access_password'])) {
        echo json_encode(['success' => true, 'message' => '无需密码']);
        exit;
    }
    
    // 验证密码
    if (password_verify($password, $project['access_password'])) {
        // 密码正确，设置session
        $projectId = $project['project_id'];
        $_SESSION['ce_project_access_' . $projectId] = true;
        $_SESSION['ce_project_access_' . $projectId . '_time'] = time();
        
        echo json_encode(['success' => true, 'message' => '验证成功']);
    } else {
        // 密码错误
        echo json_encode(['success' => false, 'message' => '密码错误']);
        // Track failed attempt
        $attempts++;
        $rateLimitData = ['attempts' => $attempts, 'reset_at' => $now + 300];
        $rateLimitDir = dirname($rateLimitFile);
        if (!is_dir($rateLimitDir)) mkdir($rateLimitDir, 0755, true);
        file_put_contents($rateLimitFile, json_encode($rateLimitData), LOCK_EX);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => '服务器错误']);
}
