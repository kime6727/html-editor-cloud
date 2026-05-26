<?php
// 数据库连接测试脚本
// 用于测试数据库配置是否正确

// 读取 .env 文件
$envFile = __DIR__ . '/.env';
$env = [];
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line) || strpos($line, '#') === 0) continue;
        $parts = explode('=', $line, 2);
        if (count($parts) === 2) {
            $env[trim($parts[0])] = trim($parts[1]);
        }
    }
}

$host = getenv('DB_HOST') ?: ($env['DB_HOST'] ?? 'localhost');
$dbname = getenv('DB_NAME') ?: ($env['DB_NAME'] ?? 'html_editor');
$username = getenv('DB_USER') ?: ($env['DB_USER'] ?? 'root');
$password = getenv('DB_PASS') ?: ($env['DB_PASS'] ?? '');
$charset = getenv('DB_CHARSET') ?: ($env['DB_CHARSET'] ?? 'utf8mb4');

echo "数据库配置测试\n";
echo "========================\n";
echo "Host: {$host}\n";
echo "Database: {$dbname}\n";
echo "Username: {$username}\n";
echo "Password: " . (empty($password) ? '(空)' : '已配置 (' . strlen($password) . ' 字符)') . "\n";
echo "Charset: {$charset}\n";
echo "========================\n\n";

// 尝试连接
try {
    $dsn = "mysql:host={$host};dbname={$dbname};charset={$charset}";
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ];
    
    $pdo = new PDO($dsn, $username, $password, $options);
    echo "✅ 数据库连接成功！\n";
    
    // 测试查询
    $stmt = $pdo->query("SELECT VERSION() as version");
    $result = $stmt->fetch();
    echo "MySQL 版本: {$result['version']}\n";
    
    // 检查表是否存在
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "数据库表数量: " . count($tables) . "\n";
    if (!empty($tables)) {
        echo "表列表: " . implode(', ', $tables) . "\n";
    }
    
} catch (PDOException $e) {
    echo "❌ 数据库连接失败！\n";
    echo "错误信息: " . $e->getMessage() . "\n";
    echo "\n可能的原因：\n";
    echo "1. 数据库密码不正确\n";
    echo "2. 数据库服务未启动\n";
    echo "3. 数据库名称不存在\n";
    echo "4. 用户权限不足\n";
}
