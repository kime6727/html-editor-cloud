import Foundation

@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userId: String
    
    private let userIdKey = "user_id_v1"
    
    private init() {
        if let existingId = UserDefaults.standard.string(forKey: userIdKey) {
            self.userId = existingId
        } else {
            self.userId = UserManager.generateUserId()
            UserDefaults.standard.set(self.userId, forKey: userIdKey)
        }
    }
    
    private static func generateUserId() -> String {
        let prefix = "usr"
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16)
        let random = String(Int.random(in: 1000...9999))
        return "\(prefix)_\(uuid)_\(random)"
    }
    
    func resetUserId() {
        let newId = UserManager.generateUserId()
        self.userId = newId
        UserDefaults.standard.set(newId, forKey: userIdKey)
    }
}
