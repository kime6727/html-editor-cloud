<?php
/**
 * 发布页面调试 - 模拟 index.php 的处理流程并输出详细错误
 */
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/plain; charset=utf-8');

echo "=== Pub 页面调试 ===\n\n";

$rootDir = __DIR__ . '/..';

echo "rootDir: $rootDir\n";
echo "pub dir exists: " . (is_dir($rootDir . '/pub') ? 'YES' : 'NO') . "\n\n";

require_once $rootDir . '/database/Database.php';

$projectId = $_GET['project_id'] ?? '91c98211';

echo "project_id: $projectId\n\n";

try {
    $db = db();
    echo "DB connection: OK\n";
    
    $project = $db->queryOne("SELECT * FROM projects WHERE project_id = ? LIMIT 1", [$projectId]);
    
    if (!$project) {
        echo "❌ Project not found!\n";
        
        $allProjects = $db->query("SELECT project_id, project_name, status FROM projects");
        echo "Total projects in DB: " . count($allProjects) . "\n";
        foreach ($allProjects as $p) {
            echo "  - {$p['project_id']}: {$p['project_name']} (status={$p['status']})\n";
        }
        exit;
    }
    
    echo "Project found:\n";
    echo "  name: {$project['project_name']}\n";
    echo "  status: {$project['status']}\n";
    echo "  expires_at: " . ($project['expires_at'] ?? 'NULL') . "\n";
    echo "  access_password: " . (empty($project['access_password']) ? 'NULL' : 'SET') . "\n\n";
    
    $projectDir = $rootDir . '/pub/' . $projectId;
    echo "projectDir: $projectDir\n";
    echo "exists: " . (is_dir($projectDir) ? 'YES' : 'NO') . "\n";
    
    if (is_dir($projectDir)) {
        $files = scandir($projectDir);
        echo "Files in dir:\n";
        foreach ($files as $f) {
            if ($f === '.' || $f === '..') continue;
            echo "  - $f (" . filesize($projectDir . '/' . $f) . " bytes)\n";
        }
    }
    
    echo "\n✅ All checks passed!\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo "Trace: " . $e->getTraceAsString() . "\n";
}