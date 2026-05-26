<?php
session_start();
require_once __DIR__ . '/database/Database.php';

// ========== 加载配置 ==========
function loadEnv($path) {
    if (!file_exists($path)) return [];
    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $env = [];
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        $parts = explode('=', $line, 2);
        if (count($parts) === 2) $env[trim($parts[0])] = trim($parts[1]);
    }
    return $env;
}

$env = loadEnv(__DIR__ . '/.env');

$protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
$host = $_SERVER['HTTP_HOST'] ?? 'localhost';
$currentDir = dirname($_SERVER['SCRIPT_NAME']);
$parentDir = dirname($currentDir);
$rootUrl = $protocol . '://' . $host . ($parentDir === '/' ? '' : $parentDir) . '/';

$config = [
    'upload_dir' => __DIR__ . '/pub/',
    'admin_user' => $env['ADMIN_USER'] ?? 'admin',
    'admin_pass' => $env['ADMIN_PASS'] ?? 'admin123',
    'items_per_page' => 50,
];

// ========== 认证 ==========
if (isset($_GET['action']) && $_GET['action'] === 'logout') { session_destroy(); header('Location: admin.php'); exit; }

$is_authenticated = $_SESSION['admin_logged_in'] ?? false;
if (!$is_authenticated && $_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login'])) {
    $user = $_POST['username'] ?? '';
    $pass = $_POST['password'] ?? '';
    if ($user === $config['admin_user'] && $pass === $config['admin_pass']) {
        $_SESSION['admin_logged_in'] = true; header('Location: admin.php'); exit;
    } else { $login_error = '用户名或密码错误'; }
}

if (!$is_authenticated) {
    ?>
    <!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>登录 - 运营后台</title>
    <style>body{font-family:-apple-system,sans-serif;background:#f0f2f5;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;}.login-card{background:white;padding:40px;border-radius:16px;box-shadow:0 4px 20px rgba(0,0,0,0.1);width:100%;max-width:400px;}h2{text-align:center;margin-bottom:24px;color:#333;}.form-group{margin-bottom:16px;}label{display:block;margin-bottom:8px;color:#666;font-size:14px;}input{width:100%;padding:12px;border:1px solid #ddd;border-radius:8px;box-sizing:border-box;}button{width:100%;padding:12px;background:#667eea;color:white;border:none;border-radius:8px;font-size:16px;cursor:pointer;margin-top:10px;}button:hover{background:#5a6fd6;}.error{color:#ef4444;background:#fee2e2;padding:10px;border-radius:8px;margin-bottom:16px;font-size:14px;text-align:center;}</style></head>
    <body><div class="login-card"><h2>运营后台登录</h2><?php if(isset($login_error)):?><div class="error"><?=$login_error?></div><?php endif;?>
    <form method="post"><input type="hidden" name="login" value="1"><div class="form-group"><label>用户名</label><input type="text" name="username" required autofocus></div><div class="form-group"><label>密码</label><input type="password" name="password" required></div><button type="submit">登录</button></form></div></body></html>
    <?php exit; }

// Generate CSRF token
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}
$csrf_token = $_SESSION['csrf_token'];

// ========== 操作处理 ==========
$action = $_GET['action'] ?? 'list'; $message = ''; $messageType = '';

