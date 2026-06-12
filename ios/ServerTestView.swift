import SwiftUI

struct ServerTestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var documentManager: DocumentManager
    
    @State private var testResults: [TestResult] = []
    @State private var isRunning = false
    @State private var testLog = ""
    @State private var progress: Double = 0
    @State private var completedCount: Int = 0
    @State private var totalCount: Int = 0
    
    struct TestResult: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let status: TestStatus
        let detail: String
        let duration: TimeInterval?
        
        enum TestStatus: Equatable {
            case success, error, running
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                configSection
                    .padding()
                
                if isRunning && totalCount > 0 {
                    progressSection
                        .padding(.horizontal)
                }
                
                Divider()
                
                if testResults.isEmpty {
                    emptyState
                } else {
                    resultsList
                }
            }
            .navigationTitle("server_test".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRunning {
                        ProgressView()
                    } else {
                        Button("run_all_tests".localized) {
                            Task { await runAllTests() }
                        }
                    }
                }
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("running_tests".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: progress, total: 1.0)
                .tint(.blue)
        }
        .padding(.vertical, 8)
    }
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("test_config".localized)
                .font(.headline)
            
            configRow("api_base_url".localized, AppConfig.apiBaseURL)
            configRow("publish_endpoint".localized, AppConfig.publishAPIBaseURL)
            configRow("api_key".localized, maskString(AppConfig.apiKey))
            configRow("hmac_secret".localized, maskString(AppConfig.hmacSecretKey))
            configRow("user_id".localized, UserManager.shared.userId.prefix(16).appending("..."))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func configRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("tap_run_tests".localized)
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(testResults) { result in
                            TestResultRow(result: result)
                        }
                        
                        if !testLog.isEmpty {
                            Divider()
                            Text(testLog)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: copyLogToClipboard) {
                    Label("copy_log".localized, systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    Task { await runAllTests() }
                }) {
                    Label("rerun_tests".localized, systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isRunning)
            }
            .padding()
        }
    }
    
    private func maskString(_ s: String) -> String {
        if s.count <= 8 { return s }
        return String(s.prefix(4)) + "****" + String(s.suffix(4))
    }
    
    // MARK: - Test Runner
    
    @MainActor
    private func runAllTests() async {
        testResults = []
        testLog = ""
        isRunning = true
        progress = 0
        completedCount = 0
        
        let testDefinitions: [(String, @MainActor (Int) async -> Void)] = [
            ("1. Connection Test", { index in await runConnectionTest(index: index) }),
            ("2. HMAC Signature Test", { index in await runHMACTest(index: index) }),
            ("3. User Sync Test", { index in await runUserSyncTest(index: index) }),
            ("4. Publish API Test", { index in await runPublishTest(index: index) }),
            ("5. Projects API Test", { index in await runProjectsTest(index: index) }),
            ("6. Delete API Test", { index in await runDeleteTest(index: index) }),
            ("7. Update Expiry API Test", { index in await runUpdateExpiryTest(index: index) }),
            ("8. Set Password API Test", { index in await runSetPasswordTest(index: index) }),
            ("9. Stats API Test", { index in await runStatsTest(index: index) }),
            ("10. Database Connection Test", { index in await runDatabaseTest(index: index) }),
            ("11. CORS Headers Test", { index in await runCORSTest(index: index) }),
            ("12. Rate Limit Test", { index in await runRateLimitTest(index: index) }),
        ]
        
        totalCount = testDefinitions.count
        
        // 顺序执行所有测试 —— 避免在 addTask 中传递 @MainActor 闭包引发的 Swift 6 并发警告
        for (index, testDef) in testDefinitions.enumerated() {
            let testName = testDef.0
            let testClosure = testDef.1
            testResults.append(TestResult(name: testName, status: .running, detail: "Testing...", duration: nil))
            let startTime = Date()
            await testClosure(index)
            let duration = Date().timeIntervalSince(startTime)
            await updateTestDuration(index: index, duration: duration)
            await incrementProgress()
        }
        
        isRunning = false
    }
    
    @MainActor
    private func updateTestDuration(index: Int, duration: TimeInterval) async {
        guard index < testResults.count else { return }
        let oldResult = testResults[index]
        testResults[index] = TestResult(
            name: oldResult.name,
            status: oldResult.status,
            detail: oldResult.detail,
            duration: duration
        )
    }
    
    @MainActor
    private func incrementProgress() async {
        completedCount += 1
        progress = Double(completedCount) / Double(totalCount)
    }
    
    @MainActor
    private func log(_ message: String) {
        testLog += message + "\n"
    }
    
    // MARK: - Individual Tests
    
    @MainActor
    private func runConnectionTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/ping.php"
        
        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL: \(url)")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = String(format: "%.2fs", CFAbsoluteTimeGetCurrent() - startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                log("GET \(url)")
                log("Status: \(httpResponse.statusCode)")
                log("Response Time: \(responseTime)")
                log("Response: \(String(data: data, encoding: .utf8) ?? "(binary)")")
                
                if httpResponse.statusCode == 200 {
                    updateTestStatus(index: index, status: .success, detail: "Server reachable! (\(httpResponse.statusCode)) - \(responseTime)")
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            log("GET \(url)")
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runHMACTest(index: Int) async {
        let apiKey = AppConfig.apiKey
        let (timestamp, signature) = HMACAuth.generate(
            apiKey: apiKey,
            secret: AppConfig.hmacSecretKey
        )

        log("API Key: \(apiKey.prefix(4))****")
        log("Timestamp: \(timestamp)")
        log("Signature: \(signature.prefix(8))...")

        let testURL = AppConfig.publishAPIBaseURL + "/publish.php"
        guard let requestURL = URL(string: testURL) else {
        log("Invalid URL: \(testURL)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.timeoutInterval = 8
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": "test",
            "project_name": "Test",
            "files": [] as [[String: Any]]
        ])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                log("POST \(testURL)")
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(String(data: data, encoding: .utf8) ?? "(binary)")")
                
                if httpResponse.statusCode == 400 {
                    let respStr = String(data: data, encoding: .utf8) ?? ""
                    if respStr.contains("Missing files") {
                        updateTestStatus(index: index, status: .success, detail: "HMAC signature verified ✓")
                    } else {
                        updateTestStatus(index: index, status: .error, detail: "Unexpected: \(respStr)")
                    }
                } else if httpResponse.statusCode == 403 {
                    let respStr = String(data: data, encoding: .utf8) ?? ""
                    updateTestStatus(index: index, status: .error, detail: "Auth failed: \(respStr)")
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runUserSyncTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/sync_user.php"

        guard let requestURL = URL(string: url) else {
        log("Invalid URL: \(url)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.timeoutInterval = 8
        
        let body: [String: Any] = [
            "user_id": UserManager.shared.userId,
            "is_pro": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        log("POST \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr)")
                
                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    let isPro = json["is_pro"] as? Bool ?? false
                    let pubCount = json["publish_count"] as? Int ?? 0
                    updateTestStatus(index: index, status: .success, detail: "is_pro=\(isPro), publish_count=\(pubCount)")
                } else {
                    updateTestStatus(index: index, status: .error, detail: respStr)
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runPublishTest(index: Int) async {
        let url = AppConfig.publishAPIBaseURL + "/publish.php"

        log("POST \(url)")
        log("API-Key: \(AppConfig.apiKey.prefix(4))****")
        log("User: \(UserManager.shared.userId.prefix(8))...")

        guard let requestURL = URL(string: url) else {
        log("Invalid URL: \(url)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        HMACAuth.applyHeaders(to: &request)
        request.setValue(UserManager.shared.userId, forHTTPHeaderField: "X-User-ID")
        request.timeoutInterval = 10
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let fields: [(String, String)] = [
            ("name", "ServerTest"),
            ("user_id", UserManager.shared.userId),
            ("is_pro", "0"),
            ("expire_days", "0"),
            ("expire_minutes", "60")
        ]
        
        for (name, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"index.html\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/html\r\n\r\n".data(using: .utf8)!)
        body.append("<html><body><h1>Server Test</h1></body></html>".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        log("Body size: \(body.count) bytes")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr)")
                
                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, status == "success" {
                    let pubUrl = json["url"] as? String ?? "N/A"
                    updateTestStatus(index: index, status: .success, detail: "Published! URL: \(pubUrl)")
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr)")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runProjectsTest(index: Int) async {
        let (timestamp, signature) = HMACAuth.generate(
            apiKey: AppConfig.apiKey,
            secret: AppConfig.hmacSecretKey
        )
        let url = AppConfig.apiBaseURL + "/api/projects.php?action=list&page=1&limit=5&user_id=\(UserManager.shared.userId)&timestamp=\(timestamp)&signature=\(signature)"

        log("GET \(url)")

        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL")
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue(AppConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 8
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr.prefix(200))")
                
                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    if let projects = json["projects"] as? [[String: Any]] {
                        updateTestStatus(index: index, status: .success, detail: "Found \(projects.count) projects")
                    } else {
                        updateTestStatus(index: index, status: .success, detail: "OK (no projects)")
                    }
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr.prefix(200))")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runDeleteTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/delete.php"

        log("POST \(url)")

        guard let requestURL = URL(string: url) else {
        log("Invalid URL: \(url)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.timeoutInterval = 8
        
        let body: [String: Any] = [
            "id": "test_delete_id",
            "user_id": UserManager.shared.userId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr)")
                
                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    if status == "success" {
                        updateTestStatus(index: index, status: .success, detail: "Delete API working")
                    } else {
                        let msg = json["message"] as? String ?? "Unknown error"
                        if msg.contains("not found") || msg.contains("does not exist") {
                            updateTestStatus(index: index, status: .success, detail: "Delete API working (test ID not found, expected)")
                        } else {
                            updateTestStatus(index: index, status: .error, detail: "Error: \(msg)")
                        }
                    }
                } else if httpResponse.statusCode == 404 {
                    let respStr = String(data: data, encoding: .utf8) ?? ""
                    if respStr.contains("not found") || respStr.contains("does not exist") {
                        updateTestStatus(index: index, status: .success, detail: "Delete API working (test ID not found, expected)")
                    } else {
                        updateTestStatus(index: index, status: .error, detail: "HTTP 404: \(respStr)")
                    }
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr)")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runUpdateExpiryTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/api/projects.php"

        log("POST \(url)")

        guard let requestURL = URL(string: url) else {
        log("Invalid URL: \(url)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.timeoutInterval = 8

        let body: [String: Any] = [
            "action": "set_expiry",
            "project_id": "test_expiry_id",
            "user_id": UserManager.shared.userId,
            "expires_at": Int(Date().timeIntervalSince1970) + 7 * 86400
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr)")
                
                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    if status == "success" {
                        updateTestStatus(index: index, status: .success, detail: "Update Expiry API working")
                    } else {
                        let msg = json["message"] as? String ?? "Unknown error"
                        if msg.contains("not found") || msg.contains("does not exist") {
                            updateTestStatus(index: index, status: .success, detail: "Update Expiry API working (test ID not found, expected)")
                        } else {
                            updateTestStatus(index: index, status: .error, detail: "Error: \(msg)")
                        }
                    }
                } else if httpResponse.statusCode == 404 {
                    let respStr = String(data: data, encoding: .utf8) ?? ""
                    if respStr.contains("not found") || respStr.contains("does not exist") {
                        updateTestStatus(index: index, status: .success, detail: "Update Expiry API working (test ID not found, expected)")
                    } else {
                        updateTestStatus(index: index, status: .error, detail: "HTTP 404: \(respStr)")
                    }
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr)")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runSetPasswordTest(index: Int) async {
        // 测试 set_password action（旧 verify_password.php 已废弃，密码验证由 index.php 网关处理）
        let url = AppConfig.apiBaseURL + "/api/projects.php"

        log("POST \(url)")

        guard let requestURL = URL(string: url) else {
        log("Invalid URL: \(url)")
        return
    }
    var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        HMACAuth.applyHeaders(to: &request)
        request.timeoutInterval = 8

        let body: [String: Any] = [
            "action": "set_password",
            "project_id": "test_password_id",
            "user_id": UserManager.shared.userId,
            "password": "test"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr)")

                if httpResponse.statusCode == 200,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let msg = (json["message"] as? String ?? "").lowercased()
                    if msg.contains("not found") || msg.contains("does not exist") || msg.contains("未找到") {
                        updateTestStatus(index: index, status: .success, detail: "Set Password API reachable (test ID not found, expected)")
                    } else {
                        updateTestStatus(index: index, status: .success, detail: "Set Password API reachable")
                    }
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr)")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }

    @MainActor
    private func runStatsTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/stats.php?id=test_stats_id"
        
        log("GET \(url)")
        
        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 8
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let respStr = String(data: data, encoding: .utf8) ?? ""
                log("Status: \(httpResponse.statusCode)")
                log("Response: \(respStr.prefix(200))")
                
                if httpResponse.statusCode == 200 {
                    updateTestStatus(index: index, status: .success, detail: "Stats API reachable")
                } else if httpResponse.statusCode == 404 {
                    let respStr = String(data: data, encoding: .utf8) ?? ""
                    if respStr.contains("not found") || respStr.contains("does not exist") {
                        updateTestStatus(index: index, status: .success, detail: "Stats API reachable (test ID not found, expected)")
                    } else {
                        updateTestStatus(index: index, status: .error, detail: "HTTP 404: \(respStr.prefix(200))")
                    }
                } else {
                    updateTestStatus(index: index, status: .error, detail: "HTTP \(httpResponse.statusCode): \(respStr.prefix(200))")
                }
            }
        } catch {
            log("Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runDatabaseTest(index: Int) async {
        let (timestamp, signature) = HMACAuth.generate(
            apiKey: AppConfig.apiKey,
            secret: AppConfig.hmacSecretKey
        )
        let url = AppConfig.apiBaseURL + "/api/projects.php?action=list&page=1&limit=1&user_id=\(UserManager.shared.userId)&timestamp=\(timestamp)&signature=\(signature)"

        log("DB Test: GET \(url)")

        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL")
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue(AppConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 8
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                if let success = json["success"] as? Bool, success {
                    let total = json["total"] as? Int ?? 0
                    updateTestStatus(index: index, status: .success, detail: "Database connected, \(total) projects found")
                } else if let error = json["error"] as? String {
                    updateTestStatus(index: index, status: .error, detail: "DB error: \(error)")
                } else {
                    updateTestStatus(index: index, status: .success, detail: "Database responding")
                }
            } else {
                updateTestStatus(index: index, status: .error, detail: "Failed to query database")
            }
        } catch {
            log("DB Test Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runCORSTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/ping.php"
        
        log("CORS Test: OPTIONS \(url)")
        
        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "OPTIONS"
        request.setValue(AppConfig.apiBaseURL, forHTTPHeaderField: "Origin")
        request.setValue("GET, POST, OPTIONS", forHTTPHeaderField: "Access-Control-Request-Method")
        request.timeoutInterval = 5
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let corsHeaders = httpResponse.allHeaderFields
                let hasAllowOrigin = corsHeaders["Access-Control-Allow-Origin"] != nil
                
                log("CORS Headers: \(corsHeaders)")
                
                if hasAllowOrigin {
                    updateTestStatus(index: index, status: .success, detail: "CORS headers present")
                } else {
                    updateTestStatus(index: index, status: .success, detail: "No CORS headers (may not be needed)")
                }
            }
        } catch {
            log("CORS Test Error: \(error.localizedDescription)")
            updateTestStatus(index: index, status: .error, detail: error.localizedDescription)
        }
    }
    
    @MainActor
    private func runRateLimitTest(index: Int) async {
        let url = AppConfig.apiBaseURL + "/ping.php"
        
        log("Rate Limit Test: Sending 3 rapid requests...")
        
        guard let requestURL = URL(string: url) else {
            updateTestStatus(index: index, status: .error, detail: "Invalid URL")
            return
        }
        
        var responses: [Int] = []
        
        for i in 0..<3 {
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 5
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    responses.append(httpResponse.statusCode)
                    log("  Request \(i+1): HTTP \(httpResponse.statusCode)")
                }
            } catch {
                log("  Request \(i+1) failed: \(error.localizedDescription)")
            }
        }
        
        if responses.count == 3 {
            let all200 = responses.allSatisfy { $0 == 200 }
            let has429 = responses.contains(429)
            
            if has429 {
                updateTestStatus(index: index, status: .success, detail: "Rate limiting active (429 detected)")
            } else if all200 {
                updateTestStatus(index: index, status: .success, detail: "No rate limit triggered (3/3 OK)")
            } else {
                updateTestStatus(index: index, status: .error, detail: "Inconsistent responses: \(responses)")
            }
        } else {
            updateTestStatus(index: index, status: .error, detail: "Only \(responses.count)/3 requests completed")
        }
    }
    
    @MainActor
    private func updateTestStatus(index: Int, status: TestResult.TestStatus, detail: String) {
        guard index >= 0 && index < testResults.count else { return }
        let oldResult = testResults[index]
        testResults[index] = TestResult(
            name: oldResult.name,
            status: status,
            detail: detail,
            duration: oldResult.duration
        )
    }
    
    private func copyLogToClipboard() {
        var fullLog = "=== Server Test Log ===\n\n"
        fullLog += "Config:\n"
        fullLog += "  API Base: \(AppConfig.apiBaseURL)\n"
        fullLog += "  API Key: \(AppConfig.apiKey.prefix(4))****\n"
        fullLog += "  HMAC Secret: \(AppConfig.hmacSecretKey.prefix(4))****\n"
        fullLog += "  User ID: \(UserManager.shared.userId)\n\n"
        
        for result in testResults {
            let icon = result.status == .success ? "✅" : result.status == .error ? "❌" : "⏳"
            let durationStr = result.duration.map { String(format: " (%.2fs)", $0) } ?? ""
            fullLog += "\(icon) \(result.name)\(durationStr)\n"
            fullLog += "   \(result.detail)\n\n"
        }
        
        let successCount = testResults.filter { $0.status == .success }.count
        let errorCount = testResults.filter { $0.status == .error }.count
        fullLog += "=== Summary ===\n"
        fullLog += "Total: \(testResults.count) | Success: \(successCount) | Failed: \(errorCount)\n\n"
        
        fullLog += "=== Raw Log ===\n\n"
        fullLog += testLog
        
        UIPasteboard.general.string = fullLog
        documentManager.toastItem = ToastItem(message: "Log copied to clipboard", type: .success)
    }
}

struct TestResultRow: View {
    let result: ServerTestView.TestResult
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let duration = result.duration {
                        Text(String(format: "%.2fs", duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(result.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    var statusIcon: String {
        switch result.status {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .running: return "arrow.triangle.2.circlepath"
        }
    }
    
    var statusColor: Color {
        switch result.status {
        case .success: return .green
        case .error: return .red
        case .running: return .orange
        }
    }
}
