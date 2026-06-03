import Foundation
import SwiftUI

struct CloudPublishedProject: Identifiable, Codable, Equatable {
    let id: String
    let projectId: String
    let projectName: String
    let url: String
    var isActive: Bool
    var visitCount: Int
    var uniqueVisitors: Int
    var todayVisits: Int
    var publishedAt: Date
    var expiresAt: Date?
    var lastVisitedAt: Date?
    var accessPassword: String?
    var hasPassword: Bool
    
    static func == (lhs: CloudPublishedProject, rhs: CloudPublishedProject) -> Bool {
        lhs.id == rhs.id
    }
}

struct VisitLog: Codable, Identifiable {
    let id: Int
    let ip: String
    let device: String
    let deviceIcon: String
    let referer: String
    let source: String
    let visitedAt: String
}

struct VisitLogsResponse: Codable {
    let success: Bool
    let total: Int
    let page: Int
    let limit: Int
    let totalPages: Int
    let logs: [VisitLog]
}


enum RedirectType: String, Codable {
    case appPromotion = "app_promotion"
    case customUrl = "custom_url"
    case customMessage = "custom_message"
}

@MainActor
class CloudProjectManager: ObservableObject {
    static let shared = CloudProjectManager()
    
    @Published var publishedProjects: [CloudPublishedProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBaseURL = AppConfig.publishAPIBaseURL
    
    init() {
        Task { await loadPublishedProjects() }
    }
    
    // MARK: - HMAC Authentication
    private func applyAuthHeaders(to request: inout URLRequest) {
        HMACAuth.applyHeaders(to: &request)
    }
    
    // MARK: - Load Published Projects
    func loadPublishedProjects() async {
        isLoading = true
        defer { isLoading = false }

        // 在主 actor 上获取 userId 一次，避免在 @Sendable 闭包内访问 main-actor isolated 属性
        let userId = await MainActor.run { UserManager.shared.userId }

        do {
            let data = try await NetworkRetryManager.shared.execute(
                policy: .exponentialBackoff(maxRetries: 3, baseDelay: 0.8)
            ) { [apiBaseURL] in
                var comps = URLComponents(string: "\(apiBaseURL)/api/projects.php")!
                comps.queryItems = [
                    URLQueryItem(name: "action", value: "list"),
                    URLQueryItem(name: "user_id", value: userId)
                ]
                var request = URLRequest(url: comps.url!)
                HMACAuth.applyHeaders(to: &request)
                request.timeoutInterval = 8
                let (data, _) = try await URLSession.shared.data(for: request)
                return data
            }

            if let response = try? JSONDecoder().decode(CloudListResponse.self, from: data) {
                if response.success {
                    publishedProjects = response.projects.map { pub in
                        CloudPublishedProject(
                            id: pub.id,
                            projectId: pub.projectId,
                            projectName: pub.projectName,
                            url: pub.url,
                            isActive: pub.isActive,
                            visitCount: pub.visitCount,
                            uniqueVisitors: pub.uniqueVisitors,
                            todayVisits: pub.todayVisits,
                            publishedAt: Date(timeIntervalSince1970: pub.publishedAt),
                            expiresAt: pub.expiresAt.map { Date(timeIntervalSince1970: $0) },
                            lastVisitedAt: pub.lastVisitedAt.map { Date(timeIntervalSince1970: $0) },
                            accessPassword: nil,
                            hasPassword: pub.hasPassword
                        )
                    }
                    errorMessage = nil
                } else {
                    errorMessage = response.message
                }
            }
        } catch NetworkRetryManager.NetworkError.noInternet {
            errorMessage = "network_offline".localized
        } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
            errorMessage = "network_unstable_retry_failed".localized
        } catch {
            errorMessage = String(format: "load_failed".localized, error.localizedDescription)
        }
    }
    
    // MARK: - Toggle Project Status
    func toggleProjectStatus(cloudId: String, isActive: Bool) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "toggle_status",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId,
            "is_active": isActive
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Unpublish Project
    func unpublishProject(cloudId: String) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "unpublish",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                if response.success {
                    publishedProjects.removeAll { $0.id == cloudId }
                }
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Set Access Password
    func setAccessPassword(cloudId: String, password: String) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "set_password",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                if response.success {
                    if let index = publishedProjects.firstIndex(where: { $0.id == cloudId }) {
                        publishedProjects[index].accessPassword = password
                        publishedProjects[index].hasPassword = true
                    }
                }
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Remove Access Password
    func removeAccessPassword(cloudId: String) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "remove_password",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                if response.success {
                    if let index = publishedProjects.firstIndex(where: { $0.id == cloudId }) {
                        publishedProjects[index].accessPassword = nil
                        publishedProjects[index].hasPassword = false
                    }
                }
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Set Expiry Date
    func setExpiryDate(cloudId: String, expiresAt: Date?) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        var body: [String: Any] = [
            "action": "set_expiry",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId
        ]
        
