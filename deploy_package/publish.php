<?php
/**
 * HTML Code Editor - Cloud Publishing API v2
 * 支持：多文件、嵌套目录、图片二进制上传、自定义短码、短链跳转
 * 安全特性：HMAC-SHA256 签名验证、时间戳防重放、IP 速率限制、路径遍历防护、CORS 限制、文件大小限制、文件类型白名单
 */

// ========== 加载配置 ==========
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

// 引入数据库类
require_once __DIR__ . '/database/Database.php';

/**
 * 从 system_config 读取配置项（缺省值兜底）
 * 用于把硬编码的配置项抽到数据库，便于运营调整
 */
function getConfig($key, $default = null) {
    try {
        $row = db()->queryOne(
            "SELECT config_value FROM system_config WHERE config_key = ?",
            [$key]
        );
        if ($row && isset($row['config_value']) && $row['config_value'] !== '') {
            return $row['config_value'];
        }
    } catch (Exception $e) {
        error_log("getConfig($key) failed: " . $e->getMessage());
    }
    return $default;
}

// 动态检测基础 URL
$protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$currentDir = dirname($_SERVER['SCRIPT_NAME']);
$parentDir = dirname($currentDir);
$rootUrl = $protocol . '://' . $host . ($parentDir === '/' ? '' : $parentDir) . '/';

// 使用绝对路径确保 pub 目录位置正确
$scriptDir = __DIR__;
$pubDir = $scriptDir . '/pub/';
if (!is_dir($pubDir)) {
    mkdir($pubDir, 0755, true);
}

// 配置
$config = [
    'upload_dir' => $pubDir,
    'base_url'   => $rootUrl . 'pub/',
    'api_keys'   => [$env['PUBLISH_API_KEY'] ?? ''],
    'max_total_size' => 50 * 1024 * 1024,
    'allowed_origins' => [
        $protocol . '://' . $host,
        'capacitor://localhost',
        'http://localhost',
    ],
    'request_timeout' => 300,
    'max_timestamp_diff' => 300,
    'rate_limit' => [
        'max_requests' => 30,
        'window_seconds' => 60,
    ],
    'allowed_extensions' => [
        'html', 'htm', 'css', 'js', 'mjs', 'json', 'md', 'markdown', 'txt',
        'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp', 'ico',
        'ttf', 'otf', 'woff', 'woff2', 'eot',
        'xml', 'yaml', 'yml', 'map',
    ],
];

// CORS 处理
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $config['allowed_origins'])) {
    header("Access-Control-Allow-Origin: $origin");
} else {
    header('Access-Control-Allow-Origin: ' . $protocol . '://' . $host);
}
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Only POST requests are allowed']);
    exit;
}

// ========== 速率限制 ==========
function checkRateLimit($config) {
    $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    $ip = filter_var($ip, FILTER_VALIDATE_IP) ?: 'unknown';
    $api_key = $_SERVER['HTTP_X_API_KEY'] ?? '';
    
    $rateDir = getDataDir('rate_limit');
    if (!is_dir($rateDir)) mkdir($rateDir, 0755, true);
    
    // 结合IP和API密钥进行速率限制，防止NAT共享IP问题
    $rateKey = hash('sha256', $ip . '_' . $api_key);
    $rateFile = $rateDir . $rateKey . '.json';
    
    $window = $config['rate_limit']['window_seconds'];
    $maxReq = $config['rate_limit']['max_requests'];
    $now = time();
    
    $requests = [];
    if (file_exists($rateFile)) {
        $data = json_decode(file_get_contents($rateFile), true);
        if (is_array($data)) {
            $requests = array_filter($data, function($t) use ($now, $window) {
                return ($now - $t) < $window;
            });
        }
    }
    
    if (count($requests) >= $maxReq) {
        http_response_code(429);
        header("X-RateLimit-Limit: $maxReq");
        header("X-RateLimit-Remaining: 0");
        header("X-RateLimit-Reset: " . ($now + $window));
        echo json_encode(['status' => 'error', 'code' => 'rate_limited', 'message' => 'Rate limit exceeded. Please try again later.']);
        exit;
    }
    
    $requests[] = $now;
    file_put_contents($rateFile, json_encode($requests), LOCK_EX);
    
    // 返回速率限制头
    $remaining = $maxReq - count($requests) - 1;
    header("X-RateLimit-Limit: $maxReq");
    header("X-RateLimit-Remaining: " . max(0, $remaining));
    header("X-RateLimit-Reset: " . ($now + $window));
}

