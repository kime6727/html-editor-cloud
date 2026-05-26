import SwiftUI

struct EnhancedPublishResultView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    let project: HTMLProject
    let result: PublishResult
    @Binding var isPresented: Bool
    
    @State private var showShareSheet = false
    @State private var showQRCode = false
    @State private var showStatsDetail = false
    
    var currentUrl: String {
        result.url
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Animation
                    successHeader
                    
                    // QR Code
                    qrCodeSection
                    
                    // URL Display
                    urlDisplay
                    
                    // Quick Actions
                    quickActions
                    
                    // Tips
                    tipsSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("publish_success".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: currentUrl) {
                    ActivityViewController(activityItems: [url, project.name])
                }
            }
            .fullScreenCover(isPresented: $showQRCode) {
                QRCodeFullScreenView(url: currentUrl, isPresented: $showQRCode)
            }
        }
    }
    
    // MARK: - Success Header
    private var successHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("publish_success_title".localized)
                    .font(.title2.bold())
                
                Text(String(format: "publish_success_subtitle".localized, project.name))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - QR Code Section
    private var qrCodeSection: some View {
        VStack(spacing: 12) {
            Button(action: { showQRCode = true }) {
                if let qrImage = QRCodeGenerator.generate(from: currentUrl) {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            
            Text("tap_qr_enlarge".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - URL Display
    private var urlDisplay: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                
                Text(currentUrl)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if let expiresAt = result.expiresAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(String(format: "expires_at_format".localized, expiresAt))
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(spacing: 12) {
            Text("quick_actions".localized)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                quickActionButton(icon: "doc.on.doc", title: "copy_link".localized, color: .blue) {
                    UIPasteboard.general.string = currentUrl
                    documentManager.toastItem = ToastItem(message: "copied".localized, type: .success)
                }
                
                quickActionButton(icon: "square.and.arrow.up", title: "share".localized, color: .green) {
                    showShareSheet = true
                }
                
                quickActionButton(icon: "safari", title: "open_browser".localized, color: .orange) {
                    if let url = URL(string: currentUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("tips".localized, systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 8) {
                tipItem(icon: "qrcode", text: "tip_qr_share".localized)
                tipItem(icon: "chart.bar.fill", text: "tip_view_stats".localized)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func tipItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
