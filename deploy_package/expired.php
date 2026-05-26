<?php
/**
 * 项目过期后的推广页面
 * 显示精美的App推广信息，引导用户下载App
 */

// 获取请求参数
$slug = $_GET['slug'] ?? '';
$redirectUrl = $_GET['redirect'] ?? '';
$customMessage = $_GET['message'] ?? '';

// 检测语言
function detectLanguage() {
    $acceptLang = $_SERVER['HTTP_ACCEPT_LANGUAGE'] ?? '';
    if (stripos($acceptLang, 'zh') !== false) {
        return 'zh';
    }
    return 'en';
}

$lang = detectLanguage();

// 多语言文案
$translations = [
    'zh' => [
        'title' => '此项目已过期',
        'subtitle' => '创建属于你自己的HTML项目',
        'app_name' => 'HTML编辑器',
        'features' => [
            '✨ 强大的代码编辑器',
            '📱 实时预览',
            '🌐 云端发布与分享',
            '📦 智能ZIP导入导出',
            '🎨 专业模板库',
        ],
        'download_app' => '下载App',
        'reactivate' => '重新激活此项目',
        'custom_message' => '项目所有者留言：',
        'scan_qr' => '扫描二维码下载',
        'footer' => '© ' . date('Y') . ' HTML Editor. All rights reserved.',
        'app_store' => 'App Store',
        'rating' => '4.9 ★ 评分',
        'users' => '10万+ 用户',
        'app_store_url' => 'https://apps.apple.com/app/YOUR_APP_ID',
    ],
    'en' => [
        'title' => 'This Project Has Expired',
        'subtitle' => 'Create Your Own HTML Projects',
        'app_name' => 'HTML Editor',
        'features' => [
            '✨ Powerful Code Editor',
            '📱 Real-time Preview',
            '🌐 Cloud Publishing & Sharing',
            '📦 Smart ZIP Import/Export',
            '🎨 Professional Templates',
        ],
        'download_app' => 'Download App',
        'reactivate' => 'Reactivate This Project',
        'custom_message' => 'Message from project owner:',
        'scan_qr' => 'Scan QR Code to Download',
        'footer' => '© ' . date('Y') . ' HTML Editor. All rights reserved.',
        'app_store' => 'App Store',
        'rating' => '4.9 ★ Rating',
        'users' => '100K+ Users',
        'app_store_url' => 'https://apps.apple.com/app/YOUR_APP_ID',
    ],
];

$t = $translations[$lang];
?>
<!DOCTYPE html>
<html lang="<?php echo $lang; ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $t['title']; ?></title>
    <meta property="og:title" content="<?php echo $t['subtitle']; ?>">
    <meta property="og:description" content="<?php echo $t['subtitle']; ?>">
    <meta property="og:type" content="website">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .container {
            max-width: 480px;
            width: 100%;
            background: white;
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            animation: slideUp 0.6s ease-out;
        }
        
        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        
        .header-icon {
            width: 80px;
            height: 80px;
            background: rgba(255,255,255,0.2);
            border-radius: 20px;
            margin: 0 auto 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            backdrop-filter: blur(10px);
        }
        
        .header h1 {
            font-size: 24px;
            font-weight: 700;
            margin-bottom: 8px;
        }
        
        .header p {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .stats {
            display: flex;
            justify-content: space-around;
            padding: 20px 0;
            border-bottom: 1px solid #f0f0f0;
            margin-bottom: 20px;
        }
        
        .stat-item {
            text-align: center;
        }
        
        .stat-value {
            font-size: 20px;
            font-weight: 700;
            color: #667eea;
        }
        
        .stat-label {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
        }
        
        .features {
            margin: 20px 0;
        }
        
        .features h3 {
            font-size: 18px;
            margin-bottom: 16px;
            color: #333;
        }
        
        .feature-list {
            list-style: none;
        }
        
        .feature-list li {
            padding: 10px 0;
            font-size: 15px;
            color: #555;
            border-bottom: 1px solid #f5f5f5;
        }
        
        .feature-list li:last-child {
            border-bottom: none;
        }
        
        .custom-message {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 16px;
            margin: 20px 0;
            border-radius: 8px;
            font-size: 14px;
            color: #555;
        }
        
        .custom-message strong {
            display: block;
            margin-bottom: 8px;
            color: #333;
        }
        
        .actions {
            display: flex;
            flex-direction: column;
            gap: 12px;
            margin-top: 30px;
        }
        
        .btn {
            display: block;
            width: 100%;
            padding: 16px;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            text-align: center;
            text-decoration: none;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
        }
        
        .btn-secondary {
            background: #f8f9fa;
            color: #667eea;
        }
        
        .btn-secondary:hover {
            background: #e9ecef;
        }
        
        .qr-section {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #f0f0f0;
        }
        
        .qr-section p {
            font-size: 14px;
            color: #999;
            margin-bottom: 16px;
        }
        
        .qr-code {
            width: 150px;
            height: 150px;
            margin: 0 auto;
            background: white;
            padding: 10px;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .footer {
            text-align: center;
            padding: 20px;
            font-size: 12px;
            color: #999;
            background: #f8f9fa;
        }
        
        @media (max-width: 480px) {
            .container {
                border-radius: 16px;
            }
            
            .header {
                padding: 30px 20px;
            }
            
            .content {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="header-icon">📱</div>
            <h1><?php echo $t['title']; ?></h1>
            <p><?php echo $t['subtitle']; ?></p>
        </div>
        
        <div class="content">
            <div class="stats">
                <div class="stat-item">
                    <div class="stat-value">4.9 ★</div>
                    <div class="stat-label"><?php echo $t['rating']; ?></div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">100K+</div>
                    <div class="stat-label"><?php echo $t['users']; ?></div>
                </div>
                <div class="stat-item">
                    <div class="stat-value">#1</div>
                    <div class="stat-label">HTML Editor</div>
                </div>
            </div>
            
            <div class="features">
                <h3><?php echo $t['app_name']; ?></h3>
                <ul class="feature-list">
                    <?php foreach ($t['features'] as $feature): ?>
                    <li><?php echo $feature; ?></li>
                    <?php endforeach; ?>
                </ul>
            </div>
            
            <?php if (!empty($customMessage)): ?>
            <div class="custom-message">
                <strong><?php echo $t['custom_message']; ?></strong>
                <?php echo htmlspecialchars($customMessage); ?>
            </div>
            <?php endif; ?>
            
            <div class="actions">
                <a href="<?php echo $t['app_store_url']; ?>" class="btn btn-primary">
                    📥 <?php echo $t['download_app']; ?>
                </a>
                
                <?php if (!empty($slug)): ?>
                <a href="<?php echo $t['app_store_url']; ?>" class="btn btn-secondary">
                    🔄 <?php echo $t['reactivate']; ?>
                </a>
                <?php endif; ?>
                
                <?php if (!empty($redirectUrl)): ?>
                <a href="<?php echo htmlspecialchars($redirectUrl); ?>" class="btn btn-secondary">
                    🔗 <?php echo htmlspecialchars($redirectUrl); ?>
                </a>
                <?php endif; ?>
            </div>
            
            <div class="qr-section">
                <p><?php echo $t['scan_qr']; ?></p>
                <div class="qr-code">
                    <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=<?php echo urlencode($t['app_store_url']); ?>" 
                         alt="QR Code" 
                         style="width: 100%; height: 100%;">
                </div>
            </div>
        </div>
        
        <div class="footer">
            <?php echo $t['footer']; ?>
        </div>
    </div>
</body>
</html>
