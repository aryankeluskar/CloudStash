//
//  MainView.swift
//  CloudStash
//
//  Created for CloudStash App
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit
import Quartz

/// The root view that handles authentication state
/// Shows AuthenticationView when not signed in, otherwise shows the main app content
struct MainView: View {
    @Environment(\.modelContext) private var modelContext

    // Track auth state with @State to force re-render
    @State private var isSignedIn: Bool = SettingsManager.shared.isSignedIn
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LivelyBackground()
            
            Group {
                if isSignedIn {
                    if showSettings {
                        InlineSettingsView(showSettings: $showSettings)
                    } else {
                        MainContentView(showSettings: $showSettings)
                    }
                } else {
                    AuthenticationView()
                }
            }
        }
        .applyAppTheme()
        .animation(.easeInOut(duration: 0.3), value: isSignedIn)
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
            // Update local state when auth changes
            isSignedIn = SettingsManager.shared.isSignedIn
        }
        .onAppear {
            // Sync state on appear
            isSignedIn = SettingsManager.shared.isSignedIn
        }
    }
}

/// The main content view shown when user is authenticated
/// Two-section layout: Temporary Stash (top) + Recent Uploads (bottom)
struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var showSettings: Bool
    @Query(sort: \UploadedFile.uploadedAt, order: .reverse) private var uploadedFiles: [UploadedFile]
    @Query(sort: \StashedFile.stashedAt, order: .reverse) private var stashedFiles: [StashedFile]

    @State private var isTargeted = false
    @State private var errorMessage: String?
    @State private var driveFiles: [GoogleDriveService.DriveFile] = []
    @State private var isLoadingList = false

    // Download/Preview state (for drive files)
    @State private var downloadingFileId: String?
    @State private var downloadProgress: Double = 0

    // Stash upload state
    @State private var uploadingStashId: PersistentIdentifier?
    @State private var stashUploadProgress: Double = 0

    // Drop zone upload indicator (reuses DropZoneView states)
    @State private var isUploading = false
    @State private var uploadTasks: [UploadTask] = []

    private static let stashDirectoryURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let stashDir = appSupport.appendingPathComponent("CloudStash/Stash", isDirectory: true)
        try? FileManager.default.createDirectory(at: stashDir, withIntermediateDirectories: true)
        return stashDir
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CloudStash")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)

            ScrollView {
                VStack(spacing: 20) {
                    // Drop zone — drops go to stash, NOT upload
                    DropZoneView(
                        isTargeted: $isTargeted,
                        isUploading: isUploading,
                        uploadTasks: uploadTasks
                    )
                    .onTapGesture {
                        if !isUploading {
                            openFilePicker()
                        }
                    }
                    .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                        handleDrop(providers)
                        return true
                    }
                    .padding(.horizontal, 16)

                    // Error message
                    if let error = errorMessage {
                        GlassCard {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Spacer()
                                Button {
                                    errorMessage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, 16)
                    }

                    // === Stash Section ===
                    if !stashedFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Stash")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                
                                Text("\(stashedFiles.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.secondary.opacity(0.1)))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button {
                                        uploadAllStashedFiles()
                                    } label: {
                                        Label("Upload All", systemImage: "arrow.up.circle.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(uploadingStashId != nil)

                                    Button {
                                        clearStash()
                                    } label: {
                                        Text("Clear")
                                            .font(.caption)
                                            .foregroundStyle(Color(nsColor: .systemRed))
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(uploadingStashId != nil)
                                }
                            }
                            .padding(.horizontal, 16)

                            LazyVStack(spacing: 8) {
                                ForEach(stashedFiles) { file in
                                    GlassCard(hoverEffect: true) {
                                        StashItemRow(
                                            stashedFile: file,
                                            stashDirectory: Self.stashDirectoryURL,
                                            isUploading: uploadingStashId == file.persistentModelID,
                                            uploadProgress: uploadingStashId == file.persistentModelID ? stashUploadProgress : 0,
                                            onUpload: {
                                                Task { await uploadStashedFile(file) }
                                            },
                                            onRemove: {
                                                removeStashedFile(file)
                                            },
                                            onPreview: {
                                                previewStashedFile(file)
                                            }
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }

                    // === Recent Uploads Section ===
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Uploads")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if isLoadingList {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Button {
                                    Task { await loadDriveFiles() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.horizontal, 16)

                        if driveFiles.isEmpty && !isLoadingList {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.on.doc")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary.opacity(0.3))
                                Text("No files uploaded yet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(driveFiles) { file in
                                    GlassCard(hoverEffect: true) {
                                        FileRowView(
                                            file: file,
                                            thumbnailURL: file.thumbnailLink.flatMap { URL(string: $0) },
                                            isDownloading: downloadingFileId == file.id,
                                            downloadProgress: downloadingFileId == file.id ? downloadProgress : 0
                                        ) {
                                            copyToClipboard(file)
                                        } onDelete: {
                                            await deleteFile(file)
                                        } onDownload: {
                                            await downloadToDownloads(file)
                                        } onPreview: {
                                            previewFile(file)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 10)
            }
            .scrollIndicators(.never)
        }
        .frame(width: 320, height: 520)
        .task {
            await loadDriveFiles()
        }
    }

    // MARK: - Stash Directory Helpers

    private func stashFileURL(for stashedFile: StashedFile) -> URL {
        Self.stashDirectoryURL.appendingPathComponent(stashedFile.localPath)
    }

    private func uniqueFilename(for originalName: String) -> String {
        let fm = FileManager.default
        let baseURL = Self.stashDirectoryURL.appendingPathComponent(originalName)
        if !fm.fileExists(atPath: baseURL.path) {
            return originalName
        }

        let nameWithoutExt = (originalName as NSString).deletingPathExtension
        let ext = (originalName as NSString).pathExtension
        var counter = 1
        while true {
            let candidate = ext.isEmpty ? "\(nameWithoutExt)-\(counter)" : "\(nameWithoutExt)-\(counter).\(ext)"
            let candidateURL = Self.stashDirectoryURL.appendingPathComponent(candidate)
            if !fm.fileExists(atPath: candidateURL.path) {
                return candidate
            }
            counter += 1
        }
    }

    // MARK: - Drop → Stash

    private func handleDrop(_ providers: [NSItemProvider]) {
        let lock = NSLock()
        var collectedURLs: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                defer { group.leave() }
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                lock.lock()
                collectedURLs.append(url)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            Task { @MainActor in
                self.addFilesToStash(collectedURLs)
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK else { return }
                Task { @MainActor in
                    addFilesToStash(panel.urls)
                }
            }
        } else {
            let response = panel.runModal()
            guard response == .OK else { return }
            Task { @MainActor in
                addFilesToStash(panel.urls)
            }
        }
    }

    @MainActor
    private func addFilesToStash(_ urls: [URL]) {
        let fm = FileManager.default
        for url in urls {
            let originalName = url.lastPathComponent
            let storedName = uniqueFilename(for: originalName)
            let destination = Self.stashDirectoryURL.appendingPathComponent(storedName)

            do {
                // Start accessing security-scoped resource for sandboxed apps
                let didAccess = url.startAccessingSecurityScopedResource()
                defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

                try fm.copyItem(at: url, to: destination)
                let attrs = try fm.attributesOfItem(atPath: destination.path)
                let size = (attrs[.size] as? Int64) ?? 0

                let stashed = StashedFile(
                    filename: originalName,
                    localPath: storedName,
                    size: size
                )
                modelContext.insert(stashed)
            } catch {
                errorMessage = "Failed to stash \(originalName): \(error.localizedDescription)"
            }
        }
        try? modelContext.save()
    }

    // MARK: - Stash Actions

    private func removeStashedFile(_ file: StashedFile) {
        let fileURL = stashFileURL(for: file)
        try? FileManager.default.removeItem(at: fileURL)
        modelContext.delete(file)
        try? modelContext.save()
    }

    private func clearStash() {
        for file in stashedFiles {
            let fileURL = stashFileURL(for: file)
            try? FileManager.default.removeItem(at: fileURL)
            modelContext.delete(file)
        }
        try? modelContext.save()
    }

    @MainActor
    private func uploadStashedFile(_ file: StashedFile) async {
        let fileURL = stashFileURL(for: file)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            errorMessage = "File not found in stash"
            modelContext.delete(file)
            try? modelContext.save()
            return
        }

        uploadingStashId = file.persistentModelID
        stashUploadProgress = 0

        do {
            let result = try await GoogleDriveService.shared.upload(fileURL: fileURL) { progress in
                Task { @MainActor in
                    self.stashUploadProgress = progress
                }
            }

            // Record in uploaded files
            let uploadedFile = UploadedFile(
                filename: file.filename,
                key: result.fileId,
                url: result.url,
                size: file.size
            )
            modelContext.insert(uploadedFile)

            // Add to drive files list
            let newDriveFile = GoogleDriveService.DriveFile(
                id: result.fileId,
                name: file.filename,
                size: file.size,
                createdTime: Date(),
                webViewLink: nil,
                thumbnailLink: nil
            )
            driveFiles.insert(newDriveFile, at: 0)

            // Copy URL to clipboard
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(result.url, forType: .string)

            // Remove from stash
            try? FileManager.default.removeItem(at: fileURL)
            modelContext.delete(file)
            try? modelContext.save()

        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }

        uploadingStashId = nil
        stashUploadProgress = 0
    }

    private func uploadAllStashedFiles() {
        // Capture current list so we iterate a snapshot
        let files = Array(stashedFiles)
        Task {
            for file in files {
                await uploadStashedFile(file)
            }
        }
    }

    private func previewStashedFile(_ file: StashedFile) {
        let url = stashFileURL(for: file)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        showQuickLook(for: url)
    }

    // MARK: - Drive File Operations

    private func loadDriveFiles() async {
        isLoadingList = true
        do {
            driveFiles = try await GoogleDriveService.shared.listFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingList = false
    }

    private func copyToClipboard(_ file: GoogleDriveService.DriveFile) {
        let url = "https://drive.google.com/uc?id=\(file.id)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
    }

    private func deleteFile(_ file: GoogleDriveService.DriveFile) async {
        do {
            try await GoogleDriveService.shared.deleteFile(fileId: file.id)
            await loadDriveFiles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cache

    private func cachedFileURL(for file: GoogleDriveService.DriveFile) -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("CloudStash")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir.appendingPathComponent(file.id + "-" + file.name)
    }

    private func getCachedFile(for file: GoogleDriveService.DriveFile) -> URL? {
        let cachedURL = cachedFileURL(for: file)
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }
        return nil
    }

    // MARK: - Download

    private func downloadToDownloads(_ file: GoogleDriveService.DriveFile) async {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = file.name
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        NSApp.activate(ignoringOtherApps: true)
        let response = await savePanel.begin()

        guard response == .OK, let destination = savePanel.url else {
            return
        }

        if let cachedURL = getCachedFile(for: file) {
            do {
                try FileManager.default.copyItem(at: cachedURL, to: destination)
                NSWorkspace.shared.selectFile(destination.path, inFileViewerRootedAtPath: "")
                return
            } catch {
                // Cache copy failed, fall through to download
            }
        }

        do {
            downloadingFileId = file.id
            downloadProgress = 0

            let cacheURL = cachedFileURL(for: file)
            let savedURL = try await GoogleDriveService.shared.download(fileId: file.id, to: cacheURL) { progress in
                Task { @MainActor in
                    downloadProgress = progress
                }
            }

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: savedURL, to: destination)

            downloadingFileId = nil

            NSWorkspace.shared.selectFile(destination.path, inFileViewerRootedAtPath: "")
        } catch {
            downloadingFileId = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preview with Quick Look

    private func previewFile(_ file: GoogleDriveService.DriveFile) {
        Task {
            let tempFile = cachedFileURL(for: file)

            if let cachedURL = getCachedFile(for: file) {
                await MainActor.run {
                    showQuickLook(for: cachedURL)
                }
                return
            }

            do {
                downloadingFileId = file.id
                downloadProgress = 0

                let savedURL = try await GoogleDriveService.shared.download(fileId: file.id, to: tempFile) { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }

                downloadingFileId = nil

                await MainActor.run {
                    showQuickLook(for: savedURL)
                }
            } catch {
                downloadingFileId = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    private func showQuickLook(for url: URL) {
        let coordinator = QuickLookCoordinator()
        coordinator.items = [QuickLookItem(url: url)]

        Self.quickLookCoordinator = coordinator

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = coordinator
        panel.delegate = coordinator
        panel.currentPreviewItemIndex = 0

        if panel.isVisible {
            panel.reloadData()
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private static var quickLookCoordinator: QuickLookCoordinator?
}

#Preview("Main View - Signed In") {
    MainContentView(showSettings: .constant(false))
        .modelContainer(for: [UploadedFile.self, StashedFile.self], inMemory: true)
}

#Preview("Main View - Wrapper") {
    MainView()
        .modelContainer(for: [UploadedFile.self, StashedFile.self], inMemory: true)
}
