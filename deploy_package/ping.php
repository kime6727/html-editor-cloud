<?php
/**
 * 健康检查端点 - 用于iOS客户端连通性测试
 * 无需认证，返回服务器状态
 */
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key, X-Timestamp, X-Signature');

echo json_encode([
    'status' => 'ok',
    'message' => 'Server is running',
    'timestamp' => date('Y-m-d H:i:s'),
    'server_time' => time(),
    'php_version' => phpversion()
]);
exit;
