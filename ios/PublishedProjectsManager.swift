import Foundation
import SwiftUI
import CryptoKit

@MainActor
class PublishedProjectsManager: ObservableObject {
    static let shared = PublishedProjectsManager()
    
    @Published var publishedProjects: [PublishedProjectInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "published_projects_cache"
    
    private init() {
        loadFromDisk()
    }
    
    struct PublishedProjectInfo: Identifiable, Codable {
        let id: UUID
        var projectName: String
        var cloudUrl: String
        var cloudId: String
        var publishedAt: Date
        var updatedAt: Date
        var expiresAt: Date?
        var visitCount: Int
        var fileCount: Int
        var thumbnailData: Data?
        var hasPassword: Bool
        
        var displayUrl: String {
            cloudUrl
        }
        
        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() > expiresAt
        }
        
        var expiresInDays: Int? {
            guard let expiresAt = expiresAt else { return nil }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
            return days
        }
        
        static func == (lhs: PublishedProjectInfo, rhs: PublishedProjectInfo) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var activeProjects: [PublishedProjectInfo] {
        publishedProjects.filter { !$0.isExpired }
    }
    
    var expiredProjects: [PublishedProjectInfo] {
        publishedProjects.filter { $0.isExpired }
    }
    
    func syncFromDocumentManager(_ documentManager: DocumentManager) {
        let cloudProjects = documentManager.projects.filter { $0.cloudUrl != nil }
        let existingProjectIds = Set(documentManager.projects.map { $0.id })
        
        // 清理：移除本地已删除项目对应的记录（这些记录的云端项目也不复存在）
        // 但保留那些本地项目已删除但云端仍然存在的历史记录（用户可能重新发布）
        publishedProjects.removeAll { pub in
            !existingProjectIds.contains(pub.id) && pub.cloudUrl.isEmpty
        }
        
        for project in cloudProjects {
            if let index = publishedProjects.firstIndex(where: { $0.cloudId == project.cloudId }) {
                var updated = publishedProjects[index]
                updated.projectName = project.name
                updated.cloudUrl = project.cloudUrl ?? updated.cloudUrl
                updated.visitCount = project.visitCount ?? updated.visitCount
                updated.fileCount = project.files.count
                updated.updatedAt = project.updatedAt
                publishedProjects[index] = updated
            } else {
                let newInfo = PublishedProjectInfo(
                    id: project.id,
                    projectName: project.name,
                    cloudUrl: project.cloudUrl ?? "",
                    cloudId: project.cloudId ?? "",
                    publishedAt: project.updatedAt,
                    updatedAt: project.updatedAt,
                    expiresAt: project.expiresAt,
                    visitCount: project.visitCount ?? 0,
                    fileCount: project.files.count,
                    thumbnailData: project.thumbnailData,
                    hasPassword: project.hasPassword
                )
                publishedProjects.append(newInfo)
            }
        }
        
        publishedProjects.sort { $0.updatedAt > $1.updatedAt }
        saveToDisk()
    }
    
    func addOrUpdate(project: HTMLProject, result: PublishResult) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let expiresAtDate = result.expiresAt != nil ? formatter.date(from: result.expiresAt!) : nil
        
        let info = PublishedProjectInfo(
            id: project.id,
            projectName: project.name,
            cloudUrl: result.url,
            cloudId: result.id,
            publishedAt: Date(),
            updatedAt: Date(),
            expiresAt: expiresAtDate,
            visitCount: 0,
            fileCount: project.files.count,
            thumbnailData: project.thumbnailData,
            hasPassword: result.hasPassword
        )
        
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == result.id }) {
            publishedProjects[index] = info
        } else {
            publishedProjects.insert(info, at: 0)
        }
        
        saveToDisk()
    }
    
    func removeProject(cloudId: String) {
        publishedProjects.removeAll { $0.cloudId == cloudId }
        saveToDisk()
    }
    
    func updateVisitCount(cloudId: String, count: Int) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            publishedProjects[index].visitCount = count
            saveToDisk()
        }
    }
    
    func updateExpiryFromServer(cloudId: String, expiresAt: String?, isPermanent: Bool) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            if let expiresAt = expiresAt {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                publishedProjects[index].expiresAt = formatter.date(from: expiresAt)
            } else {
                publishedProjects[index].expiresAt = nil
            }
            saveToDisk()
        }
    }
    
    func updatePasswordStatus(cloudId: String, hasPassword: Bool) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            publishedProjects[index].hasPassword = hasPassword
            saveToDisk()
        }
    }
    
    func fetchStats(for cloudId: String) async -> (visitCount: Int, isExpired: Bool)? {
        let urlString = AppConfig.apiBaseURL + "/stats.php?id=" + cloudId
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // 发送 HMAC 头（与服务端其他接口保持一致）
        let apiKey = AppConfig.apiKey
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let secret = AppConfig.hmacSecretKey.isEmpty ? apiKey : AppConfig.hmacSecretKey
        let message = apiKey + timestamp
        let signature = HMACService.sha256(message: message, key: secret)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let visitCount = json["visit_count"] as? Int ?? 0
                let isExpired = json["is_expired"] as? Bool ?? false
                let expiresAtStr = json["expires_at"] as? String

                await MainActor.run {
                    updateVisitCount(cloudId: cloudId, count: visitCount)

                    if let expiresAtStr = expiresAtStr {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let expiresDate = formatter.date(from: expiresAtStr)

                        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
                            publishedProjects[index].expiresAt = expiresDate
                        }
                    }
                }
                return (visitCount, isExpired)
            }
        } catch {
        }
        return nil
    }
    
    func fetchAllStats() async {
        for project in publishedProjects {
            _ = await fetchStats(for: project.cloudId)
        }
    }
    
    func deleteFromCloud(projectId: String, cloudId: String) async -> Bool {
        // Try to delete from cloud
        let cs = CloudService.shared
        var cloudDeleteSuccess = true
        do {
            try await cs.deleteProject(cloudId, userId: UserManager.shared.userId)
        } catch {
            cloudDeleteSuccess = false
            print("Failed to delete cloud project: \(error)")
        }

        // Only remove from local list if cloud deletion succeeded or project doesn't exist on server
        if cloudDeleteSuccess {
            // Remove from published list
            publishedProjects.removeAll { $0.cloudId == cloudId }
            saveToDisk()

            // Notify DocumentManager to clear cloud info for the corresponding project
            NotificationCenter.default.post(
                name: .projectCloudIdCleared,
                object: nil,
                userInfo: ["cloudId": cloudId]
            )
        }

        return cloudDeleteSuccess
    }
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(publishedProjects) {
            userDefaults.set(data, forKey: storageKey)
        }
    }
    
    private func loadFromDisk() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PublishedProjectInfo].self, from: data) else {
            return
        }
        publishedProjects = decoded
    }
}
