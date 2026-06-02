#!/bin/bash

# 测试发布API
API_KEY="zheshimiyao112233"
HMAC_SECRET="zheshimiyao112233"
BASE_URL="https://html.niceapp.eu.cc"
TIMESTAMP=$(date +%s)

# 生成HMAC签名
SIGNATURE=$(php -r "echo hash_hmac('sha256', '${API_KEY}${TIMESTAMP}', '${HMAC_SECRET}');")

echo "====================================="
echo "测试发布API连接"
echo "====================================="
echo "API Key: ${API_KEY}"
echo "Timestamp: ${TIMESTAMP}"
echo "Signature: ${SIGNATURE}"
echo "====================================="

# 创建测试HTML文件
echo '<html><body><h1>Test</h1></body></html>' > /tmp/test_publish.html

# 测试发布API
echo ""
echo "测试: 发布API完整测试"
echo "-------------------------------------"
curl -s -X POST "${BASE_URL}/publish.php" \
  -H "X-API-Key: ${API_KEY}" \
  -H "X-Timestamp: ${TIMESTAMP}" \
  -H "X-Signature: ${SIGNATURE}" \
  -F "name=TestProject" \
  -F "is_pro=0" \
  -F "expire_minutes=5" \
  -F "is_update=0" \
  -F "files[]=@/tmp/test_publish.html;filename=index.html;type=text/html"

echo ""
echo "====================================="
echo "测试完成"
echo "====================================="

# 清理临时文件
rm -f /tmp/test_publish.html
