import SwiftUI
import Network

struct PublishHubView: View {
    let project: HTMLProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var server = LocalHTMLServer()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var cloudService = CloudService.shared
    @StateObject private var publishHistory = PublishHistoryManager.shared
    
    @State private var selectedPublishMethod: PublishMethod?
    @State private var showPublishConfig = false
    @State private var showPublishResult = false
    @State private var publishingUrl = ""
    @State private var publishResult: PublishResult?
    @State private var isPublishing = false
    @State private var publishProgress: Double = 0
    @State private var publishProgressText = ""
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var showQRCode = false
    @State private var qrURL = ""
    @State private var showExportZip = false
    @State private var exportSuccess = false
    @State private var networkStatus = NetworkMonitor.shared
    @State private var showPublishedProjects = false
    
    private var liveProject: HTMLProject {
        documentManager.projects.first(where: { $0.id == project.id }) ?? project
    }
    
    enum PublishMethod: String, CaseIterable {
        case localNetwork = "local_network"
        case cloud = "cloud_publish"
        
        var title: String {
            switch self {
            case .localNetwork: return "publish_local".localized
            case .cloud: return "publish_cloud".localized
            }
        }
        
        var subtitle: String {
            switch self {
            case .localNetwork: return "publish_local_desc".localized
            case .cloud: return "publish_cloud_desc".localized
            }
        }
        
        var icon: String {
            switch self {
            case .localNetwork: return "wifi"
            case .cloud: return "icloud.and.arrow.up"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .localNetwork: return .green
            case .cloud: return .blue
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Project Info Card
                    projectInfoCard
                    
                    // Publishing Methods
                    publishingMethods
                    
                    // Quick Actions
                    quickActions
                    
                    // Published Links
                    if !publishHistory.getHistory(for: project.id).isEmpty {
                        publishedLinksSection
                    }
                }
                .padding()
            }
            .navigationTitle("publish_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
            .sheet(isPresented: $showPublishConfig) {
                PublishConfigView(project: liveProject, isPresented: $showPublishConfig) { config in
                    performPublish(config: config)
                }
                .environmentObject(documentManager)
            }
            .sheet(isPresented: $showPublishResult) {
                if let result = publishResult {
                    EnhancedPublishResultView(
                        project: project,
                        result: result,
                        isPresented: $showPublishResult
                    )
                    .environmentObject(documentManager)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ActivityViewController(activityItems: [url])
                }
            }
            .fullScreenCover(isPresented: $showQRCode) {
                QRCodeFullScreenView(url: qrURL, isPresented: $showQRCode)
            }
            .sheet(isPresented: $showPublishedProjects) {
                PublishedProjectsListView()
                    .environmentObject(documentManager)
            }
            .toast($documentManager.toastItem)
            .onDisappear {
                if server.isRunning {
                    server.stopServer()
                }
            }
        }
    }
    
