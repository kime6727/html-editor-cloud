import Foundation
import CryptoKit
import Security

@MainActor
class GitHubPublishService: ObservableObject {
    static let shared = GitHubPublishService()
    
    @Published var isConfigured: Bool = false
    @Published var githubUsername: String? = nil
    @Published var githubRepo: String? = nil
    @Published var githubBranch: String = "main"
    @Published private var githubTokenData: Data? = nil
    
    private let keychainService = "com.htmleditor.github_token"
    private let keychainAccount = "github_access_token"
    
    private init() {
        isConfigured = UserDefaults.standard.bool(forKey: "github_configured")
        githubUsername = UserDefaults.standard.string(forKey: "github_username")
        githubRepo = UserDefaults.standard.string(forKey: "github_repo")
        githubBranch = UserDefaults.standard.string(forKey: "github_branch") ?? "main"
        githubTokenData = loadTokenFromKeychain()
        
        migrateTokenFromUserDefaults()
    }
    
    private func loadTokenFromKeychain() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func saveTokenToKeychain(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    private func migrateTokenFromUserDefaults() {
        if let oldData = UserDefaults.standard.data(forKey: "github_token") {
            saveTokenToKeychain(oldData)
            UserDefaults.standard.removeObject(forKey: "github_token")
            githubTokenData = oldData
        }
    }
    
    var hasAccessToken: Bool {
        return accessToken != nil
    }
    
    var accessToken: String? {
        get {
            guard let data = githubTokenData,
                  let token = String(data: data, encoding: .utf8) else { return nil }
            return token
        }
        set {
            if let value = newValue {
                let data = value.data(using: .utf8)!
                githubTokenData = data
                saveTokenToKeychain(data)
            } else {
                githubTokenData = nil
                deleteTokenFromKeychain()
            }
        }
    }
    
    var pagesURL: String? {
        guard let username = githubUsername, let repo = githubRepo else { return nil }
        return "https://\(username).github.io/\(repo)/"
    }
    
    func saveConfiguration(username: String, repo: String, token: String, branch: String = "main") {
        self.githubUsername = username
        self.githubRepo = repo
        self.accessToken = token
        self.githubBranch = branch
        self.isConfigured = true
        
        UserDefaults.standard.set(username, forKey: "github_username")
        UserDefaults.standard.set(repo, forKey: "github_repo")
        UserDefaults.standard.set(branch, forKey: "github_branch")
        UserDefaults.standard.set(true, forKey: "github_configured")
    }
    
    func clearConfiguration() {
        self.githubUsername = nil
        self.githubRepo = nil
        self.accessToken = nil
        self.githubBranch = "main"
        self.isConfigured = false
        
        UserDefaults.standard.removeObject(forKey: "github_username")
        UserDefaults.standard.removeObject(forKey: "github_repo")
        UserDefaults.standard.removeObject(forKey: "github_branch")
        UserDefaults.standard.removeObject(forKey: "github_configured")
    }
    
    /// 发布项目到GitHub Pages
    func publishProject(_ project: HTMLProject, progressHandler: ((Double, String) -> Void)? = nil) async throws -> GitHubPublishResult {
        guard let token = accessToken else {
            throw GitHubError.notConfigured
        }
        guard let username = githubUsername, let repo = githubRepo else {
            throw GitHubError.notConfigured
        }
        
        progressHandler?(0.1, "preparing_files".localized)
        
        var files: [GitHubFile] = []
        
        let hasIndexHTML = project.files.contains { $0.displayName == "index.html" }
        
        for projectFile in project.files {
            let base64Content: String
            if let data = projectFile.data {
                base64Content = data.base64EncodedString()
            } else {
                base64Content = Data(projectFile.content.utf8).base64EncodedString()
            }
            files.append(GitHubFile(
                path: projectFile.displayName,
                content: projectFile.content,
                sha: nil,
                base64Content: base64Content
            ))
        }
        
        if !hasIndexHTML {
            let indexHTMLContent = generateIndexHTML(project: project)
            let indexBase64 = Data(indexHTMLContent.utf8).base64EncodedString()
            
            files.append(GitHubFile(
                path: "index.html",
                content: indexHTMLContent,
                sha: nil,
                base64Content: indexBase64
            ))
        }
        
        progressHandler?(0.3, "uploading_files".localized)
        
        let baseURL = "https://api.github.com/repos/\(username)/\(repo)/contents"
        
        for (index, file) in files.enumerated() {
            let fileURL = URL(string: "\(baseURL)/\(file.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? file.path)")!
            
            var request = URLRequest(url: fileURL)
            request.httpMethod = "PUT"
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            
            var body: [String: Any] = [
                "message": "Publish project: \(project.name)",
                "content": file.base64Content,
                "branch": githubBranch
            ]

            // Check if file already exists (need SHA for updates)
            let checkUrl = URL(string: "https://api.github.com/repos/\(username)/\(repo)/contents/\(file.path)")!
            var checkRequest = URLRequest(url: checkUrl)
            checkRequest.setValue("token \(token)", forHTTPHeaderField: "Authorization")
            checkRequest.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            do {
                let (checkData, checkResponse) = try await URLSession.shared.data(for: checkRequest)
                if let httpResponse = checkResponse as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: checkData) as? [String: Any],
                   let existingSha = json["sha"] as? String {
                    body["sha"] = existingSha
                }
            } catch {
                // File doesn't exist yet, no SHA needed
            }
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (responseData, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode > 299 {
                    if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                       let message = json["message"] as? String {
                        throw GitHubError.apiError(message)
                    }
                }
            } catch let error as GitHubError {
                throw error
            } catch {
                throw GitHubError.networkError(error.localizedDescription)
            }
            
            let progress = 0.3 + (Double(index + 1) / Double(files.count)) * 0.5
            progressHandler?(progress, "uploading_files".localized)
        }
        
        progressHandler?(0.9, "finalizing".localized)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let pagesURL = "https://\(username).github.io/\(repo)/"
        
        progressHandler?(1.0, "publish_success".localized)
        
        return GitHubPublishResult(
            url: pagesURL,
            projectName: project.name,
            filesCount: files.count,
            publishedAt: Date()
        )
    }
    