checkRateLimit($config);

// ========== HMAC-SHA256 签名验证 + 时间戳防重放 ==========
$api_key = $_SERVER['HTTP_X_API_KEY'] ?? '';
$timestamp = $_SERVER['HTTP_X_TIMESTAMP'] ?? '';
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';

if (empty($api_key) || !in_array($api_key, $config['api_keys'])) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Invalid or missing API key']);
    exit;
}

if (empty($timestamp) || !ctype_digit($timestamp)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Missing or invalid timestamp']);
    exit;
}

$ts = (int)$timestamp;
$now = time();
if (abs($now - $ts) > $config['max_timestamp_diff']) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'timestamp_expired', 'message' => 'Request expired or timestamp invalid']);
    exit;
}

if (empty($signature)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Missing signature']);
    exit;
}

// 计算期望的签名: HMAC-SHA256(api_key + timestamp, hmac_secret)
$hmacSecret = $env['HMAC_SECRET_KEY'] ?? $api_key;
$expectedSignature = hash_hmac('sha256', $api_key . $timestamp, $hmacSecret);
if (!hash_equals($expectedSignature, $signature)) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'code' => 'invalid_signature', 'message' => 'Invalid signature']);
    exit;
}

// 创建上传目录
$upload_dir = $config['upload_dir'];
if (!is_dir($upload_dir)) {
    mkdir($upload_dir, 0755, true);
}

// 文件大小检查
$content_length = (int)($_SERVER['CONTENT_LENGTH'] ?? 0);
if ($content_length > $config['max_total_size']) {
    http_response_code(413);
    echo json_encode(['status' => 'error', 'code' => 'project_too_large', 'message' => 'Payload too large. Max ' . ($config['max_total_size'] / 1024 / 1024) . 'MB']);
    exit;
}

// ========== 处理过期时间 ==========
$expire_days = isset($_POST['expire_days']) ? (int)$_POST['expire_days'] : 0;
$expire_minutes = isset($_POST['expire_minutes']) ? (int)$_POST['expire_minutes'] : 0;
$is_update = isset($_POST['is_update']) && $_POST['is_update'] === '1';
$user_id = $_POST['user_id'] ?? null;
$access_password = $_POST['access_password'] ?? null;
$enable_stats = isset($_POST['enable_stats']) && $_POST['enable_stats'] === '1'; // 当前未持久化，接受但不报错

// 对密码进行哈希存储
$hashed_password = null;
if (!empty($access_password)) {
    $hashed_password = password_hash($access_password, PASSWORD_BCRYPT);
}

// 服务端验证Pro状态（不信任客户端，但客户端声明Pro时更新数据库）
$is_pro = false;
$user_publish_count = 0;
if ($user_id) {
    try {
        $db = db();
        $user = $db->queryOne("SELECT is_pro, publish_count FROM users WHERE user_id = ?", [$user_id]);
        if ($user) {
            if ($user['is_pro']) {
                $is_pro = true;
            }
            $user_publish_count = (int)($user['publish_count'] ?? 0);
        }
    } catch (Exception $e) {
        error_log("User verification failed: " . $e->getMessage());
    }
}

// 免费用户不允许设置密码（避免设置后无法修改/移除）
if (!$is_pro && !empty($access_password)) {
    http_response_code(403);
    echo json_encode([
        'status' => 'error',
        'code' => 'pro_required',
        'message' => 'Pro subscription required to set access password. Please upgrade to Pro.'
    ]);
    exit;
}

