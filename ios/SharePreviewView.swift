import SwiftUI

struct SharePreviewView: View {
    let projectId: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @StateObject private var server = LocalHTMLServer()
    @State private var showQRCode = true
    @State private var isSharing = false
    @State private var showCopySuccess = false
    @ObservedObject var cloudService = CloudService.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    private let cloudServiceActor = CloudService.shared
    private let subscriptionManagerActor = SubscriptionManager.shared
    @State private var showPublishResult = false
    @State private var publishingUrl = ""
    @State private var resultProject: HTMLProject? = nil
    @State private var showPublishConfig = false
    
    private var project: HTMLProject? {
        documentManager.currentProject?.id == projectId ? documentManager.currentProject : documentManager.projects.first { $0.id == projectId }
    }
    
    var body: some View {
        NavigationStack {
            if let project = project {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "doc.text.image")
                                    .font(.title2)
                                    .foregroundColor(Color("Color"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(project.name)
                                        .font(.headline)
                                    Text("\(project.files.count) \("files".localized)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            if showQRCode, let url = server.serverURL, let qrImage = QRCodeGenerator.generate(from: url) {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            
                            if let url = server.serverURL {
                                HStack(spacing: 12) {
                                    Text(url)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    
                                    Button(action: {
                                        UIPasteboard.general.string = url
                                        showCopySuccess = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showCopySuccess = false
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(Color("Color"))
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                
                                Text("qr_hint".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("starting_server_hint".localized)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        
                        if let cloudUrl = project.cloudUrl {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "cloud.fill")
                                        .foregroundColor(.blue)
                                    Text(safeLocalize("published_status"))
                                        .font(.headline)
                                }
                                
                                HStack(spacing: 12) {
                                    Text(cloudUrl)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    
                                    Button(action: {
                                        UIPasteboard.general.string = cloudUrl
                                        showCopySuccess = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showCopySuccess = false
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(Color("Color"))
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("files".localized)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(project.files) { file in
                                    HStack {
                                        Image(systemName: file.type.icon)
                                            .foregroundColor(fileTypeColor(file.type))
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(file.displayName)
                                                .font(.subheadline)
                                            Text(file.type.displayName)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(file.content.count) B")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .monospacedDigit()
                                    }
                                    .padding(.vertical, 8)
                                    
                                    if file.id != project.files.last?.id {
                                        Divider()
                                            .padding(.leading, 32)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                if server.isRunning {
                                    server.stopServer()
                                    isSharing = false
                                } else {
                                    server.startServer(with: project)
                                    isSharing = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: server.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                    Text(server.isRunning ? "stop_sharing".localized : "start_sharing".localized)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(server.isRunning ? Color.red : Color.green)
                                .cornerRadius(12)
                            }
                            
                            if let exportURL = documentManager.exportProject(project) {
                                ShareLink(item: exportURL) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("export_project".localized)
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color("Color"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color("Color").opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: { publishToCloud(project: project) }) {
                                HStack {
                                    Image(systemName: "icloud.and.arrow.up")
                                    Text(project.cloudUrl == nil ? safeLocalize("publish_cloud") : safeLocalize("update_cloud"))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Color"))
                                .cornerRadius(12)
                                .shadow(color: Color("Color").opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .padding(.top)
                }
                .navigationTitle("share_preview".localized)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("done".localized) { dismiss() }
                            .foregroundColor(Color("Color"))
                    }
                }
                .overlay(
                    Group {
                        if showCopySuccess {
                            VStack {
                                Spacer()
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("copied_to_clipboard".localized)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                )
                .onChange(of: project.files.map { $0.content }.joined()) { _, _ in
                    if server.isRunning {
                        server.startServer(with: project)
                    }
                }
                .onDisappear {
                    if server.isRunning {
                        server.stopServer()
                    }
                }
                .sheet(isPresented: $showPublishResult) {
                    if let project = self.resultProject {
                        PublishResultView(projectName: project.name, urlString: publishingUrl, project: project)
                            .environmentObject(documentManager)
                    }
                }
                .sheet(isPresented: $showPublishConfig) {
                    if let project = self.project {
                        PublishConfigView(project: project, isPresented: $showPublishConfig) { config in
                            performPublish(project: project, config: config)
                        }
                        .environmentObject(documentManager)
                    }
                }
            } else {
                VStack {
                    Text("project_not_found".localized)
                        .foregroundColor(.secondary)
                    Button("close".localized) { dismiss() }
                        .padding()
                        .foregroundColor(Color("Color"))
                }
                .navigationTitle("share_preview".localized)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func fileTypeColor(_ type: ProjectFile.FileType) -> Color {
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
    
    private func publishToCloud(project: HTMLProject) {
        let currentProject = self.project ?? project
        if let url = currentProject.cloudUrl {
            self.resultProject = currentProject
            self.publishingUrl = url
            self.showPublishResult = true
            return
        }
        
        // Check publish limit
        if !subscriptionManager.canPublish() {
            subscriptionManager.showPaywall = true
            return
        }
        
        // Show publish config first
        showPublishConfig = true
    }
    
    private func performPublish(project: HTMLProject, config: PublishConfig) {
        Task {
            let cs = cloudServiceActor
            if let result = await cs.publishProjectWithDetails(project, config: config) {
                await MainActor.run {
                    self.resultProject = project
                    self.publishingUrl = result.url
                    self.subscriptionManager.incrementPublishedCount()
                    PublishedProjectsManager.shared.addOrUpdate(project: project, result: result)
                    self.showPublishResult = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.documentManager.updateCloudInfo(projectId: project.id, url: result.url, cloudId: result.id)
                    }
                }
            }
        }
    }
}