if ($action === 'delete' && isset($_GET['id']) && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { if (deleteProject($_GET['id'])) { $message='已删除'; $messageType='success'; } else { $message='删除失败'; $messageType='error'; } $action='list'; }

if ($action === 'bulk_delete' && $_SERVER['REQUEST_METHOD']==='POST' && isset($_POST['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) {
    $ids = $_POST['ids'] ?? []; $success=0; foreach($ids as $id){ if(deleteProject($id))$success++; }
    $message="成功删除 $success 个"; $messageType='success'; $action='list';
}

if ($action === 'ban_user' && isset($_GET['user_id']) && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { banUser($_GET['user_id'], $_GET['reason']??'违规'); $message='已封禁'; $messageType='success'; $action='users'; }
if ($action === 'unban_user' && isset($_GET['user_id']) && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { unbanUser($_GET['user_id']); $message='已解封'; $messageType='success'; $action='users'; }
if ($action === 'update_expiry' && $_SERVER['REQUEST_METHOD']==='POST' && isset($_POST['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'])) { updateProjectExpiry($_POST['project_id'], (int)$_POST['expiry_days']); $message='已更新'; $messageType='success'; $action='list'; }
if ($action === 'expire_now' && isset($_GET['id']) && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { if(expireProject($_GET['id'])){$message='已设为过期';$messageType='success';}else{$message='操作失败';$messageType='error';} $action='list'; }
if ($action === 'restore_project' && isset($_GET['id']) && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { if(restoreProject($_GET['id'])){$message='已恢复';$messageType='success';}else{$message='恢复失败';$messageType='error';} $action='list'; }
if ($action === 'run_expire_cron' && isset($_GET['csrf_token']) && hash_equals($_SESSION['csrf_token'], $_GET['csrf_token'])) { $count=runExpireCron(); $message="处理了{$count}个过期项目"; $messageType='success'; $action='list'; }

if ($action === 'export_csv') {
    try {
        $projects = db()->query("SELECT * FROM projects WHERE status!='deleted' ORDER BY created_at DESC");
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="projects_'.date('Y-m-d').'.csv"');
        $output = fopen('php://output', 'w');
        fputcsv($output, ['项目ID','项目名称','访问链接','访问量','文件数','用户ID','用户类型','过期时间','状态','创建时间']);
        foreach($projects as $p){
            $url=$rootUrl.'pub/'.$p['project_id'].'/index.html';
            fputcsv($output,[$p['project_id'],$p['project_name'],$url,$p['visit_count'],$p['file_count'],$p['user_id']??'',$p['is_pro']?'Pro':'免费',$p['expires_at']??'永久',$p['status'],$p['created_at']]);
        }
        fclose($output);
    } catch(Exception $e){ echo "导出失败: ".$e->getMessage(); }
    exit;
}

if ($action === 'stats' && isset($_GET['id'])) { showStatsPage($_GET['id']); exit; }
if ($action === 'user_detail' && isset($_GET['user_id'])) { showUserDetailPage($_GET['user_id']); exit; }

if ($action === 'save_filter' && $_SERVER['REQUEST_METHOD']==='POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if(!empty($input['name'])){ $filters = loadSavedFilters(); $filters[$input['name']] = $input['filter']; saveSavedFilters($filters); echo json_encode(['status'=>'success']); exit; }
}
if ($action === 'load_filter' && isset($_GET['filter_name'])) {
    $filters = loadSavedFilters(); if(isset($filters[$_GET['filter_name']])){ header('Location: admin.php?action=list&'.http_build_query(array_merge($_GET,$filters[$_GET['filter_name']]))); exit; }
}
if ($action === 'delete_filter' && $_SERVER['REQUEST_METHOD']==='POST') {
    $input = json_decode(file_get_contents('php://input'), true); if(!empty($input['name'])){ $filters=loadSavedFilters(); unset($filters[$input['name']]); saveSavedFilters($filters); echo json_encode(['status'=>'success']); exit; }
}

// ========== 数据查询 ==========
$projects = db()->query("SELECT * FROM projects WHERE status!='deleted' ORDER BY updated_at DESC");
$users = db()->query("SELECT * FROM users ORDER BY last_active_at DESC");

$totalProjects = count($projects);
$totalVisits = array_sum(array_column($projects,'visit_count'));
$todayVisitsResult = db()->queryOne("SELECT COUNT(*) as cnt FROM visit_logs WHERE visited_at >= CURDATE()");
$todayVisits = $todayVisitsResult['cnt'] ?? 0;
$totalUsers = count($users);
$proUsers = count(array_filter($users, fn($u)=>$u['is_pro']));
$bannedUsers = count(array_filter($users, fn($u)=>$u['status']==='banned'));

// 筛选
$filterTimeRange = $_GET['filter_time'] ?? 'all';
$filterExpiryStatus = $_GET['filter_expiry'] ?? 'all';
$filterPopularity = $_GET['filter_popularity'] ?? 'all';
$filterFileCount = $_GET['filter_files'] ?? 'all';
$filterUserType = $_GET['filter_user_type'] ?? 'all';

$filteredProjects = applyFilters($projects, ['time'=>$filterTimeRange,'expiry'=>$filterExpiryStatus,'popularity'=>$filterPopularity,'files'=>$filterFileCount,'user_type'=>$filterUserType]);

$search = $_GET['search'] ?? '';
if(!empty($search)){
    $filteredProjects = array_filter($filteredProjects, function($p) use($search){
        return stripos($p['project_name'],$search)!==false || stripos($p['project_id'],$search)!==false || stripos($p['user_id']??'',$search)!==false;
    });
}

$sort = $_GET['sort'] ?? 'updated';
usort($filteredProjects, function($a,$b) use($sort){
    switch($sort){
        case 'visits': return $b['visit_count']<=>$a['visit_count'];
        case 'created': return strtotime($b['created_at'])<=>strtotime($a['created_at']);
        case 'name': return strcmp($a['project_name'],$b['project_name']);
        default: return strtotime($b['updated_at'])<=>strtotime($a['updated_at']);
    }
});

$page = max(1, (int)($_GET['page']??1));
$perPage = $config['items_per_page'];
$totalPages = max(1, ceil(count($filteredProjects)/$perPage));
$pagedProjects = array_slice($filteredProjects, ($page-1)*$perPage, $perPage);

$userPage = max(1, (int)($_GET['user_page']??1));
$userPerPage = 20;
$userTotalPages = max(1, ceil($totalUsers/$userPerPage));
$pagedUsers = array_slice($users, ($userPage-1)*$userPerPage, $userPerPage);

$savedFilters = loadSavedFilters();

function formatDate($date){ if(!$date)return'-'; $diff=time()-strtotime($date); if($diff<3600)return floor($diff/60).'分钟前'; if($diff<86400)return floor($diff/3600).'小时前'; if($diff<604800)return floor($diff/86400).'天前'; return date('Y-m-d',strtotime($date)); }
function loadSavedFilters(){ 
    $f = getDataDir('filters') . '/saved_filters.json'; 
    return file_exists($f) ? json_decode(file_get_contents($f), true) ?: [] : []; 
}
function saveSavedFilters($f){ 
    $dir = getDataDir('filters');
    if (!is_dir($dir)) mkdir($dir, 0755, true);
    file_put_contents($dir . '/saved_filters.json', json_encode($f), LOCK_EX); 
}

function applyFilters($projects, $filters){
    $f=$projects; $now=time();
    if($filters['time']!=='all') $f=array_filter($f,function($p)use($filters,$now){
        $c=strtotime($p['created_at']);
        switch($filters['time']){case 'today':return date('Y-m-d',$c)===date('Y-m-d');case 'week':return $now-$c<=7*86400;case 'month':return $now-$c<=30*86400;case 'custom':return $c>=strtotime($_GET['filter_date_start']??'2000-01-01')&&$c<=strtotime($_GET['filter_date_end']??'2099-12-31');default:return true;}
    });
    if($filters['expiry']!=='all') $f=array_filter($f,function($p)use($filters){
        $e=!empty($p['expires_at'])&&strtotime($p['expires_at'])<$now;
        switch($filters['expiry']){case 'expired':return $e;case 'expiring_soon':return !$e&&!empty($p['expires_at'])&&ceil((strtotime($p['expires_at'])-$now)/86400)<=7;case 'permanent':return empty($p['expires_at']);case 'active':return !$e&&!empty($p['expires_at']);default:return true;}
    });
    if($filters['popularity']!=='all') $f=array_filter($f,function($p)use($filters){
        $v=$p['visit_count']; switch($filters['popularity']){case 'zero':return $v===0;case 'low':return $v>=1&&$v<=100;case 'medium':return $v>100&&$v<=1000;case 'high':return $v>1000;default:return true;}
    });
    if($filters['files']!=='all') $f=array_filter($f,function($p)use($filters){
        $c=$p['file_count']??0; switch($filters['files']){case 'single':return $c<=1;case 'multi':return $c>=2&&$c<=5;case 'complex':return $c>=6;default:return true;}
    });
    if($filters['user_type']!=='all') $f=array_filter($f,function($p)use($filters){
        $pro=$p['is_pro']; switch($filters['user_type']){case 'pro':return $pro;case 'free':return !$pro;default:return true;}
    });
    return $f;
}

function deleteProject($id){
    try{
        db()->execute("UPDATE projects SET status='deleted' WHERE project_id=?",[$id]);
        $dir=__DIR__.'/pub/'.$id; if(is_dir($dir)){ array_map('unlink',glob("$dir/*")); rmdir($dir); }
        return true;
    }catch(Exception $e){return false;}
}

function updateProjectExpiry($id, $days){
    try{
        if($days>0){$e=date('Y-m-d H:i:s',strtotime("+$days days"));db()->execute("UPDATE projects SET expires_at=?,expire_days=?,updated_at=NOW() WHERE project_id=?",[$e,$days,$id]);}
        else{db()->execute("UPDATE projects SET expires_at=NULL,expire_days=0,updated_at=NOW() WHERE project_id=?",[$id]);}
        return true;
    }catch(Exception $e){return false;}
}

function banUser($uid, $reason){ try{db()->execute("UPDATE users SET status='banned',ban_reason=?,banned_at=NOW() WHERE user_id=?",[$reason,$uid]);}catch(Exception $e){} }
function unbanUser($uid){ try{db()->execute("UPDATE users SET status='active',ban_reason=NULL,banned_at=NULL WHERE user_id=?",[$uid]);}catch(Exception $e){} }

function expireProject($id){
    try{
        $project = db()->queryOne("SELECT * FROM projects WHERE project_id=? AND status!='deleted' LIMIT 1",[$id]);
        if(!$project) return false;
        
        $dir = __DIR__.'/pub/'.$id;
        if(!is_dir($dir)) return false;
        
        // 更新数据库状态
        db()->execute("UPDATE projects SET status='expired',updated_at=NOW() WHERE project_id=?",[$id]);
        
        // 执行文件替换
        $templatePath = __DIR__.'/expired_template.html';
        if(!file_exists($templatePath)) return false;
        $expiredContent = file_get_contents($templatePath);
        
        $files = glob($dir.'/*');
        foreach($files as $file){
            if(is_file($file)){
                $filename = basename($file);
                if(substr($filename,-4)==='.bak' || $filename==='.htaccess') continue;
                $bakFile = $file.'.bak';
                if(copy($file,$bakFile)){
                    if(preg_match('/\.(html|htm)$/i',$filename)){
                        file_put_contents($file,$expiredContent);
                    }else{
                        unlink($file);
                    }
                }
            }
        }
        return true;
    }catch(Exception $e){return false;}
}

function restoreProject($id){
    try{
        $project = db()->queryOne("SELECT * FROM projects WHERE project_id=? AND status!='deleted' LIMIT 1",[$id]);
        if(!$project) return false;
        
        // 重置过期时间
        // Reset expiry to 30 days from now when restoring
        $newExpiry = date('Y-m-d H:i:s', strtotime('+30 days'));
        db()->execute("UPDATE projects SET status='active',expires_at=?,updated_at=NOW() WHERE project_id=?",[$newExpiry,$id]);
        
        $dir = __DIR__.'/pub/'.$id;
        if(!is_dir($dir)) return false;
        
        $files = glob($dir.'/*');
        foreach($files as $file){
            if(is_file($file) && substr($file,-4)==='.bak'){
                $originalFile = substr($file,0,-4);
                rename($file,$originalFile);
            }
        }
        return true;
    }catch(Exception $e){return false;}
}

function runExpireCron(){
    $expiredProjects = db()->query("SELECT project_id FROM projects WHERE expires_at IS NOT NULL AND expires_at<NOW() AND status='active'");
    $count = 0;
    foreach($expiredProjects as $p){
        if(expireProject($p['project_id'])) $count++;
    }
    return $count;
}

?>
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>运营后台</title>
<style>*{margin:0;padding:0;box-sizing:border-box;}body{font-family:-apple-system,sans-serif;background:#f5f7fa;color:#333;line-height:1.6;}.container{max-width:1400px;margin:0 auto;padding:20px;}.header{background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:30px;border-radius:16px;margin-bottom:24px;display:flex;justify-content:space-between;align-items:center;}.header h1{font-size:28px;}.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin-bottom:24px;}.stat-card{background:white;padding:24px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);}.stat-card .num{font-size:36px;font-weight:bold;color:#667eea;}.stat-card .label{color:#666;font-size:14px;}.nav-tabs{display:flex;gap:8px;margin-bottom:24px;background:white;padding:8px;border-radius:12px;}.nav-tab{padding:12px 24px;border-radius:8px;text-decoration:none;color:#666;font-weight:500;}.nav-tab.active{background:#667eea;color:white;}.toolbar{background:white;padding:16px;border-radius:12px;margin-bottom:20px;}.toolbar-row{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:12px;}.toolbar input,.toolbar select{padding:8px;border:1px solid #ddd;border-radius:8px;font-size:14px;}.filter-group{display:flex;gap:8px;align-items:center;padding:8px;background:#f8fafc;border-radius:8px;}.filter-group label{font-size:13px;color:#666;}.btn{padding:8px 16px;border:none;border-radius:8px;cursor:pointer;font-size:14px;text-decoration:none;display:inline-block;}.btn-primary{background:#667eea;color:white;}.btn-danger{background:#ef4444;color:white;}.btn-success{background:#10b981;color:white;}.btn-secondary{background:#6b7280;color:white;}.btn-warning{background:#f59e0b;color:white;}.btn-sm{padding:6px 12px;font-size:13px;}.table-container{background:white;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);overflow:hidden;margin-bottom:20px;}table{width:100%;border-collapse:collapse;}th,td{padding:14px 16px;text-align:left;border-bottom:1px solid #eee;}th{background:#f8fafc;font-weight:600;color:#555;font-size:13px;}tr:hover{background:#f8fafc;}.badge{display:inline-block;padding:4px 10px;border-radius:6px;font-size:12px;font-weight:500;}.badge-success{background:#d1fae5;color:#065f46;}.badge-warning{background:#fef3c7;color:#92400e;}.badge-danger{background:#fee2e2;color:#991b1b;}.badge-info{background:#dbeafe;color:#1e40af;}.badge-gray{background:#f3f4f6;color:#374151;}.visit-count{font-weight:600;color:#667eea;}.actions{display:flex;gap:6px;flex-wrap:wrap;}.pagination{display:flex;justify-content:center;gap:8px;padding:20px;}.pagination a,.pagination span{padding:8px 14px;border-radius:8px;text-decoration:none;color:#667eea;background:white;border:1px solid #e5e7eb;}.pagination .current{background:#667eea;color:white;border-color:#667eea;}.modal-overlay{display:none;position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:1000;justify-content:center;align-items:center;}.modal-overlay.active{display:flex;}.modal{background:white;padding:32px;border-radius:16px;width:90%;max-width:500px;}.modal input,.modal select,.modal textarea{width:100%;padding:10px;margin-bottom:12px;border:1px solid #ddd;border-radius:8px;}.modal-actions{display:flex;gap:12px;justify-content:flex-end;margin-top:16px;}.alert{padding:12px 16px;border-radius:8px;margin-bottom:16px;}.alert-success{background:#d1fae5;color:#065f46;}.alert-error{background:#fee2e2;color:#991b1b;}input[type="checkbox"]{width:18px;height:18px;}.user-avatar{width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,#667eea,#764ba2);display:flex;align-items:center;justify-content:center;color:white;font-weight:bold;font-size:16px;}.user-info{display:flex;align-items:center;gap:12px;}input[type="text"]{min-width:200px;}input[type="date"]{min-width:150px;}.saved-filters{display:flex;gap:8px;flex-wrap:wrap;}.saved-filter-tag{padding:6px 12px;background:#ede9fe;color:#5b21b6;border-radius:16px;font-size:13px;cursor:pointer;}@media(max-width:768px){.stats-grid{grid-template-columns:repeat(2,1fr);}.toolbar-row{flex-direction:column;}.filter-group{flex-direction:column;}table{font-size:13px;}th,td{padding:10px 8px;}}</style></head>
<body><div class="container">
<div class="header"><div><h1>HTML Editor 运营后台</h1><p>用户管理 · 内容监控 · 数据分析</p></div><a href="?action=logout" class="btn btn-danger" style="background:rgba(255,255,255,0.2);border:1px solid rgba(255,255,255,0.4);">退出登录</a></div>

<?php if($message):?><div class="alert alert-<?=$messageType?>"><?=$message?></div><?php endif;?>

<div class="nav-tabs"><a href="?action=list" class="nav-tab <?=$action==='list'?'active':'';?>">项目列表</a><a href="?action=users" class="nav-tab <?=$action==='users'?'active':'';?>">用户管理</a></div>

<?php if($action==='users'):?>
<div class="stats-grid"><div class="stat-card"><div class="num"><?=number_format($totalUsers)?></div><div class="label">总用户数</div></div><div class="stat-card"><div class="num" style="color:#10b981;"><?=number_format($proUsers)?></div><div class="label">Pro 用户</div></div><div class="stat-card"><div class="num" style="color:#f59e0b;"><?=number_format($totalUsers-$proUsers)?></div><div class="label">免费用户</div></div><div class="stat-card"><div class="num" style="color:#ef4444;"><?=number_format($bannedUsers)?></div><div class="label">已封禁</div></div><div class="stat-card"><div class="num" style="color:#8b5cf6;"><?=number_format($totalProjects)?></div><div class="label">总发布数</div></div><div class="stat-card"><div class="num" style="color:#06b6d4;"><?=number_format($totalVisits)?></div><div class="label">总访问量</div></div></div>

<div class="table-container"><table><thead><tr><th>用户信息</th><th>订阅状态</th><th>发布次数</th><th>总访问量</th><th>最后活跃</th><th>注册时间</th><th>操作</th></tr></thead><tbody>
<?php foreach($pagedUsers as $user):$isBanned=$user['status']==='banned';?>
<tr><td><div class="user-info"><div class="user-avatar"><?=strtoupper(substr($user['user_id'],0,1))?></div><div style="font-family:monospace;font-size:13px;color:#667eea;"><?=$user['user_id']?></div></div></td><td><?php if($user['is_pro']):?><span class="badge badge-success">Pro</span><?php else:?><span class="badge badge-gray">免费</span><?php endif;?><?php if($isBanned):?><span class="badge badge-danger">已封禁</span><?php endif;?></td><td class="visit-count"><?=number_format($user['publish_count'])?></td><td class="visit-count"><?=number_format($user['total_visits'])?></td><td><?=formatDate($user['last_active_at'])?></td><td><?=formatDate($user['created_at'])?></td><td><div class="actions"><a href="?action=user_detail&user_id=<?=urlencode($user['user_id'])?>" class="btn btn-primary btn-sm">详情</a><?php if($isBanned):?><a href="?action=unban_user&user_id=<?=urlencode($user['user_id'])?>&csrf_token=<?=$csrf_token?>" class="btn btn-success btn-sm">解封</a><?php else:?><a href="?action=ban_user&user_id=<?=urlencode($user['user_id'])?>&reason=违规&csrf_token=<?=$csrf_token?>" class="btn btn-danger btn-sm">封禁</a><?php endif;?></div></td></tr>
<?php endforeach;?>
<?php if(empty($pagedUsers)):?><tr><td colspan="7" style="text-align:center;padding:40px;color:#999;">暂无用户数据</td></tr><?php endif;?>
</tbody></table></div>

<?php if($userTotalPages>1):?><div class="pagination"><?php if($userPage>1):?><a href="?action=users&user_page=<?=$userPage-1;?>">上一页</a><?php endif;?><?php for($i=max(1,$userPage-2);$i<=min($userTotalPages,$userPage+2);$i++):?><?php if($i==$userPage):?><span class="current"><?=$i?></span><?php else:?><a href="?action=users&user_page=<?=$i;?>"><?=$i?></a><?php endif;?><?php endfor;?><?php if($userPage<$userTotalPages):?><a href="?action=users&user_page=<?=$userPage+1;?>">下一页</a><?php endif;?></div><?php endif;?>

<?php else:?>
<div class="stats-grid"><div class="stat-card"><div class="num"><?=number_format($totalProjects)?></div><div class="label">总发布链接</div></div><div class="stat-card"><div class="num"><?=number_format($totalVisits)?></div><div class="label">总访问量</div></div><div class="stat-card"><div class="num"><?=number_format($todayVisits)?></div><div class="label">今日访问</div></div><div class="stat-card"><div class="num"><?=number_format(count(array_filter($projects,fn($p)=>$p['is_pro'])))?></div><div class="label">Pro 发布</div></div></div>

<div class="toolbar">
<div class="toolbar-row"><form method="get" style="display:flex;gap:12px;flex-wrap:wrap;flex:1;"><input type="text" name="search" placeholder="搜索项目名、ID或用户ID..." value="<?=htmlspecialchars($search)?>"><select name="sort"><option value="updated" <?=$sort==='updated'?'selected':'';?>>最近更新</option><option value="created" <?=$sort==='created'?'selected':'';?>>创建时间</option><option value="visits" <?=$sort==='visits'?'selected':'';?>>访问量</option><option value="name" <?=$sort==='name'?'selected':'';?>>项目名</option></select><button type="submit" class="btn btn-primary">搜索</button><?php if($search||$filterTimeRange!=='all'||$filterExpiryStatus!=='all'):?><a href="?action=list" class="btn btn-secondary">清除</a><?php endif;?></form><button class="btn btn-warning" onclick="exportCSV()">导出CSV</button><button class="btn btn-danger" onclick="bulkDelete()">批量删除</button></div>

<div class="toolbar-row" style="border-top:1px solid #eee;padding-top:12px;">
<div class="filter-group"><label>时间:</label><select onchange="applyFilter('filter_time',this.value)"><option value="all" <?=$filterTimeRange==='all'?'selected':'';?>>全部</option><option value="today" <?=$filterTimeRange==='today'?'selected':'';?>>今日</option><option value="week" <?=$filterTimeRange==='week'?'selected':'';?>>本周</option><option value="month" <?=$filterTimeRange==='month'?'selected':'';?>>本月</option></select></div>
<div class="filter-group"><label>过期:</label><select onchange="applyFilter('filter_expiry',this.value)"><option value="all" <?=$filterExpiryStatus==='all'?'selected':'';?>>全部</option><option value="expired" <?=$filterExpiryStatus==='expired'?'selected':'';?>>已过期</option><option value="expiring_soon" <?=$filterExpiryStatus==='expiring_soon'?'selected':'';?>>即将过期</option><option value="permanent" <?=$filterExpiryStatus==='permanent'?'selected':'';?>>永久</option></select></div>
<div class="filter-group"><label>热度:</label><select onchange="applyFilter('filter_popularity',this.value)"><option value="all" <?=$filterPopularity==='all'?'selected':'';?>>全部</option><option value="zero" <?=$filterPopularity==='zero'?'selected':'';?>>0访问</option><option value="low" <?=$filterPopularity==='low'?'selected':'';?>>1-100</option><option value="medium" <?=$filterPopularity==='medium'?'selected':'';?>>100-1000</option><option value="high" <?=$filterPopularity==='high'?'selected':'';?>>1000+</option></select></div>
<div class="filter-group"><label>文件:</label><select onchange="applyFilter('filter_files',this.value)"><option value="all" <?=$filterFileCount==='all'?'selected':'';?>>全部</option><option value="single" <?=$filterFileCount==='single'?'selected':'';?>>单文件</option><option value="multi" <?=$filterFileCount==='multi'?'selected':'';?>>2-5</option><option value="complex" <?=$filterFileCount==='complex'?'selected':'';?>>6+</option></select></div>
<div class="filter-group"><label>用户:</label><select onchange="applyFilter('filter_user_type',this.value)"><option value="all" <?=$filterUserType==='all'?'selected':'';?>>全部</option><option value="pro" <?=$filterUserType==='pro'?'selected':'';?>>Pro</option><option value="free" <?=$filterUserType==='free'?'selected':'';?>>免费</option></select></div>
<div class="filter-group"><label>保存:</label><input type="text" id="filter_name" placeholder="名称" style="min-width:100px;"><button class="btn btn-primary btn-sm" onclick="saveFilter()">保存</button></div>
<?php if(!empty($savedFilters)):?><div class="filter-group"><label>已保存:</label><div class="saved-filters"><?php foreach($savedFilters as $n=>$f):?><span class="saved-filter-tag" onclick="loadFilter('<?=htmlspecialchars($n)?>')"><?=htmlspecialchars($n)?> <span onclick="event.stopPropagation();deleteFilter('<?=htmlspecialchars($n)?>')">&times;</span></span><?php endforeach;?></div></div><?php endif;?>
</div></div>

<div class="table-container"><form id="bulkForm" method="post" action="?action=bulk_delete"><input type="hidden" name="csrf_token" value="<?=$csrf_token?>"><table><thead><tr><th><input type="checkbox" id="selectAll" onclick="toggleAll()"></th><th>项目</th><th>链接</th><th>访问</th><th>状态</th><th>用户</th><th>更新</th><th>操作</th></tr></thead><tbody>
<?php foreach($pagedProjects as $p):$isExpired=!empty($p['expires_at'])&&strtotime($p['expires_at'])<time();?>
<tr><td><input type="checkbox" name="ids[]" value="<?=htmlspecialchars($p['project_id'])?>"></td><td><div style="font-weight:600;"><?=htmlspecialchars($p['project_name'])?></div><div style="font-size:12px;color:#999;"><?=htmlspecialchars($p['project_id'])?></div></td><td style="max-width:250px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><a href="<?=$rootUrl.'pub/'.$p['project_id'].'/index.html'?>" target="_blank" style="color:#667eea;"><?=$rootUrl.'pub/'.$p['project_id'].'/index.html'?></a></td><td class="visit-count"><?=number_format($p['visit_count'])?></td><td><?php if($isExpired):?><span class="badge badge-danger">已过期</span><?php elseif($p['expires_at']):?><?php $d=ceil((strtotime($p['expires_at'])-time())/86400);?><?php if($d<=7):?><span class="badge badge-warning"><?=$d?>天</span><?php else:?><span class="badge badge-info"><?=$d?>天</span><?php endif;?><?php else:?><span class="badge badge-success">永久</span><?php endif;?></td><td><?php if($p['is_pro']):?><span class="badge badge-success">Pro</span><?php else:?><span class="badge badge-gray">免费</span><?php endif;?><a href="?action=user_detail&user_id=<?=urlencode($p['user_id']??'')?>" class="btn btn-sm btn-secondary" style="margin-left:4px;font-size:11px;">查看</a></td><td><?=formatDate($p['updated_at'])?></td><td><div class="actions"><a href="<?=$rootUrl.'pub/'.$p['project_id'].'/index.html'?>" target="_blank" class="btn btn-primary btn-sm">访问</a><a href="?action=stats&id=<?=urlencode($p['project_id'])?>" class="btn btn-secondary btn-sm">统计</a><button class="btn btn-warning btn-sm" onclick="showExpiryModal('<?=htmlspecialchars($p['project_id'])?>','<?=htmlspecialchars($p['project_name'])?>')">过期</button><?php if($p['status']==='expired'):?><a href="?action=restore_project&id=<?=urlencode($p['project_id'])?>&csrf_token=<?=$csrf_token?>" class="btn btn-success btn-sm" onclick="return confirm('确定恢复？')">恢复</a><?php else:?><a href="?action=expire_now&id=<?=urlencode($p['project_id'])?>&csrf_token=<?=$csrf_token?>" class="btn btn-danger btn-sm" onclick="return confirm('确定设为过期？')">过期</a><?php endif;?></div></td></tr>
<?php endforeach;?>
<?php if(empty($pagedProjects)):?><tr><td colspan="8" style="text-align:center;padding:40px;color:#999;">暂无数据</td></tr><?php endif;?>
</tbody></table></form></div>

<?php if($totalPages>1):?><div class="pagination"><?php if($page>1):?><a href="?page=<?=$page-1;?>&sort=<?=$sort;?>&search=<?=urlencode($search);?>&filter_time=<?=$filterTimeRange;?>&filter_expiry=<?=$filterExpiryStatus;?>&filter_popularity=<?=$filterPopularity;?>&filter_files=<?=$filterFileCount;?>&filter_user_type=<?=$filterUserType;?>">上一页</a><?php endif;?><?php for($i=max(1,$page-2);$i<=min($totalPages,$page+2);$i++):?><?php if($i==$page):?><span class="current"><?=$i?></span><?php else:?><a href="?page=<?=$i;?>&sort=<?=$sort;?>&search=<?=urlencode($search);?>&filter_time=<?=$filterTimeRange;?>&filter_expiry=<?=$filterExpiryStatus;?>&filter_popularity=<?=$filterPopularity;?>&filter_files=<?=$filterFileCount;?>&filter_user_type=<?=$filterUserType;?>"><?=$i?></a><?php endif;?><?php endfor;?><?php if($page<$totalPages):?><a href="?page=<?=$page+1;?>&sort=<?=$sort;?>&search=<?=urlencode($search);?>&filter_time=<?=$filterTimeRange;?>&filter_expiry=<?=$filterExpiryStatus;?>&filter_popularity=<?=$filterPopularity;?>&filter_files=<?=$filterFileCount;?>&filter_user_type=<?=$filterUserType;?>">下一页</a><?php endif;?></div><?php endif;?>
<?php endif;?>
</div>

<div class="modal-overlay" id="expiryModal"><div class="modal"><h3>修改过期时间</h3><form method="post" action="?action=update_expiry"><input type="hidden" name="csrf_token" value="<?=$csrf_token?>"><input type="hidden" name="project_id" id="expiry_project_id"><p>项目: <span id="expiry_project_name"></span></p><input type="number" name="expiry_days" min="0" max="3650" value="0" placeholder="天数(0=永久)" required><div class="modal-actions"><button type="button" class="btn btn-secondary" onclick="hideExpiryModal()">取消</button><button type="submit" class="btn btn-success">确认</button></div></form></div></div>

<script>
function toggleAll(){document.querySelectorAll('input[name="ids[]"]').forEach(cb=>cb.checked=document.getElementById('selectAll').checked);}
function bulkDelete(){const c=document.querySelectorAll('input[name="ids[]"]:checked');if(c.length===0){alert('请选择');return;}if(confirm('确定删除'+c.length+'个？'))document.getElementById('bulkForm').submit();}
function showExpiryModal(id,name){document.getElementById('expiry_project_id').value=id;document.getElementById('expiry_project_name').textContent=name;document.getElementById('expiryModal').classList.add('active');}function hideExpiryModal(){document.getElementById('expiryModal').classList.remove('active');}
document.querySelectorAll('.modal-overlay').forEach(m=>m.addEventListener('click',e=>{if(e.target===m)m.classList.remove('active');}));
function applyFilter(n,v){const u=new URL(window.location.href);u.searchParams.set(n,v);window.location.href=u.toString();}
function saveFilter(){const n=document.getElementById('filter_name').value.trim();if(!n){alert('请输入名称');return;}const u=new URL(window.location.href);fetch('?action=save_filter',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:n,filter:{filter_time:u.searchParams.get('filter_time')||'all',filter_expiry:u.searchParams.get('filter_expiry')||'all',filter_popularity:u.searchParams.get('filter_popularity')||'all',filter_files:u.searchParams.get('filter_files')||'all',filter_user_type:u.searchParams.get('filter_user_type')||'all'}})}).then(()=>location.reload());}
function loadFilter(n){window.location.href='?action=load_filter&filter_name='+encodeURIComponent(n);}
function deleteFilter(n){if(confirm('确定删除？')){fetch('?action=delete_filter',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:n})}).then(()=>location.reload());}}
function exportCSV(){window.location.href='?action=export_csv';}
</script></body></html>

<?php
function showStatsPage($id){
    try{
        $project=db()->queryOne("SELECT * FROM projects WHERE project_id=?",[$id]);
        if(!$project){echo "<h1>项目不存在</h1>";exit;}
        
        $visits=[];for($i=6;$i>=0;$i--){$d=date('Y-m-d',strtotime("-$i days"));$r=db()->queryOne("SELECT COUNT(*) as c FROM visit_logs WHERE project_id=? AND DATE(visited_at)=?",[$id,$d]);$visits[$d]=(int)($r['c']??0);}
        $maxV=max(array_values($visits))?:1;
        ?>
        <!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>统计 - <?=$project['project_name']?></title>
        <style>*{margin:0;padding:0;box-sizing:border-box;}body{font-family:-apple-system,sans-serif;background:#f5f7fa;padding:40px;}.container{max-width:800px;margin:0 auto;}.back{color:#667eea;text-decoration:none;margin-bottom:20px;display:inline-block;}.card{background:white;padding:24px;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.08);}.stat-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:24px;}.stat-box{text-align:center;padding:16px;background:#f8fafc;border-radius:8px;}.stat-box .num{font-size:28px;font-weight:bold;color:#667eea;}.stat-box .label{color:#666;font-size:14px;margin-top:4px;}.chart{display:flex;align-items:flex-end;gap:8px;height:200px;padding:20px 0;}.bar-wrapper{flex:1;display:flex;flex-direction:column;align-items:center;gap:8px;}.bar{width:100%;background:linear-gradient(to top,#667eea,#764ba2);border-radius:4px 4px 0 0;min-height:4px;}.bar-label{font-size:12px;color:#666;}</style></head>
        <body><div class="container"><a href="admin.php?action=list" class="back">← 返回</a><div class="card"><h1><?=htmlspecialchars($project['project_name'])?></h1><div class="stat-grid"><div class="stat-box"><div class="num"><?=number_format($project['visit_count'])?></div><div class="label">总访问</div></div><div class="stat-box"><div class="num"><?=number_format(array_sum($visits))?></div><div class="label">7日访问</div></div><div class="stat-box"><div class="num"><?=htmlspecialchars($project['created_at'])?></div><div class="label">创建时间</div></div></div><h3>最近7天访问趋势</h3><div class="chart"><?php foreach($visits as $d=>$c):?><div class="bar-wrapper"><div class="bar" style="height:<?=($c/$maxV)*100?>%"></div><div class="bar-label"><?=substr($d,5)?></div><div class="bar-label" style="font-weight:600;"><?=$c?></div></div><?php endforeach;?></div></div></div></body></html>
        <?php
    }catch(Exception $e){echo "加载失败: ".$e->getMessage();}exit;
}

function showUserDetailPage($userId){
    try{
        $user=db()->queryOne("SELECT * FROM users WHERE user_id=?",[$userId]);
        if(!$user){echo "<script>alert('用户不存在');window.location.href='admin.php?action=users';</script>";exit;}
        
        $projects=db()->query("SELECT * FROM projects WHERE user_id=? AND status!='deleted' ORDER BY created_at DESC",[$userId]);
        $activities=db()->query("SELECT * FROM user_activity_logs WHERE user_id=? ORDER BY created_at DESC LIMIT 100",[$userId]);
        $totalVisits=array_sum(array_column($projects,'visit_count'));
        $isBanned=$user['status']==='banned';
        ?>
        <!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>用户详情</title>
        <style>*{margin:0;padding:0;box-sizing:border-box;}body{font-family:-apple-system,sans-serif;background:#f5f7fa;padding:40px;}.container{max-width:1200px;margin:0 auto;}.back{color:#667eea;text-decoration:none;margin-bottom:20px;display:inline-block;}.header{background:linear-gradient(135deg,#667eea,#764ba2);color:white;padding:30px;border-radius:16px;margin-bottom:24px;display:flex;justify-content:space-between;align-items:center;}.stats{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin-bottom:24px;}.stat-card{background:white;padding:24px;border-radius:12px;}.stat-card .num{font-size:36px;font-weight:bold;color:#667eea;}.stat-card .label{color:#666;font-size:14px;}table{width:100%;border-collapse:collapse;background:white;border-radius:12px;}th,td{padding:14px 16px;text-align:left;border-bottom:1px solid #eee;}th{background:#f8fafc;font-weight:600;color:#555;font-size:13px;}.badge{display:inline-block;padding:4px 10px;border-radius:6px;font-size:12px;}.badge-success{background:#d1fae5;color:#065f46;}.badge-danger{background:#fee2e2;color:#991b1b;}.badge-warning{background:#fef3c7;color:#92400e;}.badge-gray{background:#f3f4f6;color:#374151;}.btn{padding:8px 16px;border:none;border-radius:8px;cursor:pointer;font-size:14px;text-decoration:none;display:inline-block;}.btn-primary{background:#667eea;color:white;}.btn-danger{background:#ef4444;color:white;}.btn-success{background:#10b981;color:white;}.btn-sm{padding:6px 12px;font-size:13px;}</style></head>
        <body><div class="container"><a href="admin.php?action=users" class="back">← 返回</a><div class="header"><div><h1>用户详情</h1><p>用户ID: <code style="background:rgba(255,255,255,0.2);padding:4px 8px;border-radius:4px;"><?=$userId?></code></p></div><div><?php if($isBanned):?><a href="?action=unban_user&user_id=<?=urlencode($userId)?>&csrf_token=<?=$csrf_token?>" class="btn btn-success">解封</a><?php else:?><a href="?action=ban_user&user_id=<?=urlencode($userId)?>&reason=违规&csrf_token=<?=$csrf_token?>" class="btn btn-danger">封禁</a><?php endif;?></div></div>
        <div class="stats"><div class="stat-card"><div class="num"><?=$user['is_pro']?'Pro':'免费'?></div><div class="label">订阅</div></div><div class="stat-card"><div class="num"><?=number_format(count($projects))?></div><div class="label">项目</div></div><div class="stat-card"><div class="num"><?=number_format($totalVisits)?></div><div class="label">访问</div></div><div class="stat-card"><div class="num"><?=formatDate($user['last_active_at'])?></div><div class="label">活跃</div></div><div class="stat-card"><div class="num"><?=formatDate($user['created_at'])?></div><div class="label">注册</div></div></div>
        <table><thead><tr><th>项目</th><th>链接</th><th>访问</th><th>状态</th><th>创建</th><th>操作</th></tr></thead><tbody><?php foreach($projects as $p):$e=!empty($p['expires_at'])&&strtotime($p['expires_at'])<time();?><tr><td><div style="font-weight:600;"><?=htmlspecialchars($p['project_name'])?></div><div style="font-size:12px;color:#999;"><?=$p['project_id']?></div></td><td style="max-width:300px;overflow:hidden;text-overflow:ellipsis;"><a href="<?=htmlspecialchars($GLOBALS['rootUrl'].'pub/'.$p['project_id'].'/index.html')?>" target="_blank" style="color:#667eea;"><?=htmlspecialchars($p['project_id'])?></a></td><td style="font-weight:600;color:#667eea;"><?=$p['visit_count']?></td><td><?php if($e):?><span class="badge badge-danger">已过期</span><?php elseif($p['expires_at']):?><span class="badge badge-warning"><?=ceil((strtotime($p['expires_at'])-time())/86400)?>天</span><?php else:?><span class="badge badge-success">永久</span><?php endif;?></td><td><?=htmlspecialchars($p['created_at'])?></td><td><a href="?action=stats&id=<?=urlencode($p['project_id'])?>" class="btn btn-sm btn-primary">统计</a></td></tr><?php endforeach;?></tbody></table>
        <?php if(!empty($activities)):?><h3 style="margin:24px 0 16px;">活动记录</h3><div style="max-height:400px;overflow-y:auto;"><?php foreach($activities as $a):?><div style="padding:12px;border-bottom:1px solid #eee;display:flex;justify-content:space-between;"><span style="color:#667eea;"><?=htmlspecialchars($a['action'])?></span><span style="color:#666;font-size:13px;"><?=formatDate($a['created_at'])?></span></div><?php endforeach;?></div><?php endif;?>
        </div></body></html>
        <?php
    }catch(Exception $e){echo "加载失败: ".$e->getMessage();}exit;
}
?>