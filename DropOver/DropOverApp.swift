//
//  DropOverApp.swift
//  DropOver
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
struct DropOverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([UploadedFile.self])
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
    var settingsWindow: NSWindow?
    var popoverBackgroundView: PopoverBackgroundView?
    
    // Shelf components
    var shelfManager: ShelfManager?
    var shelfWindowController: ShelfWindowController?
    var globalDragMonitor: GlobalDragMonitor?
    
    // Track if shelf should auto-hide after drag
    private var shelfWasOpenedByDrag = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Setup model container
        let schema = Schema([UploadedFile.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Setup shelf components
        setupShelf()
        
        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "DropOver")
            button.action = #selector(statusBarClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .semitransient
        popover?.animates = true
        
        let contentView = ContentView()
            .modelContainer(modelContainer!)
            .environment(\.openSettingsAction, OpenSettingsAction { [weak self] in
                self?.openSettings()
            })
        popover?.contentViewController = NSHostingController(rootView: contentView)
        
        // Register URL scheme handler for OAuth
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    // MARK: - Shelf Setup
    
    private func setupShelf() {
        shelfManager = ShelfManager()
        shelfWindowController = ShelfWindowController(shelfManager: shelfManager!)
        
        // Setup global drag monitor
        globalDragMonitor = GlobalDragMonitor()
        globalDragMonitor?.onDragStarted = { [weak self] in
            guard let self = self else { return }
            if !(self.shelfWindowController?.isVisible ?? false) {
                self.shelfWasOpenedByDrag = true
                self.shelfWindowController?.showForDrag()
            }
        }
        globalDragMonitor?.onDragEnded = { [weak self] in
            // Don't auto-hide - let the user close it manually or drop files
            // The shelf stays open so the user can complete their action
        }
        
        globalDragMonitor?.start()
    }
    
    // MARK: - Status Bar Actions
    
    @objc func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right click - show context menu
            showContextMenu()
        } else {
            // Left click - toggle shelf (primary action)
            toggleShelf()
        }
    }
    
    func toggleShelf() {
        // Close popover if open
        if popover?.isShown == true {
            popover?.performClose(nil)
        }
        
        shelfWasOpenedByDrag = false
        shelfWindowController?.toggle()
    }
    
    func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        // Close shelf if open
        if shelfWindowController?.isVisible == true {
            shelfWindowController?.hide()
        }
        
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
        
        menu.addItem(NSMenuItem(title: "Show Shelf", action: #selector(menuShowShelf), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Uploads", action: #selector(menuShowPopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(menuOpenSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DropOver", action: #selector(menuQuit), keyEquivalent: "q"))
        
        for item in menu.items {
            item.target = self
        }
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func menuShowShelf() {
        toggleShelf()
    }
    
    @objc func menuShowPopover() {
        togglePopover()
    }
    
    @objc func menuOpenSettings() {
        openSettings()
    }
    
    @objc func menuQuit() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Settings
    
    func openSettings() {
        // Close popover and shelf first
        popover?.performClose(nil)
        shelfWindowController?.hide()
        
        // Check if settings window already exists
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "DropOver Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        
        // Center the window on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - OAuth URL Handler
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        
        // Handle OAuth callback
        if url.scheme == "com.dropover.app" && url.host == "oauth2callback" {
            Task {
                do {
                    try await GoogleDriveService.shared.handleOAuthCallback(url: url)
                    
                    // Refresh UI
                    await MainActor.run {
                        // Close settings window and reopen to show signed-in state
                        if let window = self.settingsWindow, window.isVisible {
                            window.close()
                            self.openSettings()
                        }
                    }
                } catch {
                    await MainActor.run {
                        let alert = NSAlert()
                        alert.messageText = "Sign In Failed"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    // MARK: - Cleanup
    
    func applicationWillTerminate(_ notification: Notification) {
        globalDragMonitor?.stop()
        shelfManager?.cleanupTempFiles()
    }
}

// Custom environment key for opening settings
struct OpenSettingsAction {
    let action: () -> Void
    
    func callAsFunction() {
        action()
    }
}

struct OpenSettingsActionKey: EnvironmentKey {
    static let defaultValue = OpenSettingsAction { }
}

extension EnvironmentValues {
    var openSettingsAction: OpenSettingsAction {
        get { self[OpenSettingsActionKey.self] }
        set { self[OpenSettingsActionKey.self] = newValue }
    }
}
