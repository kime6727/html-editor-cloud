<?php
/**
 * 发布功能诊断脚本
 * 用于测试文件上传和路径配置
 */

echo "=== 云端发布功能诊断 ===\n\n";

// 1. 检查路径配置
$scriptDir = __DIR__;
$pubDir = $scriptDir . '/../pub/';
$realPubDir = realpath($pubDir);

echo "1. 路径配置:\n";
echo "   脚本目录: $scriptDir\n";
echo "   Pub目录配置: $pubDir\n";
echo "   Pub目录实际路径: " . ($realPubDir ?: '不存在') . "\n";
echo "   Pub目录存在: " . (is_dir($pubDir) ? '是' : '否') . "\n";
echo "   Pub目录可写: " . (is_writable($pubDir) ? '是' : '否') . "\n\n";

// 2. 检查数据库连接
echo "2. 数据库连接:\n";
try {
    require_once __DIR__ . '/database/Database.php';
    $db = db();
    echo "   数据库连接: 成功\n";
    
    // 检查projects表
    $count = $db->queryOne("SELECT COUNT(*) as cnt FROM projects");
    echo "   项目总数: " . $count['cnt'] . "\n";
    
    // 检查最近的项目
    $recent = $db->query("SELECT project_id, project_name, created_at FROM projects ORDER BY created_at DESC LIMIT 5");
    echo "   最近5个项目:\n";
    foreach ($recent as $p) {
        echo "     - {$p['project_id']}: {$p['project_name']} ({$p['created_at']})\n";
        
        // 检查文件是否存在
        $projectDir = $pubDir . $p['project_id'];
        $exists = is_dir($projectDir);
        $fileCount = $exists ? count(glob($projectDir . '/*')) : 0;
        echo "       文件目录: " . ($exists ? "存在 ($fileCount 个文件)" : "不存在") . "\n";
    }
} catch (Exception $e) {
    echo "   数据库连接: 失败 - " . $e->getMessage() . "\n";
}
echo "\n";

// 3. 检查.env配置
echo "3. 环境配置:\n";
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    echo "   .env文件: 存在\n";
    $env = parse_ini_file($envFile);
    echo "   API Key: " . (isset($env['PUBLISH_API_KEY']) ? '已配置' : '未配置') . "\n";
    echo "   DB配置: " . (isset($env['DB_HOST']) ? '已配置' : '未配置') . "\n";
} else {
    echo "   .env文件: 不存在\n";
}
echo "\n";

// 4. 测试文件创建
echo "4. 文件创建测试:\n";
$testDir = $pubDir . 'test_' . time();
$testFile = $testDir . '/index.html';

try {
    if (!is_dir($testDir)) {
        mkdir($testDir, 0755, true);
    }
    
    $testContent = '<html><body>Test</body></html>';
    $result = file_put_contents($testFile, $testContent);
    
    if ($result !== false) {
        echo "   创建测试文件: 成功\n";
        echo "   测试目录: $testDir\n";
        echo "   文件大小: $result bytes\n";
        
        // 清理测试文件
        unlink($testFile);
        rmdir($testDir);
        echo "   清理测试文件: 成功\n";
    } else {
        echo "   创建测试文件: 失败\n";
    }
} catch (Exception $e) {
    echo "   创建测试文件: 失败 - " . $e->getMessage() . "\n";
}
echo "\n";

// 5. 检查PHP配置
echo "5. PHP配置:\n";
echo "   upload_max_filesize: " . ini_get('upload_max_filesize') . "\n";
echo "   post_max_size: " . ini_get('post_max_size') . "\n";
echo "   max_execution_time: " . ini_get('max_execution_time') . "s\n";
echo "   memory_limit: " . ini_get('memory_limit') . "\n";
echo "\n";

// 6. 检查最近的上传日志
echo "6. 最近的错误日志:\n";
$errorLog = ini_get('error_log');
if ($errorLog && file_exists($errorLog)) {
    echo "   错误日志文件: $errorLog\n";
    $lines = array_slice(file($errorLog), -10);
    foreach ($lines as $line) {
        if (stripos($line, 'publish') !== false || stripos($line, 'upload') !== false) {
            echo "   " . trim($line) . "\n";
        }
    }
} else {
    echo "   错误日志: 未配置或不存在\n";
}
echo "\n";

echo "=== 诊断完成 ===\n";
?>
