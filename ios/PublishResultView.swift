import SwiftUI

struct PublishResultView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    let projectName: String
    @State var urlString: String
    var project: HTMLProject?
    var publishResult: PublishResult?
    
    @ObservedObject private var cloudService = CloudService.shared
    private let cloudServiceActor = CloudService.shared
    @State private var qrImage: UIImage?
    @State private var showCopyToast = false
    @State private var isUpdating = false
    @State private var showShareSheet = false
    
    var currentUrl: String {
        urlString
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code
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
                            
                            Text(safeLocalize("cloud_qr_hint"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // URL Display
                    VStack(spacing: 12) {
                        Text(projectName)
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
                        
                        if let expiresAt = publishResult?.expiresAt {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("expires_at".localized + " " + expiresAt)
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                        }
                    }
                    
                    // Stats Preview
                    if let visitCount = project?.visitCount, visitCount > 0 {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "eye")
                                Text("\(visitCount)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Actions
                    VStack(spacing: 12) {
                        if let project = project {
                            Button(action: { updateCloud(project) }) {
                                HStack {
                                    if isUpdating {
                                        ProgressView().tint(.white).padding(.trailing, 8)
                                    } else {
                                        Image(systemName: "icloud.and.arrow.up")
                                    }
                                    Text(updateCloudLabel)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("Color"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isUpdating)
                        }
                        
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
            .navigationTitle(LanguageManager.shared.selectedLanguage == .en ? "Publish Preview" : "分享预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                }
            }
            .onAppear {
                if urlString.isEmpty {
                    urlString = project?.cloudUrl ?? ""
                }
                if !urlString.isEmpty {
                    generateQRCode()
                }
            }
            .onChange(of: project?.cloudUrl) { oldValue, newValue in
                if let newUrl = newValue, !newUrl.isEmpty {
                    self.urlString = newUrl
                    generateQRCode()
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: currentUrl) {
                    ShareSheet(activityItems: [url, projectName])
                }
            }
            .overlay(
                ToastOverlay(isPresented: $showCopyToast, message: "copy_success".localized)
            )
        }
    }
    
    private var updateCloudLabel: String {
        let key = "update_cloud"
        let localized = key.localized
        if localized == key {
            return LanguageManager.shared.selectedLanguage == .en ? "Update Cloud" : (LanguageManager.shared.selectedLanguage == .zhHans ? "更新云端内容" : "更新雲端內容")
        }
        return localized
    }
    
    private func generateQRCode() {
        qrImage = QRCodeGenerator.generate(from: currentUrl, size: CGSize(width: 440, height: 440))
    }
    
    private func updateCloud(_ project: HTMLProject) {
        isUpdating = true
        Task {
            let cs = cloudServiceActor
            // Preserve existing publish config when updating
            let config = PublishConfig(
                expireDays: 0, // 0 means keep existing expiry on server
                enableStats: true,
                accessPassword: nil // nil means don't change password on server
            )
            if let result = await cs.publishProjectWithDetails(project, config: config) {
                await MainActor.run {
                    self.urlString = result.url
                    self.documentManager.updateCloudInfo(
                        projectId: project.id,
                        url: result.url,
                        cloudId: result.id,
                        expiresAt: result.expiresAt
                    )
                    self.isUpdating = false
                    generateQRCode()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } else {
                await MainActor.run { self.isUpdating = false }
            }
        }
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
}

struct ToastOverlay: View {
    @Binding var isPresented: Bool
    let message: String
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                Text(message)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
