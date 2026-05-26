import SwiftUI

struct GitHubConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var githubService = GitHubPublishService.shared
    
    @State private var username: String = ""
    @State private var repo: String = ""
    @State private var token: String = ""
    @State private var branch: String = "main"
    @State private var isValidating = false
    @State private var showValidationResult = false
    @State private var validationSuccess = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("github_repo_info".localized), footer: Text("github_repo_hint".localized)) {
                    HStack {
                        Text("username".localized)
                        Spacer()
                        TextField("your_username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Text("repository".localized)
                        Spacer()
                        TextField("your_repo", text: $repo)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Text("branch".localized)
                        Spacer()
                        TextField("main", text: $branch)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                Section(header: Text("access_token".localized), footer: Text("github_token_hint".localized)) {
                    SecureField("ghp_xxxxxxxxxxxx", text: $token)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: validateAndSave) {
                        HStack {
                            Spacer()
                            if isValidating {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("validate_and_save".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isValidating || username.isEmpty || repo.isEmpty || token.isEmpty)
                }
                
                if githubService.isConfigured {
                    Section {
                        Button(role: .destructive, action: clearConfig) {
                            HStack {
                                Spacer()
                                Text("clear_configuration".localized)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section("help".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("github_help_1".localized)
                        Text("github_help_2".localized)
                        Text("github_help_3".localized)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("github_pages".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if githubService.isConfigured {
                        Button("done".localized) { dismiss() }
                            .foregroundColor(Color("Color"))
                    }
                }
            }
            .alert(validationSuccess ? "validation_success".localized : "validation_failed".localized, isPresented: $showValidationResult) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                if githubService.isConfigured {
                    username = githubService.githubUsername ?? ""
                    repo = githubService.githubRepo ?? ""
                    branch = githubService.githubBranch
                }
            }
        }
    }
    
    private func validateAndSave() {
        isValidating = true
        
        Task {
            do {
                githubService.saveConfiguration(username: username, repo: repo, token: token, branch: branch)
                
                let isValid = try await githubService.validateConfiguration()
                
                await MainActor.run {
                    isValidating = false
                    validationSuccess = isValid
                    validationMessage = isValid ? "github_config_success".localized : "github_config_failed".localized
                    showValidationResult = true
                    
                    if isValid {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationSuccess = false
                    validationMessage = error.localizedDescription
                    showValidationResult = true
                }
            }
        }
    }
    
    private func clearConfig() {
        githubService.clearConfiguration()
        username = ""
        repo = ""
        token = ""
        branch = "main"
    }
}
