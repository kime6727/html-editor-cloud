import SwiftUI
import MessageUI

struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appRouter: AppRouter
    @AppStorage("enableSyntaxHighlight") private var enableSyntaxHighlight = true
    @AppStorage("enableLineNumbers") private var enableLineNumbers = true
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled = true
    @AppStorage("showConsole") private var showConsole = true
    @AppStorage("defaultDevice") private var defaultDevice: String = "iPhone"
    
    @ObservedObject var languageManager = LanguageManager.shared
    @State private var showResetAlert = false
    @State private var showAboutSheet = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        Form {
            Section("Editor Settings".localized) {
                Toggle("Syntax Highlighting".localized, isOn: $enableSyntaxHighlight)
                Toggle("Show Line Numbers".localized, isOn: $enableLineNumbers)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size".localized)
                        Spacer()
                        Text("\(Int(editorFontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $editorFontSize, in: 10...24, step: 1) {
                        Text("Font Size".localized)
                    } minimumValueLabel: {
                        Text("10")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("24")
                            .font(.caption)
                    }
                }
            }
            
            Section("preview".localized) {
                Toggle("Show Console".localized, isOn: $showConsole)
                
                Picker("Default Device".localized, selection: $defaultDevice) {
                    Text("iphone".localized).tag("iPhone")
                    Text("ipad".localized).tag("iPad")
                    Text("desktop".localized).tag("Desktop")
                }
            }
            
            Section("data_management".localized) {
                Toggle("Auto Save".localized, isOn: $autoSaveEnabled)
                    .tint(Color("Color"))
                
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Reset All Data".localized)
                    }
                }
            }
            
            Section("support".localized) {
                Button {
                    showAboutSheet = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color("Color"))
                        Text("about_app".localized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                
                Button {
                    contactUs()
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color("Color"))
                        Text("contact_us".localized)
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
                
                Button {
                    shareApp()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color("Color"))
                        Text("share_app".localized)
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
                
                Button {
                    rateApp()
                } label: {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(Color("Color"))
                        Text("rate_app".localized)
                        Spacer()
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section("legal_title".localized) {
                Button {
                    showPrivacyPolicy = true
                } label: {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(Color("Color"))
                        Text("privacy_policy".localized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)

                Button {
                    if let url = URL(string: AppConfig.userAgreementURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color("Color"))
                        Text("user_agreement".localized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            
            Section {
                HStack(spacing: 20) {
                    Button("terms_of_service".localized) {
                        if let url = URL(string: AppConfig.userAgreementURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    
                    Text("|")
                        .foregroundColor(.secondary.opacity(0.3))
                    
                    Button("privacy_policy".localized) {
                        if let url = URL(string: AppConfig.privacyPolicyURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("advanced_settings".localized)
        .alert("reset_confirm_title".localized, isPresented: $showResetAlert) {
            Button("cancel".localized, role: .cancel) {}
            Button("reset_data".localized, role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("reset_confirm_msg".localized)
        }
        .sheet(isPresented: $showAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
    
    private func resetAllData() {
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        UserDefaults.standard.removeObject(forKey: "enableSyntaxHighlight")
        UserDefaults.standard.removeObject(forKey: "enableLineNumbers")
        UserDefaults.standard.removeObject(forKey: "editorFontSize")
        UserDefaults.standard.removeObject(forKey: "autoSaveEnabled")
        UserDefaults.standard.removeObject(forKey: "showConsole")
        UserDefaults.standard.removeObject(forKey: "defaultDevice")
        
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("HTMLProjects") {
            try? FileManager.default.removeItem(at: docsDir)
        }
        
        if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("HTMLDocuments") {
            try? FileManager.default.removeItem(at: docsDir)
        }
        
        // 清除用户ID和订阅状态（让用户明确知道会重置）
        UserManager.shared.resetUserId()
        
        appRouter.showOnboarding = true
    }
    
    private func contactUs() {
        let email = "fengezhao@hotmail.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
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

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AdvancedSettingsView()
                .environmentObject(AppRouter())
        }
    }
}
