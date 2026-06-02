import Foundation
import SwiftUI

@MainActor
class CloudService: ObservableObject {
    static let shared = CloudService()
    
    @Published var isPublishing = false
    @Published var lastPublishedUrl: String?
    @Published var error: String?
    @Published var lastPublishErrorType: PublishErrorType?
    @Published var lastPublishServerErrorCode: ServerErrorCode = .unknown
    
    private let apiUrl = AppConfig.publishEndpoint
    private let deleteUrl = AppConfig.apiBaseURL + "/delete.php"
    
    func deleteProject(_ cloudId: String, userId: String? = nil) async throws {
        var request = URLRequest(url: URL(string: deleteUrl)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        
        var body: [String: Any] = ["id": cloudId]
        if let userId = userId {
            body["user_id"] = userId
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func updateProjectExpiry(cloudId: String, userId: String, expireDays: Int? = nil, expireMinutes: Int? = nil, makePermanent: Bool = false, accessPassword: String? = nil, removePassword: Bool = false) async -> (success: Bool, expiresAt: String?, isPermanent: Bool, message: String) {
        let url = AppConfig.apiBaseURL + "/api/projects.php"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)

        // 计算 expires_at：优先用 expire_days/expireMinutes，否则传 makePermanent
        var expiresAtValue: Any?
        if makePermanent {
            // 永久：传 0，服务端会存为 null
            expiresAtValue = 0
        } else if let expireDays = expireDays, expireDays > 0 {
            expiresAtValue = Int(Date().timeIntervalSince1970) + expireDays * 86400
        } else if let expireMinutes = expireMinutes, expireMinutes > 0 {
            expiresAtValue = Int(Date().timeIntervalSince1970) + expireMinutes * 60
        } else {
            // 移除过期（永久移除）：传 NSNull 让 DB 存 null
            expiresAtValue = NSNull()
        }

        var body: [String: Any] = [
            "action": "set_expiry",
            "project_id": cloudId,
            "user_id": userId,
            "expires_at": expiresAtValue as Any
        ]
        if let password = accessPassword, !password.isEmpty {
            body["access_password"] = password
        }
        if removePassword {
            body["remove_password"] = true
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, nil, false, "network_error".localized)
            }

            if httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["success"] as? Bool == true {
                let expiresAt = json["expires_at"] as? String
                let isPermanent = json["is_permanent"] as? Bool ?? false
                let message = json["message"] as? String ?? "update_success".localized
                return (true, expiresAt, isPermanent, message)
            } else {
                let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                    ?? "update_failed".localized
                return (false, nil, false, msg)
            }
        } catch {
            return (false, nil, false, error.localizedDescription)
        }
    }

    func updateProjectExpiryWithRetry(cloudId: String, userId: String, expireDays: Int? = nil, expireMinutes: Int? = nil, makePermanent: Bool = false, accessPassword: String? = nil, removePassword: Bool = false) async throws -> (success: Bool, expiresAt: String?, isPermanent: Bool, message: String) {
        return try await NetworkRetryManager.shared.execute(
            policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        ) {
            await self.updateProjectExpiry(
                cloudId: cloudId,
                userId: userId,
                expireDays: expireDays,
                expireMinutes: expireMinutes,
                makePermanent: makePermanent,
                accessPassword: accessPassword,
                removePassword: removePassword
            )
        }
    }

    func setAccessPasswordWithRetry(cloudId: String, password: String) async throws -> Bool {
        return try await NetworkRetryManager.shared.execute(
            policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        ) {
            await self.setAccessPassword(cloudId: cloudId, password: password)
        }
    }

    func removeAccessPasswordWithRetry(cloudId: String) async throws -> Bool {
        return try await NetworkRetryManager.shared.execute(
            policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        ) {
            await self.removeAccessPassword(cloudId: cloudId)
        }
    }

    func unpublishProjectWithRetry(cloudId: String) async throws -> Bool {
        return try await NetworkRetryManager.shared.execute(
            policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        ) {
            await self.unpublishProject(cloudId: cloudId)
        }
    }

    // 透传到底层 CloudProjectManager（无 retry 版本仍可用）
    private func setAccessPassword(cloudId: String, password: String) async -> Bool {
        return await CloudProjectManager.shared.setAccessPassword(cloudId: cloudId, password: password)
    }
    private func removeAccessPassword(cloudId: String) async -> Bool {
        return await CloudProjectManager.shared.removeAccessPassword(cloudId: cloudId)
    }
    private func unpublishProject(cloudId: String) async -> Bool {
        return await CloudProjectManager.shared.unpublishProject(cloudId: cloudId)
    }
    private func setExpiryDate(cloudId: String, expiresAt: Date?) async -> Bool {
        return await CloudProjectManager.shared.setExpiryDate(cloudId: cloudId, expiresAt: expiresAt)
    }

