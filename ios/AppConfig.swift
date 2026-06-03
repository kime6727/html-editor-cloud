import Foundation

enum AppConfig {
    // MARK: - API & Backend
    // 生产环境：使用远程服务器
    static let apiBaseURL = "https://html.niceapp.eu.cc"
    static let publishAPIBaseURL = "https://html.niceapp.eu.cc"
    static let publishEndpoint = apiBaseURL + "/publish.php"
    static let webAppURL = "https://html.niceapp.eu.cc/"
    
    // 开发环境：使用本地服务器
    // static let apiBaseURL = "http://localhost:8080/backend"
    // static let publishAPIBaseURL = "http://localhost:8080"
    // static let publishEndpoint = apiBaseURL + "/publish.php"
    // static let webAppURL = "http://localhost:8080/"

    // MARK: - StoreKit
    static let productID = "CodeEditor_999"
    static let appStoreID = "6764022927"

    // MARK: - Limits
    static let freeProjectLimit = 5
    static let freePublishLimit = 3

    // MARK: - Legal & Support
    static let userAgreementURL = "https://page.niceapp.eu.cc/index.php/archives/User-Service-Agreement.html"
    static let privacyPolicyURL = "https://page.niceapp.eu.cc/index.php/archives/Privacy-Policy.html"
    static let onlineServiceURL = "https://page.niceapp.eu.cc/index.php/archives/13.html"
    static let supportEmail = "fengezhao@hotmail.com"
    /// App 官方介绍页（用于 Profile / Onboarding 中"了解更多"）
    static let officialWebsiteURL = "https://page.niceapp.eu.cc/apps/code_editor"

    // MARK: - App Store
    static var appStoreReviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    // MARK: - Computed URLs
    static var writeReviewURL: URL? {
        appStoreReviewURL
    }

    // MARK: - API Key (从 Info.plist 读取，生产环境应使用更安全的方式)
    static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CE_API_KEY") as? String ?? ""
    }
    
    // MARK: - HMAC Secret Key (用于签名验证)
    static var hmacSecretKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CE_HMAC_SECRET_KEY") as? String ?? ""
    }
}
