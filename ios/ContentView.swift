import SwiftUI

struct ContentView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appRouter: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject var cloudService = CloudService.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    @State private var editorText = ""
    @State private var selectedDevice: DeviceType = .iphone
    @State private var showProjectBrowser = false
    @State private var showSearchReplace = false
    @State private var showSettings = false
    @State private var showSharePreview = false
    @State private var showFileBrowser = true
    @State private var viewMode: ViewMode = .editor
    @State private var showDeleteProjectConfirmation = false
    @State private var showFullScreenPreview = false
    @State private var showPublishResult = false
    @State private var publishingUrl = ""
    @State private var resultProject: HTMLProject? = nil
    @State private var publishResult: PublishResult? = nil
    @State private var showPublishConfig = false
    @State private var showServerTest = false
    @State private var logoTapCount = 0
    
    @AppStorage("enableSyntaxHighlight") private var enableSyntaxHighlight = true
    @AppStorage("enableLineNumbers") private var enableLineNumbers = true
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    
    @State private var undoStack: [String] = []
    @State private var redoStack: [String] = []
    @State private var showiPhoneFileBrowser = false
    @State private var isDocumentLoaded = false
    
    enum ViewMode: String, CaseIterable {
        case editor = "code"
        case preview = "preview"
        case split = "split"
        
        var displayName: String {
            self.rawValue.localized
        }
        
        var icon: String {
            switch self {
            case .editor: return "chevron.left.forwardslash.chevron.right"
            case .preview: return "eye"
            case .split: return "rectangle.split.2x1"
            }
        }
    }
    
    private var primaryModifiers: some View {
        mainContent
            .background(Color(.systemGroupedBackground))
            .navigationTitle(documentManager.currentProject?.name ?? "HTML Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
    }
    
    @ViewBuilder
    private var sheetContent: some View {
        EmptyView()
            .sheet(isPresented: $showProjectBrowser) {
                ProjectBrowserView(isPresented: $showProjectBrowser)
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $documentManager.showTemplatePicker) {
                TemplatePickerView()
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $showSearchReplace) {
                SearchReplaceView(text: $editorText, isPresented: $showSearchReplace)
            }
            .sheet(isPresented: $showSettings) {
                ProfileView()
                    .environmentObject(appRouter)
                    .environmentObject(documentManager)
            }
            .sheet(isPresented: $showSharePreview) {
                if let project = documentManager.currentProject {
                    SharePreviewView(projectId: project.id)
                        .environmentObject(documentManager)
                }
            }
            .sheet(isPresented: $showPublishResult) {
                if let project = resultProject {
                    PublishResultView(projectName: project.name, urlString: publishingUrl, project: project, publishResult: publishResult)
                        .environmentObject(documentManager)
                }
            }
            .sheet(isPresented: $showPublishConfig) {
                if let project = documentManager.currentProject {
                    PublishConfigView(project: project, isPresented: $showPublishConfig) { config in
                        performPublish(project: project, config: config)
                    }
                    .environmentObject(documentManager)
                }
            }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        EmptyView()
            .fullScreenCover(isPresented: $showFullScreenPreview) {
                if let project = documentManager.currentProject {
                    FullScreenPreviewView(project: project)
                        .environmentObject(documentManager)
                }
            }
            .fileImporter(
                isPresented: $documentManager.showFileImporter,
                allowedContentTypes: [.html, .plainText, .data, .image, .font],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
            .alert("error".localized, isPresented: Binding(
                get: { documentManager.errorMessage != nil },
                set: { if !$0 { documentManager.errorMessage = nil } }
            )) {
                Button("ok".localized) { documentManager.errorMessage = nil }
            } message: {
                if let msg = documentManager.errorMessage {
                    Text(msg)
                }
            }
            .toast($documentManager.toastItem)
            .alert("delete".localized, isPresented: $showDeleteProjectConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive) {
                    if let project = documentManager.currentProject {
                        documentManager.deleteProject(project)
                    }
                }
            } message: {
                if let project = documentManager.currentProject {
                    Text("\("delete_project_confirm".localized) \(project.name)")
                }
            }
    }
    
    @ViewBuilder
    private var bottomBarContent: some View {
        if viewMode == .editor && UIDevice.current.userInterfaceIdiom != .pad {
            symbolShortcutBar
        } else if viewMode == .preview && UIDevice.current.userInterfaceIdiom != .pad {
            previewBottomToolbar
        }
    }
    
    @ViewBuilder
    private var lifecycleContent: some View {
        EmptyView()
            .onAppear { loadCurrentFile() }
            .onDisappear { documentManager.flushPendingSaves() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase != ScenePhase.active {
                    documentManager.flushPendingSaves()
                }
            }
            .onChange(of: documentManager.currentFile) { _, newFile in
                if let file = newFile {
                    if editorText != file.content {
                        editorText = file.content
                    }
                    undoStack = []
                    redoStack = []
                }
            }
    }
    
    @ViewBuilder
    private var additionalSheets: some View {
        let fileBrowser = FileBrowserView()
            .environmentObject(documentManager)
        let testView = ServerTestView()
            .environmentObject(documentManager)
        EmptyView()
            .sheet(isPresented: $showiPhoneFileBrowser) {
                NavigationStack {
                    fileBrowser
                        .navigationTitle("project_files".localized)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("done".localized) { showiPhoneFileBrowser = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showServerTest) {
                testView
            }
    }
    
    var body: some View {
        primaryModifiers
            .overlay(sheetContent)
            .overlay(overlayContent)
            .overlay(lifecycleContent)
            .overlay(additionalSheets)
            .toolbar(.hidden, for: .tabBar)
            .safeAreaInset(edge: .bottom) { bottomBarContent }
    }
    
    private func loadCurrentFile() {
        if let file = documentManager.currentFile {
            editorText = file.content
            undoStack = []
            redoStack = []
        }
    }
    
    @ViewBuilder
    var mainContent: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            projectMenu
                .frame(width: 44, alignment: .leading)
        }
        
        ToolbarItem(placement: .principal) {
            viewModePicker
                .frame(width: 150)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            trailingToolbarItems 
                .frame(width: 80, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private var viewModePicker: some View {
        Picker("view_mode".localized, selection: $viewMode) {
            Text("code".localized).tag(ViewMode.editor)
            Text("preview".localized).tag(ViewMode.preview)
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    private var trailingToolbarItems: some View {
        HStack {
            Spacer(minLength: 0)
            if UIDevice.current.userInterfaceIdiom != .pad {
                if viewMode == .editor {
                    Button(action: { showiPhoneFileBrowser = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sidebar.left")
                            Text("files".localized)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                } else {
                    Button(action: { showFullScreenPreview = true }) {
                        HStack(spacing: 6) {
                            Text("run".localized)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var previewBottomToolbar: some View {
        HStack {
            // Device Picker
            Menu {
                Picker("Default Device".localized, selection: $selectedDevice) {
                    ForEach(DeviceType.allCases, id: \.self) { device in
                        Label(device.rawValue.localized, systemImage: device.icon)
                            .tag(device)
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedDevice.icon)
                        .font(.system(size: 20))
                    Text("device".localized)
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            
            // QR Code
            Button(action: { showSharePreview = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 20))
                    Text("share".localized)
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
            
            Button(action: { publishCurrentProject() }) {
                VStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 20))
                    Text(documentManager.currentProject?.cloudUrl == nil ? safeLocalize("publish_cloud") : safeLocalize("update_cloud"))
                        .font(.caption2)
                    
                    if let url = documentManager.currentProject?.cloudUrl {
                        Text(url)
                            .font(.system(size: 8))
                            .foregroundColor(.blue.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
    
    var projectMenu: some View {
        Menu {
            Section("projects".localized) {
                Button(action: { documentManager.createNewProject() }) {
                    Label("new_project".localized, systemImage: "doc.badge.plus")
                }
                
                Button(action: { documentManager.showTemplatePicker = true }) {
                    Label("template".localized, systemImage: "square.on.square")
                }
            }
            
            Section("edit".localized) {
                Button(action: { showSearchReplace = true }) {
                    Label("search".localized, systemImage: "magnifyingglass")
                }
                
                Button(action: { showSettings = true }) {
                    Label("settings".localized, systemImage: "gearshape")
                }
            }
            
            Section("share".localized) {
                if let url = documentManager.exportCurrentProject() {
                    ShareLink(item: url) {
                        Label("share".localized, systemImage: "square.and.arrow.up")
                    }
                }
                
                Button(action: { publishCurrentProject() }) {
                    Label(documentManager.currentProject?.cloudUrl == nil ? safeLocalize("publish_cloud") : safeLocalize("update_cloud"), systemImage: "icloud.and.arrow.up")
                }
            }
            
            if let project = documentManager.currentProject {
                Section {
                    Button(action: { documentManager.duplicateProject(project) }) {
                        Label("duplicate".localized, systemImage: "doc.on.doc")
                    }
                    
                    Button(role: .destructive, action: { showDeleteProjectConfirmation = true }) {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
        }
    }
    
    var successMessageOverlay: some View {
        Group {
            if let message = documentManager.showSuccessMessage {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(message)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.bottom, 100)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            documentManager.showSuccessMessage = nil
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var iPadLayout: some View {
        HStack(spacing: 0) {
            if showFileBrowser {
                FileBrowserView()
                    .environmentObject(documentManager)
                    .transition(.move(edge: .leading))
            }
            
            Divider()
            
            VStack(spacing: 0) {
                switch viewMode {
                case .editor:
                    editorContent
                case .preview:
                    previewContent
                case .split:
                    HStack(spacing: 0) {
                        editorContent
                        Divider()
                        previewContent
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var iPhoneLayout: some View {
        VStack(spacing: 0) {
            switch viewMode {
            case .editor:
                editorContent
            case .preview, .split:
                previewContent
            }
        }
    }
    
    var editorContent: some View {
        VStack(spacing: 0) {
            // File info bar
            if let file = documentManager.currentFile {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: file.type.icon)
                            .font(.caption)
                            .foregroundColor(fileTypeColor(file.type))
                        Text(file.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    if editorText.count > 50000 {
                        Text("syntax_highlight_disabled".localized)
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else if editorText.count > 15000 {
                        Text("syntax_highlight_limited".localized)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(editorText.count) \("characters".localized)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemBackground))
            }
            
            EditorToolbarView(
                onInsertTag: insertTag,
                onFormatCode: formatCode,
                onUndo: undo,
                onRedo: redo,
                onCopy: copyText,
                onPaste: pasteText,
                onClear: clearText,
                onSelectAll: selectAll,
                canUndo: !undoStack.isEmpty,
                canRedo: !redoStack.isEmpty
            )
            
            if documentManager.isProjectLoading {
                ZStack {
                    Color(.systemBackground)
                    ProgressView("loading".localized)
                }
            } else if enableLineNumbers {
                EditorWithLineNumbers(
                    text: $editorText,
                    onTextChange: { newText in
                        pushToUndoStack()
                        documentManager.updateCurrentFile(content: newText)
                    },
                    fontSize: CGFloat(editorFontSize)
                )
            } else {
                EnhancedHTMLEditorView(
                    text: $editorText,
                    onTextChange: { newText in
                        pushToUndoStack()
                        documentManager.updateCurrentFile(content: newText)
                    },
                    showLineNumbers: .constant(false),
                    showSyntaxHighlight: .constant(enableSyntaxHighlight),
                    scrollOffset: .constant(0),
                    fontSize: CGFloat(editorFontSize)
                )
            }
        }
    }
    
    var previewContent: some View {
        Group {
            if let project = documentManager.currentProject {
                MultiFilePreviewView(
                    project: project,
                    deviceType: selectedDevice
                )
            } else {
                emptyPreviewView
            }
        }
    }
    
    var emptyPreviewView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "doc.text.image")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text("no_projects".localized)
                    .font(.title3.bold())
                
                Text("create_or_select".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: { documentManager.createNewProject() }) {
                    Label("new_project".localized, systemImage: "doc.badge.plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                Button(action: { documentManager.showTemplatePicker = true }) {
                    Label("template".localized, systemImage: "square.on.square")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button(action: { documentManager.showFileImporter = true }) {
                    Label("import_file".localized, systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func insertTag(_ tag: String) {
        pushToUndoStack()
        NotificationCenter.default.post(name: .insertKeyboardText, object: nil, userInfo: ["text": tag])
    }
    
    private func formatCode() {
        pushToUndoStack()
        let formatted = CodeFormatter.format(editorText, for: documentManager.currentFile?.type ?? .html)
        editorText = formatted
        documentManager.updateCurrentFile(content: formatted)
    }
    
    private func pushToUndoStack() {
        redoStack.removeAll()
        if undoStack.count >= 50 {
            undoStack.removeFirst()
        }
        undoStack.append(editorText)
    }
    
    private func undo() {
        guard !undoStack.isEmpty else { return }
        let currentText = editorText
        editorText = undoStack.removeLast()
        redoStack.append(currentText)
        documentManager.updateCurrentFile(content: editorText)
    }
    
    private func redo() {
        guard !redoStack.isEmpty else { return }
        let currentText = editorText
        editorText = redoStack.removeLast()
        undoStack.append(currentText)
        documentManager.updateCurrentFile(content: editorText)
    }
    
    private func copyText() {
        UIPasteboard.general.string = editorText
        documentManager.showSuccessMessage = "copy_success".localized
    }
    
    private func pasteText() {
        if let clipboardString = UIPasteboard.general.string {
            pushToUndoStack()
            editorText += clipboardString
            documentManager.updateCurrentFile(content: editorText)
            documentManager.showSuccessMessage = "pasted_success".localized
        }
    }
    
    private func clearText() {
        pushToUndoStack()
        editorText = ""
        documentManager.updateCurrentFile(content: editorText)
        documentManager.showSuccessMessage = "cleared_success".localized
    }
    
    private func selectAll() {
        NotificationCenter.default.post(name: .selectAllText, object: nil)
    }
    
    private func fileTypeColor(_ type: ProjectFile.FileType) -> Color {
        switch type {
        case .html: return .orange
        case .css: return .blue
        case .javascript: return .yellow
        default: return .primary
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if urls.count == 1 {
                documentManager.importHTML(from: urls[0])
            } else if urls.count > 1 {
                documentManager.importMultipleFiles(from: urls)
            }
        case .failure(let error):
            documentManager.errorMessage = "\("import_failed".localized): \(error.localizedDescription)"
        }
    }
    
    private var symbolShortcutBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["<", ">", "/", "=", "\"", "\'", "!", "-", "{", "}", "[", "]", "(", ")", ";", ":"], id: \.self) { symbol in
                    Button(action: { insertSymbol(symbol) }) {
                        Text(symbol)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 36, height: 36)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
    }
    
    private func insertSymbol(_ symbol: String) {
        pushToUndoStack()
        NotificationCenter.default.post(name: .insertKeyboardText, object: nil, userInfo: ["text": symbol])
    }
    
    private func publishCurrentProject() {
        guard var project = documentManager.currentProject else { return }
        
        if project.isExpired {
            project.cloudId = nil
            project.cloudUrl = nil
            project.expiresAt = nil
            documentManager.updateProject(project)
        }
        
        if let url = project.cloudUrl, !project.isExpired {
            self.resultProject = project
            self.publishingUrl = url
            self.showPublishResult = true
            return
        }
        
        if !subscriptionManager.canPublish() {
            subscriptionManager.showPaywall = true
            return
        }
        
        showPublishConfig = true
    }
    
    private func performPublish(project: HTMLProject, config: PublishConfig) {
        Task {
            if let result = await cloudService.publishProjectWithDetails(project, config: config) {
                // 检查发布结果是否有效
                if result.url.isEmpty {
                    await MainActor.run {
                        let errorCode = cloudService.lastPublishServerErrorCode
                        if errorCode == .proRequired {
                            subscriptionManager.showPaywall = true
                        } else {
                            documentManager.toastItem = ToastItem(
                                message: errorCode.localizedMessage,
                                type: .error
                            )
                        }
                    }
                    return
                }
                await MainActor.run {
                    self.resultProject = project
                    self.publishingUrl = result.url
                    self.publishResult = result
                    self.subscriptionManager.incrementPublishedCount()
                    self.showPublishResult = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.documentManager.updateCloudInfo(
                            projectId: project.id,
                            url: result.url,
                            cloudId: result.id,
                            expiresAt: result.expiresAt
                        )
                    }
                }
            }
        }
    }
}
