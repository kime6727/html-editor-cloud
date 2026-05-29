<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: text/plain; charset=utf-8');

// 模拟 index.php 的完整流程
$rootDir = dirname(__DIR__);
$projectId = $_GET['project_id'] ?? '91c98211';

echo "Step 1: rootDir=$rootDir\n";

require_once $rootDir . '/database/Database.php';

echo "Step 2: DB OK\n";

$db = db();
$project = $db->queryOne("SELECT * FROM projects WHERE project_id = ? LIMIT 1", [$projectId]);

echo "Step 3: Project columns: " . implode(', ', array_keys($project)) . "\n";

echo "Step 4: status={$project['status']}\n";

// Check for deleted/banned
if ($project['status'] === 'deleted' || $project['status'] === 'banned') {
    echo "Step 4b: Project is deleted/banned\n";
    exit;
}

// Check expiration
echo "Step 5: expires_at={$project['expires_at']}\n";

if ($project['expires_at']) {
    $expiresAt = strtotime($project['expires_at']);
    $now = time();
    echo "Step 6: expiresAt=$expiresAt, now=$now, diff=" . ($now - $expiresAt) . "s\n";
    
    if ($now > $expiresAt) {
        echo "Step 7: Project IS EXPIRED\n";
        
        if ($project['status'] !== 'expired') {
            echo "Step 8: Updating status to expired...\n";
        }
        
        // Test the columns exist
        echo "Step 9: expired_redirect_type = " . ($project['expired_redirect_type'] ?? 'NOTSET') . "\n";
        echo "Step 10: expired_redirect_url = " . ($project['expired_redirect_url'] ?? 'NOTSET') . "\n";
        echo "Step 11: expired_custom_message = " . ($project['expired_custom_message'] ?? 'NOTSET') . "\n";
        
        // Test expired template
        $templatePath = $rootDir . '/expired_template.html';
        echo "Step 12: expired_template exists: " . (file_exists($templatePath) ? 'YES' : 'NO') . "\n";
        
        echo "\n✅ All steps passed!\n";
        exit;
    }
}

// Check password
echo "Step 13: access_password = " . (empty($project['access_password']) ? 'NULL' : 'SET') . "\n";

// Check project dir
$projectDir = $rootDir . '/pub/' . $projectId;
echo "Step 14: projectDir=$projectDir, exists=" . (is_dir($projectDir) ? 'YES' : 'NO') . "\n";

if (is_dir($projectDir)) {
    $filePath = $projectDir . '/index.html';
    echo "Step 15: indexPath=$filePath, exists=" . (file_exists($filePath) ? 'YES' : 'NO') . "\n";
    if (file_exists($filePath)) {
        echo "Step 16: file size=" . filesize($filePath) . " bytes\n";
    }
}

echo "\n=== Testing readfile() ===\n";
echo "filePath: $filePath\n";
echo "realpath: " . realpath($filePath) . "\n";
echo "filesize: " . filesize($filePath) . " bytes\n";
echo "is_readable: " . (is_readable($filePath) ? 'YES' : 'NO') . "\n";

$content = file_get_contents($filePath);
echo "file_get_contents length: " . strlen($content) . "\n";
echo "First 100 chars: " . substr($content, 0, 100) . "\n";

echo "\n=== Now testing readfile() ===\n";
ob_start();
$result = @readfile($filePath);
$output = ob_get_clean();
echo "readfile result: " . var_export($result, true) . "\n";
echo "readfile output length: " . strlen($output) . "\n";

echo "\n=== Testing header() + content ===\n";
header('Content-Type: text/html; charset=utf-8');
echo $output;

echo "\n✅ ALL DONE - No errors!\n";