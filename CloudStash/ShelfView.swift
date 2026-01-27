//
//  ShelfView.swift
//  CloudStash
//
//  Created for CloudStash App
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ShelfView: View {
    @ObservedObject var manager: ShelfManager
    var settings = SettingsManager.shared
    let onClose: () -> Void
    let onOpenSettings: () -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Shelf")
                    .font(.headline)

                Spacer()

                if !manager.items.isEmpty && settings.isSignedIn {
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
            .padding(.vertical, 12)

            Divider()

            // Content
            if !settings.isSignedIn {
                // Not signed in state
                VStack(spacing: 16) {
                    Image(systemName: "cloud")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)

                    Text("Sign in to Google Drive")
                        .font(.headline)

                    Text("Connect your Google account to start uploading and sharing files.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Open Settings") {
                        onOpenSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.items.isEmpty {
                // Empty state / Drop zone
                VStack(spacing: 12) {
                    Image(systemName: isTargeted ? "arrow.down.circle.fill" : "tray.and.arrow.down")
                        .font(.system(size: 28))
                        .foregroundStyle(isTargeted ? Color.accentColor : .secondary)

                    Text(isTargeted ? "Drop here" : "Drop files here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Stage files temporarily, then upload to Google Drive")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color(nsColor: .quaternaryLabelColor).opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                                    style: StrokeStyle(lineWidth: 1, dash: [6, 3])
                                )
                        )
                )
                .padding(16)
            } else {
                // Items list
                List {
                    ForEach(manager.items) { item in
                        ShelfItemRow(item: item) {
                            manager.removeItem(item)
                        } onUpload: {
                            Task {
                                await manager.uploadItem(item)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.never)

                Divider()

                // Actions footer
                HStack(spacing: 12) {
                    if manager.isUploading {
                        ProgressView()
                            .controlSize(.small)
                        Text("Uploading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        Button {
                            Task {
                                await manager.uploadAll()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Upload All")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(manager.items.isEmpty)
                    }
                }
                .padding(16)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(width: 280, height: 360)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard settings.isSignedIn else { return false }
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
    @State private var isCopied = false

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
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
            )

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(.subheadline).weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let progress = item.uploadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .padding(.top, 2)
                } else if item.uploadedURL != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text("Uploaded")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(formatSize(item.fileSize))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // Actions
            HStack(spacing: 4) {
                if item.uploadedURL != nil {
                    Button {
                        if let url = item.uploadedURL {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url, forType: .string)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isCopied = true
                            }
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(1))
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isCopied = false
                                }
                            }
                        }
                    } label: {
                        Image(systemName: isCopied ? "checkmark.circle.fill" : "link")
                            .foregroundStyle(isCopied ? .green : .secondary)
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
                        .foregroundStyle(Color(nsColor: .systemRed))
                }
                .buttonStyle(.borderless)
                .help("Remove")
            }
            .opacity(isHovered || item.uploadProgress != nil || item.uploadedURL != nil ? 1 : 0)
        }
        .padding(.vertical, 6)
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
    } onOpenSettings: {
        print("Open Settings")
    }
}
