import SwiftUI

struct PublishedProjectsListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var manager = PublishedProjectsManager.shared
    @ObservedObject private var cloudService = CloudService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedProject: PublishedProjectsManager.PublishedProjectInfo?
    @State private var showDeleteConfirmation = false
    @State private var projectToDelete: PublishedProjectsManager.PublishedProjectInfo?
    @State private var showCopyToast = false
    @State private var showDeleteToast = false
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var projectForManageCloud: HTMLProject?
    @State private var refreshingProjectId: String?
    
    var filteredProjects: [PublishedProjectsManager.PublishedProjectInfo] {
        let projects = searchText.isEmpty ? manager.publishedProjects : manager.publishedProjects.filter {
            $0.projectName.localizedCaseInsensitiveContains(searchText) ||
            $0.cloudUrl.localizedCaseInsensitiveContains(searchText)
        }
        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if manager.publishedProjects.isEmpty {
                    emptyStateView
                } else {
                    projectList
                }
            }
            .navigationTitle("published_links".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("done".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: refreshStats) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(manager.publishedProjects.isEmpty)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "search_published".localized)
            .sheet(item: $selectedProject) { project in
                PublishedProjectDetailView(project: project)
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .sheet(item: $projectForManageCloud) { project in
                CloudProjectManagerView(project: project)
                    .environmentObject(documentManager)
            }
            .overlay(
                Group {
                    ToastOverlay(isPresented: $showCopyToast, message: "copy_success".localized)
                    ToastOverlay(isPresented: $showDeleteToast, message: "unpublish_success".localized)
                }
            )
            .onAppear {
                manager.attach(documentManager: documentManager)
                manager.syncFromDocumentManager(documentManager)
            }
            .onChange(of: documentManager.projects) { _, _ in
                manager.attach(documentManager: documentManager)
            }
            .alert("confirm_unpublish".localized, isPresented: $showDeleteConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("unpublish".localized, role: .destructive) {
                    if let project = projectToDelete {
                        unpublishProject(project)
                    }
                }
            } message: {
                if let project = projectToDelete {
                    Text(String(format: "unpublish_confirm_msg".localized, project.projectName))
                }
            }
        }
    }
    
    var projectList: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    Text(String(format: "total_published".localized, manager.publishedProjects.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !manager.activeProjects.isEmpty && manager.expiredProjects.isEmpty == false {
                        Text(String(format: "active_count".localized, manager.activeProjects.count))
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            ForEach(filteredProjects) { project in
                PublishedProjectRow(
                    project: project,
                    onCopy: { copyLink(project) },
                    onShare: { shareProject(project) },
                    onOpen: { openInBrowser(project) },
                    onDetail: {
                        selectedProject = project
                    },
                    onUnpublish: {
                        projectToDelete = project
                        showDeleteConfirmation = true
                    },
                    onManageCloud: {
                        projectForManageCloud = documentManager.projects.first(where: { $0.cloudId == project.cloudId })
                    },
                    onRefresh: {
                        refreshProjectStats(project)
                    }
                )
                .contentTransition(.opacity)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("Color").opacity(0.1), Color("Color").opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "globe")
                    .font(.system(size: 50))
                    .foregroundStyle(Color("Color"))
            }
            
            VStack(spacing: 8) {
                Text("no_published_projects".localized)
                    .font(.title2.bold())
                
                Text("publish_hint".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { dismiss() }) {
                Text("go_create".localized)
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
    }
    
    private func refreshStats() {
        isRefreshing = true
        Task {
            await manager.fetchAllStats()
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func copyLink(_ project: PublishedProjectsManager.PublishedProjectInfo) {
        UIPasteboard.general.string = project.displayUrl
        showCopyToast = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyToast = false
        }
    }
    
    private func shareProject(_ project: PublishedProjectsManager.PublishedProjectInfo) {
        shareItems = [project.displayUrl, project.projectName]
        showShareSheet = true
    }
    
    private func openInBrowser(_ project: PublishedProjectsManager.PublishedProjectInfo) {
        if let url = URL(string: project.displayUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    private func unpublishProject(_ project: PublishedProjectsManager.PublishedProjectInfo) {
        Task {
            do {
                let success = try await cloudService.unpublishProjectWithRetry(cloudId: project.cloudId)
                await MainActor.run {
                    if success {
                        HapticManager.shared.notificationSuccess()
                        showDeleteToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showDeleteToast = false
                        }
                    } else {
                        HapticManager.shared.notificationError()
                        documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                    }
                }
            } catch NetworkRetryManager.NetworkError.noInternet {
                await MainActor.run {
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_offline".localized, type: .error)
                }
            } catch NetworkRetryManager.NetworkError.maxRetriesExceeded {
                await MainActor.run {
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "network_unstable_retry_failed".localized, type: .error)
                }
            } catch {
                await MainActor.run {
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "operation_failed".localized, type: .error)
                }
            }
        }
    }
    
    private func refreshProjectStats(_ project: PublishedProjectsManager.PublishedProjectInfo) {
        refreshingProjectId = project.cloudId
        Task {
            _ = await manager.fetchStats(for: project.cloudId)
            await MainActor.run {
                refreshingProjectId = nil
            }
        }
    }
}

struct PublishedProjectRow: View {
    let project: PublishedProjectsManager.PublishedProjectInfo
    let onCopy: () -> Void
    let onShare: () -> Void
    let onOpen: () -> Void
    let onDetail: () -> Void
    let onUnpublish: () -> Void
    let onManageCloud: (() -> Void)?
    let onRefresh: (() -> Void)?
    
    @State private var showActions = false
    @State private var showManageSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let thumbnailData = project.thumbnailData,
                   let image = UIImage(data: thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .cornerRadius(10)
                        .clipped()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("Color").opacity(0.1))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "doc.text.image")
                            .font(.title3)
                            .foregroundColor(Color("Color"))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.projectName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if project.isExpired {
                            Text("expired".localized)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(project.displayUrl)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onDetail()
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.caption2)
                    Text("\(project.visitCount)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                if project.isExpired {
                    Text("expired".localized)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                } else if let days = project.expiresInDays, days > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(String(format: "expires_in_days".localized, days))
                            .font(.caption2)
                    }
                    .foregroundColor(days < 3 ? .red : days < 7 ? .orange : .secondary)
                } else if project.expiresAt == nil {
                    HStack(spacing: 4) {
                        Image(systemName: "infinity")
                            .font(.caption2)
                        Text("never_expire".localized)
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                    Text("\(project.fileCount)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { onRefresh?() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(project.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if showActions {
                HStack(spacing: 8) {
                    ActionButton(icon: "doc.on.doc", title: "copy".localized, color: .blue) {
                        onCopy()
                        withAnimation { showActions = false }
                    }
                    
                    ActionButton(icon: "square.and.arrow.up", title: "share".localized, color: .green) {
                        onShare()
                        withAnimation { showActions = false }
                    }
                    
                    ActionButton(icon: "safari", title: "open".localized, color: .purple) {
                        onOpen()
                        withAnimation { showActions = false }
                    }
                    
                    if onManageCloud != nil {
                        ActionButton(icon: "gearshape.fill", title: "cloud_management".localized, color: .orange) {
                            onManageCloud?()
                            withAnimation { showActions = false }
                        }
                    }
                    
                    ActionButton(icon: "xmark.circle", title: "unpublish".localized, color: .red) {
                        onUnpublish()
                        withAnimation { showActions = false }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showActions.toggle()
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct PublishedProjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @ObservedObject private var cloudService = CloudService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = PublishedProjectsManager.shared
    let project: PublishedProjectsManager.PublishedProjectInfo
    
    @State private var qrImage: UIImage?
    @State private var showCopyToast = false
    @State private var showShareSheet = false
    @State private var showExpiryManagement = false
    @State private var showExpiryUpdatedToast = false
    @State private var showPasswordManagement = false
    @State private var showPasswordUpdatedToast = false
    @State private var showAnalytics = false
    
    var liveProject: PublishedProjectsManager.PublishedProjectInfo {
        manager.publishedProjects.first(where: { $0.cloudId == project.cloudId }) ?? project
    }
    
    var currentUrl: String {
        liveProject.cloudUrl
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let qrImage = qrImage {
                        VStack(spacing: 16) {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            Text("cloud_qr_hint".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text(liveProject.projectName)
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            
                            Text(currentUrl)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.horizontal)
                        
                        if let expiresAt = liveProject.expiresAt {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("expires_at".localized + " " + formatDate(expiresAt))
                                    .font(.caption2)
                            }
                            .foregroundColor(liveProject.isExpired ? .red : .orange)
                            .padding(.top, 4)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                            Text("\(liveProject.visitCount)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("\(liveProject.fileCount)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    VStack(spacing: 12) {
                        Button(action: { showExpiryManagement = true }) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                Text("manage_expiry".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showPasswordManagement = true }) {
                            HStack {
                                Image(systemName: liveProject.hasPassword ? "lock.shield.fill" : "lock.open.shield.fill")
                                Text(liveProject.hasPassword ? "change_password".localized : "set_password".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.teal.opacity(0.1))
                            .foregroundColor(.teal)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showAnalytics = true }) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                Text("view_analytics".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: copyLink) {
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
                            
                            Button(action: { showShareSheet = true }) {
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
                            
                            Button(action: openInBrowser) {
                                HStack {
                                    Image(systemName: "safari")
                                    Text("open_file".localized)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationTitle("link_detail".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                }
            }
            .onAppear {
                generateQRCode()
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [currentUrl, liveProject.projectName])
            }
            .sheet(isPresented: $showExpiryManagement) {
                ExpiryManagementSheet(
                    project: liveProject,
                    isPro: subscriptionManager.isPro,
                    onUpdateExpiry: { expireDays, expireMinutes, makePermanent, accessPassword, removePassword in
                        await updateExpiry(expireDays: expireDays, expireMinutes: expireMinutes, makePermanent: makePermanent, accessPassword: accessPassword, removePassword: removePassword)
                    },
                    onDismiss: { showExpiryManagement = false }
                )
            }
            .sheet(isPresented: $showPasswordManagement) {
                PasswordManagementSheet(
                    project: liveProject,
                    onUpdatePassword: { newPassword, remove in
                        await updatePassword(newPassword: newPassword, remove: remove)
                    },
                    onDismiss: { showPasswordManagement = false }
                )
            }
            .sheet(isPresented: $showAnalytics) {
                VisitAnalyticsView(cloudId: liveProject.cloudId, projectName: liveProject.projectName)
            }
            .overlay(
                Group {
                    ToastOverlay(isPresented: $showCopyToast, message: "copy_success".localized)
                    ToastOverlay(isPresented: $showExpiryUpdatedToast, message: "expiry_updated".localized)
                    ToastOverlay(isPresented: $showPasswordUpdatedToast, message: "password_updated".localized)
                }
            )
        }
    }
    
    private func generateQRCode() {
        qrImage = QRCodeGenerator.generate(from: currentUrl, size: CGSize(width: 440, height: 440))
    }
    
    private func copyLink() {
        UIPasteboard.general.string = currentUrl
        showCopyToast = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyToast = false
        }
    }
    
    private func openInBrowser() {
        if let url = URL(string: currentUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @MainActor
    private func updateExpiry(expireDays: Int?, expireMinutes: Int?, makePermanent: Bool, accessPassword: String? = nil, removePassword: Bool = false) async {
        // Pro 门控：免费用户一律拦截
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(
                message: "pro_required_for_expiry".localized,
                type: .warning
            )
            subscriptionManager.showPaywall = true
            return
        }

        do {
            let result = try await cloudService.updateProjectExpiryWithRetry(
                cloudId: liveProject.cloudId,
                userId: UserManager.shared.userId,
                expireDays: expireDays,
                expireMinutes: expireMinutes,
                makePermanent: makePermanent,
                accessPassword: accessPassword,
                removePassword: removePassword
            )

            await MainActor.run {
                if result.success {
                    showExpiryUpdatedToast = true
                    HapticManager.shared.notificationSuccess()
                    PublishedProjectsManager.shared.updateExpiryFromServer(cloudId: liveProject.cloudId, expiresAt: result.expiresAt, isPermanent: result.isPermanent)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showExpiryUpdatedToast = false
                        showExpiryManagement = false
                    }
                } else if result.message.contains("Pro") || result.message.contains("subscription") {
                    // 服务端拒绝（非 Pro）
                    subscriptionManager.showPaywall = true
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: "pro_required_for_expiry".localized, type: .warning)
                } else {
                    HapticManager.shared.notificationError()
                    documentManager.toastItem = ToastItem(message: result.message, type: .error)
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
    
    @MainActor
    private func updatePassword(newPassword: String?, remove: Bool) async {
        // Pro 门控
        guard subscriptionManager.isPro else {
            HapticManager.shared.notificationError()
            documentManager.toastItem = ToastItem(message: "pro_required_for_password".localized, type: .warning)
            subscriptionManager.showPaywall = true
            return
        }

        do {
            let success: Bool
            if remove {
                success = try await cloudService.removeAccessPasswordWithRetry(cloudId: liveProject.cloudId)
            } else if let password = newPassword, !password.isEmpty {
                success = try await cloudService.setAccessPasswordWithRetry(cloudId: liveProject.cloudId, password: password)
            } else {
                success = false
            }

            await MainActor.run {
                if success {
                    showPasswordUpdatedToast = true
                    HapticManager.shared.notificationSuccess()
                    PublishedProjectsManager.shared.updatePasswordStatus(cloudId: liveProject.cloudId, hasPassword: !remove)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showPasswordUpdatedToast = false
                        showPasswordManagement = false
                    }
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

struct ExpiryManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: PublishedProjectsManager.PublishedProjectInfo
    let isPro: Bool
    let onUpdateExpiry: (_ expireDays: Int?, _ expireMinutes: Int?, _ makePermanent: Bool, _ accessPassword: String?, _ removePassword: Bool) async -> Void
    let onDismiss: () -> Void
    
    @State private var selectedOption: ExpiryOption = .custom
    @State private var customDays = 7
    @State private var isUpdating = false
    @State private var enablePassword: Bool = false
    @State private var accessPassword: String = ""
    @State private var removePassword: Bool = false
    
    enum ExpiryOption: String, CaseIterable {
        case fiveMinutes = "5_minutes"
        case oneHour = "1_hour"
        case oneDay = "1_day"
        case threeDays = "3_days"
        case sevenDays = "7_days"
        case thirtyDays = "30_days"
        case custom = "custom_days"
        case permanent = "permanent"
        
        var displayName: String {
            self.rawValue.localized
        }
        
        var icon: String {
            switch self {
            case .fiveMinutes: return "timer"
            case .oneHour: return "clock"
            case .oneDay, .threeDays, .sevenDays, .thirtyDays, .custom: return "calendar"
            case .permanent: return "infinity"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("select_expiry".localized)) {
                    ForEach(availableOptions, id: \.self) { option in
                        Button(action: { selectedOption = option }) {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundColor(selectedOption == option ? .orange : .secondary)
                                    .frame(width: 24)
                                Text(option.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    if selectedOption == .custom {
                        HStack {
                            Text("custom_days".localized)
                            Spacer()
                            Stepper(value: $customDays, in: 1...365) {
                                Text("\(customDays) \("days".localized)")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                Section {
                    if let expiresAt = project.expiresAt {
                        HStack {
                            Text("current_expiry".localized)
                            Spacer()
                            Text(formatDate(expiresAt))
                                .foregroundColor(project.isExpired ? .red : .orange)
                        }
                    } else {
                        HStack {
                            Text("current_expiry".localized)
                            Spacer()
                            Text("never_expire".localized)
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("current_status".localized)
                }
                
                Section(header: Text("password_protection".localized)) {
                    Toggle("enable_password".localized, isOn: $enablePassword)
                    
                    if enablePassword {
                        SecureField("set_access_password".localized, text: $accessPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Text("password_hint".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if project.hasPassword {
                        Button(role: .destructive, action: { removePassword = true }) {
                            HStack {
                                Image(systemName: "lock.open")
                                Text("remove_password".localized)
                            }
                        }
                    }
                }
            }
            .navigationTitle("manage_expiry".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { onDismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: confirmUpdate) {
                        if isUpdating {
                            ProgressView()
                        } else {
                            Text("confirm".localized)
                        }
                    }
                    .disabled(isUpdating)
                }
            }
        }
    }
    
    var availableOptions: [ExpiryOption] {
        var options: [ExpiryOption] = [.fiveMinutes, .oneHour, .oneDay, .threeDays, .sevenDays, .thirtyDays, .custom]
        if isPro {
            options.append(.permanent)
        }
        return options
    }
    
    private func confirmUpdate() {
        isUpdating = true
        Task {
            var expireDays: Int? = nil
            var expireMinutes: Int? = nil
            var makePermanent = false
            
            switch selectedOption {
            case .fiveMinutes: expireMinutes = 5
            case .oneHour: expireMinutes = 60
            case .oneDay: expireDays = 1
            case .threeDays: expireDays = 3
            case .sevenDays: expireDays = 7
            case .thirtyDays: expireDays = 30
            case .custom: expireDays = customDays
            case .permanent: makePermanent = true
            }
            
            let passwordToSend = enablePassword && !accessPassword.isEmpty ? accessPassword : nil
            await onUpdateExpiry(expireDays, expireMinutes, makePermanent, passwordToSend, removePassword)
            await MainActor.run {
                isUpdating = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Password Management Sheet
struct PasswordManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: PublishedProjectsManager.PublishedProjectInfo
    let onUpdatePassword: (_ newPassword: String?, _ remove: Bool) async -> Void
    let onDismiss: () -> Void
    
    @State private var enablePassword: Bool = false
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var removePassword: Bool = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                if project.hasPassword {
                    Section(header: Text("current_status".localized)) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                            Text("password_enabled".localized)
                                .foregroundColor(.primary)
                        }
                        
                        Button(role: .destructive, action: { removePassword = true }) {
                            HStack {
                                Image(systemName: "lock.open")
                                Text("remove_password".localized)
                            }
                        }
                    }
                }
                
                Section(header: Text(enablePassword ? "set_new_password".localized : "password_protection".localized)) {
                    Toggle("enable_password".localized, isOn: $enablePassword)
                    
                    if enablePassword {
                        SecureField("set_access_password".localized, text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        SecureField("confirm_password".localized, text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        if !newPassword.isEmpty && newPassword != confirmPassword {
                            Label("passwords_not_match".localized, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Text("password_hint".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("manage_password".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { onDismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if removePassword {
                        Button(action: confirmRemovePassword) {
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("confirm".localized)
                            }
                        }
                        .disabled(isUpdating)
                        .foregroundColor(.red)
                    } else if enablePassword && !newPassword.isEmpty && newPassword == confirmPassword {
                        Button(action: confirmSetPassword) {
                            if isUpdating {
                                ProgressView()
                            } else {
                                Text("confirm".localized)
                            }
                        }
                        .disabled(isUpdating)
                    }
                }
            }
            .alert("confirm_remove_password".localized, isPresented: $removePassword) {
                Button("cancel".localized, role: .cancel) { }
                Button("remove".localized, role: .destructive) {
                    performRemovePassword()
                }
            } message: {
                Text("remove_password_confirm_msg".localized)
            }
        }
    }
    
    private func confirmSetPassword() {
        guard !newPassword.isEmpty && newPassword == confirmPassword else {
            errorMessage = "passwords_not_match".localized
            return
        }
        isUpdating = true
        errorMessage = nil
        Task {
            await onUpdatePassword(newPassword, false)
            await MainActor.run {
                isUpdating = false
            }
        }
    }
    
    private func confirmRemovePassword() {
        isUpdating = true
        errorMessage = nil
        Task {
            await onUpdatePassword(nil, true)
            await MainActor.run {
                isUpdating = false
            }
        }
    }
    
    private func performRemovePassword() {
        confirmRemovePassword()
    }
}

// MARK: - Visit Analytics View
struct VisitAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    let cloudId: String
    let projectName: String
    
    @State private var stats: DetailedStats?
    @State private var isLoading = true
    @State private var loadError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("loading".localized).font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.top, 80)
                } else if let s = stats {
                    VStack(alignment: .leading, spacing: 16) {
                        // KPI cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            KPICard(title: "total_visits".localized, value: "\(s.totalVisits)", color: .blue, icon: "eye.fill")
                            KPICard(title: "today_visits".localized, value: "\(s.todayVisits ?? 0)", color: .green, icon: "sun.max.fill")
                            KPICard(title: "unique_visitors".localized, value: "\(s.uniqueVisitors ?? 0)", color: .purple, icon: "person.2.fill")
                            KPICard(title: "seven_day_visits".localized, value: "\(s.visitsByDay.reduce(0) { $0 + $1.count })", color: .orange, icon: "calendar")
                        }
                        .padding(.horizontal)
                        
                        // Daily chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("seven_day_trend".localized).font(.headline).padding(.horizontal)
                            dailyChart(s.visitsByDay)
                                .frame(height: 160)
                                .padding(.horizontal)
                        }
                        
                        // Top referrers
                        if let refs = s.topReferrers, !refs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("top_referrers".localized).font(.headline).padding(.horizontal)
                                VStack(spacing: 0) {
                                    ForEach(Array(refs.prefix(5).enumerated()), id: \.offset) { _, r in
                                        HStack {
                                            Text(displayReferrer(r.source)).font(.caption).lineLimit(1)
                                            Spacer()
                                            Text("\(r.count)").font(.caption).foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 8).padding(.horizontal, 12)
                                        Divider()
                                    }
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        
                        // View logs button
                        NavigationLink(destination: VisitLogsView(cloudId: cloudId, projectName: projectName)) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("view_detailed_logs".localized)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                } else if let e = loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.orange)
                        Text(e).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center).padding()
                        Button("retry".localized) { loadStats() }
                    }
                    .padding(.top, 80)
                }
            }
            .navigationTitle(projectName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("done".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadStats) { Image(systemName: "arrow.clockwise") }
                        .disabled(isLoading)
                }
            }
            .onAppear { loadStats() }
        }
    }
    
    private func loadStats() {
        isLoading = true
        loadError = nil
        Task {
            let res = await CloudService.shared.fetchDetailedStats(
                cloudId: cloudId,
                userId: UserManager.shared.userId,
                includeDetail: true
            )
            await MainActor.run {
                stats = res
                if res == nil { loadError = "stats_load_failed".localized }
                isLoading = false
            }
        }
    }
    
    private func dailyChart(_ data: [DetailedStats.DailyVisit]) -> some View {
        let sorted = data.sorted { $0.date < $1.date }
        let maxV = max(sorted.map { $0.count }.max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(sorted, id: \.date) { entry in
                VStack(spacing: 4) {
                    Text("\(entry.count)").font(.caption2).foregroundColor(.secondary).frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                        .frame(height: max(CGFloat(entry.count) / CGFloat(maxV) * 110, 2))
                    Text(String(entry.date.suffix(5))).font(.system(size: 9)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    private func deviceIcon(_ t: String) -> String {
        switch t {
        case "mobile": return "iphone"
        case "tablet": return "ipad"
        case "desktop": return "desktopcomputer"
        default: return "questionmark.circle"
        }
    }
    
    private func displayReferrer(_ s: String) -> String {
        if s == "direct" { return "direct_visit".localized }
        if let u = URL(string: s), let host = u.host { return host }
        return s
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value).font(.title2).bold().foregroundColor(.primary)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}
