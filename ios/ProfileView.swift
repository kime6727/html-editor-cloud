import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var documentManager: DocumentManager
    
    @State private var activeSheet: ProfileSheet? = nil
    @ObservedObject private var userManager = UserManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var publishedManager = PublishedProjectsManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @State private var showCopiedAlert = false
    @State private var showServerTest = false
    @State private var logoTapCount = 0
    @State private var resetWorkItem: DispatchWorkItem?
    
    enum ProfileSheet: String, Identifiable {
        case publishedProjects, paywall
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button(action: {
                            resetWorkItem?.cancel()
                            
                            logoTapCount += 1
                            if logoTapCount >= 5 {
                                showServerTest = true
                                logoTapCount = 0
                                resetWorkItem = nil
                            } else {
                                let workItem = DispatchWorkItem {
                                    logoTapCount = 0
                                    resetWorkItem = nil
                                }
                                resetWorkItem = workItem
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
                            }
                        }) {
                            Image("Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .cornerRadius(10)
                                .shadow(color: Color("Color").opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("html_editor_pro".localized)
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                Text(userManager.userId)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = userManager.userId
                                    showCopiedAlert = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        showCopiedAlert = false
                                    }
                                }) {
                                    Image(systemName: showCopiedAlert ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(showCopiedAlert ? .green : Color("Color"))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if showCopiedAlert {
                        Text("copied_to_clipboard".localized)
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: showCopiedAlert)
                    }
                }
                .listRowBackground(Color.clear)
                
                Section {
                    Button(action: {
                        activeSheet = .paywall
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionManager.isPro ? "pro_activated".localized : "unlock_pro_title".localized)
                                    .font(.headline)
                                    .foregroundColor(subscriptionManager.isPro ? .green : .primary)
                                
                                Text(subscriptionManager.isPro ? "pro_activated_desc".localized : "upgrade_pro_desc".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !subscriptionManager.isPro {
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("cloud_management".localized) {
                    Button {
                        activeSheet = .publishedProjects
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("published_links".localized)
                                    .foregroundColor(.primary)
                                if publishedManager.publishedProjects.isEmpty {
                                    Text("no_published_yet".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(String(format: "published_count_desc".localized, publishedManager.publishedProjects.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section {
                    NavigationLink(destination: AdvancedSettingsView().environmentObject(appRouter)) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color("Color"))
                            Text("advanced_settings".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("language".localized) {
                    Picker("language".localized, selection: $languageManager.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    HStack(spacing: 20) {
                        Button("restore_purchases".localized) {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                    .foregroundColor(Color("Color"))
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .publishedProjects:
                    PublishedProjectsListView()
                        .environmentObject(documentManager)
                case .paywall:
                    SubscriptionView()
                }
            }
            .sheet(isPresented: $showServerTest) {
                ServerTestView()
                    .environmentObject(documentManager)
            }
        }
    }
    
    private func shareApp() {
        let appText = "share_app_text".localized
        let activityVC = UIActivityViewController(activityItems: [appText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id6764022927?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppRouter())
    }
}