// 免费用户发布次数限制（月度限制）
// 检查用户当月发布的项目总数（包括更新）
if (!$is_pro && $user_id) {
    try {
        $db = db();
        
        // 提前获取项目ID（从multipart或JSON请求中提取）
        $projectId = null;
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        $isMultipartCheck = strpos($contentType, 'multipart/form-data') !== false;
        
        if ($isMultipartCheck) {
            $projectId = $_POST['id'] ?? null;
        } else {
            $input = file_get_contents('php://input');
            $requestData = json_decode($input, true);
            if ($requestData) {
                $projectId = $requestData['id'] ?? null;
            }
        }
        
        // 如果是更新现有项目，检查该项目是否属于当前用户
        if ($is_update && $projectId) {
            $existingProject = $db->queryOne(
                "SELECT user_id FROM projects WHERE project_id = ? AND status != 'deleted'",
                [$projectId]
            );
            
            // 如果项目不存在或不属于当前用户，拒绝更新
            if (!$existingProject || (string)$existingProject['user_id'] !== (string)$user_id) {
                http_response_code(403);
                echo json_encode([
                    'status' => 'error',
                    'code' => 'permission_denied',
                    'message' => 'Permission denied. You can only update your own projects.'
                ]);
                exit;
            }
        }
        
        // 获取当月发布的项目数量
        $monthlyCount = $db->queryOne(
            "SELECT COUNT(*) as count FROM projects 
             WHERE user_id = ? 
             AND status != 'deleted'
             AND created_at >= DATE_FORMAT(NOW(), '%Y-%m-01 00:00:00')",
            [$user_id]
        );
        
        // 免费用户每月最多发布次数（从 system_config 读取，缺省 3）
        $freeMonthlyLimit = (int)getConfig('free_user_monthly_publish_limit', 3);
        if (!$is_update && $monthlyCount['count'] >= $freeMonthlyLimit) {
            http_response_code(403);
            echo json_encode([
                'status' => 'error',
                'code' => 'publish_limit_exceeded',
                'message' => "Monthly publish limit reached ($freeMonthlyLimit projects). Upgrade to Pro for unlimited publishes."
            ]);
            exit;
        }
    } catch (Exception $e) {
        error_log("Publish limit check failed: " . $e->getMessage());
    }
}

// 免费用户限制：必须设置过期时间
if (!$is_pro && $expire_days === 0 && $expire_minutes === 0) {
    $expire_minutes = 60; // 强制60分钟（1小时）过期
}

// 判断是否是 multipart/form-data
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
$isMultipart = strpos($contentType, 'multipart/form-data') !== false;

$visitFile = 'index.html';
$firstHtml = null;

