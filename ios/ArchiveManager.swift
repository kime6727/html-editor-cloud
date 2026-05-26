import Foundation
import Compression

class ArchiveManager: @unchecked Sendable {
    static let shared = ArchiveManager()

    private init() {}

    func extractArchive(url: URL) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
            .appendingPathComponent("Extracted")
            .appendingPathComponent(UUID().uuidString)

        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let ext = url.pathExtension.lowercased()
        if ext == "zip" {
            try extractZip(at: url, to: tempDir)
        } else if ext == "rar" {
            throw ArchiveError.unsupportedFormat("RAR is not natively supported. Please use ZIP.")
        } else {
            throw ArchiveError.unsupportedFormat(ext)
        }

        return tempDir
    }

    private func extractZip(at source: URL, to destination: URL) throws {
        let bytes = [UInt8](try Data(contentsOf: source))
        let count = bytes.count

        func u16(_ pos: Int) -> Int {
            guard pos + 1 < count else { return 0 }
            return Int(bytes[pos]) | (Int(bytes[pos+1]) << 8)
        }
        func u32(_ pos: Int) -> Int {
            guard pos + 3 < count else { return 0 }
            return Int(bytes[pos]) | (Int(bytes[pos+1]) << 8)
                 | (Int(bytes[pos+2]) << 16) | (Int(bytes[pos+3]) << 24)
        }

        var eocdPos = -1
        let minSearch = max(0, count - 65558)
        for i in stride(from: count - 22, through: minSearch, by: -1) {
            if bytes[i] == 0x50 && bytes[i+1] == 0x4B && bytes[i+2] == 0x05 && bytes[i+3] == 0x06 {
                eocdPos = i
                break
            }
        }
        guard eocdPos >= 0 else {
            throw ArchiveError.extractionFailed("Not a valid ZIP file (missing EOCD)")
        }

        let cdOffset    = u32(eocdPos + 16)
        let totalEntries = u16(eocdPos + 10)

        struct CdEntry {
            let name: String
            let compressionMethod: Int
            let compressedSize: Int
            let uncompressedSize: Int
            let localHeaderOffset: Int
        }

        var entries: [CdEntry] = []
        var cdPos = cdOffset

        for _ in 0..<totalEntries {
            guard cdPos + 46 <= count,
                  bytes[cdPos] == 0x50, bytes[cdPos+1] == 0x4B,
                  bytes[cdPos+2] == 0x01, bytes[cdPos+3] == 0x02 else { break }

            let compressionMethod   = u16(cdPos + 10)
            let compressedSize      = u32(cdPos + 20)
            let uncompressedSize    = u32(cdPos + 24)
            let fileNameLen         = u16(cdPos + 28)
            let extraLen            = u16(cdPos + 30)
            let commentLen          = u16(cdPos + 32)
            let localHeaderOffset   = u32(cdPos + 42)

            guard cdPos + 46 + fileNameLen <= count else { break }
            let nameBytes = Array(bytes[(cdPos+46)..<(cdPos+46+fileNameLen)])
            let name = String(bytes: nameBytes, encoding: .utf8)
                    ?? String(bytes: nameBytes, encoding: .isoLatin1)
                    ?? ""

            entries.append(CdEntry(
                name: name,
                compressionMethod: compressionMethod,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localHeaderOffset
            ))

            cdPos += 46 + fileNameLen + extraLen + commentLen
        }

        for entry in entries {
            let lh = entry.localHeaderOffset
            guard lh + 30 <= count,
                  bytes[lh] == 0x50, bytes[lh+1] == 0x4B,
                  bytes[lh+2] == 0x03, bytes[lh+3] == 0x04 else { continue }

            let localFileNameLen = u16(lh + 26)
            let localExtraLen    = u16(lh + 28)
            let dataStart        = lh + 30 + localFileNameLen + localExtraLen

            let compressedSize = entry.compressedSize

            guard dataStart + compressedSize <= count else { continue }

            let fileName = entry.name
            let fileURL  = destination.appendingPathComponent(fileName)

            if fileName.hasSuffix("/") {
                try? FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
                continue
            }

            try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)

            guard compressedSize > 0 else {
                FileManager.default.createFile(atPath: fileURL.path, contents: Data())
                continue
            }

            let compressedData = Data(bytes[dataStart..<(dataStart + compressedSize)])

            switch entry.compressionMethod {
            case 0:
                try? compressedData.write(to: fileURL)
            case 8:
                if let decompressed = decompressRawDeflate(compressedData, expectedSize: entry.uncompressedSize) {
                    try? decompressed.write(to: fileURL)
                } else {
                    try? compressedData.write(to: fileURL)
                }
            default:
                try? compressedData.write(to: fileURL)
            }
        }
    }

    private func decompressRawDeflate(_ data: Data, expectedSize: Int) -> Data? {
        let bufSize = max(expectedSize > 0 ? expectedSize * 2 : data.count * 8, 4096)
        var dst = [UInt8](repeating: 0, count: bufSize)

        let written = data.withUnsafeBytes { srcBuf -> Int in
            guard let srcPtr = srcBuf.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_decode_buffer(&dst, bufSize, srcPtr, data.count, nil, COMPRESSION_ZLIB)
        }

        if written > 0 {
            return Data(dst.prefix(written))
        }

        var zlibWrapped = Data([0x78, 0x9C])
        zlibWrapped.append(data)

        let written2 = zlibWrapped.withUnsafeBytes { srcBuf -> Int in
            guard let srcPtr = srcBuf.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return compression_decode_buffer(&dst, bufSize, srcPtr, zlibWrapped.count, nil, COMPRESSION_ZLIB)
        }

        if written2 > 0 {
            return Data(dst.prefix(written2))
        }

        return nil
    }

    enum ArchiveError: Error, LocalizedError {
        case unsupportedFormat(String)
        case invalidPath
        case cannotOpenSource
        case cannotCreateDecompressionStream
        case cannotCreateDecodeStream
        case cannotCreateExtractStream
        case extractionFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let fmt): return "Unsupported format: \(fmt). Please use ZIP."
            case .extractionFailed(let msg): return "Extraction failed: \(msg)."
            default: return "Archive error occurred."
            }
        }
    }
}
