import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct ProjectBrowserView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var sortOption: SortOption = .updatedAt
    @State private var viewMode: ViewMode = .grid
    @State private var showNewProjectSheet = false
    @State private var showPasteSheet = false
    @State private var path = NavigationPath()
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var cloudService = CloudService.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    private let cloudServiceActor = CloudService.shared
    private let subscriptionManagerActor = SubscriptionManager.shared
    
    @State private var showPublishResult = false
    @State private var showPublishError = false
    @State private var publishErrorMessage = ""
    @State private var publishProgress: Double = 0
    @State private var publishingUrl = ""
    @State private var selectedProjectToPublish: HTMLProject? = nil
    @State private var showPublishConfig = false
    
    @State private var projectForPreview: HTMLProject? = nil
    @State private var projectForShare: HTMLProject? = nil
    @State private var projectForPublishHub: HTMLProject? = nil
    
    enum SortOption: String, CaseIterable {
        case updatedAt = "sort_updated"
        case createdAt = "sort_created"
        case name = "sort_name"
        case favorite = "sort_favorite"
        
        var localized: String {
            self.rawValue.localized
        }
    }
    
    enum ViewMode {
        case grid, list
    }
    
    var filteredProjects: [HTMLProject] {
        let filtered = searchText.isEmpty ? documentManager.projects : documentManager.projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOption {
        case .updatedAt:
            return filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .createdAt:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .favorite:
            return filtered.sorted { $0.isFavorite && !$1.isFavorite }
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if documentManager.projects.isEmpty {
                    emptyStateView
                } else {
                    projectListContent
                }
            }
            .navigationTitle("projects".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("sort_by".localized, selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.localized).tag(option)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { viewMode = .grid }) {
                            Label("grid_view".localized, systemImage: "square.grid.2x2")
                        }
                        
                        Button(action: { viewMode = .list }) {
                            Label("list_view".localized, systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButtonMenu
                }
            }
            .searchable(text: $searchText, prompt: "search".localized)
            .sheet(isPresented: $showNewProjectSheet) {
                NewProjectSheet()
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $showPasteSheet) {
                PasteCodeSheet()
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $documentManager.showTemplatePicker) {
                TemplatePickerView()
                    .environmentObject(documentManager)
            }
            .toast($documentManager.toastItem)
            .sheet(isPresented: $showPublishResult) {
                if let project = selectedProjectToPublish {
                    PublishResultView(projectName: project.name, urlString: publishingUrl, project: project)
                        .environmentObject(documentManager)
                }
            }
            .sheet(isPresented: $showPublishConfig) {
                if let project = selectedProjectToPublish {
                    PublishConfigView(project: project, isPresented: $showPublishConfig) { config in
                        performPublish(project: project, config: config)
                    }
                    .environmentObject(documentManager)
                }
            }
            .fullScreenCover(item: $projectForPreview) { project in
                FullScreenPreviewView(project: project)
                    .environmentObject(documentManager)
            }
            .fileImporter(
                isPresented: $documentManager.showFileImporter,
                allowedContentTypes: [.html, .plainText, .data, .image, .font, .zip, UTType(filenameExtension: "rar") ?? .data],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .sheet(item: $projectForShare) { project in
                SharePreviewView(projectId: project.id)
                    .environmentObject(documentManager)
            }
            .sheet(item: $projectForPublishHub) { project in
                PublishHubView(project: project)
                    .environmentObject(documentManager)
            }
            .navigationDestination(for: HTMLProject.self) { project in
                ContentView()
                    .environmentObject(documentManager)
            }
        }
    }
    
    @ViewBuilder
    var projectListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    var gridView: some View {
        let columns = [
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
        ]
        
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                ProjectCardView(project: project, path: $path,
                               onPublish: publishProject,
                               onPublishCenter: { projectForPublishHub = $0 },
                               onPreview: { projectForPreview = $0 },
                               onShare: { projectForShare = $0 })
                    .environmentObject(documentManager)
                    .staggered(index: index)
            }
        }
    }
    
    @ViewBuilder
    var listView: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(filteredProjects.enumerated()), id: \.element.id) { index, project in
                ProjectRowView(project: project, path: $path,
                              onPublish: publishProject,
                              onPublishCenter: { projectForPublishHub = $0 },
                              onPreview: { projectForPreview = $0 },
                              onShare: { projectForShare = $0 })
                    .environmentObject(documentManager)
                    .staggered(index: index)
            }
        }
    }
    
    var addButtonMenu: some View {
        Menu {
            Section("create_section".localized) {
                Button(action: { showNewProjectSheet = true }) {
                    Label("new_project".localized, systemImage: "doc.badge.plus")
                }
                Button(action: { showPasteSheet = true }) {
                    Label("paste_code".localized, systemImage: "doc.on.clipboard")
                }
                Button(action: { documentManager.showTemplatePicker = true }) {
                    Label("template".localized, systemImage: "square.on.square")
                }
            }
            Section("import_section".localized) {
                Button(action: { documentManager.showFileImporter = true }) {
                    Label("import_file".localized, systemImage: "square.and.arrow.down")
                }
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    var emptyStateView: some View {
        EmptyStateView(
            icon: "doc.text.image",
            title: "no_projects".localized,
            message: "create_first_project".localized,
            buttonTitle: "new_project".localized,
            buttonAction: { showNewProjectSheet = true },
            secondaryButtonTitle: "template".localized,
            secondaryButtonAction: { documentManager.showTemplatePicker = true }
        )
    }
    
    func publishProject(_ project: HTMLProject) {
        let liveProject = documentManager.projects.first(where: { $0.id == project.id }) ?? project
        
        if let url = liveProject.cloudUrl {
            self.selectedProjectToPublish = liveProject
            self.publishingUrl = url
            self.showPublishResult = true
            return
        }
        
        if !subscriptionManager.canPublish() {
            subscriptionManager.showPaywall = true
            return
        }
        
        selectedProjectToPublish = liveProject
        showPublishConfig = true
    }
    
    func performPublish(project: HTMLProject, config: PublishConfig) {
        Task {
            let cs = cloudServiceActor
            let result = await cs.publishProjectWithDetails(project, config: config)
            
            await MainActor.run {
                if let result = result, !result.url.isEmpty {
                    self.publishingUrl = result.url
                    self.subscriptionManager.incrementPublishedCount()
                    
                    PublishedProjectsManager.shared.addOrUpdate(project: project, result: result)
                    
                    self.showPublishError = false
                    self.showPublishResult = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.documentManager.updateCloudInfo(
                            projectId: project.id,
                            url: result.url,
                            cloudId: result.id,
                            expiresAt: result.expiresAt
                        )
                    }
                } else {
                    self.showPublishResult = false
                    self.showPublishError = true
                    self.publishErrorMessage = "publish_failed_no_url".localized
                    
                    if result?.shouldClearCloudId == true && project.cloudId != nil {
                        var updatedProject = project
                        updatedProject.cloudId = nil
                        updatedProject.cloudUrl = nil
                        documentManager.updateProject(updatedProject)
                    }
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                documentManager.importHTML(from: url)
            }
        case .failure(let error):
            documentManager.errorMessage = "\("import_failed".localized): \(error.localizedDescription)"
        }
    }
}

// MARK: - Project Card View
struct ProjectCardView: View {
    let project: HTMLProject
    @Binding var path: NavigationPath
    let onPublish: (HTMLProject) -> Void
    let onPublishCenter: (HTMLProject) -> Void
    let onPreview: (HTMLProject) -> Void
    let onShare: (HTMLProject) -> Void
    @EnvironmentObject var documentManager: DocumentManager
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            ProjectThumbnail(project: project)
                .frame(height: 140)
                .clipped()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let url = project.cloudUrl {
                            Text(url)
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("\(project.files.count)")
                            }
                            
                            Text("·")
                            
                            Text(project.updatedAt, style: .relative)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if project.cloudUrl != nil {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                HStack(spacing: 8) {
                    Button(action: { editProject() }) {
                        Label("edit".localized, systemImage: "pencil")
                            .font(.caption)
                            .foregroundColor(Color("Color"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color("Color").opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { onPreview(project) }) {
                        Label("run".localized, systemImage: "play.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .pressScale(scale: 0.97, haptic: .buttonTap)
        .onTapGesture {
            onPreview(project)
        }
        .contextMenu {
            projectContextMenu
        }
        .confirmationDialog("delete_project_title".localized, isPresented: $showDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) { }
            Button("delete".localized, role: .destructive) {
                documentManager.deleteProject(project)
            }
        } message: {
            Text(String(format: "delete_confirm_msg".localized, project.name))
        }
    }
    
    @ViewBuilder
    var projectContextMenu: some View {
        Button(action: { editProject() }) {
            Label("edit_project_menu".localized, systemImage: "pencil")
        }
        
        Button(action: { onPreview(project) }) {
            Label("run_tool_menu".localized, systemImage: "play.fill")
        }
        
        Button(action: { onShare(project) }) {
            Label("share".localized, systemImage: "square.and.arrow.up")
        }
        
        Button(action: { onPublish(project) }) {
            Label(project.cloudUrl == nil ? safeLocalize("publish_cloud") : safeLocalize("update_cloud"), systemImage: "icloud.and.arrow.up")
        }
        
        Button(action: { onPublishCenter(project) }) {
            Label(safeLocalize("publish_center"), systemImage: "arrow.up.right.circle")
        }
        
        if let urlString = project.cloudUrl, let url = URL(string: urlString) {
            Button(action: {
                UIApplication.shared.open(url)
            }) {
                Label(safeLocalize("view_cloud"), systemImage: "safari")
            }
        }
        
        Divider()
        
        Button(action: { documentManager.toggleProjectFavorite(project) }) {
            Label(project.isFavorite ? "unfavorite_menu".localized : "favorite_menu".localized, systemImage: project.isFavorite ? "star.slash" : "star")
        }
        
        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
            Label("delete".localized, systemImage: "trash")
        }
    }
    
    func editProject() {
        documentManager.switchToProject(project)
        path.append(project)
    }
}

// MARK: - Project Row View
struct ProjectRowView: View {
    let project: HTMLProject
    @Binding var path: NavigationPath
    let onPublish: (HTMLProject) -> Void
    let onPublishCenter: (HTMLProject) -> Void
    let onPreview: (HTMLProject) -> Void
    let onShare: (HTMLProject) -> Void
    @EnvironmentObject var documentManager: DocumentManager
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            ProjectThumbnail(project: project)
                .frame(width: 80, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if project.cloudUrl != nil {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                (Text(String(format: "files_count".localized, project.files.count)) + Text(" · ") + Text(project.updatedAt, style: .relative))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let url = project.cloudUrl {
                    Text(url)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { editProject() }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .pressScale(scale: 0.98, haptic: .buttonTap)
        .onTapGesture {
            onPreview(project)
        }
        .contextMenu {
            Button(action: { editProject() }) {
                Label("edit".localized, systemImage: "pencil")
            }
            
            Button(action: { onPreview(project) }) {
                Label("run".localized, systemImage: "play.fill")
            }
            
            Button(action: { onShare(project) }) {
                Label("share".localized, systemImage: "square.and.arrow.up")
            }
            
            Button(action: { onPublish(project) }) {
                Label(project.cloudUrl == nil ? safeLocalize("publish_cloud") : safeLocalize("update_cloud"), systemImage: "icloud.and.arrow.up")
            }
            
            Button(action: { onPublishCenter(project) }) {
                Label(safeLocalize("publish_center"), systemImage: "arrow.up.right.circle")
            }
            
            if let urlString = project.cloudUrl, let url = URL(string: urlString) {
                Button(action: {
                    UIApplication.shared.open(url)
                }) {
                    Label("view_cloud".localized, systemImage: "safari")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("delete".localized, systemImage: "trash")
            }
        }
        .alert("delete_project_title".localized, isPresented: $showDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) { }
            Button("delete".localized, role: .destructive) {
                documentManager.deleteProject(project)
            }
        } message: {
            Text(String(format: "delete_confirm_msg".localized, project.name))
        }
    }
    
    func editProject() {
        documentManager.switchToProject(project)
        path.append(project)
    }
}

// MARK: - Project Thumbnail
struct ProjectThumbnail: View {
    let project: HTMLProject
    @EnvironmentObject var documentManager: DocumentManager
    @State private var thumbnail: UIImage?
    @State private var isGenerating = false
    
    var body: some View {
        ZStack {
            Color(.systemGray5)
            
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "doc.text.image")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("preview_thumbnail".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    func loadThumbnail() {
        if let thumbnailData = project.thumbnailData,
           let cachedImage = UIImage(data: thumbnailData) {
            thumbnail = cachedImage
            return
        }
        
        guard let result = documentManager.prepareProjectForRunning(project) else { return }
        isGenerating = true
        
        Task { @MainActor in
            let image = await generateThumbnail(indexURL: result.indexURL, projectDir: result.projectDir)
            thumbnail = image
            isGenerating = false
            if let image = image, let jpegData = image.jpegData(compressionQuality: 0.7) {
                documentManager.saveThumbnail(jpegData, for: project.id)
            }
        }
    }
    
    @MainActor
    func generateThumbnail(indexURL: URL, projectDir: URL) async -> UIImage? {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = .white
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        let hiddenContainer = UIView(frame: CGRect(x: -1000, y: -1000, width: 375, height: 667))
        window.addSubview(hiddenContainer)
        hiddenContainer.addSubview(webView)
        
        webView.loadFileURL(indexURL, allowingReadAccessTo: projectDir.deletingLastPathComponent())
        
        let completionState = CompletionState()
        let timerBox = TimerBox()
        
        // 超时保护：5秒后强制清理
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            guard completionState.tryComplete() else { return }
            DispatchQueue.main.async {
                webView.stopLoading()
                hiddenContainer.removeFromSuperview()
            }
        }
        timerBox.value = timer
        
        let image = await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                guard !completionState.isCompleted else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let snapshotConfig = WKSnapshotConfiguration()
                snapshotConfig.rect = CGRect(x: 0, y: 0, width: 375, height: 667)
                
                webView.takeSnapshot(with: snapshotConfig) { image, error in
                    timerBox.value?.invalidate()
                    if completionState.tryComplete() {
                        hiddenContainer.removeFromSuperview()
                    }
                    continuation.resume(returning: image)
                }
            }
        }
        
        return image
    }
}

private final class CompletionState: @unchecked Sendable {
    private var _isCompleted = false
    private let lock = NSLock()
    
    var isCompleted: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isCompleted
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isCompleted = newValue
        }
    }
    
    func tryComplete() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !_isCompleted else { return false }
        _isCompleted = true
        return true
    }
}

final class TimerBox: @unchecked Sendable {
    var value: Timer?
}
