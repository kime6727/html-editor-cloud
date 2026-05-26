import Foundation

// MARK: - Project File
struct ProjectFile: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var content: String
    var data: Data? // Binary data for images/fonts
    var type: FileType
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, content: String = "", data: Data? = nil, type: FileType, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.content = content
        self.data = data
        self.type = type
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum FileType: String, Codable, CaseIterable {
        case html = "html"
        case css = "css"
        case javascript = "js"
        case json = "json"
        case markdown = "md"
        case text = "txt"
        case image = "image"
        case font = "font"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .html: return "HTML"
            case .css: return "CSS"
            case .javascript: return "JavaScript"
            case .json: return "JSON"
            case .markdown: return "Markdown"
            case .text: return "Text"
            case .image: return "Image"
            case .font: return "Font"
            case .other: return "File"
            }
        }
        
        var icon: String {
            switch self {
            case .html: return "h.square"
            case .css: return "paintbrush"
            case .javascript: return "j.square"
            case .json: return "curlybraces"
            case .markdown: return "text.badge.checkmark"
            case .text: return "doc.text"
            case .image: return "photo"
            case .font: return "textformat"
            case .other: return "doc"
            }
        }
        
        var color: String {
            switch self {
            case .html: return "#E34C26"
            case .css: return "#264DE4"
            case .javascript: return "#F7DF1E"
            case .json: return "#292929"
            case .markdown: return "#083FA1"
            case .text: return "#666666"
            case .image: return "#2ECC71"
            case .font: return "#9B59B6"
            case .other: return "#999999"
            }
        }
        
        static func from(filename: String) -> FileType {
            let ext = (filename as NSString).pathExtension.lowercased()
            switch ext {
            case "html", "htm": return .html
            case "css": return .css
            case "js", "mjs": return .javascript
            case "json": return .json
            case "md", "markdown": return .markdown
            case "txt": return .text
            case "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp": return .image
            case "ttf", "otf", "woff", "woff2": return .font
            default: return .other
            }
        }
        
        var isEditable: Bool {
            switch self {
            case .html, .css, .javascript, .json, .markdown, .text:
                return true
            case .image, .font, .other:
                return false
            }
        }
    }
    
    var displayName: String {
        if name.contains(".") {
            return name
        }
        // Special handling for fonts and images which might have varied extensions
        if type == .image || type == .font || type == .other {
            return name
        }
        return name + "." + type.rawValue
    }
}