if ($isMultipart) {
    $name = $_POST['name'] ?? 'Untitled';
    $id   = $_POST['id'] ?? null;

    // 项目ID生成逻辑
    $projectId = resolveProjectId($id, $config, $is_update, $upload_dir);
    if (is_array($projectId) && isset($projectId['error'])) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => $projectId['error']]);
        exit;
    }

    $targetPath = $upload_dir . $projectId;
    $stagingPath = $upload_dir . $projectId . '.staging_' . time();

    // 如果是更新，尝试从备份恢复（可能是之前过期的项目）
    restoreFromBackup($targetPath);

    // 先写入临时目录，成功后再原子替换
    if (is_dir($stagingPath)) safeDeleteDir($stagingPath);
    mkdir($stagingPath, 0755, true);

    if (!isset($_FILES['files'])) {
        echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'No files received']);
        exit;
    }

    $files = $_FILES['files'];
    $fileCount = is_array($files['name']) ? count($files['name']) : 1;
    $totalFiles = 0;
    $totalSize = 0;
    $maxSingleFileSize = 10 * 1024 * 1024; // 单文件10MB限制

    for ($i = 0; $i < $fileCount; $i++) {
        $tmpPath  = is_array($files['tmp_name']) ? $files['tmp_name'][$i] : $files['tmp_name'];
        $origName = is_array($files['name'])     ? $files['name'][$i]     : $files['name'];
        $error    = is_array($files['error'])    ? $files['error'][$i]    : $files['error'];
        $fileSize = is_array($files['size'])     ? $files['size'][$i]     : $files['size'];

        if ($error !== UPLOAD_ERR_OK) continue;
        
        // 单文件大小验证
        if ($fileSize > $maxSingleFileSize) {
            http_response_code(413);
            echo json_encode([
                'status' => 'error',
                'code' => 'project_too_large',
                'message' => "File '$origName' exceeds maximum size of 10MB"
            ]);
            exit;
        }
        
        $totalSize += $fileSize;

        $safeName = sanitizePath($origName);
        if (empty($safeName)) continue;

        // 文件类型白名单检查
        $ext = strtolower(pathinfo($safeName, PATHINFO_EXTENSION));
        if (!in_array($ext, $config['allowed_extensions'])) {
            continue;
        }

        $destFile = safeJoinPath($stagingPath, $safeName);
        if ($destFile === false) continue;

        $destDir = dirname($destFile);
        if (!is_dir($destDir)) {
            mkdir($destDir, 0755, true);
        }

        if (move_uploaded_file($tmpPath, $destFile)) {
            $totalFiles++;

            if ($safeName === 'index.html' || $safeName === 'index.htm') {
                $visitFile = $safeName;
            } elseif ($firstHtml === null && in_array($ext, ['html', 'htm'])) {
                $firstHtml = $safeName;
            }
        } else {
            error_log("Failed to move uploaded file: $destFile");
        }
    }
    
    // 总大小二次验证
    if ($totalSize > $config['max_total_size']) {
        http_response_code(413);
        echo json_encode(['status' => 'error', 'code' => 'project_too_large', 'message' => 'Total payload too large. Max ' . ($config['max_total_size'] / 1024 / 1024) . 'MB']);
        exit;
    }

    if ($totalFiles === 0) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'code' => 'operation_failed', 'message' => 'Failed to save uploaded files']);
        exit;
    }

    if ($visitFile === 'index.html' && !file_exists($stagingPath . '/index.html') && $firstHtml) {
        $visitFile = $firstHtml;
    }

    // 原子替换：删除旧目录，重命名临时目录到正式目录
    if (is_dir($targetPath)) safeDeleteDir($targetPath);
    rename($stagingPath, $targetPath);

} else {
    $input = file_get_contents('php://input');
    $data  = json_decode($input, true);

    if (($data['action'] ?? '') === 'test') {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Missing files']);
        exit;
    }

    if (!$data || !isset($data['files'])) {
        echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => 'Invalid data payload']);
        exit;
    }

    $id = $data['id'] ?? null;
    $expire_days = isset($data['expire_days']) ? (int)$data['expire_days'] : 0;
    $is_update = isset($data['is_update']) && $data['is_update'] === true;
    $name = $data['name'] ?? 'Untitled';

    $projectId = resolveProjectId($id, $config, $is_update, $upload_dir);
    if (is_array($projectId) && isset($projectId['error'])) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'code' => 'invalid_request', 'message' => $projectId['error']]);
        exit;
    }

    $targetPath = $upload_dir . $projectId;
    $stagingPath = $upload_dir . $projectId . '.staging_' . time();

    // 如果是更新，尝试从备份恢复（可能是之前过期的项目）
    restoreFromBackup($targetPath);

    // 先写入临时目录，成功后再原子替换
    if (is_dir($stagingPath)) safeDeleteDir($stagingPath);
    mkdir($stagingPath, 0755, true);

    $totalFiles = 0;
    foreach ($data['files'] as $fileName => $content) {
        $safeName = sanitizePath($fileName);
        if (empty($safeName)) continue;

        $ext = strtolower(pathinfo($safeName, PATHINFO_EXTENSION));
        if (!in_array($ext, $config['allowed_extensions'])) {
            continue;
        }

        $destFile = safeJoinPath($stagingPath, $safeName);
        if ($destFile === false) continue;

        $destDir = dirname($destFile);
        if (!is_dir($destDir)) mkdir($destDir, 0755, true);

        if (file_put_contents($destFile, $content) !== false) {
            $totalFiles++;

            if ($safeName === 'index.html' || $safeName === 'index.htm') {
                $visitFile = $safeName;
            } elseif ($firstHtml === null && in_array($ext, ['html', 'htm'])) {
                $firstHtml = $safeName;
            }
        } else {
            error_log("Failed to write file: $destFile");
        }
    }

    if ($totalFiles === 0) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'code' => 'operation_failed', 'message' => 'Failed to save uploaded files']);
        exit;
    }

    if ($visitFile === 'index.html' && !file_exists($stagingPath . '/index.html') && $firstHtml) {
        $visitFile = $firstHtml;
    }

    // 原子替换
    if (is_dir($targetPath)) safeDeleteDir($targetPath);
    rename($stagingPath, $targetPath);
}

