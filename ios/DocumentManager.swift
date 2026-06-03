import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Compression

@MainActor
class DocumentManager: ObservableObject {
    @Published var projects: [HTMLProject] = []
    @Published var currentProject: HTMLProject?
    @Published var currentFile: ProjectFile?
    @Published var isPreviewVisible = true
    @Published var showTemplatePicker = false
    @Published var showFileImporter = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage: String?
    @Published var toastItem: ToastItem?
    @Published var isReady = false
    @Published var initializationStatus: InitializationStatus = .initializing
    @Published var isProjectLoading = false
    
    var shareServer: LocalHTMLServer?
    
    private let projectsDirectory: URL
    private let metadataFile: URL
    private var autosaveTask: Task<Void, Never>?
    private let autosaveDelayNanos: UInt64 = 2_000_000_000
    
    enum InitializationStatus {
        case initializing
        case ready
        case failed(String)
    }
    
    struct ProjectMetadata: Codable {
        var projects: [ProjectInfo]
        
        struct ProjectInfo: Codable {
            let id: UUID
            var name: String
            var createdAt: Date
            var updatedAt: Date
            var hasThumbnail: Bool
            var isFavorite: Bool
            var fileCount: Int
        }
    }
    
    @Published var metadata: ProjectMetadata
    
    // MARK: - Undo/Redo
    
    struct UndoAction {
        let id = UUID()
        let type: ActionType
        let projectId: UUID
        let previousState: HTMLProject?
        let previousFileId: UUID?
        let timestamp = Date()
        
        enum ActionType {
            case deleteProject
            case deleteFile
            case renameProject
            case renameFile
        }
    }
    
    @Published private var undoStack: [UndoAction] = []
    @Published private var redoStack: [UndoAction] = []
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    private func pushUndo(_ action: UndoAction) {
        undoStack.append(action)
        if undoStack.count > 20 { undoStack.removeFirst() }
        redoStack.removeAll()
        updateUndoRedoState()
    }
    
    private func updateUndoRedoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        
        switch action.type {
        case .deleteProject:
            if let project = action.previousState {
                saveProjectToDisk(project)
                projects.append(project)
                if currentProject == nil {
                    currentProject = project
                    currentFile = project.mainFile
                }
                saveMetadata()
                showToast(String(format: "undo_delete_project".localized, project.name), type: .success)
            }
        case .deleteFile:
            if let project = action.previousState,
               let file = action.previousFileId,
               let originalProject = projects.first(where: { $0.id == action.projectId }) {
                var updated = originalProject
                if let fileObj = project.files.first(where: { $0.id == file }) {
                    updated.addFile(fileObj)
                    updateProject(updated)
                    currentFile = fileObj
                    saveProjectToDisk(updated)
                    saveMetadata()
                    showToast(String(format: "undo_delete_file".localized, fileObj.displayName), type: .success)
                }
            }
        case .renameProject:
            if let project = action.previousState {
                if let index = projects.firstIndex(where: { $0.id == action.projectId }) {
                    projects[index] = project
                    currentProject = project
                    saveProjectToDisk(project)
                    saveMetadata()
                    showToast("undo_rename_project".localized, type: .success)
                }
            }
        case .renameFile:
            if let project = action.previousState,
               let fileId = action.previousFileId {
                if let index = projects.firstIndex(where: { $0.id == action.projectId }) {
                    projects[index] = project
                    currentProject = project
                    if currentFile?.id == fileId {
                        currentFile = project.files.first(where: { $0.id == fileId })
                    }
                    saveProjectToDisk(project)
                    saveMetadata()
                    showToast("undo_rename_file".localized, type: .success)
                }
            }
        }
        
        redoStack.append(action)
        updateUndoRedoState()
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        
        switch action.type {
        case .deleteProject:
            if let project = action.previousState {
                deleteProject(project)
            }
        case .deleteFile:
            if let fileId = action.previousFileId,
               var project = currentProject,
               project.id == action.projectId {
                project.removeFile(id: fileId)
                updateProject(project)
                if currentFile?.id == fileId {
                    currentFile = project.mainFile
                }
                saveProjectToDisk(project)
                saveMetadata()
            }
        case .renameProject:
            if action.previousState != nil {
                if let current = projects.first(where: { $0.id == action.projectId }) {
                    let newName = current.name
                    updateProjectName(newName)
                }
            }
        case .renameFile:
            if let project = action.previousState,
               let fileId = action.previousFileId,
               let file = project.files.first(where: { $0.id == fileId }) {
                renameFileInCurrentProject(fileId: fileId, to: file.name)
            }
        }
        
