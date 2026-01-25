//
//  ShelfView.swift
//  DropOver
//
//  Created for DropOver App
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ShelfView: View {
    @ObservedObject var manager: ShelfManager
    let onClose: () -> Void
    
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Shelf")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !manager.items.isEmpty {
                    Button {
                        manager.clearAll()
                    } label: {
                        Text("Clear")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                }
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Content
            if manager.items.isEmpty {
                // Empty state / Drop zone
                VStack(spacing: 12) {
                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "tray.and.arrow.down")
                        .font(.system(size: 32))
                        .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                    
                    Text(isTargeted ? "Drop here" : "Drop files here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Stage files temporarily, then upload to Google Drive with one click")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                        .padding(12)
                )
            } else {
                // Items list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(manager.items) { item in
                            ShelfItemRow(item: item) {
                                manager.removeItem(item)
                            } onUpload: {
                                Task {
                                    await manager.uploadItem(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Actions
                HStack(spacing: 12) {
                    if manager.isUploading {
                        ProgressView()
                            .controlSize(.small)
                        Text("Uploading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            Task {
                                await manager.uploadAll()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Upload All")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!SettingsManager.shared.isSignedIn || manager.items.isEmpty)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(width: 280, height: 340)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
            return true
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    manager.addItem(from: url)
                }
            }
        }
    }
}

struct ShelfItemRow: View {
    let item: ShelfItem
    let onRemove: () -> Void
    let onUpload: () -> Void
    
    @State private var isHovered = false
    @State private var thumbnail: NSImage?
    
    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .separatorColor).opacity(0.3))
                
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: iconForFile(item.filename))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 32, height: 32)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(.caption).weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if let progress = item.uploadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                } else if let url = item.uploadedURL {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Uploaded")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(formatSize(item.fileSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 4)
            
            // Actions
            HStack(spacing: 4) {
                if item.uploadedURL != nil {
                    Button {
                        if let url = item.uploadedURL {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url, forType: .string)
                        }
                    } label: {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Copy URL")
                } else if item.uploadProgress == nil {
                    Button {
                        onUpload()
                    } label: {
                        Image(systemName: "arrow.up.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Upload")
                    .disabled(!SettingsManager.shared.isSignedIn)
                }
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove")
            }
            .opacity(isHovered || item.uploadProgress != nil ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(nsColor: .separatorColor).opacity(0.3) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let url = item.localURL
        
        // Only load thumbnails for images
        let ext = url.pathExtension.lowercased()
        guard ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"].contains(ext) else { return }
        
        DispatchQueue.global(qos: .utility).async {
            guard let image = NSImage(contentsOf: url) else { return }
            
            // Create thumbnail
            let size = NSSize(width: 64, height: 64)
            let thumbnail = NSImage(size: size)
            thumbnail.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: size),
                      from: NSRect(origin: .zero, size: image.size),
                      operation: .copy,
                      fraction: 1.0)
            thumbnail.unlockFocus()
            
            DispatchQueue.main.async {
                self.thumbnail = thumbnail
            }
        }
    }
    
    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "svg", "heic", "heif":
            return "photo"
        case "mp4", "mov", "avi":
            return "video"
        case "mp3", "wav", "m4a":
            return "music.note"
        case "pdf":
            return "doc.richtext"
        case "zip", "rar", "7z":
            return "archivebox"
        default:
            return "doc"
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    ShelfView(manager: ShelfManager()) {
        print("Close")
    }
}