    // MARK: - Project Info Card
    private var projectInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "doc.text.image")
                    .font(.title2)
                    .foregroundColor(Color("Color"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(liveProject.name)
                        .font(.headline)
                    Text(String(format: "project_files_count".localized, liveProject.files.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Cloud status badge
                if liveProject.cloudUrl != nil {
                    Label(safeLocalize("published_status"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // File size info
            HStack(spacing: 16) {
                infoBadge(icon: "doc.text", title: "files".localized, value: "\(liveProject.files.count)")
                infoBadge(icon: "text.word.spacing", title: "size".localized, value: formatFileSize(liveProject.totalSize))
                infoBadge(icon: "clock", title: "updated".localized, value: formatDate(liveProject.updatedAt))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Publishing Methods
    private var publishingMethods: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("publish_methods".localized)
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(PublishMethod.allCases, id: \.self) { method in
                publishMethodCard(method: method)
            }
        }
    }
    
    private func publishMethodCard(method: PublishMethod) -> some View {
        Button(action: { handlePublishMethod(method) }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(method.iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: method.icon)
                        .font(.title2)
                        .foregroundColor(method.iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(method.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
        .disabled(isPublishing)
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quick_actions".localized)
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickActionButton(icon: "qrcode", title: "qr_code".localized, color: .blue) {
                    if let url = server.serverURL ?? liveProject.cloudUrl {
                        qrURL = url
                        showQRCode = true
                    }
                }
                
                quickActionButton(icon: "square.and.arrow.up", title: "share_link".localized, color: .green) {
                    if let url = server.serverURL ?? liveProject.cloudUrl {
                        shareURL = URL(string: url)
                        showShareSheet = true
                    }
                }
                
                quickActionButton(icon: "archivebox", title: "export_zip".localized, color: .orange) {
                    exportProjectAsZip()
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Published Links Section
    private var publishedLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("published_links".localized)
                    .font(.headline)
                
                Spacer()
                
                Button("view_all".localized) {
                    showPublishedProjects = true
                }
                .font(.caption)
                .foregroundColor(Color("Color"))
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(publishHistory.getHistory(for: project.id).prefix(3)) { record in
                    publishedLinkRow(record: record)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func publishedLinkRow(record: PublishRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.method == .cloud ? "icloud.fill" : "wifi")
                .foregroundColor(record.method == .cloud ? .blue : .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(record.url)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                Text(formatDate(record.publishedAt) + " · \(record.visitCount) " + "views".localized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = record.url
                documentManager.toastItem = ToastItem(message: "copied".localized, type: .success)
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color("Color"))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Actions
    private func handlePublishMethod(_ method: PublishMethod) {
        switch method {
        case .localNetwork:
            startLocalSharing()
        case .cloud:
            startCloudPublish()
        }
    }
    
    private func startLocalSharing() {
        if server.isRunning {
            server.stopServer()
            documentManager.toastItem = ToastItem(message: "sharing_stopped".localized, type: .info)
        } else {
            server.startServer(with: liveProject)
            documentManager.toastItem = ToastItem(message: "sharing_started".localized, type: .success)
        }
    }
    
    private func startCloudPublish() {
        if liveProject.cloudUrl != nil {
            // Show existing cloud URL
            publishingUrl = liveProject.cloudUrl!
            let dateFormatter = ISO8601DateFormatter()
            publishResult = PublishResult(
                url: liveProject.cloudUrl!,
                id: liveProject.cloudId ?? "",
                expiresAt: liveProject.expiresAt.map { dateFormatter.string(from: $0) }
            )
            showPublishResult = true
            return
        }
        
        // 检查发布限制
        if !subscriptionManager.canPublish() {
            subscriptionManager.showPaywall = true
            return
        }
        
        // 所有用户都可以发布，免费用户默认5分钟过期
        showPublishConfig = true
    }
    
    private func performPublish(config: PublishConfig) {
        isPublishing = true
        publishProgress = 0
        publishProgressText = "publishing".localized
        
        Task {
            // Simulate progress
            for i in 0...10 {
                await MainActor.run {
                    publishProgress = Double(i) * 0.1
                    if i < 3 {
                        publishProgressText = "preparing_files".localized
                    } else if i < 7 {
                        publishProgressText = "uploading".localized
                    } else {
                        publishProgressText = "finalizing".localized
                    }
                }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            if let result = await cloudService.publishProjectWithDetails(liveProject, config: config) {
                await MainActor.run {
                    self.publishResult = result
                    self.publishingUrl = result.url
                    self.isPublishing = false
                    
                    // Update project cloud info
                    documentManager.updateCloudInfo(
                        projectId: liveProject.id,
                        url: result.url,
                        cloudId: result.id,
                        expiresAt: result.expiresAt
                    )
                    
                    // Add to publish history
                    PublishHistoryManager.shared.addRecord(
                        projectId: liveProject.id,
                        projectName: liveProject.name,
                        url: result.url,
                        method: .cloud,
                        visitCount: 0
                    )
                    
                    subscriptionManager.incrementPublishedCount()
                    showPublishResult = true
                }
                
                // Sync stats in background after successful publish
                Task {
                    _ = await PublishedProjectsManager.shared.fetchStats(for: result.id)
                }
            } else {
                await MainActor.run {
                    isPublishing = false
                    // 区分业务错误码，给出最合适的提示
                    let errorCode = cloudService.lastPublishServerErrorCode
                    let message: String
                    if errorCode.triggersPaywall {
                        subscriptionManager.showPaywall = true
                        message = "pro_required".localized
                    } else if errorCode == .publishLimitExceeded {
                        message = "publish_limit_reached".localized
                        subscriptionManager.showPaywall = true
                    } else {
                        message = errorCode.localizedMessage
                    }
                    documentManager.toastItem = ToastItem(message: message, type: .error)
                }
            }
        }
    }
    
    private func exportProjectAsZip() {
        if let zipURL = documentManager.exportProject(liveProject) {
            shareURL = zipURL
            showShareSheet = true
            documentManager.toastItem = ToastItem(message: "export_success".localized, type: .success)
        } else {
            documentManager.toastItem = ToastItem(message: "export_failed".localized, type: .error)
        }
    }
    
    // MARK: - Helpers
    private func infoBadge(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct QRCodeFullScreenView: View {
    let url: String
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                if let qrImage = QRCodeGenerator.generate(from: url) {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                }
                
                Text(url)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    UIPasteboard.general.string = url
                }) {
                    Label("copy_link".localized, systemImage: "doc.on.doc")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Color"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("qr_code".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
        }
    }
}

// MARK: - Network Monitor
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "port.hdmi"
            case .unknown: return "questionmark"
            }
        }
    }
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .ethernet
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

extension HTMLProject {
    var totalSize: Int {
        files.reduce(0) { $0 + $1.content.count }
    }
}
