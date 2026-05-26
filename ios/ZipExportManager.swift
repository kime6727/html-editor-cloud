import Foundation
import Compression

@MainActor
class ZipExportManager {
    enum ExportError: Error, LocalizedError {
        case projectNotFound
        case noFilesToExport
        case createZipFailed
        
        var errorDescription: String? {
            switch self {
            case .projectNotFound: return "Project not found"
            case .noFilesToExport: return "No files to export"
            case .createZipFailed: return "Failed to create ZIP file"
            }
        }
    }
    
    static let shared = ZipExportManager()
    
    private let tempDirectory = FileManager.default.temporaryDirectory
    
    /// 导出单个项目为Zip文件
    func exportProject(_ project: HTMLProject) throws -> URL {
        let projectDir = tempDirectory.appendingPathComponent("export_\(project.id.uuidString)")
        
        try? FileManager.default.removeItem(at: projectDir)
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        for file in project.files {
            let fileURL = projectDir.appendingPathComponent(file.name)
            if let data = file.data {
                try data.write(to: fileURL)
            } else {
                try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
        
        let zipURL = tempDirectory.appendingPathComponent("\(project.name.replacingOccurrences(of: "/", with: "_")).zip")
        try? FileManager.default.removeItem(at: zipURL)
        
        try createZip(from: projectDir, to: zipURL)
        
        try? FileManager.default.removeItem(at: projectDir)
        
        return zipURL
    }
    
    /// 导出所有项目为Zip文件
    func exportAllProjects(_ projects: [HTMLProject]) throws -> URL {
        let allProjectsDir = tempDirectory.appendingPathComponent("export_all_projects")
        
        try? FileManager.default.removeItem(at: allProjectsDir)
        try FileManager.default.createDirectory(at: allProjectsDir, withIntermediateDirectories: true)
        
        for project in projects {
            let projectSubDir = allProjectsDir.appendingPathComponent(project.name.replacingOccurrences(of: "/", with: "_"))
            try FileManager.default.createDirectory(at: projectSubDir, withIntermediateDirectories: true)
            
            for file in project.files {
                let fileURL = projectSubDir.appendingPathComponent(file.name)
                if let data = file.data {
                    try data.write(to: fileURL)
                } else {
                    try file.content.write(to: fileURL, atomically: true, encoding: .utf8)
                }
            }
        }
        
        let zipURL = tempDirectory.appendingPathComponent("all_projects.zip")
        try? FileManager.default.removeItem(at: zipURL)
        
        try createZip(from: allProjectsDir, to: zipURL)
        
        try? FileManager.default.removeItem(at: allProjectsDir)
        
        return zipURL
    }
    
    /// 创建Zip文件（使用Apple Compression框架）
    private func createZip(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: source, includingPropertiesForKeys: [.isRegularFileKey])
        
        var filesToCompress: [(data: Data, filename: String)] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                let relativePath = fileURL.path.replacingOccurrences(of: source.path, with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                let data = try Data(contentsOf: fileURL)
                filesToCompress.append((data, relativePath))
            }
        }
        
        guard !filesToCompress.isEmpty else {
            throw ExportError.noFilesToExport
        }
        
        try archiveFiles(filesToCompress, to: destination)
    }
    
    /// 使用压缩框架归档文件
    private func archiveFiles(_ files: [(data: Data, filename: String)], to destination: URL) throws {
        let outputHandle = try FileHandle(forWritingTo: destination)
        defer { try? outputHandle.close() }
        
        for (_, file) in files.enumerated() {
            let fileData = file.data
            let fname = file.filename
            
            var compressedData = Data()
            compressedData.reserveCapacity(fileData.count)
            
            let result = fileData.withUnsafeBytes { sourcePtr in
                compressedData.withUnsafeMutableBytes { destPtr in
                    compression_encode_buffer(
                        destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        destPtr.count,
                        sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                        sourcePtr.count,
                        nil,
                        COMPRESSION_ZLIB
                    )
                }
            }
            
            compressedData.count = result
            
            let localFileHeader = createLocalFileHeader(filename: fname, compressedSize: UInt32(result), uncompressedSize: UInt32(fileData.count), crc32: calculateCRC32(fileData))
            try outputHandle.write(contentsOf: localFileHeader)
            try outputHandle.write(contentsOf: compressedData)
        }
    }
    
    private func createLocalFileHeader(filename: String, compressedSize: UInt32, uncompressedSize: UInt32, crc32: UInt32) -> Data {
        var header = Data()
        
        header.append(UInt32(0x04034b50))
        header.append(UInt16(20))
        header.append(UInt16(0))
        header.append(UInt16(8))
        header.append(UInt16(0))
        header.append(UInt16(0))
        header.append(UInt32(0))
        header.append(crc32)
        header.append(compressedSize)
        header.append(uncompressedSize)
        header.append(UInt16(filename.utf8.count))
        header.append(UInt16(0))
        
        header.append(filename.data(using: .utf8)!)
        
        return header
    }
    
    private func calculateCRC32(_ data: Data) -> UInt32 {
        var crc32: UInt32 = 0
        crc32 = data.reduce(0) { crc, byte in
            var c = crc ^ UInt32(byte)
            for _ in 0..<8 {
                c = (c >> 1) ^ (c & 1 == 1 ? 0xEDB88320 : 0)
            }
            return c
        }
        return crc32
    }
}

extension Data {
    mutating func append<T: FixedWidthInteger>(_ value: T) {
        var value = value.littleEndian
        append(Data(bytes: &value, count: MemoryLayout<T>.size))
    }
}
