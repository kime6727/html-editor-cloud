import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @EnvironmentObject var appRouter: AppRouter
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Projects List
            ProjectBrowserView(isPresented: .constant(false))
                .tabItem {
                    Label("projects".localized, systemImage: "folder.fill")
                }
                .tag(0)
            
            // Profile
            ProfileView()
                .environmentObject(appRouter)
                .environmentObject(documentManager)
                .tabItem {
                    Label("profile".localized, systemImage: "person.fill")
                }
                .tag(1)
        }
        .accentColor(Color("Color"))
    }
}

struct SettingsTabView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var documentManager: DocumentManager
    @State private var activeSheet: SettingsSheet? = nil
    @AppStorage("enableSyntaxHighlight") private var enableSyntaxHighlight = true
    @AppStorage("enableLineNumbers") private var enableLineNumbers = true
    @AppStorage("editorFontSize") private var editorFontSize: Double = 14
    @AppStorage("autoSaveEnabled") private var autoSaveEnabled = true
    
    enum SettingsSheet: String, Identifiable {
        case privacy, terms, about
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("editor_section".localized)) {
                    Toggle("syntax_highlighting".localized, isOn: $enableSyntaxHighlight)
                    Toggle("show_line_numbers".localized, isOn: $enableLineNumbers)
                    Toggle("auto_save".localized, isOn: $autoSaveEnabled)
                    
                    HStack {
                        Text("font_size".localized)
                        Spacer()
                        Text("\(Int(editorFontSize))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $editorFontSize, in: 10...24, step: 1)
                }
                
                Section(header: Text("data_section".localized)) {
                    HStack {
                        Text("projects_count".localized)
                        Spacer()
                        Text("\(documentManager.projects.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { documentManager.createNewProject() }) {
                        Label("new_project".localized, systemImage: "doc.badge.plus")
                    }
                    
                    if !documentManager.projects.isEmpty {
                        let urls = documentManager.exportAllProjects()
                        if !urls.isEmpty {
                            ShareLink(items: urls) {
                                Label("export_all".localized, systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
                
                Section(header: Text("about_section".localized)) {
                    Button(action: { activeSheet = .about }) {
                        Label("about_app".localized, systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("user_id".localized)
                        Spacer()
                        Text(UserManager.shared.userId)
                            .foregroundColor(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                Section(header: Text("legal_title".localized)) {
                    Button(action: { activeSheet = .privacy }) {
                        Label("privacy_policy".localized, systemImage: "hand.raised.fill")
                    }
                    
                    Button(action: { activeSheet = .terms }) {
                        Label("terms_of_service".localized, systemImage: "doc.text.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive, action: resetOnboarding) {
                        Label("reset_onboarding".localized, systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("settings".localized)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .privacy:
                    PrivacyPolicyView()
                case .terms:
                    TermsOfServiceView()
                case .about:
                    AboutView()
                }
            }
        }
    }
    
    private func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        appRouter.showOnboarding = true
    }
}

// MARK: - Terms of Service View
struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("terms_of_service".localized)
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Group {
                        SectionTitle("tos_s1_title".localized)
                        Text("tos_s1_desc".localized)
                        
                        SectionTitle("tos_s2_title".localized)
                        Text("tos_s2_desc".localized)

                        SectionTitle("tos_s3_title".localized)
                        Text("tos_s3_desc".localized)

                        SectionTitle("tos_s4_title".localized)
                        Text("tos_s4_desc".localized)

                        SectionTitle("tos_s5_title".localized)
                        Text("tos_s5_desc".localized)

                        SectionTitle("tos_s6_title".localized)
                        Text("tos_s6_desc".localized)

                        SectionTitle("tos_s7_title".localized)
                        Text("tos_s7_desc".localized)

                        SectionTitle("tos_s8_title".localized)
                        Text("tos_s8_desc".localized)
                    }
                    .padding(.bottom, 8)
                    
                    Text("\("last_updated".localized)：2026-04")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("privacy_policy_title".localized)
                        .font(.title.bold())
                        .padding(.bottom, 8)
                    
                    Group {
                        SectionTitle("privacy_s1_title".localized)
                        Text("privacy_s1_desc".localized)
                        
                        SectionTitle("privacy_s2_title".localized)
                        Text("privacy_s2_desc".localized)

                        SectionTitle("privacy_s3_title".localized)
                        Text("privacy_s3_desc".localized)

                        SectionTitle("privacy_s4_title".localized)
                        Text("privacy_s4_desc".localized)

                        SectionTitle("privacy_s5_title".localized)
                        Text("privacy_s5_desc".localized)

                        SectionTitle("privacy_s6_title".localized)
                        Text("privacy_s6_desc".localized)

                        SectionTitle("privacy_s7_title".localized)
                        Text("privacy_s7_desc".localized)

                        SectionTitle("privacy_s8_title".localized)
                        Text("privacy_s8_desc".localized)
                    }
                    .padding(.bottom, 8)
                    
                    Text("\("last_updated".localized)：2026-04")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Code Editor – HTML & Preview")
                        .font(.title2.bold())
                    
                    Text("\("version".localized) 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("about_description".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    if let url = URL(string: "https://page.niceapp.eu.cc/apps/code_editor/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("visit_official_website".localized)
                        .font(.subheadline.bold())
                        .foregroundColor(Color("Color"))
                }
                
                Spacer()
                
                Text("© 2026 \("copyright".localized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) { dismiss() }
                        .foregroundColor(Color("Color"))
                }
            }
        }
    }
}

// MARK: - Editor Tab View
struct EditorTabView: View {
    @EnvironmentObject var documentManager: DocumentManager
    
    var body: some View {
        Group {
            if documentManager.currentProject != nil {
                NavigationStack {
                    ContentView()
                }
            } else {
                EmptyEditorView()
            }
        }
    }
}

// MARK: - Empty Editor View
struct EmptyEditorView: View {
    @EnvironmentObject var documentManager: DocumentManager
    @State private var activeSheet: EditorSheet? = nil
    
    enum EditorSheet: String, Identifiable {
        case newProject, templatePicker
        
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("Color").opacity(0.1), Color("Color").opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 50))
                        .foregroundStyle(Color("Color"))
                }
                
                VStack(spacing: 8) {
                    Text("no_projects".localized)
                        .font(.title2.bold())
                    
                    Text("create_or_select".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Button(action: { activeSheet = .newProject }) {
                        Label("new_project".localized, systemImage: "doc.badge.plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Color"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: { activeSheet = .templatePicker }) {
                        Label("template".localized, systemImage: "square.on.square")
                            .font(.headline)
                            .foregroundColor(Color("Color"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("Color").opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("editor_title".localized)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newProject:
                    NewProjectSheet()
                        .environmentObject(documentManager)
                case .templatePicker:
                    TemplatePickerView()
                        .environmentObject(documentManager)
                }
            }
        }
    }
}

struct SectionTitle: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
}
