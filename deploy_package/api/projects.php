<?php
/**
 * HTML Code Editor - Projects Management API
 * 统一的项目管理接口
 * 支持: 列表、详情、状态切换、过期设置、密码管理、删除、统计
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');

error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
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

$env = loadEnv(__DIR__ . '/../.env');

// HMAC-SHA256 签名验证
$api_key = $_SERVER['HTTP_X_API_KEY'] ?? '';
$timestamp = $_SERVER['HTTP_X_TIMESTAMP'] ?? $_GET['timestamp'] ?? '';
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? $_GET['signature'] ?? '';

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

require_once __DIR__ . '/../database/Database.php';

// 获取action
$action = $_GET['action'] ?? $_POST['action'] ?? '';

// 路由分发
switch ($action) {
    case 'list':
        handleListProjects();
        break;
    case 'get':
        handleGetProject();
        break;
    case 'toggle_status':
        handleToggleStatus();
        break;
    case 'set_expiry':
        handleSetExpiry();
        break;
    case 'set_password':
        handleSetPassword();
        break;
    case 'remove_password':
        handleRemovePassword();
        break;
    case 'unpublish':
        handleUnpublish();
        break;
    case 'stats':
        handleGetStats();
        break;
    case 'update_content':
        handleUpdateContent();
        break;
    case 'set_redirect_url':
        handleSetRedirectUrl();
        break;
    case 'get_visit_logs':
        handleGetVisitLogs();
        break;
    case 'batch_operation':
        handleBatchOperation();
        break;
    case 'create_temp_link':
        handleCreateTempLink();
        break;
    default:
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
        exit;
}

// ========== 处理函数 ==========

/**
 * 列出用户的所有项目
 */
