import Foundation

struct PublishRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let projectId: UUID
    let projectName: String
    let url: String
    let method: PublishMethod
    let publishedAt: Date
    var visitCount: Int
    var lastVisitedAt: Date?
    var isActive: Bool
    
    enum PublishMethod: String, Codable {
        case local
        case cloud
        case _github_legacy = "github"  // kept for backward-compatible decoding only
        
        var displayName: String {
            switch self {
            case .local: return "Local Network"
            case .cloud: return "Cloud"
            case ._github_legacy: return "Cloud"
            }
        }
    }
}

@MainActor
class PublishHistoryManager: ObservableObject {
    static let shared = PublishHistoryManager()
    
    @Published private var records: [PublishRecord] = []
    
    private let saveKey = "publish_history_records"
    
    init() {
        loadRecords()
    }
    
    func addRecord(
        projectId: UUID,
        projectName: String,
        url: String,
        method: PublishRecord.PublishMethod,
        visitCount: Int = 0
    ) {
        let record = PublishRecord(
            id: UUID(),
            projectId: projectId,
            projectName: projectName,
            url: url,
            method: method,
            publishedAt: Date(),
            visitCount: visitCount,
            isActive: true
        )
        records.insert(record, at: 0)
        if records.count > 100 {
            records = Array(records.prefix(100))
        }
        saveRecords()
    }
    
    func getHistory(for projectId: UUID) -> [PublishRecord] {
        return records.filter { $0.projectId == projectId }
            .sorted { $0.publishedAt > $1.publishedAt }
    }
    
    func getAllHistory() -> [PublishRecord] {
        return records.sorted { $0.publishedAt > $1.publishedAt }
    }
    
    func incrementVisitCount(for recordId: UUID) {
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            records[index].visitCount += 1
            records[index].lastVisitedAt = Date()
            saveRecords()
        }
    }
    
    func deactivateRecord(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isActive = false
            saveRecords()
        }
    }
    
    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        saveRecords()
    }
    
    func clearHistory(for projectId: UUID) {
        records.removeAll { $0.projectId == projectId }
        saveRecords()
    }
    
    func clearAllHistory() {
        records.removeAll()
        saveRecords()
    }
    
    var totalPublishCount: Int {
        records.count
    }
    
    var totalVisitCount: Int {
        records.reduce(0) { $0 + $1.visitCount }
    }
    
    // MARK: - Persistence
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([PublishRecord].self, from: data) {
            records = decoded.filter { $0.method != ._github_legacy }
        }
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
