//
//  ShelfManager.swift
//  CloudStash
//
//  Created for CloudStash App
//

import Foundation
import AppKit
import Combine

// MARK: - Shelf Item Model

struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let originalURL: URL
    let localURL: URL
    let isCopy: Bool
    let fileSize: Int64
    var uploadProgress: Double?
    var uploadedURL: String?
    var uploadedFileId: String?
    
    var filename: String {
        originalURL.lastPathComponent
    }
    
    static func == (lhs: ShelfItem, rhs: ShelfItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shelf Manager

class ShelfManager: ObservableObject {
    @Published var items: [ShelfItem] = []
    @Published var isUploading = false
    @Published var errorMessage: String?
    
    private let tempDirectory: URL
    private let maxCopySize: Int64 = 10 * 1024 * 1024 // 10 MB
    
    init() {
        // Create temp directory for shelf copies
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CloudStashShelf", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        self.tempDirectory = tempDir
    }
    
    // MARK: - Item Management
    
    func addItem(from url: URL) {
        // Check if already added
        if items.contains(where: { $0.originalURL == url }) {
            return
        }
        
        let fileManager = FileManager.default
        
        // Get file size
        let fileSize: Int64
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            fileSize = 0
        }
        
        let localURL: URL
        let isCopy: Bool
        
        // Copy files under 10MB, keep reference for larger files
        if fileSize > 0 && fileSize < maxCopySize {
            // Copy to temp directory
            let copyURL = tempDirectory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
            do {
                try fileManager.copyItem(at: url, to: copyURL)
                localURL = copyURL
                isCopy = true
            } catch {
                // Fall back to reference if copy fails
                localURL = url
                isCopy = false
            }
        } else {
            // Keep reference for large files
            localURL = url
            isCopy = false
        }
        
        let item = ShelfItem(
            id: UUID(),
            originalURL: url,
            localURL: localURL,
            isCopy: isCopy,
            fileSize: fileSize
        )
        
        items.append(item)
    }
    
    func removeItem(_ item: ShelfItem) {
        // Remove from list
        items.removeAll { $0.id == item.id }
        
        // Delete temp copy if exists
        if item.isCopy {
            try? FileManager.default.removeItem(at: item.localURL)
        }
    }
    
    func clearAll() {
        // Delete all temp copies
        for item in items where item.isCopy {
            try? FileManager.default.removeItem(at: item.localURL)
        }
        items.removeAll()
    }
    
    // MARK: - Upload
    
    func uploadItem(_ item: ShelfItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        // Check if file still exists
        guard FileManager.default.fileExists(atPath: items[index].localURL.path) else {
            await MainActor.run {
                errorMessage = "File no longer exists: \(item.filename)"
                items.remove(at: index)
            }
            return
        }
        
        await MainActor.run {
            isUploading = true
            items[index].uploadProgress = 0
        }
        
        do {
            let result = try await GoogleDriveService.shared.upload(fileURL: items[index].localURL) { progress in
                Task { @MainActor in
                    if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                        self.items[idx].uploadProgress = progress
                    }
                }
            }
            
            await MainActor.run {
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].uploadProgress = nil
                    items[idx].uploadedURL = result.url
                    items[idx].uploadedFileId = result.fileId
                }
                isUploading = false
                
                // Copy URL to clipboard
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.url, forType: .string)
            }
        } catch {
            await MainActor.run {
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    items[idx].uploadProgress = nil
                }
                errorMessage = error.localizedDescription
                isUploading = false
            }
        }
    }
    
    func uploadAll() async {
        let itemsToUpload = items.filter { $0.uploadedURL == nil }
        guard !itemsToUpload.isEmpty else { return }
        
        await MainActor.run {
            isUploading = true
        }
        
        var uploadedURLs: [String] = []
        
        for item in itemsToUpload {
            guard let index = items.firstIndex(where: { $0.id == item.id }) else { continue }
            
            // Check if file still exists
            guard FileManager.default.fileExists(atPath: items[index].localURL.path) else {
                await MainActor.run {
                    items.remove(at: index)
                }
                continue
            }
            
            await MainActor.run {
                items[index].uploadProgress = 0
            }
            
            do {
                let result = try await GoogleDriveService.shared.upload(fileURL: items[index].localURL) { progress in
                    Task { @MainActor in
                        if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                            self.items[idx].uploadProgress = progress
                        }
                    }
                }
                
                await MainActor.run {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].uploadProgress = nil
                        items[idx].uploadedURL = result.url
                        items[idx].uploadedFileId = result.fileId
                    }
                }
                
                uploadedURLs.append(result.url)
            } catch {
                await MainActor.run {
                    if let idx = items.firstIndex(where: { $0.id == item.id }) {
                        items[idx].uploadProgress = nil
                    }
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        let finalURLs = uploadedURLs
        await MainActor.run {
            isUploading = false

            // Copy all URLs to clipboard
            if !finalURLs.isEmpty {
                NSPasteboard.general.clearContents()
                if finalURLs.count == 1 {
                    NSPasteboard.general.setString(finalURLs[0], forType: .string)
                } else {
                    NSPasteboard.general.setString(finalURLs.joined(separator: "\n"), forType: .string)
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanupTempFiles() {
        // Remove all temp files in the shelf directory
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
    
    deinit {
        cleanupTempFiles()
    }
}
