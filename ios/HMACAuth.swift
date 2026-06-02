import Foundation
import CryptoKit

/// HMAC-SHA256 签名工具单例
/// 集中所有后端 API 鉴权用的 HMAC 签名逻辑
enum HMACAuth {
    /// 生成 (timestamp, signature) 元组
    /// - Parameters:
    ///   - apiKey: API Key (AppConfig.apiKey)
    ///   - secret: HMAC 密钥 (AppConfig.hmacSecretKey 或 fallback 到 apiKey)
    ///   - timestamp: 时间戳字符串，nil 时使用当前时间
    static func generate(apiKey: String, secret: String? = nil, timestamp: String? = nil) -> (timestamp: String, signature: String) {
        let ts = timestamp ?? String(Int(Date().timeIntervalSince1970))
        let effectiveSecret = (secret?.isEmpty == false) ? secret! : apiKey
        let message = apiKey + ts
        let sig = HMAC<SHA256>.authenticationCode(
            for: Data(message.utf8),
            using: SymmetricKey(data: Data(effectiveSecret.utf8))
        ).map { String(format: "%02x", $0) }.joined()
        return (ts, sig)
    }

    /// 应用所有标准鉴权头到 URLRequest
    static func applyHeaders(to request: inout URLRequest) {
        let ts = String(Int(Date().timeIntervalSince1970))
        let (timestamp, signature) = generate(
            apiKey: AppConfig.apiKey,
            secret: AppConfig.hmacSecretKey,
            timestamp: ts
        )
        request.setValue(AppConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
    }
}
