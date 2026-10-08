import SwiftUI
import AppKit

// MARK: - Liquid Glass Design System (Apple macOS HIG)

public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var isInteractive: Bool
    
    public init(cornerRadius: CGFloat = 16, padding: CGFloat = 16, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isInteractive = isInteractive
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // 1. Frosted glass core
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 2. Subtle translucent white surface
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            Color(NSColor(name: nil, dynamicProvider: { appearance in
                                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                                    return NSColor(white: 0.18, alpha: 0.35)
                                } else {
                                    return NSColor(white: 1.0, alpha: 0.45)
                                }
                            }))
                        )
                    
                    // 3. Specular highlight border
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.0),
                                    .init(color: Color.white.opacity(0.20), location: 0.35),
                                    .init(color: Color.primary.opacity(0.05), location: 0.7),
                                    .init(color: Color.white.opacity(0.15), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

public struct LiquidGlassButtonStyle: ButtonStyle {
    var tintColor: Color? = nil
    var isProminent: Bool = false
    
    public init(tintColor: Color? = nil, isProminent: Bool = false) {
        self.tintColor = tintColor
        self.isProminent = isProminent
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        let tint = tintColor ?? Color.accentColor
        
        return configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isProminent {
                        // 1. Frosted glass foundation
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // 2. Vibrant Apple translucent tint gradient
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(configuration.isPressed ? 0.95 : 0.90),
                                        tint.opacity(configuration.isPressed ? 0.85 : 0.78)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 3. High-reflection specular liquid glass top sheen
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.55), location: 0.0),
                                        .init(color: Color.white.opacity(0.18), location: 0.42),
                                        .init(color: Color.clear, location: 0.50)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 4. Brilliant specular rim border
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.85), location: 0.0),
                                        .init(color: Color.white.opacity(0.30), location: 0.35),
                                        .init(color: Color.black.opacity(0.20), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    } else {
                        // 1. Translucent frosted glass core
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        // 2. Dynamic translucent surface
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                Color(NSColor(name: nil, dynamicProvider: { appearance in
                                    if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                                        return NSColor(white: 0.25, alpha: configuration.isPressed ? 0.50 : 0.35)
                                    } else {
                                        return NSColor(white: 1.0, alpha: configuration.isPressed ? 0.80 : 0.60)
                                    }
                                }))
                            )
                        
                        // 3. Subtle specular sheen
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.35), location: 0.0),
                                        .init(color: Color.white.opacity(0.08), location: 0.45),
                                        .init(color: Color.clear, location: 0.52)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // 4. Specular glass rim
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color.white.opacity(0.70), location: 0.0),
                                        .init(color: Color.white.opacity(0.20), location: 0.40),
                                        .init(color: Color.black.opacity(0.08), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.9
                            )
                    }
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(
                color: isProminent ? tint.opacity(0.35) : Color.black.opacity(0.06),
                radius: isProminent ? 7 : 3,
                x: 0,
                y: isProminent ? 2.5 : 1
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Native macOS Frosted Glass (Behind Window Sampling)
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode
    public let state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.autoresizingMask = [.width, .height]
        return view
    }

    public func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
    }
}

// MARK: - Sidebar Frosted Glass Background (Apple Notes Style)
public struct SidebarGlassBackgroundView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Native macOS sidebar frosted glass (blurs wallpaper/windows behind)
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            
            // 2. Apple Notes sidebar exact neutral cool gray wash
            Color(NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                    return NSColor(white: 0.16, alpha: 0.60)
                } else {
                    return NSColor(red: 0.935, green: 0.935, blue: 0.950, alpha: 0.72)
                }
            }))
            
            // 3. Subtle depth separator line on the trailing edge (1px native divider)
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 1)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Detail Liquid Glass Background (Translucent glass like Apple official)
public struct LiquidDetailGlassBackgroundView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Native macOS behind-window frosted glass
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
            
            // 2. Translucent surface for authentic Apple desktop sampling
            Color(NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                    return NSColor(white: 0.10, alpha: 0.20)
                } else {
                    return NSColor(white: 0.98, alpha: 0.25)
                }
            }))
            
            // 3. Subtle ambient fluid lights
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.05), Color.cyan.opacity(0.02), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: w * 0.35
                        )
                    )
                    .frame(width: w * 0.6, height: w * 0.6)
                    .position(x: w * 0.85, y: h * 0.35)
                    .blur(radius: 70)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.05), Color.indigo.opacity(0.02), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: w * 0.4
                        )
                    )
                    .frame(width: w * 0.7, height: w * 0.7)
                    .position(x: w * 0.15, y: h * 0.75)
                    .blur(radius: 70)
            }
        }
        .ignoresSafeArea()
    }
}

public struct LiquidBackgroundView: View {
    public init() {}
    
    public var body: some View {
        LiquidDetailGlassBackgroundView()
    }
}

// MARK: - Circular Glass Toolbar Button (Apple Notes Style)
public struct GlassCircleButton: View {
    let systemImage: String
    let tooltip: String
    var size: CGFloat = 30
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(systemImage: String, tooltip: String, size: CGFloat = 30, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.tooltip = tooltip
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Glass background
                Circle()
                    .fill(isHovered ? Color.primary.opacity(0.14) : Color.primary.opacity(0.08))
                
                // Specular glass rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.primary.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
                
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundColor(isHovered ? .primary : .primary.opacity(0.85))
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// View Extensions for convenience
public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    func liquidGlassButton(tint: Color? = nil, prominent: Bool = false) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(tintColor: tint, isProminent: prominent))
    }
    
    @ViewBuilder
    func withoutFocusRing() -> some View {
        if #available(macOS 14.0, *) {
            self.focusable(false)
                .focusEffectDisabled()
        } else {
            self.focusable(false)
        }
    }
}
