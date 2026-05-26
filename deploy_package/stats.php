<?php
/**
 * HTML Code Editor - Stats API (MySQL版本)
 * 提供单个项目的访问统计信息
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

if ($_SERVER['REQUEST_METHOD'] !== 'GET' || !isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Missing id parameter']);
    exit;
}

$projectId = $_GET['id'];

require_once __DIR__ . '/database/Database.php';

// HMAC Authentication (optional - if auth headers present, verify them)
$apiKey = $_SERVER['HTTP_X_API_KEY'] ?? '';
$timestamp = $_SERVER['HTTP_X_TIMESTAMP'] ?? '';
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';

if (!empty($apiKey) && !empty($timestamp) && !empty($signature)) {
    // Verify HMAC signature
    $envPath = __DIR__ . '/.env';
    $configApiKey = '';
    $configHmacSecret = '';
    if (file_exists($envPath)) {
        $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            if (strpos(trim($line), '#') === 0) continue;
            $parts = explode('=', $line, 2);
            if (count($parts) === 2) {
                if (trim($parts[0]) === 'PUBLISH_API_KEY') $configApiKey = trim($parts[1]);
                if (trim($parts[0]) === 'HMAC_SECRET_KEY') $configHmacSecret = trim($parts[1]);
            }
        }
    }
    
    if ($configApiKey && $apiKey === $configApiKey) {
        $secret = $configHmacSecret ?: $configApiKey;
        $message = $apiKey . $timestamp;
        $expectedSignature = hash_hmac('sha256', $message, $secret);
        
        if (abs(time() - (int)$timestamp) > 300 || !hash_equals($expectedSignature, $signature)) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Authentication failed']);
            exit;
        }
    }
}

$project = db()->queryOne(
    "SELECT * FROM projects WHERE project_id = ? AND status != 'deleted' LIMIT 1",
    [$projectId]
);

if (!$project) {
    http_response_code(404);
    echo json_encode(['status' => 'error', 'message' => 'Project not found']);
    exit;
}

$visits = [];
$projectIdDb = $project['project_id'];

// 优化：使用单条SQL查询获取7天数据
$sevenDaysAgo = date('Y-m-d', strtotime('-6 days'));
$today = date('Y-m-d');

$sql = "SELECT DATE(visited_at) as visit_date, COUNT(*) as cnt 
        FROM visit_logs 
        WHERE project_id = ? 
        AND DATE(visited_at) BETWEEN ? AND ?
        GROUP BY DATE(visited_at)
        ORDER BY visit_date ASC";

$results = db()->query($sql, [$projectIdDb, $sevenDaysAgo, $today]);

// 创建日期索引的结果映射
$visitMap = [];
foreach ($results as $row) {
    $visitMap[$row['visit_date']] = (int)$row['cnt'];
}

// 填充完整的7天数据（包括没有访问的日期）
for ($i = 6; $i >= 0; $i--) {
    $date = date('Y-m-d', strtotime("-$i days"));
    $visits[$date] = $visitMap[$date] ?? 0;
}

// 获取唯一访客数
$uniqueResult = db()->queryOne(
    "SELECT COUNT(DISTINCT ip_address) as cnt FROM visit_logs WHERE project_id = ?",
    [$projectIdDb]
);
$uniqueVisitors = (int)($uniqueResult['cnt'] ?? 0);

// 获取今日访问数
$todayResult = db()->queryOne(
    "SELECT COUNT(*) as cnt FROM visit_logs WHERE project_id = ? AND DATE(visited_at) = CURDATE()",
    [$projectIdDb]
);
$todayVisits = (int)($todayResult['cnt'] ?? 0);

echo json_encode([
    'status' => 'success',
    'visit_count' => $project['visit_count'] ?? 0,
    'total_visits' => $project['visit_count'] ?? 0,
    'unique_visitors' => $uniqueVisitors,
    'today_visits' => $todayVisits,
    'seven_day_visits' => array_sum($visits),
    'daily_visits' => $visits,
    'created_at' => $project['created_at'] ?? null,
    'expires_at' => $project['expires_at'] ?? null,
    'is_expired' => $project['expires_at'] ? (strtotime($project['expires_at']) < time()) : false,
]);
