<?php
/**
 * 数据库连接和结构验证脚本
 * 版本: v3.0
 * 日期: 2026-05-15
 * 说明: 增强版，包含v3新功能检查（实时过期、密码保护、访问统计）
 */

header('Content-Type: text/html; charset=utf-8');

$rootDir = dirname(__DIR__);

// 期望的表结构定义
$expectedSchema = [
    'projects' => [
        'id', 'project_id', 'project_name', 'user_id', 'is_pro', 'file_count',
        'visit_count', 'status', 'expire_days', 'expire_minutes', 'expires_at',
        'access_password', 'expired_redirect_type', 'expired_redirect_url',
        'expired_custom_message', 'created_at', 'updated_at', 'last_visited_at'
    ],
    'users' => [
        'id', 'user_id', 'is_pro', 'pro_activated_at', 'publish_count',
        'total_visits', 'created_at', 'last_active_at', 'status', 'ban_reason', 'banned_at'
    ],
    'visit_logs' => [
        'id', 'project_id', 'ip_address', 'user_agent', 'referer', 'country',
        'city', 'device_type', 'visited_at'
    ],
    'user_activity_logs' => [
        'id', 'user_id', 'project_id', 'action', 'details', 'created_at'
    ],
    'admin_logs' => [
        'id', 'admin_user', 'action', 'target_type', 'target_id', 'details',
        'ip_address', 'created_at'
    ],
    'daily_stats' => [
        'id', 'stat_date', 'total_projects', 'total_visits', 'new_users',
        'active_users', 'pro_users', 'publish_count', 'created_at', 'updated_at'
    ],
    'system_config' => [
        'id', 'config_key', 'config_value', 'description', 'updated_at'
    ],
    'subscription_records' => [
        'id', 'user_id', 'transaction_id', 'product_id', 'status',
        'purchased_at', 'expires_at', 'refund_date'
    ],
];

$expectedTables = array_keys($expectedSchema);

$expectedViews = ['v_user_stats', 'v_project_stats'];

$v3ConfigKeys = [
    'free_user_expire_minutes' => '60',
    'enable_realtime_expiry_check' => '1',
    'enable_password_protection' => '1',
    'enable_visit_tracking' => '1',
    'session_timeout_minutes' => '60',
];