function handleListProjects() {
    $userId = $_GET['user_id'] ?? null;
    
    try {
        $sql = "SELECT 
                    p.*,
                    (SELECT COUNT(*) FROM visit_logs vl WHERE vl.project_id = p.project_id AND DATE(vl.visited_at) = CURDATE()) as today_visits,
                    (SELECT COUNT(DISTINCT ip_address) FROM visit_logs vl WHERE vl.project_id = p.project_id) as unique_visitors
                FROM projects p 
                WHERE p.status != 'deleted'";
        
        $params = [];
        if ($userId) {
            $sql .= " AND p.user_id = ?";
            $params[] = $userId;
        }
        
        $sql .= " ORDER BY p.updated_at DESC";
        
        $projects = db()->query($sql, $params);
        
        $result = [];
        foreach ($projects as $p) {
            $result[] = [
                'id' => $p['project_id'],
                'projectId' => $p['project_id'],
                'projectName' => $p['project_name'],
                'url' => buildProjectUrl($p),
                'isActive' => $p['status'] === 'active',
                'visitCount' => (int)$p['visit_count'],
                'uniqueVisitors' => (int)($p['unique_visitors'] ?? 0),
                'todayVisits' => (int)($p['today_visits'] ?? 0),
                'publishedAt' => strtotime($p['created_at']),
                'expiresAt' => $p['expires_at'] ? strtotime($p['expires_at']) : null,
                'lastVisitedAt' => $p['last_visited_at'] ? strtotime($p['last_visited_at']) : null,
                'hasPassword' => !empty($p['access_password'])
            ];
        }
        
        echo json_encode([
            'success' => true,
            'message' => 'Projects loaded',
            'projects' => $result
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 获取单个项目详情
 */
function handleGetProject() {
    $projectId = $_GET['project_id'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        $project = db()->queryOne(
            "SELECT * FROM projects WHERE project_id = ? AND status != 'deleted'",
            [$projectId]
        );
        
        if (!$project) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Project not found']);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'project' => [
                'id' => $project['project_id'],
                'name' => $project['project_name'],
                'url' => buildProjectUrl($project),
                'visitCount' => (int)$project['visit_count'],
                'status' => $project['status'],
                'expiresAt' => $project['expires_at'],
                'hasPassword' => !empty($project['access_password'])
            ]
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 切换项目状态（启用/停用）
 */
function handleToggleStatus() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $isActive = $input['is_active'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId || $isActive === null) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        $newStatus = $isActive ? 'active' : 'inactive';
        
        db()->execute(
            "UPDATE projects SET status = ?, updated_at = NOW() WHERE project_id = ?",
            [$newStatus, $projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Status updated'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 设置过期时间
 */
function handleSetExpiry() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $expiresAt = $input['expires_at'] ?? null; // Unix timestamp
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        $expiryDate = null;
        $expireDays = 0;
        
        if ($expiresAt !== null && $expiresAt > 0) {
            $expiryDate = date('Y-m-d H:i:s', $expiresAt);
            $expireDays = ceil(($expiresAt - time()) / 86400);
        }
        
        db()->execute(
            "UPDATE projects SET expires_at = ?, expire_days = ?, updated_at = NOW() WHERE project_id = ?",
            [$expiryDate, $expireDays, $projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Expiry updated'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 设置访问密码
 */
function handleSetPassword() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $password = $input['password'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId || !$password) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        // 使用bcrypt加密密码
        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        
        db()->execute(
            "UPDATE projects SET access_password = ?, updated_at = NOW() WHERE project_id = ?",
            [$hashedPassword, $projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Password set'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 移除访问密码
 */
function handleRemovePassword() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        db()->execute(
            "UPDATE projects SET access_password = NULL, updated_at = NOW() WHERE project_id = ?",
            [$projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Password removed'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 取消发布（删除项目）
 */
function handleUnpublish() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        
        // 获取项目信息
        $project = db()->queryOne(
            "SELECT * FROM projects WHERE project_id = ?",
            [$projectId]
        );
        
        if (!$project) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Project not found']);
            return;
        }
        
        // 软删除数据库记录
        db()->execute(
            "UPDATE projects SET status = 'deleted', updated_at = NOW() WHERE project_id = ?",
            [$projectId]
        );
        
        // 删除文件目录
        $uploadDir = __DIR__ . '/../pub/';
        $projectDir = $uploadDir . $projectId;
        if (!is_dir($projectDir)) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Project directory not found']);
            return;
        }
        
        // 删除文件目录
        safeDeleteDir($projectDir);
        
        echo json_encode([
            'success' => true,
            'message' => 'Project unpublished'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 获取项目统计
 */
function handleGetStats() {
    $projectId = $_GET['project_id'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        $project = db()->queryOne(
            "SELECT * FROM projects WHERE project_id = ?",
            [$projectId]
        );
        
        if (!$project) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Project not found']);
            return;
        }
        
        // 获取7天访问数据
        $visits = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $result = db()->queryOne(
                "SELECT COUNT(*) as cnt FROM visit_logs WHERE project_id = ? AND DATE(visited_at) = ?",
                [$projectId, $date]
            );
            $visits[] = [
                'date' => $date,
                'count' => (int)($result['cnt'] ?? 0)
            ];
        }
        
        // 获取来源统计
        $referrers = db()->query(
            "SELECT referer as source, COUNT(*) as count 
             FROM visit_logs 
             WHERE project_id = ? AND referer IS NOT NULL AND referer != '' 
             GROUP BY referer 
             ORDER BY count DESC 
             LIMIT 10",
            [$projectId]
        );
        
        // 获取唯一访客数
        $uniqueResult = db()->queryOne(
            "SELECT COUNT(DISTINCT ip_address) as cnt FROM visit_logs WHERE project_id = ?",
            [$projectId]
        );
        $uniqueVisitors = (int)($uniqueResult['cnt'] ?? 0);
        
        // 获取今日访问数
        $todayResult = db()->queryOne(
            "SELECT COUNT(*) as cnt FROM visit_logs WHERE project_id = ? AND DATE(visited_at) = CURDATE()",
            [$projectId]
        );
        $todayVisits = (int)($todayResult['cnt'] ?? 0);
        
        echo json_encode([
            'totalVisits' => (int)$project['visit_count'],
            'uniqueVisitors' => $uniqueVisitors,
            'todayVisits' => $todayVisits,
            'visitsByDay' => $visits,
            'topReferrers' => $referrers,
            'topCountries' => []
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 更新项目内容
 */
function handleUpdateContent() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $content = $input['content'] ?? null;
    $userId = $input['user_id'] ?? null;
    
    if (!$projectId || !$content) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        // 更新文件内容
        $uploadDir = __DIR__ . '/../pub/';
        $projectDir = $uploadDir . $projectId;
        $indexFile = $projectDir . '/index.html';
        
        if (!is_dir($projectDir)) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Project directory not found']);
            return;
        }
        
        file_put_contents($indexFile, $content);
        
        // 更新数据库
        db()->execute(
            "UPDATE projects SET updated_at = NOW() WHERE project_id = ?",
            [$projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Content updated'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 设置到期后重定向URL
 */
function handleSetRedirectUrl() {
    $input = json_decode(file_get_contents('php://input'), true);
    $projectId = $input['project_id'] ?? null;
    $userId = $input['user_id'] ?? null;
    $redirectUrl = $input['redirect_url'] ?? null;
    $customMessage = $input['custom_message'] ?? null;
    $redirectType = $input['redirect_type'] ?? 'app_promotion'; // app_promotion, custom_url, custom_message
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        // 验证自定义URL格式
        if ($redirectType === 'custom_url' && $redirectUrl) {
            if (!filter_var($redirectUrl, FILTER_VALIDATE_URL)) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Invalid redirect URL']);
                return;
            }
        }
        
        // 更新数据库
        db()->execute(
            "UPDATE projects SET 
             expired_redirect_type = ?, 
             expired_redirect_url = ?, 
             expired_custom_message = ?,
             updated_at = NOW() 
             WHERE project_id = ?",
            [$redirectType, $redirectUrl, $customMessage, $projectId]
        );
        
        echo json_encode([
            'success' => true,
            'message' => 'Redirect settings updated'
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 获取访问日志详情
 */
function handleGetVisitLogs() {
    $projectId = $_GET['project_id'] ?? null;
    $userId = $_GET['user_id'] ?? null;
    $page = (int)($_GET['page'] ?? 1);
    $limit = (int)($_GET['limit'] ?? 50);
    $startDate = $_GET['start_date'] ?? null;
    $endDate = $_GET['end_date'] ?? null;
    
    if (!$projectId) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing project_id']);
        return;
    }
    
    try {
        requireProjectOwner($projectId, $userId);
        // 构建查询条件
        $where = "WHERE project_id = ?";
        $params = [$projectId];
        
        if ($startDate) {
            $where .= " AND DATE(visited_at) >= ?";
            $params[] = $startDate;
        }
        
        if ($endDate) {
            $where .= " AND DATE(visited_at) <= ?";
            $params[] = $endDate;
        }
        
        // 获取总数
        $totalResult = db()->queryOne(
            "SELECT COUNT(*) as cnt FROM visit_logs $where",
            $params
        );
        $total = (int)($totalResult['cnt'] ?? 0);
        
        // 获取分页数据
        $offset = ($page - 1) * $limit;
        $logs = db()->query(
            "SELECT 
                id,
                ip_address,
                user_agent,
                referer,
                device_type,
                visited_at
             FROM visit_logs 
             $where
             ORDER BY visited_at DESC 
             LIMIT ? OFFSET ?",
            array_merge($params, [$limit, $offset])
        );
        
        // 处理日志数据
        $processedLogs = [];
        foreach ($logs as $log) {
            // 解析User Agent获取更多信息
            $deviceIcon = 'desktop';
            if (stripos($log['user_agent'], 'mobile') !== false || stripos($log['user_agent'], 'iphone') !== false) {
                $deviceIcon = 'mobile';
            } elseif (stripos($log['user_agent'], 'ipad') !== false || stripos($log['user_agent'], 'tablet') !== false) {
                $deviceIcon = 'tablet';
            }
            
            // 解析来源
            $source = '直接访问';
            if (!empty($log['referer'])) {
                $parsedUrl = parse_url($log['referer']);
                $source = $parsedUrl['host'] ?? '未知来源';
            }
            
            $processedLogs[] = [
                'id' => $log['id'],
                'ip' => maskIP($log['ip_address']),
                'device' => $log['device_type'] ?? 'unknown',
                'deviceIcon' => $deviceIcon,
                'referer' => $log['referer'] ?? '',
                'source' => $source,
                'visitedAt' => $log['visited_at']
            ];
        }
        
        echo json_encode([
            'success' => true,
            'total' => $total,
            'page' => $page,
            'limit' => $limit,
            'totalPages' => ceil($total / $limit),
            'logs' => $processedLogs
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 批量操作
 */
function handleBatchOperation() {
    $input = json_decode(file_get_contents('php://input'), true);
    $operation = $input['operation'] ?? null; // delete, extend_expiry, toggle_status
    $projectIds = $input['project_ids'] ?? [];
    $userId = $input['user_id'] ?? null;
    $params = $input['params'] ?? [];
    
    if (!$operation || empty($projectIds)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing parameters']);
        return;
    }
    
    try {
        $successCount = 0;
        $failCount = 0;
        $errors = [];
        
        foreach ($projectIds as $projectId) {
            try {
                requireProjectOwner($projectId, $userId);
                switch ($operation) {
                    case 'delete':
                        // 软删除
                        db()->execute(
                            "UPDATE projects SET status = 'deleted', updated_at = NOW() WHERE project_id = ?",
                            [$projectId]
                        );
                        
                        // 删除文件目录
                        $uploadDir = __DIR__ . '/../pub/';
                        $projectDir = $uploadDir . $projectId;
                        if (is_dir($projectDir)) {
                            safeDeleteDir($projectDir);
                        }
                        
                        break;
                        
                    case 'extend_expiry':
                        $days = (int)($params['days'] ?? 7);
                        $newExpiry = time() + ($days * 86400);
                        $expiryDate = date('Y-m-d H:i:s', $newExpiry);
                        
                        db()->execute(
                            "UPDATE projects SET expires_at = ?, expire_days = ?, updated_at = NOW() WHERE project_id = ?",
                            [$expiryDate, $days, $projectId]
                        );
                        break;
                        
                    case 'toggle_status':
                        $newStatus = $params['status'] ?? 'active';
                        db()->execute(
                            "UPDATE projects SET status = ?, updated_at = NOW() WHERE project_id = ?",
                            [$newStatus, $projectId]
                        );
                        break;
                        
                    default:
                        throw new Exception("Unknown operation: $operation");
                }
                
                $successCount++;
            } catch (Exception $e) {
                $failCount++;
                $errors[] = [
                    'project_id' => $projectId,
                    'error' => $e->getMessage()
                ];
            }
        }
        
        echo json_encode([
            'success' => true,
            'message' => "Batch operation completed",
            'successCount' => $successCount,
            'failCount' => $failCount,
            'errors' => $errors
        ]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}

/**
 * 创建临时访问链接
 */
function handleCreateTempLink() {
    http_response_code(410);
    echo json_encode(['success' => false, 'message' => 'Temporary access links have been removed']);
}

// ========== 辅助函数 ==========

function buildProjectUrl($project) {
    $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $currentDir = dirname(dirname($_SERVER['SCRIPT_NAME']));
    $rootUrl = $protocol . '://' . $host . ($currentDir === '/' ? '' : $currentDir) . '/';
    
    return $rootUrl . 'pub/' . $project['project_id'] . '/index.html';
}

function getDataDir($type = '') {
    $baseDir = dirname(__DIR__, 2) . '/data/';
    if ($type !== '') {
        $baseDir .= trim($type, '/') . '/';
    }
    if (!is_dir($baseDir)) {
        mkdir($baseDir, 0755, true);
    }
    return $baseDir;
}

function requireProjectOwner($projectId, $userId) {
    if (empty($userId)) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Missing user_id']);
        exit;
    }
    
    $project = db()->queryOne(
        "SELECT user_id FROM projects WHERE project_id = ? AND status != 'deleted' LIMIT 1",
        [$projectId]
    );
    
    if (!$project) {
        http_response_code(404);
        echo json_encode(['success' => false, 'message' => 'Project not found']);
        exit;
    }
    
    if (!empty($project['user_id']) && $project['user_id'] !== $userId) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Permission denied']);
        exit;
    }
}

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

function maskIP($ip) {
    if (empty($ip)) return '';
    $parts = explode('.', $ip);
    if (count($parts) === 4) {
        return $parts[0] . '.' . $parts[1] . '.*.*';
    }
    return substr($ip, 0, strlen($ip) - 4) . '****';
}