        undoStack.append(action)
        updateUndoRedoState()
    }
    
    init() {
        let containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.projectsDirectory = containerURL.appendingPathComponent("HTMLProjects")
        self.metadataFile = self.projectsDirectory.appendingPathComponent(".metadata.json")
        self.metadata = ProjectMetadata(projects: [])
        
        NotificationCenter.default.addObserver(
            forName: .projectCloudIdCleared,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let cloudId = notification.userInfo?["cloudId"] as? String {
                Task { @MainActor in
                    self?.clearCloudInfo(forCloudId: cloudId)
                }
            }
        }
        
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        do {
            // 捕获需要用到的 URL，避免在 detached task 中访问 @MainActor 隔离的 self
            let projectsDir = self.projectsDirectory
            let metaFile = self.metadataFile
            
            let initialState = try await Task.detached(priority: .userInitiated) {
                try FileManager.default.createDirectory(at: projectsDir, withIntermediateDirectories: true)
                
                let loadedMetadata: ProjectMetadata
                if let data = try? Data(contentsOf: metaFile),
                   let decoded = try? JSONDecoder().decode(ProjectMetadata.self, from: data) {
                    loadedMetadata = decoded
                } else {
                    loadedMetadata = ProjectMetadata(projects: [])
                }
                
                let stubProjects = loadedMetadata.projects.map { info in
                    HTMLProject(
                        id: info.id,
                        name: info.name,
                        files: [ProjectFile(name: "index", content: HTMLProject.defaultHTML(), type: .html)],
                        createdAt: info.createdAt,
                        updatedAt: info.updatedAt
                    )
                }
                
                return (loadedMetadata, stubProjects)
            }.value
            
            let loadedMetadata = initialState.0
            var stubProjects = initialState.1
            
            // Migrate old documents if no projects exist
            if stubProjects.isEmpty {
                stubProjects = await migrateOldDocuments()
            }
            
            // Create default project if still empty
            if stubProjects.isEmpty {
                let defaultProject = HTMLProject.empty
                saveProjectToDisk(defaultProject)
                stubProjects.append(defaultProject)
            }
            
            await MainActor.run {
                self.projects = stubProjects
                self.currentProject = stubProjects.first
                self.currentFile = stubProjects.first?.mainFile
                self.metadata = loadedMetadata
                self.initializationStatus = .ready
                self.isReady = true
                HapticManager.shared.notificationSuccess()
            }
            
            // Lazy load actual project data in background
            Task { [weak self] in
                await self?.lazyLoadProjectData(loadedMetadata)
            }
            
        } catch {
            await MainActor.run {
                self.initializationStatus = .failed(error.localizedDescription)
            }
        }
    }
    
    private func lazyLoadProjectData(_ metadata: ProjectMetadata) async {
        for info in metadata.projects {
            await loadSingleProjectData(info.id)
        }
    }
    
    private func loadSingleProjectData(_ projectId: UUID) async {
        let projectDir = projectsDirectory.appendingPathComponent(projectId.uuidString)
        let projectMetaURL = projectDir.appendingPathComponent(".project.json")
        
        guard let data = try? Data(contentsOf: projectMetaURL),
              var project = try? JSONDecoder().decode(HTMLProject.self, from: data) else { return }
        
        let thumbnailURL = projectDir.appendingPathComponent(".thumbnail")
        project.thumbnailData = try? Data(contentsOf: thumbnailURL)
        
        await MainActor.run {
            if let index = self.projects.firstIndex(where: { $0.id == projectId }) {
                self.projects[index] = project
                if self.currentProject?.id == projectId {
                    self.currentProject = project
                }
            }
        }
    }
    
    private func loadProjectDataOnDemand(_ projectId: UUID) async {
        await loadSingleProjectData(projectId)
    }
    
    private func migrateOldDocuments() async -> [HTMLProject] {
        let oldDocsDir = projectsDirectory.deletingLastPathComponent().appendingPathComponent("HTMLDocuments")
        let oldMetaFile = oldDocsDir.appendingPathComponent(".metadata.json")
        
        guard let data = try? Data(contentsOf: oldMetaFile),
              let oldMeta = try? JSONDecoder().decode(OldDocumentMetadata.self, from: data) else {
            return []
        }
        
        var migrated: [HTMLProject] = []
        for info in oldMeta.documents {
            let fileURL = oldDocsDir.appendingPathComponent("\(info.id).html")
            guard let content = try? String(contentsOf: fileURL) else { continue }
            
            let project = HTMLProject(
                name: info.name,
                files: [ProjectFile(name: "index", content: content, type: .html)],
                createdAt: info.createdAt,
                updatedAt: info.updatedAt
            )
            saveProjectToDisk(project)
            migrated.append(project)
        }
        
        return migrated
    }
    
    private struct OldDocumentMetadata: Codable {
        var documents: [OldDocumentInfo]
        struct OldDocumentInfo: Codable {
            let id: UUID
            var name: String
            var createdAt: Date
            var updatedAt: Date
        }
    }
    
    // MARK: - Project Management
    
    func createNewProject(from template: HTMLTemplate? = nil) {
        if !SubscriptionManager.shared.canCreateProject(currentCount: projects.count) {
            SubscriptionManager.shared.showPaywall = true
            showToast("free_limit_reached".localized, type: .warning)
            return
        }
        
        let newProject = HTMLProject(
            name: template?.name ?? "Untitled",
            files: template?.files.map { ProjectFile(name: $0.name, content: $0.content, data: $0.data, type: $0.type) } ?? [
                ProjectFile(name: "index", content: HTMLProject.defaultHTML(), type: .html)
            ]
        )
        saveProjectToDisk(newProject)
        projects.insert(newProject, at: 0)
        currentProject = newProject
        currentFile = newProject.mainFile
        saveMetadata()
        showToast(String(format: "create_success".localized + ": %@", newProject.name), type: .success)
    }
    
    func duplicateProject(_ project: HTMLProject) {
        if !SubscriptionManager.shared.canCreateProject(currentCount: projects.count) {
            SubscriptionManager.shared.showPaywall = true
            showToast("free_limit_reached".localized, type: .warning)
            return
        }
        
        let newProject = HTMLProject(
            name: project.name + " (\("duplicate".localized))",
            files: project.files.map { ProjectFile(name: $0.name, content: $0.content, data: $0.data, type: $0.type) },
            createdAt: Date(),
            updatedAt: Date()
        )
        saveProjectToDisk(newProject)
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.insert(newProject, at: index + 1)
        } else {
            projects.insert(newProject, at: 0)
        }
        currentProject = newProject
        currentFile = newProject.mainFile
        saveMetadata()
        showToast(String(format: "duplicate_with_name".localized, newProject.name), type: .success)
    }
    
    func deleteProject(_ project: HTMLProject) {
        autosaveTask?.cancel()

        let action = UndoAction(
            type: .deleteProject,
            projectId: project.id,
            previousState: project,
            previousFileId: nil
        )
        pushUndo(action)

        // Delete cloud version if project is published
        if let cloudId = project.cloudId {
            Task {
                do {
                    try await CloudService.shared.deleteProject(cloudId, userId: UserManager.shared.userId)
                } catch {
                    // Cloud deletion failed, but continue with local deletion
                    print("Failed to delete cloud project: \(error)")
                }
            }
            // Also remove from PublishedProjectsManager
            PublishedProjectsManager.shared.removeProject(cloudId: cloudId)
        }

        projects.removeAll { $0.id == project.id }

        let projectDir = projectsDirectory.appendingPathComponent(project.id.uuidString)
        try? FileManager.default.removeItem(at: projectDir)

        if currentProject?.id == project.id {
            currentProject = projects.first
            currentFile = projects.first?.mainFile
        }

        saveMetadata()
        showToast(String(format: "deleted_with_name".localized, project.name), type: .info)
    }
    
    func updateProjectName(_ name: String) {
        guard var project = currentProject else { return }
        
        let action = UndoAction(
            type: .renameProject,
            projectId: project.id,
            previousState: project,
            previousFileId: nil
        )
        pushUndo(action)
        
        project.name = name
        project.updatedAt = Date()
        currentProject = project
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        }
        
        saveProjectToDisk(project)
        saveMetadata()
    }
    
    func toggleProjectFavorite(_ project: HTMLProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].toggleFavorite()
            saveProjectToDisk(projects[index])
            saveMetadata()
        }
    }
    
    func updateCloudInfo(projectId: UUID, url: String, cloudId: String, expiresAt: String? = nil) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else { return }
        projects[index].cloudUrl = url
        projects[index].cloudId = cloudId
        if let expiresStr = expiresAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            projects[index].expiresAt = formatter.date(from: expiresStr)
        }
        saveProjectToDisk(projects[index])
        saveMetadata()
        
        if currentProject?.id == projectId {
            currentProject = projects[index]
        }
    }
    
    func clearCloudInfo(forCloudId cloudId: String) {
        guard let index = projects.firstIndex(where: { $0.cloudId == cloudId }) else { return }
        projects[index].cloudUrl = nil
        projects[index].cloudId = nil
        projects[index].expiresAt = nil
        projects[index].visitCount = nil
        saveProjectToDisk(projects[index])
        saveMetadata()
        
        if currentProject?.id == projects[index].id {
            currentProject = projects[index]
        }
    }
    
    // MARK: - File Management
    
    func addFileToCurrentProject(name: String, content: String = "", type: ProjectFile.FileType) {
        guard var project = currentProject else { return }
        // Multi-file support is a Pro feature (free users limited to 3 files per project)
        if !SubscriptionManager.shared.isPro && project.files.count >= 3 {
            SubscriptionManager.shared.showPaywall = true
            showToast("pro_feature_multi_file".localized, type: .warning)
            return
        }
        let newFile = ProjectFile(name: name, content: content, type: type)
        project.addFile(newFile)
        
        updateProject(project)
        currentFile = newFile
        showToast(String(format: "add_file_success".localized, newFile.displayName), type: .success)
    }
    
    func removeFileFromCurrentProject(fileId: UUID) {
        guard var project = currentProject else { return }
        
        let action = UndoAction(
            type: .deleteFile,
            projectId: project.id,
            previousState: project,
            previousFileId: fileId
        )
        pushUndo(action)
        
        project.removeFile(id: fileId)
        
        updateProject(project)
        if currentFile?.id == fileId {
            currentFile = project.mainFile
        }
        showToast("deleted_file_success".localized, type: .info)
    }
    
    func renameFileInCurrentProject(fileId: UUID, to newName: String) {
        guard var project = currentProject else { return }
        
        let action = UndoAction(
            type: .renameFile,
            projectId: project.id,
            previousState: project,
            previousFileId: fileId
        )
        pushUndo(action)
        
        project.renameFile(id: fileId, to: newName)
        
        updateProject(project)
        if currentFile?.id == fileId {
            currentFile = project.files.first { $0.id == fileId }
        }
    }
    
    func updateCurrentFile(content: String) {
        guard var project = currentProject,
              let file = currentFile,
              let fileIndex = project.files.firstIndex(where: { $0.id == file.id }) else { return }
        
        if project.files[fileIndex].content == content { return }
        
        project.files[fileIndex].content = content
        project.files[fileIndex].updatedAt = Date()
        project.updatedAt = Date()
        
        updateProject(project)
        currentFile = project.files[fileIndex]
        
        // Update share server
        shareServer?.updateProject(project)
        
        scheduleAutosave()
    }
    
    func switchToFile(_ file: ProjectFile) {
        flushPendingSaves()
        currentFile = file
        // Remember last opened file
        if var project = currentProject {
            project.lastOpenedFileId = file.id
            updateProject(project)
        }
    }
    
    func switchToProject(_ project: HTMLProject) {
        flushPendingSaves()
        
        if project.files.count <= 1 && project.files.first?.content == HTMLProject.defaultHTML() {
            isProjectLoading = true
            Task {
                await loadProjectDataOnDemand(project.id)
                await MainActor.run {
                    if let loaded = self.projects.first(where: { $0.id == project.id }) {
                        self.currentProject = loaded
                        if let lastId = loaded.lastOpenedFileId,
                           let file = loaded.files.first(where: { $0.id == lastId }) {
                            self.currentFile = file
                        } else {
                            self.currentFile = loaded.mainFile
                        }
                    }
                    self.isProjectLoading = false
                }
            }
        } else {
            currentProject = project
            if let lastId = project.lastOpenedFileId,
               let file = project.files.first(where: { $0.id == lastId }) {
                currentFile = file
            } else {
                currentFile = project.mainFile
            }
        }
    }
    
    // MARK: - Import/Export
    
    func importHTML(from url: URL) {
        let ext = url.pathExtension.lowercased()
        if ext == "zip" || ext == "rar" {
            Task { await handleArchiveImport(url: url) }
            return
        }
        
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        do {
            let fileName = url.deletingPathExtension().lastPathComponent
            let actualFileName = url.lastPathComponent
            let type = ProjectFile.FileType.from(filename: actualFileName)
            
            let newFile: ProjectFile
            if type == .image || type == .font {
                let data = try Data(contentsOf: url)
                newFile = ProjectFile(name: actualFileName, data: data, type: type)
            } else {
                let content = try String(contentsOf: url)
                newFile = ProjectFile(name: actualFileName, content: content, type: type)
            }
            
            if let project = currentProject {
                var updated = project
                updated.addFile(newFile)
                updateProject(updated)
                currentFile = newFile
                showToast(String(format: "import_success_with_name".localized, newFile.displayName), type: .success)
            } else {
                let newProject = HTMLProject(name: fileName, files: [newFile])
                saveProjectToDisk(newProject)
                projects.insert(newProject, at: 0)
                currentProject = newProject
                currentFile = newProject.mainFile
                saveMetadata()
                showToast(String(format: "import_success_with_name".localized, newProject.name), type: .success)
            }
        } catch {
            showToast(String(format: "import_failed_with_name".localized, error.localizedDescription), type: .error)
        }
    }
    
    func importMultipleFiles(from urls: [URL]) {
        var projectFiles: [ProjectFile] = []
        var projectName: String?
        
        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            
            let fileName = url.deletingPathExtension().lastPathComponent
            let actualFileName = url.lastPathComponent
            let type = ProjectFile.FileType.from(filename: actualFileName)
            
            if type == .image || type == .font {
                if let data = try? Data(contentsOf: url) {
                    projectFiles.append(ProjectFile(name: actualFileName, data: data, type: type))
                }
            } else {
                projectFiles.append(ProjectFile(name: actualFileName, content: content, type: type))
            }
            
            if projectName == nil {
                projectName = fileName
            }
        }
        
        guard !projectFiles.isEmpty else {
            showToast("import_failed".localized, type: .error)
            return
        }
        
        if let project = currentProject {
            var updated = project
            for file in projectFiles {
                updated.addFile(file)
            }
            updateProject(updated)
            currentFile = projectFiles.first
            showToast(String(format: "import_success_count".localized, projectFiles.count), type: .success)
        } else {
            let newProject = HTMLProject(name: projectName ?? "Untitled", files: projectFiles)
            saveProjectToDisk(newProject)
            projects.insert(newProject, at: 0)
            currentProject = newProject
            currentFile = newProject.mainFile
            saveMetadata()
            showToast(String(format: "import_success_count".localized, projectFiles.count), type: .success)
        }
    }
    
    private func handleArchiveImport(url: URL) async {
        // ZIP import is a Pro feature
        if !SubscriptionManager.shared.isPro {
            SubscriptionManager.shared.showPaywall = true
            showToast("pro_feature_zip_import".localized, type: .warning)
            return
        }

        let fm = FileManager.default
        
        // 1. 获取安全权限
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        // 2. 如果是 iCloud 文件，先触发下载并等待
        showToast("正在准备文件...", type: .info)
        
        // 检查是否是 iCloud 占位文件（未下载到本地）
        if let resourceValues = try? url.resourceValues(forKeys: [.ubiquitousItemIsDownloadingKey, .ubiquitousItemDownloadingStatusKey]) {
            let status = resourceValues.ubiquitousItemDownloadingStatus
            if status == .notDownloaded || status == .current {
                // 触发下载
                try? fm.startDownloadingUbiquitousItem(at: url)
                
                // 轮询等待下载完成（最多等 30 秒）
                showToast("iCloud 文件下载中，请稍候...", type: .info)
                var waited = 0
                while waited < 30 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 秒
                    waited += 1
                    if let vals = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
                       vals.ubiquitousItemDownloadingStatus == .current {
                        break // 下载完成
                    }
                    // 超时
                    if waited >= 30 {
                        showToast("iCloud 文件下载超时，请先在文件 App 中下载后再导入。", type: .error)
                        return
                    }
                }
            }
        }
        
        // 3. 使用 NSFileCoordinator 协调读取（处理 iCloud 并发）
        let tempCopyDir = fm.temporaryDirectory.appendingPathComponent("ZipCopy_\(UUID().uuidString)")
        let tempCopyURL = tempCopyDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            try fm.createDirectory(at: tempCopyDir, withIntermediateDirectories: true)
        } catch {
            showToast("无法创建临时目录：\(error.localizedDescription)", type: .error)
            return
        }
        
        // NSFileCoordinator 在后台线程执行，需要先离开 MainActor
        let copyResult: Result<Void, Error> = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var coordinatorError: NSError?
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinatorError) { readURL in
                    do {
                        // 直接使用 FileManager.default 避免捕获外部 fm 变量导致的 Sendable 警告
                        try FileManager.default.copyItem(at: readURL, to: tempCopyURL)
                        continuation.resume(returning: .success(()))
                    } catch {
                        continuation.resume(returning: .failure(error))
                    }
                }
                if let err = coordinatorError {
                    continuation.resume(returning: .failure(err))
                }
            }
        }
        
        switch copyResult {
        case .failure(let error):
            try? fm.removeItem(at: tempCopyDir)
            showToast("文件复制失败：\(error.localizedDescription)", type: .error)
            return
        case .success:
            break
        }
        
        defer { try? fm.removeItem(at: tempCopyDir) }
        
        // 4. 解压
        showToast("正在解压...", type: .info)
        let extractedDir: URL
        do {
            extractedDir = try ArchiveManager.shared.extractArchive(url: tempCopyURL)
        } catch {
            showToast("解压失败：\(error.localizedDescription)", type: .error)
            return
        }
        defer { try? fm.removeItem(at: extractedDir) }
        
        // 5. 扫描并收集文件
        let projectName = url.deletingPathExtension().lastPathComponent
        var projectFiles: [ProjectFile] = []
        
        let supportedExts = ["html", "htm", "css", "js", "json", "md", "txt",
                              "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp",
                              "ttf", "otf", "woff", "woff2"]
        
        let enumerator = fm.enumerator(
            at: extractedDir,
            includingPropertiesForKeys: [URLResourceKey.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            guard let vals = try? fileURL.resourceValues(forKeys: [URLResourceKey.isDirectoryKey]),
                  vals.isDirectory != true else { continue }
            
            let fileExt = fileURL.pathExtension.lowercased()
            guard supportedExts.contains(fileExt) else { continue }
            
            var relativePath = fileURL.path.replacingOccurrences(of: extractedDir.path, with: "")
            if relativePath.hasPrefix("/") { relativePath.removeFirst() }
            guard !relativePath.isEmpty else { continue }
            
            let type = ProjectFile.FileType.from(filename: fileURL.lastPathComponent)
            
            if type == .image || type == .font {
                if let data = try? Data(contentsOf: fileURL) {
                    projectFiles.append(ProjectFile(name: relativePath, data: data, type: type))
                }
            } else {
                let content = (try? String(contentsOf: fileURL, encoding: .utf8))
                              ?? (try? String(contentsOf: fileURL, encoding: .isoLatin1))
                              ?? ""
                projectFiles.append(ProjectFile(name: relativePath, content: content, type: type))
            }
        }
        
        if projectFiles.isEmpty {
            showToast("ZIP 中未找到支持的文件（HTML/CSS/JS/图片等）", type: .error)
            return
        }
        
        // 6. 创建项目
        let newProject = HTMLProject(name: projectName, files: projectFiles)
        saveProjectToDisk(newProject)
        projects.insert(newProject, at: 0)
        switchToProject(newProject)
        saveMetadata()
        showToast(String(format: "import_success_with_name".localized, newProject.name), type: .success)
    }
    
    func importImage(_ data: Data, name: String) {
        guard var project = currentProject else { return }
        let type = ProjectFile.FileType.from(filename: name)
        let newFile = ProjectFile(name: name, data: data, type: type)
        project.addFile(newFile)
        updateProject(project)
        currentFile = newFile
        showToast(String(format: "image_added_success".localized, name), type: .success)
    }
    
    func exportCurrentProject() -> URL? {
        guard let project = currentProject else { return nil }
        return exportProject(project)
    }
    
    func exportProject(_ project: HTMLProject) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Export")
            .appendingPathComponent(project.id.uuidString)
        
        try? FileManager.default.removeItem(at: tempDir)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for file in project.files {
            let fileURL = tempDir.appendingPathComponent(file.displayName)
            
            // 重要：创建父目录以支持嵌套路径
            let directoryURL = fileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            if let data = file.data {
                try? data.write(to: fileURL)
            } else {
                try? file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
        
        return tempDir
    }
    
    func prepareProjectForRunning(_ project: HTMLProject) -> (indexURL: URL, projectDir: URL)? {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Run")
            .appendingPathComponent(project.id.uuidString)
        
        // Ensure clean start
        try? FileManager.default.removeItem(at: tempDir)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        for file in project.files {
            let fileURL = tempDir.appendingPathComponent(file.displayName)
            
            // 重要：创建父目录以支持嵌套路径 (如 assets/logo.png)
            let directoryURL = fileURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            if let data = file.data {
                try? data.write(to: fileURL)
            } else {
                try? file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
        
        guard let mainFile = project.mainFile else { return nil }
        let indexURL = tempDir.appendingPathComponent(mainFile.displayName)
        return (indexURL, tempDir)
    }
    
    func exportAllProjects() -> [URL] {
        return projects.compactMap { exportProject($0) }
    }
    
    // MARK: - Persistence
    
    func updateProject(_ project: HTMLProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            currentProject = project
        }
    }
    
    func saveProjectToDisk(_ project: HTMLProject) {
        let projectDir = projectsDirectory.appendingPathComponent(project.id.uuidString)
        do {
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        } catch {
            showToast(String(format: "save_failed".localized, error.localizedDescription), type: .error)
            return
        }
        
        // Save project metadata
        let projectMetaURL = projectDir.appendingPathComponent(".project.json")
        do {
            let encoded = try JSONEncoder().encode(project)
            try encoded.write(to: projectMetaURL)
        } catch {
            showToast(String(format: "save_failed".localized, error.localizedDescription), type: .error)
            return
        }
        
        // Save thumbnail
        if let thumbnailData = project.thumbnailData {
            let thumbnailURL = projectDir.appendingPathComponent(".thumbnail")
            try? thumbnailData.write(to: thumbnailURL)
        }
    }
    
    func saveMetadata() {
        metadata.projects = projects.map { project in
            ProjectMetadata.ProjectInfo(
                id: project.id,
                name: project.name,
                createdAt: project.createdAt,
                updatedAt: project.updatedAt,
                hasThumbnail: project.thumbnailData != nil,
                isFavorite: project.isFavorite,
                fileCount: project.files.count
            )
        }
        
        if let encoded = try? JSONEncoder().encode(metadata) {
            try? encoded.write(to: metadataFile)
        }
    }
    
    func flushPendingSaves() {
        autosaveTask?.cancel()
        autosaveTask = nil
        
        guard let project = currentProject else { return }
        saveProjectToDisk(project)
        saveMetadata()
    }
    
    private func scheduleAutosave() {
        autosaveTask?.cancel()
        let autoSaveEnabled = UserDefaults.standard.bool(forKey: "autoSaveEnabled")
        if autoSaveEnabled == false { return }
        autosaveTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: autosaveDelayNanos)
            guard !Task.isCancelled else { return }
            
            if let project = self.currentProject {
                self.saveProjectToDisk(project)
                self.saveMetadata()
            }
        }
    }
    
    // MARK: - Thumbnail
    
    func saveThumbnail(_ thumbnailData: Data, for projectId: UUID) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].thumbnailData = thumbnailData
            saveProjectToDisk(projects[index])
            saveMetadata()
        }
    }
    
    func regenerateThumbnailForCurrentProject() {
        guard let project = currentProject else { return }
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].thumbnailData = nil
            let projectDir = projectsDirectory.appendingPathComponent(project.id.uuidString)
            let thumbnailURL = projectDir.appendingPathComponent(".thumbnail")
            try? FileManager.default.removeItem(at: thumbnailURL)
        }
    }
    
    func reinitialize() async {
        await initialize()
    }
    
    deinit {
        autosaveTask?.cancel()
    }

    private func showToast(_ message: String, type: ToastType) {
        toastItem = ToastItem(message: message, type: type)
        switch type {
        case .success: HapticManager.shared.notificationSuccess()
        case .error: HapticManager.shared.notificationError()
        case .warning: HapticManager.shared.notificationWarning()
        case .info: HapticManager.shared.lightImpact()
        }
    }
}