        if let expiresAt = expiresAt {
            body["expires_at"] = expiresAt.timeIntervalSince1970
        } else {
            body["expires_at"] = NSNull()
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                if response.success {
                    if let index = publishedProjects.firstIndex(where: { $0.id == cloudId }) {
                        publishedProjects[index].expiresAt = expiresAt
                    }
                }
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Update Content
    func updateProjectContent(projectId: String, content: String) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "update_content",
            "project_id": projectId,
            "user_id": UserManager.shared.userId,
            "content": content
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Set Expired Redirect URL
    func setExpiredRedirect(cloudId: String, redirectType: RedirectType, redirectUrl: String? = nil, customMessage: String? = nil) async -> Bool {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        var body: [String: Any] = [
            "action": "set_redirect_url",
            "project_id": cloudId,
            "user_id": UserManager.shared.userId,
            "redirect_type": redirectType.rawValue
        ]
        
        if let redirectUrl = redirectUrl {
            body["redirect_url"] = redirectUrl
        }
        
        if let customMessage = customMessage {
            body["custom_message"] = customMessage
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try? JSONDecoder().decode(CloudActionResponse.self, from: data) {
                return response.success
            }
        } catch {}
        
        return false
    }
    
    // MARK: - Get Visit Logs
    func getVisitLogs(cloudId: String, page: Int = 1, limit: Int = 50, startDate: String? = nil, endDate: String? = nil) async -> VisitLogsResponse? {
        guard var urlComponents = URLComponents(string: "\(apiBaseURL)/api/projects.php") else {
            return nil
        }
        
        var queryItems = [
            URLQueryItem(name: "action", value: "get_visit_logs"),
            URLQueryItem(name: "project_id", value: cloudId),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "user_id", value: UserManager.shared.userId)
        ]
        
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: startDate))
        }
        
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: endDate))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else { return nil }
        
        var request = URLRequest(url: url)
        applyAuthHeaders(to: &request)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try? JSONDecoder().decode(VisitLogsResponse.self, from: data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Batch Operation
    func batchOperation(operation: String, projectIds: [String], params: [String: Any] = [:]) async -> (success: Bool, successCount: Int, failCount: Int) {
        var request = URLRequest(url: URL(string: "\(apiBaseURL)/api/projects.php")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuthHeaders(to: &request)
        
        let body: [String: Any] = [
            "action": "batch_operation",
            "operation": operation,
            "user_id": UserManager.shared.userId,
            "project_ids": projectIds,
            "params": params
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let successCount = json["successCount"] as? Int,
               let failCount = json["failCount"] as? Int {
                return (success, successCount, failCount)
            }
        } catch {}
        
        return (false, 0, 0)
    }
}

// MARK: - Response Models
struct CloudListResponse: Codable {
    let success: Bool
    let message: String
    let projects: [CloudProjectInfo]
    
    struct CloudProjectInfo: Codable {
        let id: String
        let projectId: String
        let projectName: String
        let url: String
        let isActive: Bool
        let visitCount: Int
        let uniqueVisitors: Int
        let todayVisits: Int
        let publishedAt: TimeInterval
        let expiresAt: TimeInterval?
        let lastVisitedAt: TimeInterval?
        let hasPassword: Bool
    }
}

struct CloudActionResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Redirect Settings View
struct RedirectSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var cloudManager = CloudProjectManager.shared
    
    let cloudId: String
    @Binding var isPresented: Bool
    
    @State private var selectedType: RedirectType = .appPromotion
    @State private var customUrl = ""
    @State private var customMessage = ""
    @State private var isUpdating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("expired_redirect_type".localized), footer: Text("expired_redirect_hint".localized)) {
                    Picker("redirect_type".localized, selection: $selectedType) {
                        Label("app_promotion_page".localized, systemImage: "app.badge.fill")
                            .tag(RedirectType.appPromotion)
                        Label("custom_url_redirect".localized, systemImage: "link")
                            .tag(RedirectType.customUrl)
                        Label("custom_message".localized, systemImage: "text.bubble.fill")
                            .tag(RedirectType.customMessage)
                    }
                    .pickerStyle(.inline)
                }
                
                if selectedType == .customUrl {
                    Section(header: Text("custom_redirect_url".localized), footer: Text("custom_url_hint".localized)) {
                        TextField("https://example.com", text: $customUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                }
                
                if selectedType == .customMessage {
                    Section(header: Text("custom_message".localized), footer: Text("custom_message_hint".localized)) {
                        TextEditor(text: $customMessage)
                            .frame(minHeight: 100)
                    }
                }
                
                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            if isUpdating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("save".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isUpdating || !canSave)
                }
            }
            .navigationTitle("expired_redirect".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
    }
    
    private var canSave: Bool {
        if selectedType == .customUrl {
            return URL(string: customUrl) != nil
        }
        if selectedType == .customMessage {
            return !customMessage.isEmpty
        }
        return true
    }
    
    private func saveSettings() {
        isUpdating = true
        Task {
            let url = selectedType == .customUrl ? customUrl : nil
            let message = selectedType == .customMessage ? customMessage : nil
            
            let success = await cloudManager.setExpiredRedirect(
                cloudId: cloudId,
                redirectType: selectedType,
                redirectUrl: url,
                customMessage: message
            )
            
            await MainActor.run {
                isUpdating = false
                if success {
                    documentManager.toastItem = ToastItem(
                        message: "update_success".localized,
                        type: .success
                    )
                    dismiss()
                } else {
                    documentManager.toastItem = ToastItem(
                        message: "update_failed".localized,
                        type: .error
                    )
                }
            }
        }
    }
}

