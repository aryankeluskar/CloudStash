//
//  ShelfWindow.swift
//  DropOver
//
//  Created for DropOver App
//

import AppKit
import SwiftUI

// MARK: - Shelf Panel (Floating Window)

class ShelfPanel: NSPanel {
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 340),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure panel behavior
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        // Hide standard window buttons
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Position in top-right corner
        positionInTopRight()
        
        // Register for screen change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func screenParametersChanged() {
        positionInTopRight()
    }
    
    func positionInTopRight() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = self.frame.size
        let padding: CGFloat = 20
        
        let x = screenFrame.maxX - windowSize.width - padding
        let y = screenFrame.maxY - windowSize.height - padding
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func showWithAnimation() {
        guard !self.isVisible else { return }
        
        // Start with alpha 0 and slightly offset
        self.alphaValue = 0
        let finalOrigin = self.frame.origin
        self.setFrameOrigin(NSPoint(x: finalOrigin.x + 20, y: finalOrigin.y))
        
        self.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
            self.animator().setFrameOrigin(finalOrigin)
        }
    }
    
    func hideWithAnimation(completion: (() -> Void)? = nil) {
        guard self.isVisible else {
            completion?()
            return
        }
        
        let finalOrigin = NSPoint(x: self.frame.origin.x + 20, y: self.frame.origin.y)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
            self.animator().setFrameOrigin(finalOrigin)
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.positionInTopRight()
            self?.alphaValue = 1
            completion?()
        })
    }
}

// MARK: - Shelf Window Controller

class ShelfWindowController: NSWindowController {
    
    private let shelfManager: ShelfManager
    
    init(shelfManager: ShelfManager) {
        self.shelfManager = shelfManager
        
        let panel = ShelfPanel()
        super.init(window: panel)
        
        // Set up the SwiftUI content
        let shelfView = ShelfView(manager: shelfManager) { [weak self] in
            self?.hide()
        }
        
        let hostingView = NSHostingView(rootView: shelfView)
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        // Create a visual effect view for the background
        let visualEffect = NSVisualEffectView()
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.frame = panel.contentView?.bounds ?? .zero
        visualEffect.autoresizingMask = [.width, .height]
        
        // Add hosting view on top of visual effect
        visualEffect.addSubview(hostingView)
        
        panel.contentView = visualEffect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isVisible: Bool {
        window?.isVisible ?? false
    }
    
    func show() {
        (window as? ShelfPanel)?.showWithAnimation()
    }
    
    func hide() {
        (window as? ShelfPanel)?.hideWithAnimation()
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func showForDrag() {
        // Show the shelf when a drag operation is detected
        if !isVisible {
            show()
        }
    }
}