    /// 生成包含iframe的index.html来嵌入项目内容
    private func generateIndexHTML(project: HTMLProject) -> String {
        let htmlFiles = project.files.filter { $0.type == .html || $0.name.lowercased().hasSuffix(".html") || $0.name.lowercased().hasSuffix(".htm") }
        let mainHTMLFile = htmlFiles.first { $0.displayName == "index.html" } ?? htmlFiles.first
        
        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(project.name)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; overflow: hidden; }
            </style>
        </head>
        <body>
        """
        
        if project.files.count == 1, let file = mainHTMLFile {
            html += file.content
        } else if let mainFile = mainHTMLFile {
            let mainFileName = mainFile.displayName
            html += """
            <iframe src="\(mainFileName)" style="width: 100%; height: 100%; border: none;"></iframe>
            """
        } else {
            html += """
            <p>No HTML file found in project.</p>
            """
        }
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    /// 验证GitHub配置
    func validateConfiguration() async throws -> Bool {
        guard let token = accessToken else { return false }
        guard let username = githubUsername, let repo = githubRepo else { return false }
        
        let url = URL(string: "https://api.github.com/repos/\(username)/\(repo)")!
        var request = URLRequest(url: url)
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                return true
            } else if httpResponse.statusCode == 404 {
                throw GitHubError.repoNotFound
            } else if httpResponse.statusCode == 401 {
                throw GitHubError.invalidToken
            }
        }
        
        return false
    }
}

struct GitHubPublishResult {
    let url: String
    let projectName: String
    let filesCount: Int
    let publishedAt: Date
}

struct GitHubFile {
    let path: String
    let content: String
    let sha: String?
    let base64Content: String
}

enum GitHubError: Error, LocalizedError {
    case notConfigured
    case repoNotFound
    case invalidToken
    case apiError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "GitHub not configured. Please configure your repository first."
        case .repoNotFound:
            return "Repository not found. Please check the username and repository name."
        case .invalidToken:
            return "Invalid access token. Please check your token."
        case .apiError(let message):
            return "GitHub API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