// MARK: - Visit Logs View
struct VisitLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cloudManager = CloudProjectManager.shared
    
    let cloudId: String
    let projectName: String
    
    @State private var logs: [VisitLog] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var totalLogs = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading && logs.isEmpty {
                    ProgressView("loading".localized)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logs.isEmpty {
                    emptyState
                } else {
                    logsList
                }
            }
            .navigationTitle("visit_logs".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                }
            }
            .task {
                await loadLogs()
            }
        }
    }
    
    private var logsList: some View {
        VStack(spacing: 0) {
            List(logs) { log in
                VisitLogRow(log: log)
            }
            .listStyle(.plain)
            
            if totalPages > 1 {
                paginationBar
            }
        }
    }
    
    private var paginationBar: some View {
        HStack {
            Button(action: {
                if currentPage > 1 {
                    currentPage -= 1
                    Task { await loadLogs() }
                }
            }) {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage <= 1)
            
            Text("page_format".localizedWithFormat(currentPage, totalPages))
                .font(.caption)
            
            Button(action: {
                if currentPage < totalPages {
                    currentPage += 1
                    Task { await loadLogs() }
                }
            }) {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage >= totalPages)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("no_visit_logs".localized)
                .font(.title3.bold())
            
            Text("no_visit_logs_hint".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadLogs() async {
        isLoading = true
        if let response = await cloudManager.getVisitLogs(cloudId: cloudId, page: currentPage, limit: 50) {
            logs = response.logs
            totalPages = response.totalPages
            totalLogs = response.total
        }
        isLoading = false
    }
}

struct VisitLogRow: View {
    let log: VisitLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: deviceIcon)
                    .foregroundColor(.blue)
                
                Text(log.ip)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(log.visitedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "arrowshape.turn.up.left")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                Text(log.source)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var deviceIcon: String {
        switch log.deviceIcon {
        case "mobile":
            return "iphone"
        case "tablet":
            return "ipad"
        default:
            return "desktopcomputer"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .short
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateString
    }
}

// MARK: - Link Preview View
struct LinkPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let projectUrl: String
    let projectName: String
    let hasPassword: Bool
    let accessPassword: String?
    
    @State private var qrImage: UIImage?
    @State private var showShareSheet = false
    
    var currentUrl: String {
        projectUrl
    }
    
    var shareableUrl: String {
        if hasPassword, let pwd = accessPassword {
            return "\(currentUrl)?pwd=\(pwd)"
        }
        return currentUrl
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    previewHeader
                    
                    qrCodeSection
                    
                    linkInfoCard
                    
                    previewActions
                    
                    sharePreviewSection
                }
                .padding()
            }
            .navigationTitle("link_preview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [shareableUrl, projectName])
            }
            .onAppear {
                generateQRCode()
            }
        }
    }
    
    private var previewHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(projectName)
                .font(.title2.bold())
            
            Text("link_preview_hint".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            
            Text("cloud_qr_hint".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var linkInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("link_info".localized, systemImage: "info.circle.fill")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                    Text(currentUrl)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                if hasPassword {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        Text("password_protected".localized)
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var previewActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    UIPasteboard.general.string = shareableUrl
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("copy_link".localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("share".localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                if let url = URL(string: currentUrl) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "safari")
                    Text("open_in_browser".localized)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    private var sharePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("share_preview".localized, systemImage: "photo.on.rectangle.angled")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text("share_preview_hint".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    mockDeviceView(device: "iphone", label: "Mobile")
                    mockDeviceView(device: "ipad", label: "Tablet")
                    mockDeviceView(device: "desktopcomputer", label: "Desktop")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func mockDeviceView(device: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: device)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func generateQRCode() {
        guard let data = shareableUrl.data(using: .utf8) else { return }
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")
            
            if let output = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = output.transformed(by: transform)
                
                if let cgImage = CIContext().createCGImage(scaledImage, from: scaledImage.extent) {
                    qrImage = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}
