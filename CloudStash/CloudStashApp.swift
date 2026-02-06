//
//  CloudStashApp.swift
//  CloudStash
//
//  Created by Aryan K on 1/25/26.
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - Popover Background View
class PopoverBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.set()
        dirtyRect.fill()
    }
}

@main
struct CloudStashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([UploadedFile.self, StashedFile.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var modelContainer: ModelContainer?
    var popoverBackgroundView: PopoverBackgroundView?

    // Drag detection state
    private var dragPollTimer: Timer?
    private var lastDragChangeCount: Int = 0
    private var isDraggingFiles = false
    private var popoverAutoShownByDrag = false
    private var filesWereDroppedInApp = false
    private var mouseUpMonitor: Any?
    private var escapeMonitor: Any?
    private var dragEndWorkItem: DispatchWorkItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent multiple instances - quit if another instance is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleId = Bundle.main.bundleIdentifier ?? "com.cloudstash.CloudStash"
        let runningInstances = runningApps.filter { $0.bundleIdentifier == myBundleId }
        if runningInstances.count > 1 {
            // Another instance is already running, quit this one
            NSApp.terminate(nil)
            return
        }

        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup model container
        let schema = Schema([UploadedFile.self, StashedFile.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "CloudStash")
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup popover
        popover = NSPopover()
        // Match MainContentView frame height (520) so both sections fit
        popover?.contentSize = NSSize(width: 320, height: 520)
        popover?.behavior = .semitransient
        popover?.animates = true

        let mainView = MainView()
            .modelContainer(modelContainer!)
        popover?.contentViewController = NSHostingController(rootView: mainView)
        
        // Register URL scheme handler for OAuth
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Monitor for file drags system-wide to auto-show popover
        startDragMonitoring()
    }
    
    // MARK: - Status Bar Actions
    
    @objc func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right click - show context menu
            showContextMenu()
        } else {
            // Left click - toggle main popover (primary action)
            // This shows AuthenticationView if not signed in, or uploads view if signed in
            togglePopover()
        }
    }
    
    func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            
            // Add solid white background to popover (including the arrow/notch)
            if let contentView = popover.contentViewController?.view,
               let frameView = contentView.window?.contentView?.superview {
                // Check if background view already exists
                if popoverBackgroundView == nil || popoverBackgroundView?.superview == nil {
                    let bgView = PopoverBackgroundView(frame: frameView.bounds)
                    bgView.autoresizingMask = [.width, .height]
                    frameView.addSubview(bgView, positioned: .below, relativeTo: frameView)
                    popoverBackgroundView = bgView
                }
            }
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit CloudStash", action: #selector(menuQuit), keyEquivalent: "q"))
        
        for item in menu.items {
            item.target = self
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func menuOpenSettings() {
        // Open the popover (settings is handled inline within the popover)
        if let popover = popover, !popover.isShown {
            togglePopover()
        }
    }

    @objc func menuQuit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - OAuth URL Handler

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            print("[CloudStash OAuth] Failed to parse URL from event")
            return
        }
        print("[CloudStash OAuth] Callback received (NSAppleEvent): \(url)")
        processOAuthURL(url)
    }

    private func processOAuthURL(_ url: URL) {
        print("[CloudStash OAuth] Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil"), Path: \(url.path)")

        // Handle OAuth callback (reversed client ID scheme)
        // Note: With custom URL schemes, "oauth2callback" may appear as
        // the host (scheme://oauth2callback) or the path (scheme:/oauth2callback)
        // depending on how the URL is parsed. Check both.
        let expectedScheme = "com.googleusercontent.apps.446555451602-urjojbh2ln1uokl3alfnvll65v5973lk"
        let isOAuthCallback = url.host == "oauth2callback" || url.path.contains("oauth2callback")
        if url.scheme == expectedScheme && isOAuthCallback {
            print("[CloudStash OAuth] Valid callback, processing...")

            Task {
                do {
                    print("[CloudStash OAuth] Calling handleOAuthCallback...")
                    try await GoogleDriveService.shared.handleOAuthCallback(url: url)
                    print("[CloudStash OAuth] handleOAuthCallback succeeded!")

                    // Notify all views of auth state change
                    await MainActor.run {
                        print("[CloudStash OAuth] Notifying UI of sign-in complete...")
                        SettingsManager.shared.notifySignInComplete()

                        // Show success notification
                        let alert = NSAlert()
                        alert.messageText = "Signed In Successfully"
                        alert.informativeText = "You're now connected to Google Drive as \(SettingsManager.shared.userEmail)"
                        alert.alertStyle = .informational
                        if let icon = NSImage(named: "CloudStashIcon") {
                            alert.icon = icon
                        }
                        alert.addButton(withTitle: "OK")
                        alert.runModal()

                        print("[CloudStash OAuth] Sign-in complete, isSignedIn: \(SettingsManager.shared.isSignedIn)")
                    }
                } catch {
                    print("[CloudStash OAuth] Error: \(error.localizedDescription)")
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Sign In Failed"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .warning
                        if let icon = NSImage(named: "CloudStashIcon") {
                            alert.icon = icon
                        }
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        } else {
            print("[CloudStash OAuth] Unrecognized URL - expected scheme: \(expectedScheme)")
        }
    }
    
    // MARK: - Drag Monitoring
    //
    // Detects system-wide file drags by combining two signals:
    // 1. Polling NSPasteboard(name: .drag).changeCount — only reacts when a NEW drag starts
    //    (the pasteboard retains stale types after drag ends, so we never check types alone)
    // 2. Global monitors for leftMouseUp and Escape — reliably detect when any drag ends

    func startDragMonitoring() {
        // Snapshot the current changeCount so we don't react to stale pasteboard state
        lastDragChangeCount = NSPasteboard(name: .drag).changeCount

        // Poll for new drag sessions (changeCount increments when a new drag begins)
        dragPollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkForNewDrag()
        }
        // Ensure timer fires even during modal/tracking run loop modes
        RunLoop.current.add(dragPollTimer!, forMode: .common)

        // Global monitor: mouse-up signals drag end (drop or release)
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.handleDragEnd()
        }

        // Global monitor: Escape key cancels a drag
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.handleDragEnd()
            }
        }

        // Listen for successful drops into our app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFilesDroppedInApp),
            name: .filesDroppedInApp,
            object: nil
        )
    }

    @objc private func handleFilesDroppedInApp() {
        filesWereDroppedInApp = true
    }

    private func checkForNewDrag() {
        let dragPasteboard = NSPasteboard(name: .drag)
        let currentChangeCount = dragPasteboard.changeCount

        // Only react when changeCount actually changes (= new drag started)
        guard currentChangeCount != lastDragChangeCount else { return }
        lastDragChangeCount = currentChangeCount

        // Check if the new drag contains file URLs
        guard let types = dragPasteboard.types else { return }
        let fileTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("public.file-url"),
        ]
        let containsFiles = fileTypes.contains { types.contains($0) }
        guard containsFiles else { return }

        // New file drag detected — cancel any pending drag-end action and reset drop flag
        dragEndWorkItem?.cancel()
        dragEndWorkItem = nil
        isDraggingFiles = true
        filesWereDroppedInApp = false

        // Auto-show popover if not already visible
        if let popover = popover, !popover.isShown {
            popoverAutoShownByDrag = true
            showPopover()
        }
    }

    private func handleDragEnd() {
        guard isDraggingFiles else { return }

        // Short delay so the drop handler in MainView has time to process and post
        // the .filesDroppedInApp notification before we check the flag
        dragEndWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isDraggingFiles = false

            // If we auto-showed the popover and the file was NOT dropped into our app,
            // close the popover — the user dragged it somewhere else
            if self.popoverAutoShownByDrag && !self.filesWereDroppedInApp {
                self.popover?.performClose(nil)
            }

            self.popoverAutoShownByDrag = false
            self.filesWereDroppedInApp = false
        }
        dragEndWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func showPopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        guard !popover.isShown else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()

        if let contentView = popover.contentViewController?.view,
           let frameView = contentView.window?.contentView?.superview {
            if popoverBackgroundView == nil || popoverBackgroundView?.superview == nil {
                let bgView = PopoverBackgroundView(frame: frameView.bounds)
                bgView.autoresizingMask = [.width, .height]
                frameView.addSubview(bgView, positioned: .below, relativeTo: frameView)
                popoverBackgroundView = bgView
            }
        }
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up drag monitoring
        dragPollTimer?.invalidate()
        dragPollTimer = nil
        dragEndWorkItem?.cancel()
        dragEndWorkItem = nil
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
        // Clean up temporary cache directory used for downloaded/previewed files
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("CloudStash", isDirectory: true)
        if FileManager.default.fileExists(atPath: tempDir.path) {
            do {
                try FileManager.default.removeItem(at: tempDir)
            } catch {
                print("[CloudStash] Failed to clean temporary cache directory: \(error)")
            }
        }
    }
}

