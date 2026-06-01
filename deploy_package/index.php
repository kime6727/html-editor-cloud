<?php
/**
 * HTML Code Editor - Project Access Gateway
 * 实时检查项目过期状态、密码验证、访问记录
 * 所有对 pub/{project_id}/ 的请求都通过此文件路由
 */

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

session_start();

// 加载数据库
$rootDir = __DIR__;
require_once $rootDir . '/database/Database.php';

// 从URL中提取 project_id
$requestUri = $_SERVER['REQUEST_URI'];
$pathParts = explode('/', trim(parse_url($requestUri, PHP_URL_PATH), '/'));
$projectId = null;

for ($i = 0; $i < count($pathParts); $i++) {
    if ($pathParts[$i] === 'pub' && isset($pathParts[$i + 1])) {
        $projectId = $pathParts[$i + 1];
        break;
    }
}

if (!$projectId) {
    $projectId = $_GET['project_id'] ?? null;
}

if (!$projectId || !preg_match('/^[a-z0-9]{8,12}$/', $projectId)) {
    http_response_code(404);
    readfile($rootDir . '/expired_template.html');
    exit;
}

try {
    $db = db();
    $project = $db->queryOne(
        "SELECT * FROM projects WHERE project_id = ? LIMIT 1",
        [$projectId]
    );
    
    if (!$project) {
        http_response_code(404);
        readfile($rootDir . '/expired_template.html');
        exit;
    }
    
    if ($project['status'] === 'deleted' || $project['status'] === 'banned') {
        http_response_code(404);
        readfile($rootDir . '/expired_template.html');
        exit;
    }
    
    if ($project['expires_at']) {
        $expiresAt = strtotime($project['expires_at']);
        $now = time();
        
        if ($now > $expiresAt) {
            if ($project['status'] !== 'expired') {
                $db->execute(
                    "UPDATE projects SET status = 'expired', updated_at = NOW() WHERE project_id = ?",
                    [$projectId]
                );
            }
            
            http_response_code(410);
            
            // Check for custom expired redirect/message settings
            $redirectType = $project['expired_redirect_type'] ?? null;
            $redirectUrl = $project['expired_redirect_url'] ?? null;
            $customMessage = $project['expired_custom_message'] ?? null;
            
            if ($redirectType === 'custom_url' && !empty($redirectUrl)) {
                header('Location: ' . $redirectUrl);
                exit;
            }
            
            if ($redirectType === 'custom_message' && !empty($customMessage)) {
                header('Content-Type: text/html; charset=utf-8');
                echo '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Expired</title><style>body{font-family:-apple-system,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#f5f5f5;}.msg{background:white;padding:40px;border-radius:16px;box-shadow:0 2px 10px rgba(0,0,0,0.1);text-align:center;max-width:400px;}</style></head><body><div class="msg">' . htmlspecialchars($customMessage) . '</div></body></html>';
                exit;
            }
            
            // Default: show expired template
            $templatePath = $rootDir . '/expired_template.html';
            if (file_exists($templatePath)) {
                readfile($templatePath);
            } else {
                echo 'This project has expired.';
            }
            exit;
        }
    }
    
    if (!empty($project['access_password'])) {
        $sessionKey = 'ce_project_access_' . $projectId;
        $attemptsKey = 'ce_pwd_attempts_' . $projectId;
        $lockKey = 'ce_pwd_lock_' . $projectId;

        if (empty($_SESSION[$sessionKey])) {
            // 锁定检查：15 分钟内 5 次错误则锁定 15 分钟
            if (!empty($_SESSION[$lockKey]) && $_SESSION[$lockKey] > time()) {
                $remaining = ceil(($_SESSION[$lockKey] - time()) / 60);
                showPasswordPrompt($projectId, "尝试次数过多，请 {$remaining} 分钟后再试", true);
                exit;
            }

            if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['password'])) {
                $submittedPassword = $_POST['password'];

                if (password_verify($submittedPassword, $project['access_password'])) {
                    $_SESSION[$sessionKey] = true;
                    $_SESSION[$sessionKey . '_time'] = time();
                    unset($_SESSION[$attemptsKey], $_SESSION[$lockKey]);
                } else {
                    $_SESSION[$attemptsKey] = ($_SESSION[$attemptsKey] ?? 0) + 1;

                    if ($_SESSION[$attemptsKey] >= 5) {
                        $_SESSION[$lockKey] = time() + 900; // 锁定 15 分钟
                        unset($_SESSION[$attemptsKey]);
                        showPasswordPrompt($projectId, '尝试次数过多，已临时锁定 15 分钟', true);
                    } else {
                        $left = 5 - $_SESSION[$attemptsKey];
                        showPasswordPrompt($projectId, "密码错误，还可尝试 {$left} 次");
                    }
                    exit;
                }
            } else {
                showPasswordPrompt($projectId);
                exit;
            }
        }
    }
    
    recordVisit($db, $projectId);
    
    $db->execute(
        "UPDATE projects SET visit_count = visit_count + 1, last_visited_at = NOW() WHERE project_id = ?",
        [$projectId]
    );
    
    $projectDir = __DIR__ . '/pub/' . $projectId;
    
    $requestedFile = $_GET['file'] ?? 'index.html';
    $filePath = $projectDir . '/' . $requestedFile;
    
    $realPath = realpath($filePath);
    $realProjectDir = realpath($projectDir);
    
    if ($realPath === false || strpos($realPath, $realProjectDir) !== 0) {
        http_response_code(404);
        echo 'File not found';
        exit;
    }
    
    if (!is_file($realPath)) {
        if (is_dir($realPath) && is_file($realPath . '/index.html')) {
            $realPath = $realPath . '/index.html';
        } else {
            http_response_code(404);
            echo 'File not found';
            exit;
        }
    }
    
    $ext = strtolower(pathinfo($realPath, PATHINFO_EXTENSION));
    $mimeTypes = [
        'html' => 'text/html; charset=utf-8',
        'htm'  => 'text/html; charset=utf-8',
        'css'  => 'text/css',
        'js'   => 'application/javascript',
        'mjs'  => 'application/javascript',
        'json' => 'application/json',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
        'svg'  => 'image/svg+xml',
        'webp' => 'image/webp',
        'bmp'  => 'image/bmp',
        'ico'  => 'image/x-icon',
        'ttf'  => 'font/ttf',
        'otf'  => 'font/otf',
        'woff' => 'font/woff',
        'woff2'=> 'font/woff2',
        'eot'  => 'application/vnd.ms-fontobject',
        'xml'  => 'application/xml',
        'md'   => 'text/markdown',
        'txt'  => 'text/plain',
    ];
    
    $mimeType = $mimeTypes[$ext] ?? 'application/octet-stream';
    header("Content-Type: {$mimeType}");
    
    if (in_array($ext, ['html', 'htm'])) {
        header('Cache-Control: no-cache, no-store, must-revalidate');
        header('Pragma: no-cache');
        header('Expires: 0');
    } else {
        header('Cache-Control: public, max-age=604800');
    }
    
    readfile($realPath);
    
} catch (Exception $e) {
    error_log("[IndexGateway] Error: " . $e->getMessage());
    http_response_code(500);
    echo 'Server error';
    exit;
}

