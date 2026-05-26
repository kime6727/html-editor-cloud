import SwiftUI

struct FolderBrowserView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @State private var currentFolderId: UUID?
    @State private var showNewFolderSheet = false
    @State private var showAddFileSheet = false
    @State private var newFolderName = ""
    @State private var renamingFolderId: UUID?
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: FolderItem?
    @State private var movingFileId: UUID?
    @State private var showMoveSheet = false
    @FocusState private var isRenameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb navigation
            if !folderPath.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        Button(action: { currentFolderId = nil }) {
                            Image(systemName: "house")
                                .foregroundColor(.blue)
                        }
                        
                        ForEach(folderPath) { folder in
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: { currentFolderId = folder.id }) {
                                Text(folder.name)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
            }
            
            // Header
            HStack {
                Text(currentFolderName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(currentItems.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                
                Menu {
                    Button(action: { showNewFolderSheet = true }) {
                        Label("new_folder".localized, systemImage: "folder.badge.plus")
                    }
                    
                    Button(action: { showAddFileSheet = true }) {
                        Label("add_file_menu".localized, systemImage: "doc.badge.plus")
                    }
                    
                    Button(action: { documentManager.showFileImporter = true }) {
                        Label("import_asset".localized, systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            
            // Items list
            if currentItems.isEmpty {
                FileBrowserEmptyState()
            } else {
                List {
                    // Folders section
                    let folders = currentSubfolders
                    if !folders.isEmpty {
                        Section("folders_section".localized) {
                            ForEach(folders) { folder in
                                folderRow(folder)
                            }
                        }
                    }
                    
                    // Files section
                    let files = currentFiles
                    if !files.isEmpty {
                        Section("files_section".localized) {
                            ForEach(files) { file in
                                fileRow(file)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 220 : .infinity)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderSheet(folderName: $newFolderName) {
                createFolder()
            }
        }
        .sheet(isPresented: $showAddFileSheet) {
            AddFileSheet()
                .environmentObject(documentManager)
        }
        .sheet(isPresented: $showMoveSheet) {
            MoveFileSheet(fileId: $movingFileId, currentFolderId: $currentFolderId)
                .environmentObject(documentManager)
        }
        .onAppear {
            loadCurrentItems()
        }
        .onChange(of: documentManager.currentProject) { _, _ in
            currentFolderId = nil
            loadCurrentItems()
        }
    }
    
    // MARK: - Computed Properties
    
    var currentFolderName: String {
        if let folderId = currentFolderId,
           let folder = documentManager.currentProject?.folders.first(where: { $0.id == folderId }) {
            return folder.name
        }
        return "files".localized
    }
    
    var folderPath: [ProjectFolder] {
        guard let project = documentManager.currentProject,
              let folderId = currentFolderId else { return [] }
        return project.folderPath(for: folderId)
    }
    
    var currentSubfolders: [ProjectFolder] {
        guard let project = documentManager.currentProject else { return [] }
        return project.subfolders(of: currentFolderId)
    }
    
    var currentFiles: [ProjectFile] {
        guard let project = documentManager.currentProject else { return [] }
        return project.filesInFolder(folderId: currentFolderId)
    }
    
    var currentItems: [FolderItem] {
        var items: [FolderItem] = []
        
        items.append(contentsOf: currentSubfolders.map { folder in
            FolderItem(
                id: folder.id,
                name: folder.name,
                type: .folder,
                createdAt: folder.createdAt,
                updatedAt: folder.updatedAt,
                icon: "folder.fill",
                color: "#FFD700",
                isEditable: true
            )
        })
        
        items.append(contentsOf: currentFiles.map { file in
            FolderItem(
                id: file.id,
                name: file.displayName,
                type: .file(file.type),
                createdAt: file.createdAt,
                updatedAt: file.updatedAt,
                icon: file.type.icon,
                color: file.type.color,
                isEditable: file.type.isEditable
            )
        })
        
        return items
    }
    
    // MARK: - Views
    
    @ViewBuilder
    func folderRow(_ folder: ProjectFolder) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            if renamingFolderId == folder.id {
                TextField("folder_name_placeholder".localized, text: $renameText)
                    .focused($isRenameFocused)
                    .font(.system(size: 13))
                    .onSubmit {
                        confirmRenameFolder()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isRenameFocused = true
                        }
                    }
            } else {
                Text(folder.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            if renamingFolderId != folder.id {
                currentFolderId = folder.id
            }
        }
        .contextMenu {
            Button(action: {
                renamingFolderId = folder.id
                renameText = folder.name
            }) {
                Label("rename".localized, systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                itemToDelete = FolderItem(
                    id: folder.id,
                    name: folder.name,
                    type: .folder,
                    createdAt: folder.createdAt,
                    updatedAt: folder.updatedAt,
                    icon: "folder.fill",
                    color: "#FFD700",
                    isEditable: true
                )
                showDeleteConfirmation = true
            }) {
                Label("delete".localized, systemImage: "trash")
            }
        }
    }
    
    @ViewBuilder
    func fileRow(_ file: ProjectFile) -> some View {
        HStack(spacing: 8) {
            Image(systemName: file.type.icon)
                .font(.system(size: 14))
                .foregroundColor(colorForType(file.type))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(documentManager.currentFile?.id == file.id ? .white : .primary)
                    .lineLimit(1)
                
                Text(file.type.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(documentManager.currentFile?.id == file.id ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
            
            if documentManager.currentFile?.id == file.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            documentManager.currentFile?.id == file.id
            ? Color.blue
            : Color.clear
        )
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            documentManager.switchToFile(file)
        }
        .contextMenu {
            if file.type.isEditable {
                Button(action: {
                    documentManager.switchToFile(file)
                }) {
                    Label("open_file".localized, systemImage: "doc.text")
                }
            }
            
            Button(action: {
                movingFileId = file.id
                showMoveSheet = true
            }) {
                Label("move_to_folder".localized, systemImage: "folder")
            }
            
            Button(action: {
                documentManager.renameFileInCurrentProject(fileId: file.id, to: file.name)
            }) {
                Label("rename_file".localized, systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                itemToDelete = FolderItem(
                    id: file.id,
                    name: file.displayName,
                    type: .file(file.type),
                    createdAt: file.createdAt,
                    updatedAt: file.updatedAt,
                    icon: file.type.icon,
                    color: file.type.color,
                    isEditable: file.type.isEditable
                )
                showDeleteConfirmation = true
            }) {
                Label("delete".localized, systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    func loadCurrentItems() {
        // Refresh the view when project changes
    }
    
    func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        if var project = documentManager.currentProject {
            _ = project.addFolder(name: name, parentId: currentFolderId)
            documentManager.updateProject(project)
        }
        
        newFolderName = ""
        showNewFolderSheet = false
    }
    
    func confirmRenameFolder() {
        guard let folderId = renamingFolderId, !renameText.isEmpty else {
            renamingFolderId = nil
            return
        }
        
        if var project = documentManager.currentProject {
            project.renameFolder(id: folderId, to: renameText)
            documentManager.updateProject(project)
        }
        
        renamingFolderId = nil
    }
    
    func colorForType(_ type: ProjectFile.FileType) -> Color {
        switch type {
        case .html: return .orange
        case .css: return .blue
        case .javascript: return .yellow
        case .json: return .gray
        case .markdown: return .purple
        case .text: return .secondary
        case .image: return .green
        case .font: return .purple
        case .other: return .secondary
        }
    }
}

// MARK: - New Folder Sheet
struct NewFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var folderName: String
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("folder_info".localized) {
                    TextField("folder_name_placeholder".localized, text: $folderName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("new_folder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("create".localized) {
                        onCreate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Move File Sheet
struct MoveFileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @Binding var fileId: UUID?
    @Binding var currentFolderId: UUID?
    
    var body: some View {
        NavigationStack {
            List {
                Section("root_folder".localized) {
                    Button(action: {
                        moveFile(to: nil)
                    }) {
                        HStack {
                            Image(systemName: "house")
                            Text("root".localized)
                            Spacer()
                            if currentFolderId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if let project = documentManager.currentProject, !project.folders.isEmpty {
                    Section("folders_section".localized) {
                        ForEach(project.folders) { folder in
                            Button(action: {
                                moveFile(to: folder.id)
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                    Text(folder.name)
                                    Spacer()
                                    if currentFolderId == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("move_to_folder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
    }
    
    func moveFile(to folderId: UUID?) {
        guard let fileId = fileId else { return }
        
        if var project = documentManager.currentProject {
            project.moveFile(fileId: fileId, toFolderId: folderId)
            documentManager.updateProject(project)
        }
        
        dismiss()
    }
}
