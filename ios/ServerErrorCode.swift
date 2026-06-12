import Foundation

/// 服务端业务错误码（对应 deploy_package/*.php 返回的 JSON.code 字段）
/// 客户端根据 code 类型决定 UI 引导（订阅页、限流提示等）
enum ServerErrorCode: String {
    /// 需要订阅 Pro（设置密码 / 改过期 / 永久链接）
    case proRequired = "pro_required"
    /// 限流（速率 / 频次）
    case rateLimited = "rate_limited"
    /// 月度发布额度耗尽
    case publishLimitExceeded = "publish_limit_exceeded"
    /// 项目体积过大
    case projectTooLarge = "project_too_large"
    /// 权限拒绝（user_id 不匹配 / 未认证）
    case permissionDenied = "permission_denied"
    /// 项目不存在
    case projectNotFound = "project_not_found"
    /// HMAC 签名失败
    case invalidSignature = "invalid_signature"
    /// 时间戳超出允许窗口
    case timestampExpired = "timestamp_expired"
    /// 请求参数无效（字段缺失/格式错误）
    case invalidRequest = "invalid_request"
    /// 操作失败（服务端异常）
    case operationFailed = "operation_failed"
    /// 未知 / 业务码缺失
    case unknown

    static func from(json: [String: Any]) -> ServerErrorCode {
        if let codeStr = json["code"] as? String,
           let parsed = ServerErrorCode(rawValue: codeStr) {
            return parsed
        }
        return .unknown
    }

    static func from(response: URLResponse?, data: Data?) -> ServerErrorCode {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .unknown
        }
        return from(json: json)
    }
}

/// 错误码 → UI 引导动作
extension ServerErrorCode {
    var localizedMessage: String {
        switch self {
        case .proRequired:
            return "pro_required".localized
        case .rateLimited:
            return "request_too_frequent".localized
        case .publishLimitExceeded:
            return "publish_limit_reached".localized
        case .projectTooLarge:
            return "project_too_large".localized
        case .permissionDenied:
            return "permission_denied".localized
        case .projectNotFound:
            return "project_not_found".localized
        case .invalidSignature, .timestampExpired:
            return "client_outdated_update_required".localized
        case .invalidRequest:
            return "invalid_request".localized
        case .operationFailed:
            return "operation_failed".localized
        case .unknown:
            return "operation_failed".localized
        }
    }

    /// 是否应触发 paywall
    var triggersPaywall: Bool {
        self == .proRequired
    }

    /// 是否应触发 AppStore 升级（提示用户更新 App）
    var triggersAppUpdatePrompt: Bool {
        switch self {
        case .invalidSignature, .timestampExpired:
            return true
        default:
            return false
        }
    }
}