    func setExpiryDateWithRetry(cloudId: String, expiresAt: Date?) async throws -> Bool {
        return try await NetworkRetryManager.shared.execute(
            policy: .exponentialBackoff(maxRetries: 3, baseDelay: 1.0)
        ) {
            await self.setExpiryDate(cloudId: cloudId, expiresAt: expiresAt)
        }
    }

    func publishProjectWithDetails(_ project: HTMLProject, config: PublishConfig = .default) async -> PublishResult? {
        // Verify Pro status before publishing to prevent stale cached state
        _ = await SubscriptionManager.shared.verifyProStatus()

        await MainActor.run {
            isPublishing = true
            error = nil
            lastPublishedUrl = nil
            lastPublishErrorType = nil
            lastPublishServerErrorCode = .unknown
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        body.append(formField(name: "name", value: project.name, boundary: boundary))
        
        body.append(formField(name: "user_id", value: UserManager.shared.userId, boundary: boundary))
        
        let isProUser = SubscriptionManager.shared.isPro
        body.append(formField(name: "is_pro", value: isProUser ? "1" : "0", boundary: boundary))
        
        if let cloudId = project.cloudId {
            body.append(formField(name: "id", value: cloudId, boundary: boundary))
        }
        
        if config.expireDays > 0 {
            body.append(formField(name: "expire_days", value: String(config.expireDays), boundary: boundary))
        } else if !isProUser {
            body.append(formField(name: "expire_minutes", value: "60", boundary: boundary))
        }
        
        let isUpdate = project.cloudId != nil
        body.append(formField(name: "is_update", value: isUpdate ? "1" : "0", boundary: boundary))
        
        if let password = config.accessPassword, !password.isEmpty {
            body.append(formField(name: "access_password", value: password, boundary: boundary))
        }
        body.append(formField(name: "enable_stats", value: config.enableStats ? "1" : "0", boundary: boundary))
        
        for file in project.files {
            let fileName = file.displayName
            
            if let binaryData = file.data {
                body.append(formFilePart(
                    fieldName: "files[]",
                    fileName: fileName,
                    mimeType: mimeType(for: fileName),
                    data: binaryData,
                    boundary: boundary
                ))
            } else if file.type.isEditable {
                body.append(formFilePart(
                    fieldName: "files[]",
                    fileName: fileName,
                    mimeType: "text/plain; charset=utf-8",
                    data: Data(file.content.utf8),
                    boundary: boundary
                ))
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run { 
                    error = "network_error".localized
                    isPublishing = false
                    lastPublishErrorType = .networkError
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            }
            
            switch httpResponse.statusCode {
            case 200:
                if let result = try? JSONDecoder().decode(PublishResponse.self, from: data),
                   result.status == "success",
                   let url = result.url,
                   let id = result.id {
                    await MainActor.run {
                        self.lastPublishedUrl = url
                        self.isPublishing = false
                    }
                    return PublishResult(
                        url: url,
                        id: id,
                        expiresAt: result.expiresAt,
                        hasPassword: result.hasPassword
                    )
                } else {
                    let decoded = try? JSONDecoder().decode(PublishResponse.self, from: data)
                    let msg = decoded?.message ?? "publish_failed".localized
                    let code: ServerErrorCode = decoded?.code.flatMap { ServerErrorCode(rawValue: $0) } ?? .unknown
                    await MainActor.run {
                        error = msg
                        isPublishing = false
                        lastPublishErrorType = .clientError(msg)
                        lastPublishServerErrorCode = code
                    }
                    return PublishResult(url: "", id: "", shouldClearCloudId: false)
                }
            case 400:
                let decoded = try? JSONDecoder().decode(PublishResponse.self, from: data)
                let msg = decoded?.message ?? "publish_bad_request".localized
                let code: ServerErrorCode = decoded?.code.flatMap { ServerErrorCode(rawValue: $0) } ?? .unknown
                await MainActor.run {
                    error = msg
                    isPublishing = false
                    lastPublishErrorType = .clientError(msg)
                    lastPublishServerErrorCode = code
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: true)
            case 403:
                let decoded = try? JSONDecoder().decode(PublishResponse.self, from: data)
                let code: ServerErrorCode = decoded?.code.flatMap { ServerErrorCode(rawValue: $0) } ?? .permissionDenied
                let msg = decoded?.message ?? "publish_auth_failed".localized
                await MainActor.run {
                    error = msg
                    isPublishing = false
                    lastPublishErrorType = .serverError
                    lastPublishServerErrorCode = code
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            case 413:
                await MainActor.run {
                    error = "project_too_large".localized
                    isPublishing = false
                    lastPublishErrorType = .clientError("project_too_large".localized)
                    lastPublishServerErrorCode = .projectTooLarge
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            case 429:
                await MainActor.run {
                    error = "request_too_frequent".localized
                    isPublishing = false
                    lastPublishErrorType = .serverError
                    lastPublishServerErrorCode = .rateLimited
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            case 500...599:
                await MainActor.run {
                    error = "publish_server_error".localized
                    isPublishing = false
                    lastPublishErrorType = .serverError
                    lastPublishServerErrorCode = .unknown
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            default:
                await MainActor.run { 
                    error = "publish_failed_code".localized + " \(httpResponse.statusCode)"
                    isPublishing = false
                    lastPublishErrorType = .serverError
                }
                return PublishResult(url: "", id: "", shouldClearCloudId: false)
            }
        } catch let urlError as URLError {
            await MainActor.run {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    self.error = "network_offline".localized
                case .timedOut:
                    self.error = "network_timeout".localized
                case .cannotFindHost, .cannotConnectToHost:
                    self.error = "network_host_unreachable".localized
                default:
                    self.error = urlError.localizedDescription
                }
                self.isPublishing = false
                self.lastPublishErrorType = .networkError
            }
            return PublishResult(url: "", id: "", shouldClearCloudId: false)
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isPublishing = false
                self.lastPublishErrorType = .networkError
            }
            return PublishResult(url: "", id: "", shouldClearCloudId: false)
        }
    }
    
    // MARK: - Fetch Detailed Stats
    func fetchDetailedStats(cloudId: String, userId: String, includeDetail: Bool = true) async -> DetailedStats? {
        guard var urlComponents = URLComponents(string: AppConfig.apiBaseURL + "/api/projects.php") else {
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "action", value: "stats"),
            URLQueryItem(name: "project_id", value: cloudId)
        ]
        
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        HMACAuth.applyHeaders(to: &request)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try? JSONDecoder().decode(DetailedStats.self, from: data)
        } catch {
        }
        
        return nil
    }
    
    // MARK: - Multipart Form Helpers
    
    private func formField(name: String, value: String, boundary: String) -> Data {
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
        return data
    }
    
    private func formFilePart(fieldName: String, fileName: String, mimeType: String, data fileData: Data, boundary: String) -> Data {
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        return data
    }
    
    private func mimeType(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return "text/html"
        case "css":         return "text/css"
        case "js":          return "application/javascript"
        case "json":        return "application/json"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "svg":         return "image/svg+xml"
        case "webp":        return "image/webp"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        default:            return "application/octet-stream"
        }
    }
}

struct PublishResult {
    let url: String
    let id: String
    let expiresAt: String?
    let shouldClearCloudId: Bool
    let hasPassword: Bool
    