// 保存项目到数据库
saveProjectToDatabase($projectId, $expire_days, $name ?? 'Untitled', $expire_minutes, $user_id, $is_pro, $totalFiles, $hashed_password, $is_update);

// 构建返回URL
$longUrl = $config['base_url'] . $projectId . '/' . $visitFile;

$expiresAt = null;
if ($expire_days > 0) {
    $expiresAt = date('Y-m-d H:i:s', strtotime("+$expire_days days"));
} elseif ($expire_minutes > 0) {
    $expiresAt = date('Y-m-d H:i:s', strtotime("+$expire_minutes minutes"));
}

echo json_encode([
    'status' => 'success',
    'code' => 'ok',
    'url'    => $longUrl,
    'id'     => $projectId,
    'expires_at' => $expiresAt,
    'has_password' => !empty($hashed_password),
]);

// ========== 项目ID处理函数 ==========

function resolveProjectId($existingId, $config, $isUpdate, $uploadDir) {
    // 如果是更新且存在已有ID，优先使用已有ID
    if ($isUpdate && $existingId && isValidProjectId($existingId)) {
        return $existingId;
    }
    
    // 生成随机项目ID
    return generateRandomProjectId($uploadDir);
}

function isValidProjectId($id) {
    return preg_match('/^[a-z0-9]{8}$/', $id);
}

function generateRandomProjectId($uploadDir) {
    $maxAttempts = 10;
    for ($i = 0; $i < $maxAttempts; $i++) {
        $id = substr(md5(uniqid(mt_rand(), true)), 0, 8);
        if (!is_dir($uploadDir . $id)) {
            return $id;
        }
    }
    // 如果冲突太多，使用更长的ID
    return substr(md5(uniqid(mt_rand(), true)), 0, 12);
}

/**
 * 保存项目到数据库（使用事务确保数据一致性）
 */
function saveProjectToDatabase($projectId, $expireDays, $projectName, $expireMinutes = 0, $userId = null, $isPro = false, $fileCount = 0, $hashedPassword = null, $isUpdate = false) {
    try {
        $db = db();
        $db->beginTransaction();

        // 检查是否是更新
        $existing = $db->queryOne("SELECT id, expires_at, access_password FROM projects WHERE project_id = ?", [$projectId]);

        // 计算过期时间
        $expiresAt = null;
        if ($expireDays > 0) {
            $expiresAt = date('Y-m-d H:i:s', strtotime("+$expireDays days"));
        } elseif ($expireMinutes > 0) {
            $expiresAt = date('Y-m-d H:i:s', strtotime("+$expireMinutes minutes"));
        } elseif ($isUpdate && $existing) {
            // 更新时未提供过期参数，保留原有过期时间
            $expiresAt = $existing['expires_at'];
        }

        // 更新时未提供密码，保留原有密码
        if ($isUpdate && $existing && $hashedPassword === null) {
            $hashedPassword = $existing['access_password'];
        }

        if ($existing) {
            // 更新现有项目
            $db->execute(
                "UPDATE projects SET
                 project_name = ?,
                 user_id = ?,
                 is_pro = ?,
                 file_count = ?,
                 expire_days = ?,
                 expire_minutes = ?,
                 expires_at = ?,
                 access_password = ?,
                 updated_at = NOW()
                 WHERE project_id = ?",
                [$projectName, $userId, $isPro ? 1 : 0, $fileCount, $expireDays, $expireMinutes, $expiresAt, $hashedPassword, $projectId]
            );
        } else {
            // 插入新项目
            $db->execute(
                "INSERT INTO projects 
                 (project_id, project_name, user_id, is_pro, file_count, expire_days, expire_minutes, expires_at, access_password, visit_count, status) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'active')",
                [$projectId, $projectName, $userId, $isPro ? 1 : 0, $fileCount, $expireDays, $expireMinutes, $expiresAt, $hashedPassword]
            );
        }
        
        // 更新或创建用户记录
        if ($userId) {
            upsertUser($userId, $isPro, $projectId);
            
            // 记录用户活动
            logUserActivity($userId, $existing ? 'update' : 'publish', $projectId);
        }
        
        $db->commit();
    } catch (Exception $e) {
        if (isset($db)) {
            try {
                $db->rollBack();
            } catch (Exception $rollbackEx) {
                error_log("Failed to rollback: " . $rollbackEx->getMessage());
            }
        }
        error_log("Failed to save project to database: " . $e->getMessage());
        throw $e;
    }
}

