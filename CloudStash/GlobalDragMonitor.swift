//
//  GlobalDragMonitor.swift
//  CloudStash
//
//  Created for CloudStash App
//

import AppKit
import Foundation

// MARK: - Global Drag Monitor

class GlobalDragMonitor {
    
    private var dragMonitor: Any?
    private var mouseUpMonitor: Any?
    private var isDragging = false
    private var hideTimer: Timer?
    
    var onDragStarted: (() -> Void)?
    var onDragEnded: (() -> Void)?
    
    init() {}
    
    func start() {
        stop() // Ensure no duplicate monitors
        
        // Monitor for drag events (mouse dragged with button pressed)
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.handleDragEvent(event)
        }
        
        // Monitor for mouse up to detect drag end
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
        }
    }
    
    func stop() {
        if let monitor = dragMonitor {
            NSEvent.removeMonitor(monitor)
            dragMonitor = nil
        }
        
        if let monitor = mouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            mouseUpMonitor = nil
        }
        
        hideTimer?.invalidate()
        hideTimer = nil
        isDragging = false
    }
    
    private func handleDragEvent(_ event: NSEvent) {
        // Check if files are being dragged by checking the general pasteboard
        // Note: We check the drag pasteboard for file promises or file URLs
        
        if !isDragging {
            // Check if there are files on the drag pasteboard
            if isFileDrag() {
                isDragging = true
                hideTimer?.invalidate()
                hideTimer = nil
                
                DispatchQueue.main.async { [weak self] in
                    self?.onDragStarted?()
                }
            }
        }
    }
    
    private func handleMouseUp(_ event: NSEvent) {
        if isDragging {
            isDragging = false
            
            // Add a small delay before hiding to allow for the drop to complete
            hideTimer?.invalidate()
            hideTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.onDragEnded?()
                }
            }
        }
    }
    
    private func isFileDrag() -> Bool {
        // Check the drag pasteboard for file URLs
        let pasteboard = NSPasteboard(name: .drag)
        
        // Check for file URLs
        if let types = pasteboard.types {
            let fileTypes: [NSPasteboard.PasteboardType] = [
                .fileURL,
                NSPasteboard.PasteboardType("public.file-url"),
                NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url"),
                NSPasteboard.PasteboardType("NSFilenamesPboardType")
            ]
            
            for fileType in fileTypes {
                if types.contains(fileType) {
                    return true
                }
            }
            
            // Also check for file promise types (used by Finder and other apps)
            if types.contains(NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-content-type")) {
                return true
            }
        }
        
        return false
    }
    
    deinit {
        stop()
    }
}

// MARK: - Drag Session Detector

/// Alternative approach using NSDraggingInfo if needed
class DragSessionObserver: NSObject {
    
    static let shared = DragSessionObserver()
    
    var onDragSessionBegan: (() -> Void)?
    var onDragSessionEnded: (() -> Void)?
    
    private var isObserving = false
    
    override init() {
        super.init()
    }
    
    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        // Register for drag notifications if available
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(draggingSessionWillBegin),
            name: NSNotification.Name("NSDraggingSessionWillBeginNotification"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(draggingSessionEnded),
            name: NSNotification.Name("NSDraggingSessionEndedNotification"),
            object: nil
        )
    }
    
    func stopObserving() {
        isObserving = false
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func draggingSessionWillBegin(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.onDragSessionBegan?()
        }
    }
    
    @objc private func draggingSessionEnded(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.onDragSessionEnded?()
        }
    }
    
    deinit {
        stopObserving()
    }
}
