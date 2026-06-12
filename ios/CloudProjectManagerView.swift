import SwiftUI

struct CloudProjectManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var cloudManager = CloudProjectManager.shared
    @ObservedObject private var cloudService = CloudService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    let project: HTMLProject
    
    @State private var selectedProject: CloudPublishedProject?
    @State private var showPasswordSheet = false
    @State private var showExpirySheet = false
    @State private var isUpdating = false
    @State private var showRedirectSettings = false
    @State private var showVisitLogs = false
    @State private var showLinkPreview = false
    @State private var showDeleteConfirmation = false
    
    var publishedProject: CloudPublishedProject? {
        cloudManager.publishedProjects.first { $0.projectId == project.id.uuidString }
    }
    
    private var cloudId: String? {
        publishedProject?.id
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let pub = publishedProject {
                        // Project Status Header
                        statusHeader(pub: pub)
                        
                        // Access Management
                        accessManagement(pub: pub)
                        
                        // Link Management
                        linkManagement(pub: pub)
                        
                        // Visit Statistics
                        visitStatistics(pub: pub)
                        
                        // Danger Zone
                        dangerZone(pub: pub)
                    } else {
                        notPublishedView
                    }
                }
                .padding()
            }
            .navigationTitle("cloud_project_management".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
            .sheet(isPresented: $showPasswordSheet) {
                Group {
                    if let cid = cloudId, let pub = publishedProject {
                        PasswordSettingView(project: project, cloudId: cid, currentPassword: pub.accessPassword, isPresented: $showPasswordSheet)
                    }
                }
            }
            .sheet(isPresented: $showExpirySheet) {
                Group {
                    if let cid = cloudId, let pub = publishedProject {
                        ExpirySettingView(project: project, cloudId: cid, currentExpiry: pub.expiresAt, isPresented: $showExpirySheet)
                    }
                }
            }
            .sheet(isPresented: $showRedirectSettings) {
                Group {
                    if let cid = cloudId {
                        RedirectSettingsView(cloudId: cid, isPresented: $showRedirectSettings)
                            .environmentObject(documentManager)
                    }
                }
            }
            .sheet(isPresented: $showVisitLogs) {
                Group {
                    if let cid = cloudId {
                        VisitLogsView(cloudId: cid, projectName: project.name)
                    }
                }
            }
            .sheet(isPresented: $showLinkPreview) {
                LinkPreviewView(
                    projectUrl: publishedProject?.url ?? "",
                    projectName: project.name,
                    hasPassword: publishedProject?.hasPassword ?? false,
                    accessPassword: publishedProject?.accessPassword
                )
            }
            .toast($documentManager.toastItem)
            .task {
                await cloudManager.loadPublishedProjects()
            }
        }
    }
    
    // MARK: - Status Header
    private func statusHeader(pub: CloudPublishedProject) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(pub.isActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 70, height: 70)
                
                Image(systemName: pub.isActive ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(pub.isActive ? .green : .red)
            }
            
            VStack(spacing: 8) {
                Text(pub.isActive ? "sharing_active".localized : "sharing_stopped".localized)
                    .font(.title2.bold())
                    .foregroundColor(pub.isActive ? .green : .red)
                
                Text(pub.url)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                statusBadge(icon: "eye.fill", title: "visits".localized, value: "\(pub.visitCount)", color: .blue)
                statusBadge(icon: "clock.fill", title: "published_at".localized, value: formatDate(pub.publishedAt), color: .orange)
                statusBadge(icon: "calendar", title: "expires".localized, value: pub.expiresAt.map { formatShortDate($0) } ?? "never".localized, color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func statusBadge(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
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
    
    // MARK: - Access Management
    private func accessManagement(pub: CloudPublishedProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("access_control".localized, systemImage: "lock.shield.fill")
                .font(.headline)
            
            VStack(spacing: 10) {
                // Password Protection
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("access_password".localized)
                            .font(.subheadline)
                        Text(pub.accessPassword != nil ? "password_set".localized : "password_not_set".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Pro 门控：免费用户引导订阅
                        if !subscriptionManager.isPro {
                            subscriptionManager.showPaywall = true
                            HapticManager.shared.notificationError()
                            documentManager.toastItem = ToastItem(message: "pro_required_for_password".localized, type: .warning)
                            return
                        }
                        showPasswordSheet = true
                    }) {
                        Text(pub.accessPassword != nil ? "change".localized : "set".localized)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(subscriptionManager.isPro ? Color.blue : Color.gray)
                            .cornerRadius(6)
                    }
                    .disabled(!subscriptionManager.isPro)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
                
                // Toggle Active Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pub.isActive ? "stop_sharing".localized : "resume_sharing".localized)
                            .font(.subheadline)
                        Text(pub.isActive ? "stop_sharing_desc".localized : "resume_sharing_desc".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { pub.isActive },
                        set: { _ in toggleSharing(pub: pub) }
                    ))
                    .labelsHidden()
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Link Management
    private func linkManagement(pub: CloudPublishedProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("link_management".localized, systemImage: "link.circle.fill")
                .font(.headline)
            
            VStack(spacing: 10) {
                // Link Preview
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("link_preview".localized)
                            .font(.subheadline)
                        Text("preview_share_link".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showLinkPreview = true }) {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
                
                // Expiry Date
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("link_expiry".localized)
                            .font(.subheadline)
                        Text(pub.expiresAt.map { formatDateTime($0) } ?? "no_expiry".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Pro 门控：免费用户引导订阅
                        if !subscriptionManager.isPro {
                            subscriptionManager.showPaywall = true
                            HapticManager.shared.notificationError()
                            documentManager.toastItem = ToastItem(message: "pro_required_for_expiry".localized, type: .warning)
                            return
                        }
                        showExpirySheet = true
                    }) {
                        Text("edit".localized)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(subscriptionManager.isPro ? Color.blue : Color.gray)
                            .cornerRadius(6)
                    }
                    .disabled(!subscriptionManager.isPro)
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
                
                // Expired Redirect Settings
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("expired_redirect".localized)
                            .font(.subheadline)
                        Text("expired_redirect_hint_short".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showRedirectSettings = true }) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundColor(.purple)
                            .padding(8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Visit Statistics
    private func visitStatistics(pub: CloudPublishedProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("visit_statistics".localized, systemImage: "chart.bar.fill")
                    .font(.headline)
                
                Spacer()

                HStack(spacing: 12) {
                    Button(action: { showVisitLogs = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                            Text("visit_logs".localized)
                        }
                        .font(.caption)
                        .foregroundColor(Color("Color"))
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCard(icon: "eye.fill", title: "total_visits".localized, value: "\(pub.visitCount)", color: .blue)
                statCard(icon: "person.fill", title: "unique_visitors".localized, value: "\(pub.uniqueVisitors)", color: .green)
                statCard(icon: "calendar.today", title: "today_visits".localized, value: "\(pub.todayVisits)", color: .orange)
                statCard(icon: "clock.fill", title: "last_visit".localized, value: pub.lastVisitedAt.map { formatRelativeDate($0) } ?? "never".localized, color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Danger Zone
    private func dangerZone(pub: CloudPublishedProject) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("danger_zone".localized, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("unpublish_project".localized)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .alert("confirm_unpublish".localized, isPresented: $showDeleteConfirmation) {
                Button("unpublish".localized, role: .destructive) {
                    if let pub = publishedProject { unpublishProject(pub: pub) }
                }
                Button("cancel".localized, role: .cancel) {}
            } message: {
                Text(String(format: "unpublish_confirm_msg".localized, project.name))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Not Published View
    private var notPublishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("not_published_title".localized)
                .font(.title2.bold())
            
            Text("not_published_desc".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Navigate to publish
            }) {
                Text("publish_now".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Color"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(40)
    }
    
    // MARK: - Actions

    private func toggleSharing(pub: CloudPublishedProject) {
        guard let cid = cloudId else { return }
        isUpdating = true
        Task {
            let success = await cloudManager.toggleProjectStatus(cloudId: cid, isActive: !pub.isActive)
            await MainActor.run {
                isUpdating = false
                if success {
                    documentManager.toastItem = ToastItem(
                        message: pub.isActive ? "sharing_stopped".localized : "sharing_resumed".localized,
                        type: .success
                    )
                    Task { await cloudManager.loadPublishedProjects() }
                } else {
                    documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                }
            }
        }
    }
    
    private func unpublishProject(pub: CloudPublishedProject) {
        guard let cid = cloudId else { return }
        Task {
            do {
                let success = try await cloudService.unpublishProjectWithRetry(cloudId: cid)
                await MainActor.run {
                    if success {
                        HapticManager.shared.notificationSuccess()
                        documentManager.toastItem = ToastItem(message: "unpublish_success".localized, type: .success)
                        Task { await cloudManager.loadPublishedProjects() }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
            } catch {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
            }
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Password Setting View
struct PasswordSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var cloudManager = CloudProjectManager.shared
    @ObservedObject private var cloudService = CloudService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    let project: HTMLProject
    let cloudId: String
    let currentPassword: String?
    @Binding var isPresented: Bool

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isUpdating = false
    
    var passwordStrength: (level: Int, text: String, color: Color) {
        if newPassword.isEmpty {
            return (0, "", .clear)
        }
        
        var score = 0
        if newPassword.count >= 6 { score += 1 }
        if newPassword.count >= 10 { score += 1 }
        if newPassword.contains(where: { $0.isUppercase }) { score += 1 }
        if newPassword.contains(where: { $0.isLowercase }) { score += 1 }
        if newPassword.contains(where: { $0.isNumber }) { score += 1 }
        if newPassword.contains(where: { !"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }) { score += 1 }
        
        if score <= 2 {
            return (1, "weak_password".localized, .red)
        } else if score <= 4 {
            return (2, "medium_password".localized, .orange)
        } else {
            return (3, "strong_password".localized, .green)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("set_access_password".localized), footer: Text("password_hint".localized)) {
                    SecureField("new_password".localized, text: $newPassword)
                    
                    if !newPassword.isEmpty {
                        HStack(spacing: 8) {
                            Text("password_strength".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index < passwordStrength.level ? passwordStrength.color : Color.gray.opacity(0.3))
                                    .frame(height: 4)
                            }
                            
                            Text(passwordStrength.text)
                                .font(.caption)
                                .foregroundColor(passwordStrength.color)
                        }
                        .padding(.top, 4)
                    }
                    
                    SecureField("confirm_password".localized, text: $confirmPassword)
                    
                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        Text("passwords_not_match".localized)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                if currentPassword != nil {
                    Section {
                        Button(role: .destructive, action: removePassword) {
                            HStack {
                                Spacer()
                                Text("remove_password".localized)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: savePassword) {
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
                    .disabled(isUpdating || newPassword.isEmpty || newPassword != confirmPassword || newPassword.count < 6)
                }
            }
            .navigationTitle("set_password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
    }
    
    private func savePassword() {
        // Pro 门控
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(message: "pro_required_for_password".localized, type: .warning)
            subscriptionManager.showPaywall = true
            return
        }

        isUpdating = true
        Task {
            do {
                let success = try await cloudService.setAccessPasswordWithRetry(cloudId: cloudId, password: newPassword)
                await MainActor.run {
                    isUpdating = false
                    if success {
                        HapticManager.shared.notificationSuccess()
                        documentManager.toastItem = ToastItem(message: "password_set_success".localized, type: .success)
                        dismiss()
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
                }
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                }
            }
        }
    }

    private func removePassword() {
        // Pro 门控
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(message: "pro_required_for_password".localized, type: .warning)
            subscriptionManager.showPaywall = true
            return
        }

        Task {
            do {
                let success = try await cloudService.removeAccessPasswordWithRetry(cloudId: cloudId)
                await MainActor.run {
                    if success {
                        HapticManager.shared.notificationSuccess()
                        documentManager.toastItem = ToastItem(message: "password_removed".localized, type: .success)
                        dismiss()
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
            } catch {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
            }
        }
    }
}

// MARK: - Expiry Setting View
struct ExpirySettingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var cloudManager = CloudProjectManager.shared
    @ObservedObject private var cloudService = CloudService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    let project: HTMLProject
    let cloudId: String
    let currentExpiry: Date?
    @Binding var isPresented: Bool

    @State private var enableExpiry = false
    @State private var selectedDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var isUpdating = false
    
    private let quickOptions: [(String, TimeInterval)] = [
        ("1_day".localized, 24 * 60 * 60),
        ("3_days".localized, 3 * 24 * 60 * 60),
        ("7_days".localized, 7 * 24 * 60 * 60),
        ("30_days".localized, 30 * 24 * 60 * 60),
        ("no_expiry".localized, 0)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("set_expiry".localized, isOn: $enableExpiry)
                }
                
                if enableExpiry {
                    Section("quick_select".localized) {
                        ForEach(quickOptions.prefix(4), id: \.0) { option in
                            Button(action: {
                                selectedDate = Date().addingTimeInterval(option.1)
                            }) {
                                HStack {
                                    Text(option.0)
                                    Spacer()
                                    if abs(selectedDate.timeIntervalSinceNow - option.1) < 60 {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color("Color"))
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("custom_date".localized) {
                        DatePicker("expiry_date".localized, selection: $selectedDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    }
                } else {
                    Section {
                        Button(action: removeExpiry) {
                            HStack {
                                Spacer()
                                Text("remove_expiry".localized)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: saveExpiry) {
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
                    .disabled(isUpdating)
                }
            }
            .navigationTitle("set_expiry".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
            .onAppear {
                enableExpiry = currentExpiry != nil
                if let expiry = currentExpiry {
                    selectedDate = expiry
                }
            }
        }
    }
    
    private func saveExpiry() {
        // Pro 门控
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(message: "pro_required_for_expiry".localized, type: .warning)
            subscriptionManager.showPaywall = true
            return
        }

        isUpdating = true
        Task {
            do {
                let expiry = enableExpiry ? selectedDate : nil
                let success = try await cloudService.setExpiryDateWithRetry(cloudId: cloudId, expiresAt: expiry)
                await MainActor.run {
                    isUpdating = false
                    if success {
                        HapticManager.shared.notificationSuccess()
                        documentManager.toastItem = ToastItem(message: "expiry_updated".localized, type: .success)
                        dismiss()
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
                }
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                }
            }
        }
    }

    private func removeExpiry() {
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(message: "pro_required_for_expiry".localized, type: .warning)
            subscriptionManager.showPaywall = true
            return
        }

        Task {
            do {
                let success = try await cloudService.setExpiryDateWithRetry(cloudId: cloudId, expiresAt: nil)
                await MainActor.run {
                    if success {
                        HapticManager.shared.notificationSuccess()
                        documentManager.toastItem = ToastItem(message: "expiry_removed".localized, type: .success)
                        dismiss()
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
            } catch {
                HapticManager.shared.notificationError()
                documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
            }
        }
    }
}