function showPasswordPrompt($projectId, $errorMessage = null, $locked = false) {
    $promptPath = __DIR__ . '/password_prompt.html';

    if (file_exists($promptPath)) {
        $content = file_get_contents($promptPath);
        $content = str_replace('{{PROJECT_ID}}', $projectId, $content);

        if ($errorMessage) {
            $content = str_replace('{{ERROR_MESSAGE}}', $errorMessage, $content);
            $content = str_replace('{{SHOW_ERROR}}', 'block', $content);
        } else {
            $content = str_replace('{{ERROR_MESSAGE}}', '', $content);
            $content = str_replace('{{SHOW_ERROR}}', 'none', $content);
        }

        // 锁定时禁用提交按钮
        if ($locked) {
            $content = preg_replace(
                '/(<button[^>]*type="submit"[^>]*>)/i',
                '$1 disabled style="opacity:0.5;cursor:not-allowed;"',
                $content
            );
        }

        header('Content-Type: text/html; charset=utf-8');
        header('Cache-Control: no-cache, no-store, must-revalidate');
        echo $content;
    } else {
        header('Content-Type: text/html; charset=utf-8');
        ?>
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>需要密码</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .container {
                    background: white;
                    border-radius: 20px;
                    padding: 40px 30px;
                    max-width: 400px;
                    width: 100%;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    text-align: center;
                }
                h1 { font-size: 22px; color: #1a1a1a; margin-bottom: 12px; }
                p { font-size: 14px; color: #666; margin-bottom: 24px; }
                .error {
                    color: #ef4444;
                    font-size: 13px;
                    margin-bottom: 16px;
                    display: <?= $errorMessage ? 'block' : 'none' ?>;
                }
                input[type="password"] {
                    width: 100%;
                    padding: 14px 16px;
                    border: 2px solid #e5e7eb;
                    border-radius: 12px;
                    font-size: 16px;
                    margin-bottom: 16px;
                    outline: none;
                    transition: border-color 0.2s;
                }
                input[type="password"]:focus {
                    border-color: #667eea;
                }
                button {
                    width: 100%;
                    padding: 14px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    border: none;
                    border-radius: 12px;
                    font-size: 16px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: transform 0.2s;
                }
                button:hover { transform: translateY(-2px); }
                button:active { transform: translateY(0); }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>此页面需要密码</h1>
                <p>请输入访问密码以查看内容</p>
                <div class="error"><?= htmlspecialchars($errorMessage ?? '') ?></div>
                <form method="POST" action="">
                    <input type="password" name="password" placeholder="请输入密码" required autofocus>
                    <button type="submit">访问页面</button>
                </form>
            </div>
        </body>
        </html>
        <?php
    }
    exit;
}

function recordVisit($db, $projectId) {
    try {
        $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        $deviceType = 'desktop';
        
        if (preg_match('/Mobile|Android|iPhone|iPad|iPod/i', $userAgent)) {
            if (preg_match('/iPad|Tablet/i', $userAgent)) {
                $deviceType = 'tablet';
            } else {
                $deviceType = 'mobile';
            }
        }
        
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        $ip = filter_var($ip, FILTER_VALIDATE_IP) ?: 'unknown';
        
        $referer = $_SERVER['HTTP_REFERER'] ?? null;
        
        $ipData = anonymizeIP($ip);
        
        $db->execute(
            "INSERT INTO visit_logs (project_id, ip_address, ip_hash, user_agent, referer, device_type, visited_at) 
             VALUES (?, ?, ?, ?, ?, ?, NOW())",
            [$projectId, $ipData['anonymized'], $ipData['hash'], $userAgent, $referer, $deviceType]
        );
        
    } catch (Exception $e) {
        error_log("[IndexGateway] Failed to record visit: " . $e->getMessage());
    }
}
?>
