//
//  ContentView.swift
//  CloudStash
//
//  Created by Aryan K on 1/26/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine
import AppKit
import Quartz
import QuickLookThumbnailing

// MARK: - Upload Task Model

struct UploadTask: Identifiable {
    let id = UUID()
    let filename: String
    let url: URL
    var progress: Double = 0
    var status: UploadStatus = .pending
    var resultURL: String?

    enum UploadStatus {
        case pending
        case uploading
        case completed
        case failed(String)
    }
}

// MARK: - Content View (Legacy - redirects to MainView)

/// Legacy ContentView - Now replaced by MainView
/// This struct exists for compatibility but redirects to MainView
struct ContentView: View {
    var body: some View {
        MainView()
    }
}

// MARK: - Drop Zone View

struct DropZoneView: View {
    @Binding var isTargeted: Bool
    let isUploading: Bool
    let uploadTasks: [UploadTask]

    private var completedCount: Int {
        uploadTasks.filter {
            if case .completed = $0.status { return true }
            return false
        }.count
    }

    private var totalCount: Int {
        uploadTasks.count
    }

    private var overallProgress: Double {
        guard !uploadTasks.isEmpty else { return 0 }
        return uploadTasks.reduce(0) { $0 + $1.progress } / Double(uploadTasks.count)
    }

    private var currentlyUploading: UploadTask? {
        uploadTasks.first {
            if case .uploading = $0.status { return true }
            return false
        }
    }

    private var allCompleted: Bool {
        completedCount == totalCount && totalCount > 0
    }