/**
 * 更新或插入用户记录
 */
function upsertUser($userId, $isPro, $projectId) {
    try {
        $db = db();
        $now = date('Y-m-d H:i:s');
        
        // 检查用户是否存在
        $existingUser = $db->queryOne("SELECT id, is_pro FROM users WHERE user_id = ?", [$userId]);
        
        if ($existingUser) {
            // 更新用户
            $db->execute(
                "UPDATE users SET 
                 is_pro = ?, 
                 last_active_at = NOW(),
                 publish_count = publish_count + 1
                 WHERE user_id = ?",
                [$isPro ? 1 : 0, $userId]
            );
        } else {
            // 创建新用户
            $db->execute(
                "INSERT INTO users (user_id, is_pro, publish_count, created_at, last_active_at) 
                 VALUES (?, ?, 1, ?, ?)",
                [$userId, $isPro ? 1 : 0, $now, $now]
            );
        }
    } catch (Exception $e) {
        error_log("Failed to upsert user: " . $e->getMessage());
    }
}

/**
 * 记录用户活动日志
 */
function logUserActivity($userId, $action, $projectId) {
    try {
        $db = db();
        $db->execute(
            "INSERT INTO user_activity_logs (user_id, project_id, action) VALUES (?, ?, ?)",
            [$userId, $projectId, $action]
        );
    } catch (Exception $e) {
        error_log("Failed to log user activity: " . $e->getMessage());
    }
}

// ========== 安全辅助函数 ==========

function sanitizePath($path) {
    $path = str_replace('\\', '/', $path);
    $path = preg_replace('#\.\.+/#', '', $path);
    $path = preg_replace('#/\.\.+#', '', $path);
    $path = preg_replace('#^\.\.?/#', '', $path);
    $path = ltrim($path, '/');
    if (empty($path) || $path[0] === '/' || strpos($path, ':') !== false) {
        return '';
    }
    return $path;
}

function safeJoinPath($baseDir, $relativePath) {
    $baseReal = realpath($baseDir);
    if ($baseReal === false) {
        $baseReal = realpath(dirname($baseDir)) . '/' . basename($baseDir);
    }

    $fullPath = $baseReal . '/' . $relativePath;
    $fullReal = realpath(dirname($fullPath));

    if ($fullReal === false) {
        $parentDir = dirname($fullPath);
        if (strpos(realpath(dirname($parentDir)) ?: '', $baseReal) !== 0) {
            return false;
        }
        return $fullPath;
    }

    if (strpos($fullReal, $baseReal) !== 0) {
        return false;
    }

    return $fullPath;
}

function safeDeleteDir($dir) {
    if (!is_dir($dir)) return;
    $realDir = realpath($dir);
    if ($realDir === false) return;

    $items = scandir($realDir);
    foreach ($items as $item) {
        if ($item === '.' || $item === '..') continue;
        $path = $realDir . '/' . $item;
        if (is_dir($path)) {
            safeDeleteDir($path);
        } else {
            unlink($path);
        }
    }
    rmdir($realDir);
}

/**
 * 从备份恢复文件（用于重新发布时恢复过期项目的原始内容）
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
        error_log("[Publish] Restored {$restored} files from backup for {$targetPath}");
    }
}

?>
