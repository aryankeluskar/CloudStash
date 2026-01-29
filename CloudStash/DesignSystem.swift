//
//  DesignSystem.swift
//  CloudStash
//
//  Created for CloudStash App Redesign
//

import SwiftUI

// MARK: - App Theme Modifier

struct AppThemeModifier: ViewModifier {
    @State private var theme = SettingsManager.shared.appTheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
            .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
                 // Re-read theme if needed, though usually bound to settings
            }
    }
    
    private var colorScheme: ColorScheme? {
        switch SettingsManager.shared.appTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

extension View {
    func applyAppTheme() -> some View {
        modifier(AppThemeModifier())
    }
}

// MARK: - Animated Background (Lively Mode)

struct LivelyBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    // Pastels for light mode
    let colors: [Color] = [
        Color(hex: "FF9A9E"), // Soft Pink
        Color(hex: "FECFEF"), // Pale Pink
        Color(hex: "A18CD1"), // Soft Purple
        Color(hex: "FBC2EB"), // Lavender
        Color(hex: "8FD3F4"), // Sky Blue
        Color(hex: "84FAB0")  // Mint
    ].map { $0.opacity(0.4) }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Base background
                Color(nsColor: .windowBackgroundColor).opacity(0.5)
                
                if colorScheme == .light {
                    // Animated Blobs
                    ForEach(0..<4) { index in
                        BlobView(
                            color: colors[index % colors.count],
                            size: CGSize(width: proxy.size.width * 0.8, height: proxy.size.width * 0.8),
                            offset: animate ? randomOffset(in: proxy.size) : randomOffset(in: proxy.size)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 10...20))
                            .repeatForever(autoreverses: true),
                            value: animate
                        )
                    }
                    
                    // Glass Overlay to blur the blobs
                    VisualEffectView(material: .headerView, blendingMode: .behindWindow)
                        .opacity(0.3)
                    
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animate = true
        }
    }
    
    func randomOffset(in size: CGSize) -> CGSize {
        CGSize(
            width: CGFloat.random(in: -size.width/2...size.width/2),
            height: CGFloat.random(in: -size.height/2...size.height/2)
        )
    }
}

struct BlobView: View {
    let color: Color
    let size: CGSize
    let offset: CGSize
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .blur(radius: 60)
            .offset(offset)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    var hoverEffect: Bool = false
    @State private var isHovered = false
    
    init(hoverEffect: Bool = false, @ViewBuilder content: () -> Content) {
        self.hoverEffect = hoverEffect
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    if colorScheme == .light {
                        // Light Mode: Glassy white with blur
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.4))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    } else {
                        // Dark Mode: Standard translucent dark
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            .strokeBorder(Color(nsColor: .separatorColor).opacity(0.2), lineWidth: 0.5)
                    }
                }
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .light ? (isHovered && hoverEffect ? 0.1 : 0.05) : 0.2),
                radius: isHovered && hoverEffect ? 10 : 5,
                x: 0,
                y: isHovered && hoverEffect ? 4 : 2
            )
            .scaleEffect(isHovered && hoverEffect ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Helper to access NSVisualEffectView in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