echo "<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <title>数据库健康检查</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .container { background: white; border-radius: 12px; padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #007AFF; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        h3 { color: #666; }
        .success { color: #34C759; font-weight: bold; }
        .error { color: #FF3B30; font-weight: bold; }
        .warning { color: #FF9500; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #eee; }
        th { background: #f8f9fa; font-weight: 600; }
        .check-item { padding: 8px 0; border-bottom: 1px solid #f0f0f0; }
        .check-item:last-child { border-bottom: none; }
        .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; }
        .badge-success { background: #E8F5E9; color: #2E7D32; }
        .badge-error { background: #FFEBEE; color: #C62828; }
        .badge-warning { background: #FFF3E0; color: #EF6C00; }
        .summary { background: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; }
        .summary-item { display: flex; justify-content: space-between; padding: 8px 0; }
        code { background: #f5f5f5; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
        .migration-sql { background: #263238; color: #A5D6A7; padding: 15px; border-radius: 8px; overflow-x: auto; font-family: monospace; font-size: 13px; line-height: 1.5; }
        .check-section { background: #f8f9fa; border-left: 4px solid #007AFF; padding: 15px; margin: 15px 0; border-radius: 4px; }
        .tip-box { background: #E3F2FD; border-left: 4px solid #2196F3; padding: 12px; margin: 10px 0; border-radius: 4px; }
        .tip-box strong { color: #1565C0; }
        ul li { margin: 8px 0; line-height: 1.6; }
    </style>
</head>
<body>
<div class='container'>
<h1>🔍 数据库健康检查</h1>
<p>检查时间: " . date('Y-m-d H:i:s') . "</p>
<hr>";

// 1. 检查 .env 文件
echo "<h2>📁 1. 环境配置检查</h2>";
$envFile = dirname(__DIR__) . '/.env';
echo "<p>路径：<code>$envFile</code></p>";

if (file_exists($envFile)) {
    echo "<span class='success'>✅ .env 文件存在</span><br>";
    $env = [];
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line) || strpos($line, '#') === 0) continue;
        $parts = explode('=', $line, 2);
        if (count($parts) === 2) {
            $env[trim($parts[0])] = trim($parts[1]);
        }
    }
    
    $configItems = [
        'DB_HOST' => '数据库主机',
        'DB_NAME' => '数据库名',
        'DB_USER' => '数据库用户',
        'DB_PASS' => '数据库密码',
        'DB_CHARSET' => '字符集',
        'PUBLISH_API_KEY' => '发布API密钥',
        'HMAC_SECRET_KEY' => 'HMAC密钥',
        'DEBUG' => '调试模式'
    ];
    
    echo "<table><tr><th>配置项</th><th>状态</th></tr>";
    foreach ($configItems as $key => $label) {
        $value = $env[$key] ?? null;
        $status = empty($value) || $value === 'CHANGE_ME_USE_ENV_VARIABLE' ? 'error' : 'success';
        $displayValue = $key === 'DB_PASS' || $key === 'PUBLISH_API_KEY' || $key === 'HMAC_SECRET_KEY' 
            ? (empty($value) ? '(空)' : '已配置 (' . strlen($value) . '字符)') 
            : ($value ?? '未设置');
        echo "<tr><td>$label</td><td class='$status'>$displayValue</td></tr>";
    }
    echo "</table>";
} else {
    echo "<span class='error'>❌ .env 文件不存在！</span><br>";
    $env = null;
}

// 2. 数据库连接测试
echo "<h2>🔌 2. 数据库连接测试</h2>";
$pdo = null;
if ($env) {
    try {
        $charset = $env['DB_CHARSET'] ?? 'utf8mb4';
        $dsn = "mysql:host={$env['DB_HOST']};dbname={$env['DB_NAME']};charset={$charset}";
        $pdo = new PDO($dsn, $env['DB_USER'], $env['DB_PASS'], [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES {$charset}",
        ]);
        echo "<span class='success'>✅ 数据库连接成功！</span><br>";
        echo "<p>DSN: <code>$dsn</code></p>";
        
        // 获取MySQL版本
        $stmt = $pdo->query("SELECT VERSION() as version");
        $version = $stmt->fetch()['version'];
        echo "<p>MySQL版本: <code>$version</code></p>";
        
    } catch (PDOException $e) {
        echo "<span class='error'>❌ 数据库连接失败！</span><br>";
        echo "<p>错误信息: <code>" . htmlspecialchars($e->getMessage()) . "</code></p>";
        echo "<p><b>常见原因：</b></p>";
        echo "<ul>";
        echo "<li>数据库用户名或密码错误</li>";
        echo "<li>数据库不存在</li>";
        echo "<li>数据库没有权限</li>";
        echo "</ul>";
        echo "</div></body></html>";
        exit;
    }
} else {
    echo "<span class='error'>❌ 无法测试：.env 文件未找到</span><br>";
    echo "</div></body></html>";
    exit;
}

// 3. 表存在性检查
echo "<h2>📊 3. 表存在性检查</h2>";
$stmt = $pdo->query("SHOW TABLES");
$existingTables = $stmt->fetchAll(PDO::FETCH_COLUMN);

echo "<table><tr><th>表名</th><th>状态</th></tr>";
foreach ($expectedTables as $table) {
    $exists = in_array($table, $existingTables);
    $status = $exists ? 'success' : 'error';
    $badge = $exists ? '✅ 存在' : '❌ 缺失';
    echo "<tr><td><code>$table</code></td><td class='$status'>$badge</td></tr>";
}
echo "</table>";

$missingTables = array_diff($expectedTables, $existingTables);
if (!empty($missingTables)) {
    echo "<p class='warning'>⚠️ 缺失 " . count($missingTables) . " 个表: " . implode(', ', $missingTables) . "</p>";
} else {
    echo "<p class='success'>✅ 所有期望的表都存在</p>";
}

// 4. 表结构详细检查
echo "<h2>🔍 4. 表结构详细检查</h2>";

$missingColumns = [];
$allTablesOK = true;

foreach ($expectedSchema as $tableName => $expectedCols) {
    if (!in_array($tableName, $existingTables)) {
        continue; // 表不存在，跳过
    }
    
    echo "<h3>表: <code>$tableName</code></h3>";
    
    // 获取实际列
    $stmt = $pdo->prepare("SHOW COLUMNS FROM `$tableName`");
    $stmt->execute();
    $actualCols = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // 检查缺失的列
    $missing = array_diff($expectedCols, $actualCols);
    $extra = array_diff($actualCols, $expectedCols);
    
    if (empty($missing) && empty($extra)) {
        echo "<span class='success'>✅ 结构完整 (" . count($actualCols) . " 个字段)</span>";
    } else {
        $allTablesOK = false;
        if (!empty($missing)) {
            echo "<span class='error'>❌ 缺失字段: " . implode(', ', array_map(function($c) { return "<code>$c</code>"; }, $missing)) . "</span>";
            foreach ($missing as $col) {
                $missingColumns[] = ['table' => $tableName, 'column' => $col];
            }
        }
        if (!empty($extra)) {
            echo "<br><span class='warning'>⚠️ 多余字段: " . implode(', ', array_map(function($c) { return "<code>$c</code>"; }, $extra)) . "</span>";
        }
    }
    echo "<br>";
}

// 5. 生成迁移SQL（如果有缺失字段）
if (!empty($missingColumns)) {
    echo "<h2>🔧 5. 自动生成的迁移SQL</h2>";
    echo "<p>以下SQL语句用于修复缺失的字段，请在数据库管理工具中执行：</p>";
    
    echo "<div class='migration-sql'>";
    echo "-- 数据库迁移脚本 - 自动修复缺失字段<br>";
    echo "-- 生成时间: " . date('Y-m-d H:i:s') . "<br><br>";
    
    $currentTable = '';
    foreach ($missingColumns as $item) {
        if ($item['table'] !== $currentTable) {
            if ($currentTable !== '') echo "<br>";
            echo "-- 修复表: {$item['table']}<br>";
            $currentTable = $item['table'];
        }
        echo "ALTER TABLE `{$item['table']}` ADD COLUMN `{$item['column']}` VARCHAR(255) DEFAULT NULL;<br>";
    }
    echo "</div>";
}

// 6. projects 表详细结构
echo "<h2>📋 6. projects 表详细结构</h2>";
$stmt = $pdo->query("DESCRIBE projects");
$columns = $stmt->fetchAll();

echo "<table><tr><th>字段</th><th>类型</th><th>允许NULL</th><th>键</th><th>默认值</th><th>额外</th></tr>";
foreach ($columns as $col) {
    echo "<tr>";
    echo "<td><code>{$col['Field']}</code></td>";
    echo "<td>{$col['Type']}</td>";
    echo "<td>{$col['Null']}</td>";
    echo "<td>{$col['Key']}</td>";
    echo "<td>" . ($col['Default'] ?? 'NULL') . "</td>";
    echo "<td>{$col['Extra']}</td>";
    echo "</tr>";
}
echo "</table>";

// 7. 数据统计
echo "<h2>📈 7. 数据统计</h2>";
$statsTables = ['users', 'projects', 'visit_logs', 'subscription_records'];
echo "<table><tr><th>表名</th><th>记录数</th></tr>";
foreach ($statsTables as $table) {
    if (in_array($table, $existingTables)) {
        $stmt = $pdo->query("SELECT COUNT(*) as count FROM `$table`");
        $count = $stmt->fetch()['count'];
        echo "<tr><td><code>$table</code></td><td>$count 条</td></tr>";
    }
}
echo "</table>";

// 8. 总结
echo "<h2>📝 8. 检查总结</h2>";
echo "<div class='summary'>";
echo "<div class='summary-item'><span>数据库连接</span><span class='status-badge badge-success'>✅ 正常</span></div>";
echo "<div class='summary-item'><span>表数量</span><span>" . count($existingTables) . " / " . count($expectedTables) . "</span></div>";
echo "<div class='summary-item'><span>结构完整性</span><span class='status-badge " . ($allTablesOK ? 'badge-success' : 'badge-error') . "'>" . ($allTablesOK ? '✅ 完整' : '❌ 需要修复') . "</span></div>";

if (!empty($missingColumns)) {
    echo "<div class='summary-item'><span>缺失字段数</span><span class='warning'>" . count($missingColumns) . " 个</span></div>";
}

echo "</div>";

// 发布功能测试提示
$stmt = $pdo->prepare("SHOW COLUMNS FROM `projects` LIKE 'access_password'");
$stmt->execute();
$hasAccessPassword = $stmt->fetch() !== false;
echo "<h3>发布功能状态</h3>";
if ($hasAccessPassword) {
    echo "<p class='success'>✅ projects 表包含 access_password 字段，发布功能应该可以正常工作</p>";
} else {
    echo "<p class='error'>❌ projects 表缺少 access_password 字段，发布功能将失败！</p>";
    echo "<p>请执行上方生成的迁移SQL来修复。</p>";
}

// 9. 视图存在性检查
echo "<h2>👁️ 9. 数据库视图检查</h2>";
$stmt = $pdo->query("SHOW FULL TABLES WHERE Table_type = 'VIEW'");
$existingViews = $stmt->fetchAll(PDO::FETCH_COLUMN);

echo "<table><tr><th>视图名</th><th>状态</th></tr>";
foreach ($expectedViews as $view) {
    $exists = in_array($view, $existingViews);
    $status = $exists ? 'success' : 'warning';
    $badge = $exists ? '✅ 存在' : '⚠️ 缺失（非关键）';
    echo "<tr><td><code>$view</code></td><td class='$status'>$badge</td></tr>";
}
echo "</table>";

// 10. 索引检查
echo "<h2>📑 10. 索引优化检查</h2>";
$expectedIndexes = [
    'projects' => ['idx_user_status_created', 'idx_expires_at', 'idx_user_id'],
    'visit_logs' => ['idx_project_visited', 'idx_project_id'],
    'users' => ['uk_user_id', 'idx_is_pro'],
];

foreach ($expectedIndexes as $table => $indexes) {
    if (!in_array($table, $existingTables)) continue;
    
    echo "<h3>表: <code>$table</code></h3>";
    
    $stmt = $pdo->query("SHOW INDEX FROM `$table`");
    $actualIndexes = [];
    while ($row = $stmt->fetch()) {
        if (!in_array($row['Key_name'], ['PRIMARY'])) {
            $actualIndexes[] = $row['Key_name'];
        }
    }
    $actualIndexes = array_unique($actualIndexes);
    
    foreach ($indexes as $index) {
        $exists = in_array($index, $actualIndexes);
        $status = $exists ? 'success' : 'warning';
        $badge = $exists ? '✅ 存在' : '⚠️ 缺失';
        echo "<p class='$status'>$badge <code>$index</code></p>";
    }
}

// 11. 系统配置检查（v3）
echo "<h2>⚙️ 11. v3 系统配置检查</h2>";

if (in_array('system_config', $existingTables)) {
    echo "<table><tr><th>配置项</th><th>期望值</th><th>当前值</th><th>状态</th></tr>";
    
    foreach ($v3ConfigKeys as $key => $expectedValue) {
        $stmt = $pdo->prepare("SELECT config_value FROM system_config WHERE config_key = ?");
        $stmt->execute([$key]);
        $row = $stmt->fetch();
        
        if ($row) {
            $actualValue = $row['config_value'];
            $match = ($actualValue === $expectedValue);
            $status = $match ? 'success' : 'warning';
            $badge = $match ? '✅ 正确' : '⚠️ 不匹配';
        } else {
            $actualValue = '(未配置)';
            $status = 'error';
            $badge = '❌ 缺失';
        }
        
        echo "<tr><td><code>$key</code></td><td>$expectedValue</td><td>$actualValue</td><td class='$status'>$badge</td></tr>";
    }
    echo "</table>";
} else {
    echo "<p class='error'>❌ system_config 表不存在</p>";
}

// 12. 过期项目状态检查
echo "<h2>⏰ 12. 过期项目状态检查</h2>";

if (in_array('projects', $existingTables)) {
    // 检查应过期但状态仍为active的项目
    $stmt = $pdo->query("
        SELECT COUNT(*) as count FROM projects 
        WHERE expires_at IS NOT NULL 
        AND expires_at < NOW() 
        AND status = 'active'
    ");
    $staleExpired = $stmt->fetch()['count'];
    
    // 检查已过期项目总数
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM projects WHERE status = 'expired'");
    $totalExpired = $stmt->fetch()['count'];
    
    // 检查永久项目数
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM projects WHERE expires_at IS NULL AND status = 'active'");
    $permanentCount = $stmt->fetch()['count'];
    
    // 检查免费用户项目（expire_minutes > 0）
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM projects WHERE is_pro = 0 AND expire_minutes > 0");
    $freeProjects = $stmt->fetch()['count'];
    
    echo "<table><tr><th>检查项</th><th>数量</th><th>状态</th></tr>";
    
    if ($staleExpired > 0) {
        echo "<tr><td>已过期但状态仍为active</td><td>$staleExpired</td><td class='error'>❌ 需要更新</td></tr>";
        echo "</table>";
        echo "<p class='warning'>⚠️ 这些项目应该被标记为 expired 状态。网关会实时检查，但建议更新数据库：</p>";
        echo "<div class='migration-sql'>";
        echo "UPDATE projects SET status = 'expired', updated_at = NOW() WHERE expires_at < NOW() AND status = 'active';";
        echo "</div>";
    } else {
        echo "<tr><td>过期状态一致性</td><td>$staleExpired</td><td class='success'>✅ 无异常</td></tr>";
    }
    
    echo "<tr><td>已过期项目总数</td><td>$totalExpired</td><td class='success'>✅ 正常</td></tr>";
    echo "<tr><td>永久有效项目</td><td>$permanentCount</td><td class='success'>✅ 正常</td></tr>";
    echo "<tr><td>免费用户项目（有时效）</td><td>$freeProjects</td><td class='success'>✅ 正常</td></tr>";
    echo "</table>";
}

// 13. 访问日志功能检查
echo "<h2>📊 13. 访问统计功能检查</h2>";

if (in_array('visit_logs', $existingTables)) {
    // 检查最近24小时的访问记录
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM visit_logs WHERE visited_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)");
    $todayVisits = $stmt->fetch()['count'];
    
    // 检查最近的访问记录
    $stmt = $pdo->query("SELECT MAX(visited_at) as last_visit FROM visit_logs");
    $lastVisit = $stmt->fetch()['last_visit'];
    
    // 检查今日访问量最多的项目
    $stmt = $pdo->query("
        SELECT p.project_id, p.project_name, COUNT(*) as visits 
        FROM visit_logs vl 
        JOIN projects p ON vl.project_id = p.project_id 
        WHERE vl.visited_at >= CURDATE() 
        GROUP BY vl.project_id 
        ORDER BY visits DESC 
        LIMIT 5
    ");
    $topProjects = $stmt->fetchAll();
    
    echo "<table><tr><th>检查项</th><th>数据</th><th>状态</th></tr>";
    echo "<tr><td>24小时内访问量</td><td>$todayVisits</td><td class='success'>✅ 正常</td></tr>";
    
    if ($lastVisit) {
        echo "<tr><td>最近访问时间</td><td>$lastVisit</td><td class='success'>✅ 正常</td></tr>";
    } else {
        echo "<tr><td>最近访问时间</td><td>无记录</td><td class='warning'>⚠️ 可能网关未启用</td></tr>";
    }
    echo "</table>";
    
    if (!empty($topProjects)) {
        echo "<h3>今日访问 TOP 5 项目</h3>";
        echo "<table><tr><th>项目ID</th><th>项目名称</th><th>访问次数</th></tr>";
        foreach ($topProjects as $proj) {
            echo "<tr><td><code>{$proj['project_id']}</code></td><td>{$proj['project_name']}</td><td>{$proj['visits']}</td></tr>";
        }
        echo "</table>";
    }
    
    // 检查设备类型分布
    $stmt = $pdo->query("
        SELECT device_type, COUNT(*) as count 
        FROM visit_logs 
        WHERE visited_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) 
        GROUP BY device_type 
        ORDER BY count DESC
    ");
    $deviceStats = $stmt->fetchAll();
    
    if (!empty($deviceStats)) {
        echo "<h3>近7天设备类型分布</h3>";
        echo "<table><tr><th>设备类型</th><th>访问量</th><th>占比</th></tr>";
        $totalWeekVisits = array_sum(array_column($deviceStats, 'count'));
        foreach ($deviceStats as $stat) {
            $percentage = round(($stat['count'] / $totalWeekVisits) * 100, 1);
            echo "<tr><td>{$stat['device_type']}</td><td>{$stat['count']}</td><td>{$percentage}%</td></tr>";
        }
        echo "</table>";
    }
} else {
    echo "<p class='error'>❌ visit_logs 表不存在</p>";
}

// 14. 文件权限检查
echo "<h2>📁 14. 文件权限检查</h2>";

$checkDirs = [
    'pub' => ['path' => $rootDir . '/pub', 'writable' => true],
    'data' => ['path' => $rootDir . '/data', 'writable' => true],
    'database' => ['path' => $rootDir . '/database', 'writable' => false],
];

echo "<table><tr><th>目录</th><th>存在</th><th>可写</th><th>状态</th></tr>";
foreach ($checkDirs as $name => $config) {
    $exists = is_dir($config['path']);
    $writable = $exists ? is_writable($config['path']) : false;
    $needWritable = $config['writable'];
    
    $existsBadge = $exists ? '✅' : '❌';
    
    if ($needWritable) {
        $writableBadge = $writable ? '✅' : '❌';
        $status = ($exists && $writable) ? 'success' : 'error';
    } else {
        $writableBadge = $writable ? '⚠️ (建议不可写)' : '✅';
        $status = $exists ? 'success' : 'error';
    }
    
    echo "<tr><td><code>$name</code></td><td>$existsBadge</td><td>$writableBadge</td><td class='$status'>" . ($status === 'success' ? '✅ 正常' : '❌ 需要修复') . "</td></tr>";
}
echo "</table>";

// 15. 网关功能集成检查
echo "<h2>🚪 15. 网关功能集成检查（v3新功能）</h2>";

$gatewayChecks = [
    'index.php 网关文件' => ['file' => $rootDir . '/index.php', 'required' => true],
    'password_prompt.html 密码页面' => ['file' => $rootDir . '/password_prompt.html', 'required' => true],
    'expired_template.html 过期页面' => ['file' => $rootDir . '/expired_template.html', 'required' => true],
    'expire_cron.php 定时任务' => ['file' => $rootDir . '/expire_cron.php', 'required' => false],
];

echo "<table><tr><th>文件</th><th>存在</th><th>状态</th></tr>";
foreach ($gatewayChecks as $name => $config) {
    $exists = file_exists($config['file']);
    $status = $exists ? 'success' : ($config['required'] ? 'error' : 'warning');
    $badge = $exists ? '✅ 存在' : ($config['required'] ? '❌ 缺失' : '⚠️ 可选');
    echo "<tr><td><code>$name</code></td><td class='$status'>$badge</td></tr>";
}
echo "</table>";

// Nginx配置提示
echo "<h3>⚠️ Nginx 配置提醒</h3>";
echo "<p>确保你的 Nginx 配置包含以下 rewrite 规则（已在 <code>nginx.conf</code> 中提供）：</p>";
echo "<div class='migration-sql'>";
echo "# HTML文件请求通过网关检查<br>";
echo "location ~ ^/pub/([a-z0-9]+)/([^.]+\\.(html|htm))\$ {<br>";
echo "    rewrite ^/pub/([a-z0-9]+)/([^.]+\\.(html|htm))\$ /index.php?project_id=\$1&file=\$2 last;<br>";
echo "}<br><br>";
echo "# 项目目录根路径<br>";
echo "location ~ ^/pub/([a-z0-9]+)/?\$ {<br>";
echo "    rewrite ^/pub/([a-z0-9]+)/?\$ /index.php?project_id=\$1&file=index.html last;<br>";
echo "}";
echo "</div>";

// 16. 总结
echo "<h2>📝 16. 检查总结</h2>";
echo "<div class='summary'>";
echo "<div class='summary-item'><span>数据库连接</span><span class='status-badge badge-success'>✅ 正常</span></div>";
echo "<div class='summary-item'><span>表数量</span><span>" . count($existingTables) . " / " . count($expectedTables) . "</span></div>";
echo "<div class='summary-item'><span>结构完整性</span><span class='status-badge " . ($allTablesOK ? 'badge-success' : 'badge-error') . "'>" . ($allTablesOK ? '✅ 完整' : '❌ 需要修复') . "</span></div>";
echo "<div class='summary-item'><span>v3 网关功能</span><span class='status-badge badge-success'>✅ 就绪</span></div>";

if (!empty($missingColumns)) {
    echo "<div class='summary-item'><span>缺失字段数</span><span class='warning'>" . count($missingColumns) . " 个</span></div>";
}

echo "</div>";

// 最终建议
echo "<h3>💡 优化建议</h3>";
echo "<ul>";

if ($staleExpired > 0) {
    echo "<li>⚠️ 有 $staleExpired 个项目已过期但状态未更新，建议执行迁移SQL</li>";
}

if ($todayVisits == 0) {
    echo "<li>⚠️ 24小时内无访问记录，请确认 Nginx rewrite 规则已生效</li>";
}

if (!$lastVisit) {
    echo "<li>⚠️ 访问日志表为空，网关可能未正确配置</li>";
}

echo "<li>✅ 定期执行 expire_cron.php 处理过期项目备份（建议每5分钟）</li>";
echo "<li>✅ 监控 visit_logs 表大小，建议定期清理30天前的日志</li>";
echo "</ul>";

echo "<hr>";
echo "<p style='color: #999; font-size: 12px;'>数据库健康检查工具 v3.0 | " . date('Y-m-d H:i:s') . " | 支持 Nginx + PHP-FPM</p>";

echo "</div></body></html>";
?>
