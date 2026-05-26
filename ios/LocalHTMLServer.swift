import Foundation
import Network

@MainActor
class LocalHTMLServer: ObservableObject {
    @Published var isRunning = false
    @Published var serverURL: String?
    @Published var errorMessage: String?
    
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var currentProject: HTMLProject?
    private let connectionQueue = DispatchQueue(label: "com.htmlpreview.connection", qos: .userInitiated)
    
    func startServer(with project: HTMLProject) {
        guard !isRunning else { return }
        
        currentProject = project
        errorMessage = nil
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.acceptLocalOnly = false
            
            listener = try NWListener(using: parameters, on: .any)
            
            listener?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        if let port = self.listener?.port {
                            self.isRunning = true
                            self.serverURL = self.getServerURL(port: port)
                            self.errorMessage = nil
                        }
                    case .failed(let error):
                        let errorDesc = error.localizedDescription
                        self.errorMessage = String(format: "server_start_failed".localized, errorDesc)
                        self.isRunning = false
                        
                        if errorDesc.contains("cancelled") || errorDesc.contains("48") {
                            self.errorMessage = "server_port_in_use".localized
                        } else if errorDesc.contains("WiFi") || errorDesc.contains("network") {
                            self.errorMessage = "server_no_wifi".localized
                        }
                    case .cancelled:
                        self.isRunning = false
                    default:
                        break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    await self?.handleConnection(connection)
                }
            }
            
            listener?.start(queue: connectionQueue)
            
        } catch {
            let errorDesc = error.localizedDescription
            errorMessage = String(format: "server_init_failed".localized, errorDesc)
            
            if errorDesc.contains("cancelled") || errorDesc.contains("48") {
                errorMessage = "server_port_in_use".localized
            } else if errorDesc.contains("WiFi") || errorDesc.contains("network") {
                errorMessage = "server_no_wifi".localized
            }
        }
    }
    
    func stopServer() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener = nil
        serverURL = nil
        isRunning = false
    }
    
    func updateProject(_ project: HTMLProject) {
        currentProject = project
    }
    
    private func handleConnection(_ connection: NWConnection) async {
        connections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if case .ready = state {
                    await self.receiveRequest(on: connection)
                } else if case .failed(_) = state {
                    self.connections.removeAll { $0 === connection }
                } else if case .cancelled = state {
                    self.connections.removeAll { $0 === connection }
                }
            }
        }
        
        connection.start(queue: connectionQueue)
    }
    
    private func receiveRequest(on connection: NWConnection) async {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                if let request = String(data: data, encoding: .utf8) {
                    Task { @MainActor [weak self] in
                        await self?.sendResponse(to: connection, request: request)
                    }
                }
            }
            
            if isComplete {
                connection.cancel()
            } else if error == nil {
                Task { @MainActor [weak self] in
                    await self?.receiveRequest(on: connection)
                }
            }
        }
    }
    
    // MARK: - 真正的 HTTP 路由分发（支持嵌套路径 + 图片二进制）
    
    private func sendResponse(to connection: NWConnection, request: String) async {
        // 解析请求行，取出 GET /path HTTP/1.1
        let requestPath = parseRequestPath(from: request)
        let responseData = buildResponseData(for: requestPath)
        
        connection.send(content: responseData, completion: .contentProcessed { error in
            if let error = error {
            }
            connection.cancel()
        })
    }
    
    /// 从 HTTP 请求报文中解析请求路径
    private func parseRequestPath(from request: String) -> String {
        // 格式：GET /path?query HTTP/1.1
        let lines = request.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { return "/" }
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return "/" }
        
        var path = parts[1]
        // 去掉 query string
        if let queryStart = path.firstIndex(of: "?") {
            path = String(path[path.startIndex..<queryStart])
        }
        // URL 解码
        return path.removingPercentEncoding ?? path
    }
    
    /// 根据请求路径构建完整的 HTTP 响应 Data（含头部）
    private func buildResponseData(for path: String) -> Data {
        guard let project = currentProject else {
            return httpResponse(status: "404 Not Found", contentType: "text/plain", body: Data("Not Found".utf8))
        }
        
        // 规范化路径：/ 映射到 index.html
        var filePath = path
        if filePath == "/" || filePath.isEmpty {
            filePath = "/index.html"
        }
        // 去掉前导斜杠，得到相对路径
        let relativePath = filePath.hasPrefix("/") ? String(filePath.dropFirst()) : filePath
        
        // 在项目文件列表中查找匹配的文件
        if let file = findFile(relativePath: relativePath, in: project) {
            let (contentType, bodyData) = fileResponseBody(file: file)
            return httpResponse(status: "200 OK", contentType: contentType, body: bodyData)
        }
        
        // 找不到文件 → 404
        return httpResponse(status: "404 Not Found", contentType: "text/plain", body: Data("File not found: \(relativePath)".utf8))
    }
    
    /// 在项目中查找与请求路径匹配的文件
    private func findFile(relativePath: String, in project: HTMLProject) -> ProjectFile? {
        // 精确匹配（displayName 包含相对路径如 assets/logo.png）
        if let exact = project.files.first(where: { $0.displayName == relativePath }) {
            return exact
        }
        // 模糊匹配：如果路径的最后一段文件名和 displayName 的文件名部分一致
        let requestFileName = (relativePath as NSString).lastPathComponent
        return project.files.first(where: { ($0.displayName as NSString).lastPathComponent == requestFileName })
    }
    
    /// 构建响应体数据和 Content-Type
    private func fileResponseBody(file: ProjectFile) -> (contentType: String, body: Data) {
        let mimeType = mimeTypeForFile(file)
        
        if let binaryData = file.data {
            return (mimeType, binaryData)
        } else {
            return (mimeType + "; charset=utf-8", Data(file.content.utf8))
        }
    }
    
    /// 根据文件类型返回对应 MIME 类型
    private func mimeTypeForFile(_ file: ProjectFile) -> String {
        let ext = (file.displayName as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return "text/html"
        case "css":         return "text/css"
        case "js":          return "application/javascript"
        case "json":        return "application/json"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif":         return "image/gif"
        case "svg":         return "image/svg+xml"
        case "webp":        return "image/webp"
        case "ico":         return "image/x-icon"
        case "ttf":         return "font/ttf"
        case "otf":         return "font/otf"
        case "woff":        return "font/woff"
        case "woff2":       return "font/woff2"
        default:            return "application/octet-stream"
        }
    }
    
    /// 构建 HTTP 响应报文
    private func httpResponse(status: String, contentType: String, body: Data) -> Data {
        let header = """
        HTTP/1.1 \(status)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.count)\r
        Access-Control-Allow-Origin: *\r
        Cache-Control: no-cache\r
        Connection: close\r
        \r\n
        """
        var response = Data(header.utf8)
        response.append(body)
        return response
    }
    
    private func getServerURL(port: NWEndpoint.Port) -> String {
        let localIP = getLocalIPAddress()
        return "http://\(localIP):\(port)"
    }
    
    private func getLocalIPAddress() -> String {
        var address: String = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            return address
        }
        guard let firstAddr = ifaddr else {
            return address
        }
        
        defer { freeifaddrs(ifaddr) }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                              socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              socklen_t(0),
                              NI_NUMERICHOST)
                    let ipAddress = String(cString: hostname)
                    
                    if !ipAddress.hasPrefix("127.") && !ipAddress.isEmpty {
                        address = ipAddress
                        break
                    }
                }
            }
        }
        
        return address
    }
    
    deinit {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener = nil
    }
}
