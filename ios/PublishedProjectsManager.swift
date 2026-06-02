import Foundation
import SwiftUI
import Combine

@MainActor
class PublishedProjectsManager: ObservableObject {
    static let shared = PublishedProjectsManager()

    @Published private(set) var publishedProjects: [PublishedProjectInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let cloudManager: CloudProjectManager
    private var cancellables = Set<AnyCancellable>()
    private weak var documentManager: DocumentManager?

    private init(cloudManager: CloudProjectManager = .shared) {
        self.cloudManager = cloudManager

        // 单一数据源：监听 CloudProjectManager 的变化自动刷新
        cloudManager.$publishedProjects
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildFromCloud()
            }
            .store(in: &cancellables)

        cloudManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        cloudManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }

    /// 绑定 DocumentManager，用于合并本地缩略图/文件数等本地专属字段
    func attach(documentManager: DocumentManager) {
        self.documentManager = documentManager
        rebuildFromCloud()
    }

    struct PublishedProjectInfo: Identifiable, Codable, Equatable {
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
    }

    var activeProjects: [PublishedProjectInfo] {
        publishedProjects.filter { !$0.isExpired }
    }

    var expiredProjects: [PublishedProjectInfo] {
        publishedProjects.filter { $0.isExpired }
    }

    /// 触发网络拉取（委托给 CloudProjectManager）
    func syncFromDocumentManager(_ documentManager: DocumentManager) {
        self.documentManager = documentManager
        Task { await cloudManager.loadPublishedProjects() }
    }

    /// 发布成功后通知刷新（由发布流程调用）
    func addOrUpdate(project: HTMLProject, result: PublishResult) {
        // 发布成功后让服务器作为唯一权威，触发一次重新拉取即可
        Task { await cloudManager.loadPublishedProjects() }
    }

    /// 移除（委托 CloudProjectManager.unpublishProject）
    func removeProject(cloudId: String) {
        Task {
            _ = await cloudManager.unpublishProject(cloudId: cloudId)
            await cloudManager.loadPublishedProjects()
        }
    }

    /// 更新访问计数（直接修改内存中的投影）
    func updateVisitCount(cloudId: String, count: Int) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            publishedProjects[index].visitCount = count
        }
    }

    /// 同步过期时间（从服务器返回后回写到本地）
    func updateExpiryFromServer(cloudId: String, expiresAt: String?, isPermanent: Bool) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            if let expiresAt = expiresAt {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                publishedProjects[index].expiresAt = formatter.date(from: expiresAt)
            } else {
                publishedProjects[index].expiresAt = nil
            }
        }
    }

    /// 同步密码状态
    func updatePasswordStatus(cloudId: String, hasPassword: Bool) {
        if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
            publishedProjects[index].hasPassword = hasPassword
        }
    }

    /// 拉取单个项目的统计数据
    func fetchStats(for cloudId: String) async -> (visitCount: Int, isExpired: Bool)? {
        let urlString = AppConfig.apiBaseURL + "/stats.php?id=" + cloudId
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        HMACAuth.applyHeaders(to: &request)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let visitCount = json["visit_count"] as? Int ?? 0
                let isExpired = json["is_expired"] as? Bool ?? false
                let expiresAtStr = json["expires_at"] as? String

                updateVisitCount(cloudId: cloudId, count: visitCount)

                if let expiresAtStr = expiresAtStr {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let expiresDate = formatter.date(from: expiresAtStr)
                    if let index = publishedProjects.firstIndex(where: { $0.cloudId == cloudId }) {
                        publishedProjects[index].expiresAt = expiresDate
                    }
                }
                return (visitCount, isExpired)
            }
        } catch {
        }
        return nil
    }

    /// 批量拉取所有项目的统计
    func fetchAllStats() async {
        for project in publishedProjects {
            _ = await fetchStats(for: project.cloudId)
        }
    }

    /// 同步删除：先服务端删除，成功后再清理本地投影
    func deleteFromCloud(projectId: String, cloudId: String) async -> Bool {
        let success = await cloudManager.unpublishProject(cloudId: cloudId)
        if success {
            NotificationCenter.default.post(
                name: .projectCloudIdCleared,
                object: nil,
                userInfo: ["cloudId": cloudId]
            )
        }
        return success
    }

    // MARK: - Private

    /// 重建本地投影（合并 CloudProjectManager 数据与 DocumentManager 本地字段）
    private func rebuildFromCloud() {
        let cloudProjects = cloudManager.publishedProjects
        let localProjects = documentManager?.projects ?? []

        publishedProjects = cloudProjects.map { cp in
            let local = localProjects.first { $0.id.uuidString == cp.projectId }
            return PublishedProjectInfo(
                id: local?.id ?? UUID(uuidString: cp.projectId) ?? UUID(),
                projectName: cp.projectName,
                cloudUrl: cp.url,
                cloudId: cp.id,
                publishedAt: cp.publishedAt,
                updatedAt: cp.publishedAt,
                expiresAt: cp.expiresAt,
                visitCount: cp.visitCount,
                fileCount: local?.files.count ?? 1,
                thumbnailData: local?.thumbnailData,
                hasPassword: cp.hasPassword
            )
        }
    }
}
