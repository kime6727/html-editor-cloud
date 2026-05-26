import SwiftUI
import WebKit

struct FullScreenPreviewView: View {
    let project: HTMLProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    @State private var selectedDevice: DeviceType = .iphone
    @State private var isLandscape = false
    @State private var showConsole = false
    @State private var isLoading = false
    @State private var consoleMessages: [HTMLPreviewView.ConsoleMessage] = []
    @State private var scale: CGFloat = 1.0
    @State private var useDeviceFrame = true
    @State private var showControls = true
    @State private var autoHideTimer: Timer?
    @ObservedObject var cloudService = CloudService.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @ObservedObject var ratingManager = RatingManager.shared
    @State private var showPublishResult = false
    @State private var publishingUrl = ""
    @State private var resultProject: HTMLProject? = nil
    @State private var publishResult: PublishResult? = nil
    @State private var showShareSheet = false
    @State private var snapshotImage: UIImage?
    @State private var showSnapshotToast = false
    @State private var showPublishConfig = false
    @State private var showPublishError = false
    @State private var publishErrorMessage = ""
    @State private var publishingProjectId: UUID?
    
    private var liveProject: HTMLProject {
        documentManager.projects.first { $0.id == project.id } ?? project
    }
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            
            MultiFileWebView(
                project: project,
                isLoading: $isLoading,
                consoleMessages: $consoleMessages
            )
            .ignoresSafeArea()
            
            // Top controls
            VStack {
                HStack {
                    // Close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Screenshot button
                    Button(action: { captureSnapshot() }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.2)))
                            .shadow(radius: 4)
                    }
                    
                    // Cloud publish button
                    Button(action: { publishProject() }) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.2)))
                            .shadow(radius: 4)
                    }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Snapshot toast
            if showSnapshotToast {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("snapshot_captured".localized)
                            .font(.subheadline)
                        Spacer()
                        Button("share".localized) {
                            showShareSheet = true
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Rating prompt overlay
            if ratingManager.showRatingPrompt {
                RatingPromptView(isPresented: $ratingManager.showRatingPrompt)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .sheet(isPresented: $showPublishResult) {
            if let p = resultProject {
                PublishResultView(
                    projectName: p.name,
                    urlString: p.cloudUrl ?? publishingUrl,
                    project: p,
                    publishResult: publishResult
                )
                .environmentObject(documentManager)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showPublishConfig) {
            if let p = resultProject ?? documentManager.projects.first(where: { $0.id == project.id }) {
                PublishConfigView(project: p, isPresented: $showPublishConfig) { config in
                    performPublish(project: p, config: config)
                }
                .environmentObject(documentManager)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = snapshotImage {
                ShareSheet(activityItems: [image, "\(liveProject.name) - HTML Preview"])
            }
        }
        .onAppear {
            ratingManager.incrementRunCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClosePreview"))) { _ in
            dismiss()
        }
    }
    
    @ViewBuilder
    var previewContent: some View {
        MultiFileWebView(
            project: project,
            isLoading: $isLoading,
            consoleMessages: $consoleMessages
        )
    }
    
    private func captureSnapshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        
        snapshotImage = image
        showSnapshotToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showSnapshotToast = false
            }
        }
    }
    
    private func publishProject() {
        let currentProject = liveProject

        if currentProject.cloudUrl != nil {
            resultProject = currentProject
            publishingUrl = currentProject.cloudUrl ?? ""
            DispatchQueue.main.async {
                self.showPublishResult = true
            }
            return
        }
        
        // 检查发布限制
        if !subscriptionManager.canPublish() {
            subscriptionManager.showPaywall = true
            return
        }
        
        // 所有用户都可以发布，免费用户默认5分钟过期
        resultProject = currentProject
        showPublishConfig = true
    }
    
    private func performPublish(project: HTMLProject, config: PublishConfig) {
        publishingProjectId = project.id
        Task {
            let result = await cloudService.publishProjectWithDetails(project, config: config)
            
            await MainActor.run {
                if let result = result, !result.url.isEmpty {
                    let currentProject = documentManager.projects.first { $0.id == project.id } ?? project
                    self.resultProject = currentProject
                    self.publishingUrl = result.url
                    self.publishResult = result
                    self.subscriptionManager.incrementPublishedCount()
                    self.showPublishResult = true
                    self.showPublishError = false
                    
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
                    self.publishingProjectId = nil
                }
            }
        }
    }
}