    init(url: String, id: String, expiresAt: String? = nil, shouldClearCloudId: Bool = false, hasPassword: Bool = false) {
        self.url = url
        self.id = id
        self.expiresAt = expiresAt
        self.shouldClearCloudId = shouldClearCloudId
        self.hasPassword = hasPassword
    }
}

enum PublishErrorType {
    case networkError
    case serverError
    case clientError(String)
    case shouldClearCloudId
}

struct PublishResponse: Codable {
    let status: String
    let url: String?
    let id: String?
    let expiresAt: String?
    let message: String?
    let hasPassword: Bool
    let code: String?

    enum CodingKeys: String, CodingKey {
        case status, url, id, message, code
        case expiresAt = "expires_at"
        case hasPassword = "has_password"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        hasPassword = (try? container.decode(Bool.self, forKey: .hasPassword)) ?? false
        code = try? container.decodeIfPresent(String.self, forKey: .code)
    }
}

// MARK: - Detailed Stats Model
struct DetailedStats: Codable {
    let totalVisits: Int
    let todayVisits: Int?
    let uniqueVisitors: Int?
    let visitsByDay: [DailyVisit]
    let topReferrers: [TopReferrer]?
    let topCountries: [TopCountry]?
    
    struct DailyVisit: Codable {
        let date: String
        let count: Int
    }
    
    struct TopReferrer: Codable {
        let source: String
        let count: Int
    }
    
    struct TopCountry: Codable {
        let country: String
        let count: Int
    }
}
