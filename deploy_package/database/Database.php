<?php
/**
 * HTML Code Editor - Database Configuration
 * MySQL 数据库配置和PDO连接类
 */

class Database {
    private static $instance = null;
    private $pdo;
    
    // 数据库配置
    private $host;
    private $port;
    private $dbname;
    private $username;
    private $password;
    private $charset;
    
    private function __construct() {
        // 从 .env 文件读取配置
        $envFile = __DIR__ . '/../.env';
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
        
        $this->host = getenv('DB_HOST') ?: ($env['DB_HOST'] ?? 'localhost');
        $this->port = getenv('DB_PORT') ?: ($env['DB_PORT'] ?? '3306');
        $this->dbname = getenv('DB_NAME') ?: ($env['DB_NAME'] ?? 'html_editor');
        $this->username = getenv('DB_USER') ?: ($env['DB_USER'] ?? 'root');
        $this->password = getenv('DB_PASS') ?: ($env['DB_PASS'] ?? '');
        $this->charset = getenv('DB_CHARSET') ?: ($env['DB_CHARSET'] ?? 'utf8mb4');
        
        $this->connect();
    }
    
    /**
     * 获取单例实例
     */
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    /**
     * 连接数据库
     */
    private function connect() {
        $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->dbname};charset={$this->charset}";
        
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES {$this->charset}",
            PDO::ATTR_PERSISTENT => true,
            PDO::MYSQL_ATTR_SSL_CA => '/etc/ssl/certs/ca-certificates.crt',
            PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => true,
        ];
        
        try {
            $this->pdo = new PDO($dsn, $this->username, $this->password, $options);
        } catch (PDOException $e) {
            // 记录错误日志
            error_log("Database connection error: " . $e->getMessage());
            
            // 在开发环境显示详细错误
            if (defined('DEBUG') && DEBUG) {
                die("Database connection failed: " . $e->getMessage());
            } else {
                die("Database connection failed. Please try again later.");
            }
        }
    }
    
    /**
     * 获取PDO实例
     */
    public function getPdo() {
        return $this->pdo;
    }
    
    /**
     * 执行查询并返回所有结果
     */
    public function query($sql, $params = []) {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll();
        } catch (PDOException $e) {
            error_log("Query error: " . $e->getMessage() . "\nSQL: $sql");
            throw $e;
        }
    }
    
    /**
     * 执行查询并返回单行结果
     */
    public function queryOne($sql, $params = []) {
        try {
            $stmt = $this->pdo->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetch();
        } catch (PDOException $e) {
            error_log("Query error: " . $e->getMessage() . "\nSQL: $sql");
            throw $e;
        }
    }
    
    /**
     * 执行INSERT/UPDATE/DELETE
     */
    public function execute($sql, $params = []) {
        try {
            $stmt = $this->pdo->prepare($sql);
            return $stmt->execute($params);
        } catch (PDOException $e) {
            error_log("Execute error: " . $e->getMessage() . "\nSQL: $sql");
            throw $e;
        }
    }
    
    /**
     * 插入数据并返回最后插入的ID
     */
    public function insert($sql, $params = []) {
        $this->execute($sql, $params);
        return $this->pdo->lastInsertId();
    }
    
    /**
     * 开启事务
     */
    public function beginTransaction() {
        return $this->pdo->beginTransaction();
    }
    
    /**
     * 提交事务
     */
    public function commit() {
        return $this->pdo->commit();
    }
    
    /**
     * 回滚事务
     */
    public function rollBack() {
        return $this->pdo->rollBack();
    }
    
    /**
     * 防止克隆
     */
    private function __clone() {}
    
    /**
     * 防止反序列化
     */
    public function __wakeup() {
        throw new Exception("Cannot unserialize singleton");
    }
}

/**
 * 快捷函数：获取数据库实例
 */
function db() {
    return Database::getInstance();
}

/**
 * 获取持久化数据目录
 * 替代/tmp/目录，防止服务器重启丢失数据
 */
function getDataDir($subdir = '') {
    $baseDir = __DIR__ . '/../data/';
    if (!is_dir($baseDir)) {
        mkdir($baseDir, 0755, true);
    }
    
    $targetDir = $baseDir . $subdir;
    if (!empty($subdir) && !is_dir($targetDir)) {
        mkdir($targetDir, 0755, true);
    }
    
    return $targetDir;
}

/**
 * IP地址匿名化处理
 * 将IP地址转换为哈希值，符合GDPR等隐私法规要求
 * 
 * @param string $ip 原始IP地址
 * @param string $salt 盐值（应从环境变量读取）
 * @return array ['hash' => string, 'anonymized' => string]
 */
function anonymizeIP($ip, $salt = null) {
    if (empty($ip) || $ip === 'unknown') {
        return ['hash' => null, 'anonymized' => 'unknown'];
    }
    
    if ($salt === null) {
        $envFile = __DIR__ . '/../.env';
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
        $salt = $env['HMAC_SECRET_KEY'] ?? 'default_salt_2026';
    }
    
    $hash = substr(hash('sha256', $ip . '_' . $salt), 0, 16);
    
    $anonymized = $ip;
    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
        $parts = explode('.', $ip);
        $parts[3] = '0';
        $anonymized = implode('.', $parts);
    } elseif (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
        $parts = explode(':', $ip);
        $count = count($parts);
        if ($count >= 3) {
            $parts[$count - 1] = '0';
            $parts[$count - 2] = '0';
            $anonymized = implode(':', $parts);
        }
    }
    
    return ['hash' => $hash, 'anonymized' => $anonymized];
}
