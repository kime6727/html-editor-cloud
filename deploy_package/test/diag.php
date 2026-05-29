<?php
/**
 * 快速诊断：数据库连接调试
 */
header('Content-Type: text/plain; charset=utf-8');

echo "=== 环境变量 ===\n";
echo "DB_HOST=" . (getenv('DB_HOST') ?: 'NOT SET') . "\n";
echo "DB_PORT=" . (getenv('DB_PORT') ?: 'NOT SET') . "\n";
echo "DB_NAME=" . (getenv('DB_NAME') ?: 'NOT SET') . "\n";
echo "DB_USER=" . (getenv('DB_USER') ?: 'NOT SET') . "\n";
echo "DB_PASS length=" . strlen(getenv('DB_PASS') ?: '') . "\n\n";

$envFile = __DIR__ . '/../.env';
echo "=== .env 文件 ===\n";
if (file_exists($envFile)) {
    echo "文件存在: $envFile\n";
    echo "大小: " . filesize($envFile) . " bytes\n";
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    echo "行数: " . count($lines) . "\n";
    foreach ($lines as $line) {
        $line = trim($line);
        if (strpos($line, '#') === 0) continue;
        if (stripos($line, 'PASS') === false && stripos($line, 'SECRET') === false && stripos($line, 'KEY') === false) {
            echo "  $line\n";
        } else {
            $parts = explode('=', $line, 2);
            echo "  {$parts[0]}=***隐藏***\n";
        }
    }
} else {
    echo "❌ .env 文件不存在!\n";
}
echo "\n=== 管理员登录凭证 (admin.php 用 .env 本地验证，不查DB) ===\n";
$adminUser = getenv('ADMIN_USER') ?: 'NOT SET';
$adminPass = getenv('ADMIN_PASS') ?: '';
echo "用户名: $adminUser\n";
$plen = strlen($adminPass);
echo "密码长度: $plen 字符\n";
if ($plen >= 4) {
    echo "密码前2位: " . substr($adminPass, 0, 2) . "***" . " 后2位: " . substr($adminPass, -2) . "\n";
} elseif ($plen > 0) {
    echo "密码: (太短，只有 $plen 位)\n";
} else {
    echo "⚠️ 密码未设置!\n";
}
echo "➡️ 请用上面这个密码登录后台!\n\n";

echo "=== DNS 解析测试 ===\n";
$hostname = getenv('DB_HOST') ?: 'db';
$resolved = gethostbyname($hostname);
echo "gethostbyname('$hostname') = $resolved\n\n";

echo "=== PDO 连接测试 ===\n";
try {
    $host = getenv('DB_HOST') ?: 'db';
    $port = getenv('DB_PORT') ?: '3306';
    $dbname = getenv('DB_NAME') ?: 'html_editor';
    $user = getenv('DB_USER') ?: 'html_editor';
    $pass = getenv('DB_PASS') ?: '';
    
    echo "尝试连接: mysql:host=$host;port=$port;dbname=$dbname\n";
    echo "用户: $user\n";
    
    $dsn = "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4";
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5,
        PDO::MYSQL_ATTR_SSL_CA => '/etc/ssl/certs/ca-certificates.crt',
        PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
    ]);
    echo "✅ 数据库连接成功!\n";
    echo "MySQL版本: " . $pdo->query("SELECT VERSION()")->fetchColumn() . "\n";
    echo "当前数据库: " . $pdo->query("SELECT DATABASE()")->fetchColumn() . "\n";
} catch (PDOException $e) {
    echo "❌ 连接失败: " . $e->getMessage() . "\n";
    echo "错误码: " . $e->getCode() . "\n";
}

echo "\n=== TCP 端口测试 ===\n";
$host = getenv('DB_HOST') ?: 'db';
$port = intval(getenv('DB_PORT') ?: '3306');
$errno = 0;
$errstr = '';
$fp = @fsockopen($host, $port, $errno, $errstr, 5);
if ($fp) {
    echo "✅ $host:$port 端口可达\n";
    fclose($fp);
} else {
    echo "❌ $host:$port 不可达 (errno=$errno, errstr=$errstr)\n";
}

echo "\n=== /etc/resolv.conf ===\n";
if (file_exists('/etc/resolv.conf')) {
    echo file_get_contents('/etc/resolv.conf');
} else {
    echo "文件不存在\n";
}

echo "\n=== /etc/hosts ===\n";
if (file_exists('/etc/hosts')) {
    echo file_get_contents('/etc/hosts');
} else {
    echo "文件不存在\n";
}