    var body: some View {
        VStack(spacing: 8) {
            if isUploading {
                if allCompleted {
                    // All done state
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(nsColor: .systemGreen))
                    if totalCount == 1 {
                        Text("Copied to clipboard!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(totalCount) URLs copied to clipboard!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Progress state
                    VStack(spacing: 6) {
                        ProgressView(value: overallProgress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 220)

                        // Status text
                        if totalCount == 1 {
                            Text("Uploading \(currentlyUploading?.filename ?? "")...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("Uploading \(completedCount + 1) of \(totalCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let current = currentlyUploading {
                                Text(current.filename)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            } else {
                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "arrow.up.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                Text(isTargeted ? "Drop to stash" : "Drop files to stash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(
            GlassCard(hoverEffect: true) {
                Color.clear
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.clear,
                    lineWidth: isTargeted ? 2 : 0
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isTargeted)
    }
}

// MARK: - Progress View Style

struct ActiveProgressViewStyle: ProgressViewStyle {
    var height: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            let progress = configuration.fractionCompleted ?? 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(nsColor: .separatorColor).opacity(0.3))
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeOut(duration: 0.15), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Image Caching

enum CachedImageState {
    case loading
    case success(Image)
    case failure
}

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, NSImage>()

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: NSImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

final class ImageLoader: ObservableObject {
    @Published var state: CachedImageState = .loading
    private var task: Task<Void, Never>?

    func load(from url: URL) {
        if let cached = ImageCache.shared.image(for: url) {
            state = .success(Image(nsImage: cached))
            return
        }

        task?.cancel()
        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = NSImage(data: data) else {
                    await MainActor.run { self.state = .failure }
                    return
                }
                ImageCache.shared.insert(image, for: url)
                await MainActor.run { self.state = .success(Image(nsImage: image)) }
            } catch {
                await MainActor.run { self.state = .failure }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

struct CachedAsyncImage<Content: View>: View {
    let url: URL
    @ViewBuilder let content: (CachedImageState) -> Content
    @StateObject private var loader = ImageLoader()

    var body: some View {
        content(loader.state)
            .onAppear { loader.load(from: url) }
            .onChange(of: url) { _, newURL in
                loader.load(from: newURL)
            }
            .onDisappear { loader.cancel() }
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let file: GoogleDriveService.DriveFile
    let thumbnailURL: URL?
    let isDownloading: Bool
    let downloadProgress: Double
    let onCopy: () -> Void
    let onDelete: () async -> Void
    let onDownload: () async -> Void
    let onPreview: () -> Void

    @State private var isHovered = false
    @State private var isDeleting = false
    @State private var isCopied = false

    private var isImageFile: Bool {
        let ext = (file.name as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp", "svg"].contains(ext)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            if let thumbnailURL, isImageFile {
                CachedAsyncImage(url: thumbnailURL) { state in
                    switch state {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    case .loading:
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .separatorColor).opacity(0.3))
                    Image(systemName: iconForFile(file.name))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(.subheadline).weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Show progress bar OR file size
                if isDownloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(ActiveProgressViewStyle(height: 6))
                        .padding(.top, 2)
                } else {
                    Text(formatSize(file.size))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // Action buttons - always in layout, opacity controlled by hover
            HStack(spacing: 4) {
                Button {
                    if !isDeleting && !isDownloading {
                        onCopy()
                        Task { @MainActor in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isCopied = true
                            }
                            try? await Task.sleep(for: .seconds(1))
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isCopied = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "link")
                        .foregroundStyle(isCopied ? Color.green : Color.secondary)
                }
                .buttonStyle(.borderless)
                .help("Copy URL")
                .disabled(isDeleting || isDownloading)

                Button {
                    Task {
                        await onDownload()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.borderless)
                .help("Download")
                .disabled(isDeleting || isDownloading)

                Button {
                    Task {
                        isDeleting = true
                        await onDelete()
                        isDeleting = false
                    }
                } label: {
                    if isDeleting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "trash")
                            .foregroundStyle(Color(nsColor: .systemRed))
                    }
                }
                .buttonStyle(.borderless)
                .help("Delete")
                .disabled(isDeleting || isDownloading)
            }
            .opacity(isHovered || isDeleting || isDownloading ? 1 : 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .draggable("https://drive.google.com/uc?id=\(file.id)") {
            // Drag preview
            Label(file.name, systemImage: iconForFile(file.name))
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            if !isDownloading {
                onPreview()
            }
        }
    }

    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "svg":
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

// MARK: - Stash Item Row View

struct StashItemRow: View {
    let stashedFile: StashedFile
    let stashDirectory: URL
    let isUploading: Bool
    let uploadProgress: Double
    let onUpload: () -> Void
    let onRemove: () -> Void
    let onPreview: () -> Void

    @State private var isHovered = false
    @State private var thumbnail: NSImage?

    private var fileURL: URL {
        stashDirectory.appendingPathComponent(stashedFile.localPath)
    }

    private var isPreviewable: Bool {
        let ext = (stashedFile.filename as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp", "svg", "pdf", "heic", "tiff", "bmp"].contains(ext)
    }

    var body: some View {
        HStack(spacing: 10) {
            // File icon / thumbnail
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                    )
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(nsColor: .separatorColor).opacity(0.3))
                    Image(systemName: iconForFile(stashedFile.filename))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 32, height: 32)
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(stashedFile.filename)
                    .font(.system(.subheadline).weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                if isUploading {
                    ProgressView(value: uploadProgress)
                        .progressViewStyle(ActiveProgressViewStyle(height: 6))
                        .padding(.top, 2)
                } else {
                    Text(formatSize(stashedFile.size))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            // Action buttons
            HStack(spacing: 4) {
                Button {
                    if !isUploading { onUpload() }
                } label: {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.borderless)
                .help("Upload to Drive")
                .disabled(isUploading)

                Button {
                    if !isUploading { onRemove() }
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Color(nsColor: .systemRed))
                }
                .buttonStyle(.borderless)
                .help("Remove from stash")
                .disabled(isUploading)
            }
            .opacity(isHovered || isUploading ? 1 : 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onDrag {
            NSItemProvider(contentsOf: fileURL) ?? NSItemProvider()
        }
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) {
            if !isUploading {
                onPreview()
            }
        }
        .task(id: stashedFile.localPath) {
            guard isPreviewable else { return }
            await generateThumbnail()
        }
    }

    private func generateThumbnail() async {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 64, height: 64),
            scale: NSScreen.main?.backingScaleFactor ?? 2.0,
            representationTypes: .thumbnail
        )

        do {
            let representation = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            await MainActor.run {
                self.thumbnail = representation.nsImage
            }
        } catch {
            // Fall back to icon — thumbnail stays nil
        }
    }

    private func iconForFile(_ filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "webp", "svg", "heic", "tiff", "bmp":
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

// MARK: - Quick Look Support

class QuickLookItem: NSObject, QLPreviewItem {
    let url: URL

    init(url: URL) {
        self.url = url
        super.init()
    }

    var previewItemURL: URL? { url }
    var previewItemTitle: String? { url.lastPathComponent }
}

class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    var items: [QuickLookItem] = []

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        items.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard index < items.count else { return nil }
        return items[index]
    }
}

// MARK: - Previews

#Preview("Content View") {
    ContentView()
        .modelContainer(for: [UploadedFile.self, StashedFile.self], inMemory: true)
}

#Preview("Drop Zone - Idle") {
    DropZoneView(isTargeted: .constant(false), isUploading: false, uploadTasks: [])
        .padding()
        .frame(width: 320)
}

#Preview("Drop Zone - Targeted") {
    DropZoneView(isTargeted: .constant(true), isUploading: false, uploadTasks: [])
        .padding()
        .frame(width: 320)
}
