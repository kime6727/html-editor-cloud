import Foundation

struct ProjectFolder: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var parentId: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, parentId: UUID? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct FolderItem: Identifiable {
    let id: UUID
    let name: String
    let type: ItemType
    let createdAt: Date
    let updatedAt: Date
    let icon: String
    let color: String
    let isEditable: Bool
    
    enum ItemType {
        case folder
        case file(ProjectFile.FileType)
    }
}

extension HTMLProject {
    var folders: [ProjectFolder] {
        get {
            if let data = UserDefaults.standard.data(forKey: "project_folders_\(id.uuidString)"),
               let decoded = try? JSONDecoder().decode([ProjectFolder].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "project_folders_\(id.uuidString)")
            }
        }
    }
    
    var fileFolderMap: [String: UUID] {
        get {
            if let data = UserDefaults.standard.data(forKey: "project_file_folders_\(id.uuidString)"),
               let decoded = try? JSONDecoder().decode([String: UUID].self, from: data) {
                return decoded
            }
            return [:]
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: "project_file_folders_\(id.uuidString)")
            }
        }
    }
    
    mutating func addFolder(name: String, parentId: UUID? = nil) -> ProjectFolder {
        let folder = ProjectFolder(name: name, parentId: parentId)
        var currentFolders = folders
        currentFolders.append(folder)
        folders = currentFolders
        updatedAt = Date()
        return folder
    }
    
    mutating func removeFolder(id: UUID) {
        var currentFolders = folders
        currentFolders.removeAll { $0.id == id }
        folders = currentFolders
        
        var currentMap = fileFolderMap
        currentMap = currentMap.filter { $0.value != id }
        fileFolderMap = currentMap
        
        updatedAt = Date()
    }
    
    mutating func moveFile(fileId: UUID, toFolderId: UUID?) {
        var currentMap = fileFolderMap
        if let folderId = toFolderId {
            currentMap[fileId.uuidString] = folderId
        } else {
            currentMap.removeValue(forKey: fileId.uuidString)
        }
        fileFolderMap = currentMap
        updatedAt = Date()
    }
    
    mutating func renameFolder(id: UUID, to newName: String) {
        var currentFolders = folders
        if let index = currentFolders.firstIndex(where: { $0.id == id }) {
            currentFolders[index].name = newName
            currentFolders[index].updatedAt = Date()
            folders = currentFolders
            updatedAt = Date()
        }
    }
    
    func filesInFolder(folderId: UUID?) -> [ProjectFile] {
        if let folderId = folderId {
            return files.filter { fileFolderMap[$0.id.uuidString] == folderId }
        } else {
            return files.filter { fileFolderMap[$0.id.uuidString] == nil }
        }
    }
    
    func subfolders(of parentId: UUID?) -> [ProjectFolder] {
        return folders.filter { $0.parentId == parentId }
    }
    
    func folderPath(for folderId: UUID) -> [ProjectFolder] {
        var path: [ProjectFolder] = []
        var currentId: UUID? = folderId
        
        while let id = currentId,
              let folder = folders.first(where: { $0.id == id }) {
            path.insert(folder, at: 0)
            currentId = folder.parentId
        }
        
        return path
    }
}
