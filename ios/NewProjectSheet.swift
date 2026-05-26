import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @State private var projectName = ""
    @State private var selectedTemplate: HTMLTemplate?
    @State private var showTemplatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("project_info".localized) {
                    TextField("project_name".localized, text: $projectName)
                        .autocorrectionDisabled()
                    
                    if let template = selectedTemplate {
                        HStack {
                            Text("template".localized)
                            Spacer()
                            Text(template.name)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("quick_create".localized) {
                    Button(action: {
                        selectedTemplate = nil
                        createProject()
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(Color("Color"))
                            Text("blank_project".localized)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        selectedTemplate = HTMLTemplate.templates.first { $0.nameKey == "template_website_name" }
                        createProject()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.green)
                            Text("full_website".localized)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        selectedTemplate = HTMLTemplate.templates.first { $0.nameKey == "template_click_name" }
                        createProject()
                    }) {
                        HStack {
                            Image(systemName: "gamecontroller")
                                .foregroundColor(.orange)
                            Text("game_template".localized)
                            Spacer()
                        }
                    }
                }
                
                Section {
                    Button(action: { showTemplatePicker = true }) {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(Color("Color"))
                            Text("more_templates".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("new_project".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("create".localized) {
                        createProject()
                    }
                    .fontWeight(.semibold)
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty && selectedTemplate == nil)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView { template in
                    selectedTemplate = template
                    createProject()
                }
                .environmentObject(documentManager)
            }
        }
    }
    
    private func createProject() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        
        if let template = selectedTemplate {
            let newProject = HTMLProject(
                name: name.isEmpty ? template.name : name,
                files: template.files.map { ProjectFile(name: $0.name, content: $0.content, type: $0.type) }
            )
            documentManager.saveProjectToDisk(newProject)
            documentManager.projects.insert(newProject, at: 0)
            documentManager.currentProject = newProject
            documentManager.currentFile = newProject.mainFile
            documentManager.saveMetadata()
            documentManager.showSuccessMessage = "\("create_success".localized): \(newProject.name)"
        } else {
            documentManager.createNewProject()
            if !name.isEmpty, var project = documentManager.currentProject {
                project.name = name
                documentManager.updateProject(project)
                documentManager.saveProjectToDisk(project)
                documentManager.saveMetadata()
            }
        }
        
        dismiss()
    }
}

struct PasteCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @State private var pastedCode = ""
    @State private var projectName = ""
    @State private var detectedType: ProjectFile.FileType = .html
    
    var body: some View {
        NavigationStack {
            Form {
                Section("project_info".localized) {
                    TextField("\("project_name".localized) (\("optional".localized))", text: $projectName)
                        .autocorrectionDisabled()
                }
                
                Section("code".localized) {
                    TextEditor(text: $pastedCode)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 300)
                        .onChange(of: pastedCode) { _, newValue in
                            detectType(from: newValue)
                        }
                }
                
                Section("files".localized) {
                    Picker("template".localized, selection: $detectedType) {
                        ForEach(ProjectFile.FileType.allCases.filter { $0.isEditable }, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section {
                    Button(action: pasteFromClipboard) {
                        Label("paste_from_clipboard".localized, systemImage: "doc.on.clipboard")
                    }
                }
            }
            .navigationTitle("paste_code".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("create".localized) {
                        createFromPaste()
                    }
                    .fontWeight(.semibold)
                    .disabled(pastedCode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func detectType(from code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("<") {
            detectedType = .html
        } else if trimmed.contains("{") && trimmed.contains("}") {
            if trimmed.contains("function") || trimmed.contains("const") || trimmed.contains("let") || trimmed.contains("var") {
                detectedType = .javascript
            } else {
                detectedType = .json
            }
        } else if trimmed.contains("body") || trimmed.contains(".") && trimmed.contains("{") {
            detectedType = .css
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboard = UIPasteboard.general.string {
            pastedCode = clipboard
        }
    }
    
    private func createFromPaste() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        let fileName = detectedType == .html ? "index" : "main"
        
        let project = HTMLProject(
            name: name.isEmpty ? "pasted_project".localized : name,
            files: [ProjectFile(name: fileName, content: pastedCode, type: detectedType)]
        )
        
        documentManager.saveProjectToDisk(project)
        documentManager.projects.insert(project, at: 0)
        documentManager.currentProject = project
        documentManager.currentFile = project.mainFile
        documentManager.saveMetadata()
        documentManager.showSuccessMessage = "create_success".localized
        
        dismiss()
    }
}
