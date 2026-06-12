<?php
/**
 * HTML Code Editor - 过期项目定时处理脚本
 * 通过cron定时运行，检查已过期项目并执行文件替换
 * 
 * 使用方式：
 * 1. 命令行：php expire_cron.php
 * 2. Web访问：curl https://your-domain.com/expire_cron.php?key=YOUR_SECRET_KEY
 * 
 * 建议cron配置：每5分钟执行一次
 * */

// 加载配置
require_once __DIR__ . '/database/Database.php';

// 简单密钥验证（防止未授权访问）
$secretKey = $_GET['key'] ?? '';
$envPath = __DIR__ . '/.env';
if (file_exists($envPath)) {
    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), 'CRON_SECRET_KEY=') === 0) {
            $expectedKey = trim(explode('=', $line, 2)[1]);
            break;
        }
    }
}
$expectedKey = $expectedKey ?? 'default_cron_secret_key';

// 命令行模式跳过密钥验证
if (php_sapi_name() !== 'cli' && $secretKey !== $expectedKey) {
    http_response_code(403);
    echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
    exit;
}

// 读取过期模板
$templatePath = __DIR__ . '/expired_template.html';
$expiredContent = file_exists($templatePath) ? file_get_contents($templatePath) : null;

if (!$expiredContent) {
    error_log("[ExpireCron] Template not found: {$templatePath}");
    exit("Template not found\n");
}

$uploadDir = __DIR__ . '/pub/';
$processed = 0;
$errors = 0;

try {
    // 查找已过期但尚未处理文件替换的项目（status 可能是 active 或 expired）
    $expiredProjects = db()->query(
        "SELECT project_id, project_name, expires_at, status 
         FROM projects 
         WHERE expires_at IS NOT NULL 
         AND expires_at < NOW() 
         AND status IN ('active', 'expired')"
    );
    
    if (empty($expiredProjects)) {
        echo "No expired projects to process.\n";
        exit;
    }
    
    foreach ($expiredProjects as $project) {
        $projectId = $project['project_id'];
        $projectDir = $uploadDir . $projectId;
        
        if (!is_dir($projectDir)) {
            // No directory, just update status if needed
            if ($project['status'] !== 'expired') {
                db()->execute(
                    "UPDATE projects SET status = 'expired', updated_at = NOW() WHERE project_id = ?",
                    [$projectId]
                );
            }
            continue;
        }
        
        // Check if files have already been replaced (all HTML files are expired template)
        $htmlFiles = glob($projectDir . '/*.html');
        $needsReplacement = false;
        foreach ($htmlFiles as $htmlFile) {
            if (substr(basename($htmlFile), -4) !== '.bak' && !file_exists($htmlFile . '.bak')) {
                // Original HTML file exists without a .bak backup - needs replacement
                $needsReplacement = true;
                break;
            }
        }
        
        if ($needsReplacement) {
            // Execute file backup and replacement
            if (handleProjectExpire($projectDir, $expiredContent)) {
                db()->execute(
                    "UPDATE projects SET status = 'expired', updated_at = NOW() WHERE project_id = ?",
                    [$projectId]
                );
                $processed++;
                echo "Processed: {$projectId} ({$project['project_name']})\n";
            } else {
                $errors++;
                error_log("[ExpireCron] Failed to process: {$projectId}");
            }
        } else if ($project['status'] !== 'expired') {
            // Files already replaced, just update status
            db()->execute(
                "UPDATE projects SET status = 'expired', updated_at = NOW() WHERE project_id = ?",
                [$projectId]
            );
            $processed++;
        }
    }
    
    echo "Completed: {$processed} projects expired, {$errors} errors.\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    error_log("[ExpireCron] " . $e->getMessage());
}

/**
 * 处理项目过期：将原始文件备份为 .bak，并替换为过期提示页面
 */
function handleProjectExpire($projectDir, $expiredContent) {
    $files = glob($projectDir . '/*');
    $backedUp = 0;
    
    foreach ($files as $file) {
        if (is_file($file)) {
            $filename = basename($file);
            
            // 跳过 .bak 文件和 .htaccess
            if (substr($filename, -4) === '.bak' || $filename === '.htaccess') {
                continue;
            }
            
            // 备份原始文件
            $bakFile = $file . '.bak';
            if (copy($file, $bakFile)) {
                // HTML文件替换为过期提示页面
                if (preg_match('/\.(html|htm)$/i', $filename)) {
                    file_put_contents($file, $expiredContent);
                } else {
                    // 其他文件删除（已备份）
                    unlink($file);
                }
                $backedUp++;
            }
        }
    }
    
    error_log("[ExpireCron] Project expired: backed up {$backedUp} files in {$projectDir}");
    return $backedUp > 0;
}
?>
