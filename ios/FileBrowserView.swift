import SwiftUI

struct FileBrowserView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @State private var showAddFileSheet = false
    @State private var renamingFileId: UUID?
    @State private var renameText = ""
    @State private var showDeleteConfirmation = false
    @State private var fileToDelete: ProjectFile?
    @FocusState private var isRenameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("files".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(documentManager.currentProject?.files.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                
                Menu {
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
            
            // File list
            if let project = documentManager.currentProject {
                List {
                    Section("html_files_section".localized) {
                        ForEach(project.htmlFiles) { file in
                            fileRow(file)
                        }
                    }
                    
                    if !project.codeFiles.filter({ $0.type != .html }).isEmpty {
                        Section("code_files_section".localized) {
                            ForEach(project.codeFiles.filter({ $0.type != .html })) { file in
                                fileRow(file)
                            }
                        }
                    }
                    
                    if !project.assetFiles.isEmpty {
                        Section("assets_section".localized) {
                            ForEach(project.assetFiles) { file in
                                fileRow(file)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                Spacer()
                Text("no_project_selected".localized)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 220 : .infinity)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAddFileSheet) {
            AddFileSheet()
                .environmentObject(documentManager)
        }
    }
    
    @ViewBuilder
    func fileRow(_ file: ProjectFile) -> some View {
        HStack(spacing: 8) {
            Image(systemName: file.type.icon)
                .font(.system(size: 14))
                .foregroundColor(colorForType(file.type))
                .frame(width: 24)
            
            if renamingFileId == file.id {
                TextField("file_name_placeholder".localized, text: $renameText)
                    .focused($isRenameFocused)
                    .font(.system(size: 13))
                    .onSubmit {
                        confirmRename()
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isRenameFocused = true
                        }
                    }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(documentManager.currentFile?.id == file.id ? .white : .primary)
                        .lineLimit(1)
                    
                    Text(file.type.displayName)
                        .font(.system(size: 10))
                        .foregroundColor(documentManager.currentFile?.id == file.id ? .white.opacity(0.7) : .secondary)
                }
            }
            
            Spacer()
            
            if documentManager.currentFile?.id == file.id && renamingFileId != file.id {
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
            if renamingFileId != file.id {
                documentManager.switchToFile(file)
            }
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
                renamingFileId = file.id
                renameText = file.name
            }) {
                Label("rename_file".localized, systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                fileToDelete = file
                showDeleteConfirmation = true
            }) {
                Label("delete".localized, systemImage: "trash")
            }
        }
        .alert("delete_file_title".localized, isPresented: $showDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) {
                fileToDelete = nil
            }
            Button("delete".localized, role: .destructive) {
                if let file = fileToDelete {
                    documentManager.removeFileFromCurrentProject(fileId: file.id)
                }
                fileToDelete = nil
            }
        } message: {
            if let file = fileToDelete {
                Text(String(format: "delete_confirm_msg".localized, file.displayName))
            }
        }
    }
    
    func confirmRename() {
        guard let fileId = renamingFileId, !renameText.isEmpty else {
            renamingFileId = nil
            return
        }
        documentManager.renameFileInCurrentProject(fileId: fileId, to: renameText)
        renamingFileId = nil
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

// MARK: - Add File Sheet
struct AddFileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @State private var fileName = ""
    @State private var selectedType: ProjectFile.FileType = .html
    
    var body: some View {
        NavigationStack {
            Form {
                Section("file_info".localized) {
                    TextField("file_name_no_ext_placeholder".localized, text: $fileName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Picker("file_type".localized, selection: $selectedType) {
                        ForEach(ProjectFile.FileType.allCases.filter { $0 != .image && $0 != .other }, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section {
                    Text(String(format: "file_will_be_created".localized, fileName, selectedType.rawValue))
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("add_file_menu".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("create".localized) {
                        createFile()
                    }
                    .fontWeight(.semibold)
                    .disabled(fileName.isEmpty)
                }
            }
        }
    }
    
    func createFile() {
        let name = fileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let content = defaultContentForType(selectedType)
        documentManager.addFileToCurrentProject(name: name, content: content, type: selectedType)
        dismiss()
    }
    
    func defaultContentForType(_ type: ProjectFile.FileType) -> String {
        let lang = LanguageManager.shared.selectedLanguage.rawValue
        switch type {
        case .html:
            return """
            <!DOCTYPE html>
            <html lang="\(lang)">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>New Page</title>
            </head>
            <body>
                <h1>New Page</h1>
            </body>
            </html>
            """
        case .css:
            return """
            \("default_css_comment".localized)
            
            body {
                font-family: -apple-system, sans-serif;
            }
            """
        case .javascript:
            return """
            \("default_js_comment".localized)
            
            console.log('Hello World!');
            """
        case .json:
            return """
            {
              "name": "example",
              "version": "1.0.0"
            }
            """
        case .markdown:
            return "default_md_content".localized
        case .text, .image, .font, .other:
            return ""
        }
    }
}