// MARK: - HTML Project
struct HTMLProject: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var files: [ProjectFile]
    var createdAt: Date
    var updatedAt: Date
    var thumbnailData: Data?
    var lastOpenedFileId: UUID?
    var isFavorite: Bool
    var cloudUrl: String?
    var cloudId: String?
    var expiresAt: Date?
    var visitCount: Int?
    var hasPassword: Bool
    
    init(id: UUID = UUID(), name: String = "Untitled", files: [ProjectFile] = [], createdAt: Date = Date(), updatedAt: Date = Date(), thumbnailData: Data? = nil, lastOpenedFileId: UUID? = nil, isFavorite: Bool = false, cloudUrl: String? = nil, cloudId: String? = nil, expiresAt: Date? = nil, visitCount: Int? = nil, hasPassword: Bool = false) {
        self.id = id
        self.name = name
        self.files = files
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailData = thumbnailData
        self.lastOpenedFileId = lastOpenedFileId
        self.isFavorite = isFavorite
        self.cloudUrl = cloudUrl
        self.cloudId = cloudId
        self.expiresAt = expiresAt
        self.visitCount = visitCount
        self.hasPassword = hasPassword
    }
    
    var mainFile: ProjectFile? {
        files.first { $0.type == .html } ?? files.first
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var htmlFiles: [ProjectFile] {
        files.filter { $0.type == .html }
    }
    
    var assetFiles: [ProjectFile] {
        files.filter { $0.type == .image || $0.type == .other }
    }
    
    var codeFiles: [ProjectFile] {
        files.filter { $0.type != .image }
    }
    
    mutating func addFile(_ file: ProjectFile) {
        files.append(file)
        updatedAt = Date()
    }
    
    mutating func removeFile(id: UUID) {
        files.removeAll { $0.id == id }
        updatedAt = Date()
    }
    
    mutating func updateFile(id: UUID, content: String) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].content = content
            files[index].updatedAt = Date()
            updatedAt = Date()
        }
    }
    
    mutating func renameFile(id: UUID, to newName: String) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            let oldName = files[index].name
            let oldDisplayName = files[index].displayName
            files[index].name = newName
            files[index].updatedAt = Date()
            
            if oldName != newName {
                let newDisplayName = files[index].displayName
                
                for i in 0..<files.count where i != index {
                    if files[i].type.isEditable && !files[i].content.isEmpty {
                        var content = files[i].content
                        
                        let patterns = [
                            "(href\\s*=\\s*[\"'])(\(NSRegularExpression.escapedPattern(for: oldDisplayName)))([\"'])",
                            "(src\\s*=\\s*[\"'])(\(NSRegularExpression.escapedPattern(for: oldDisplayName)))([\"'])",
                            "(href\\s*=\\s*[\"'])(\(NSRegularExpression.escapedPattern(for: oldName)))([\"'])",
                            "(src\\s*=\\s*[\"'])(\(NSRegularExpression.escapedPattern(for: oldName)))([\"'])",
                        ]
                        
                        for pattern in patterns {
                            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                                let range = NSRange(content.startIndex..., in: content)
                                if pattern.contains(oldDisplayName) {
                                    content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "$1\(newDisplayName)$3")
                                } else {
                                    content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: "$1\(newName)$3")
                                }
                            }
                        }
                        
                        files[i].content = content
                        files[i].updatedAt = Date()
                    }
                }
            }
            
            updatedAt = Date()
        }
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
    
    static var empty: HTMLProject {
        HTMLProject(name: "Untitled", files: [
            ProjectFile(name: "index", content: defaultHTML(), type: .html)
        ])
    }
    
    static func defaultHTML() -> String {
        """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>My Page</title>
            <link rel="stylesheet" href="style.css">
        </head>
        <body>
            <h1>Hello World!</h1>
            <p>Start editing to see your changes...</p>
            <script src="script.js"></script>
        </body>
        </html>
        """
    }
    
    static func defaultCSS() -> String {
        """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        
        h1 {
            font-size: 3rem;
            text-align: center;
            margin-bottom: 1rem;
        }
        
        p {
            font-size: 1.2rem;
            opacity: 0.9;
        }
        """
    }
    
    static func defaultJS() -> String {
        """
        console.log('Hello from JavaScript!');
        
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Page loaded successfully');
        });
        """
    }
}

// MARK: - Publish Configuration
struct PublishConfig: Codable {
    var expireDays: Int
    var enableStats: Bool
    var accessPassword: String?
    
    static let `default` = PublishConfig(expireDays: 0, enableStats: true, accessPassword: nil)
}

// MARK: - Device Type
enum DeviceType: String, Codable, CaseIterable {
    case iphone = "iPhone"
    case ipad = "iPad"
    case desktop = "Desktop (PC)"
    case se = "iPhone SE"
    case proMax = "iPhone Pro Max"

    var icon: String {
        switch self {
        case .iphone: return "iphone.gen3"
        case .ipad: return "ipad.gen2"
        case .desktop: return "desktopcomputer"
        case .se: return "iphone.homebutton"
        case .proMax: return "iphone.gen3"
        }
    }

    var width: CGFloat {
        switch self {
        case .iphone: return 390
        case .ipad: return 820
        case .desktop: return 1200
        case .se: return 375
        case .proMax: return 430
        }
    }

    var height: CGFloat {
        switch self {
        case .iphone: return 844
        case .ipad: return 1180
        case .desktop: return 800
        case .se: return 667
        case .proMax: return 932
        }
    }
}

@MainActor
func safeLocalize(_ key: String) -> String {
    let localized = key.localized
    if localized == key {
        switch key {
        case "update_cloud":
            return LanguageManager.shared.selectedLanguage == .en ? "Update Cloud" : "更新云端内容"
        case "view_cloud":
            return LanguageManager.shared.selectedLanguage == .en ? "View Online" : "查看在线链接"
        case "published_status":
            return LanguageManager.shared.selectedLanguage == .en ? "Published to Cloud" : "已同步云端"
        case "publish_cloud":
            return LanguageManager.shared.selectedLanguage == .en ? "Publish to Cloud" : "同步至云端"
        default:
            return localized
        }
    }
    return localized
}

extension Notification.Name {
    static let projectCloudIdCleared = Notification.Name("projectCloudIdCleared")
}
