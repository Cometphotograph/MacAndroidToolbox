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
            .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - macOS 27 Official Stoplights (Traffic Lights) Component
public struct MacOS27StoplightsView: View {
    @State private var isHoveringGroup: Bool = false
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 9) {
            // Close (14x14)
            stoplightCircle(
                baseColor: Color(red: 1.0, green: 0.36, blue: 0.38),
                glyph: "xmark",
                glyphSize: 7,
                glyphColor: Color(red: 0.45, green: 0.05, blue: 0.08)
            ) {
                if let window = NSApp.keyWindow {
                    window.performClose(nil)
                } else {
                    NSApp.terminate(nil)
                }
            }
            
            // Minimize (14x14)
            stoplightCircle(
                baseColor: Color(red: 0.98, green: 0.78, blue: 0.0),
                glyph: "minus",
                glyphSize: 7.5,
                glyphColor: Color(red: 0.50, green: 0.30, blue: 0.0)
            ) {
                NSApp.keyWindow?.miniaturize(nil)
            }
            
            // Zoom (14x14)
            stoplightCircle(
                baseColor: Color(red: 0.21, green: 0.78, blue: 0.35),
                glyph: "arrow.up.left.and.arrow.down.right",
                glyphSize: 6.5,
                glyphColor: Color(red: 0.05, green: 0.38, blue: 0.12)
            ) {
                NSApp.keyWindow?.zoom(nil)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHoveringGroup = hovering
            }
        }
    }
    
    @ViewBuilder
    private func stoplightCircle(
        baseColor: Color,
        glyph: String,
        glyphSize: CGFloat,
        glyphColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(baseColor)
                
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.60), location: 0.0),
                                .init(color: Color.white.opacity(0.15), location: 0.45),
                                .init(color: Color.clear, location: 0.60)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.50),
                                Color.black.opacity(0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
                
                if isHoveringGroup {
                    Image(systemName: glyph)
                        .font(.system(size: glyphSize, weight: .bold))
                        .foregroundColor(glyphColor)
                        .transition(.opacity)
                }
            }
            .frame(width: 14, height: 14)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - macOS 27 Liquid Glass Circular Sidebar Toggle Button (32x32)
public struct MacOS27SidebarToggleButton: View {
    let action: () -> Void
    var size: CGFloat = 32
    @State private var isHovered: Bool = false
    
    public init(size: CGFloat = 32, action: @escaping () -> Void) {
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                
                Circle()
                    .fill(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
                
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.45), location: 0.0),
                                .init(color: Color.white.opacity(0.10), location: 0.50),
                                .init(color: Color.clear, location: 0.60)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.60), location: 0.0),
                                .init(color: Color.primary.opacity(0.10), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
                
                Image(systemName: "sidebar.leading")
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundColor(isHovered ? .primary : .primary.opacity(0.85))
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(L10n("tb_toggle_sidebar"))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - macOS 27 Liquid Glass Search Bar Button (⌘K)
public struct MacOS27SearchBarButton: View {
    let action: () -> Void
    @State private var isHovered: Bool = false
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isHovered ? .primary : .secondary)
                
                Text(L10n("search_title"))
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                HStack(spacing: 1.5) {
                    Text("⌘")
                        .font(.system(size: 11, weight: .medium))
                    Text("K")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.secondary.opacity(0.8))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .padding(.horizontal, 10)
            .frame(width: 190, height: 32)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04))
                    
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.55), location: 0.0),
                                    .init(color: Color.primary.opacity(0.10), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - macOS 27 Glass Circular Action Button (32x32)
public struct MacOS27GlassCircleButton: View {
    let systemImage: String
    let tooltip: String
    var size: CGFloat = 32
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    public init(systemImage: String, tooltip: String, size: CGFloat = 32, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.tooltip = tooltip
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                
                Circle()
                    .fill(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.05))
                
                Circle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.45), location: 0.0),
                                .init(color: Color.white.opacity(0.10), location: 0.50),
                                .init(color: Color.clear, location: 0.60)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.60), location: 0.0),
                                .init(color: Color.primary.opacity(0.10), location: 1.0)
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
            .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
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

// MARK: - macOS 27 Unified Header Background (Hard Scroll Edge Effect)
public struct MacOS27HeaderBackgroundView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Native SwiftUI ultra-thin frosted glass (samples & blurs SwiftUI views underneath)
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Highly translucent tint layer so underlying button & card colors shine through
            Color(NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                    return NSColor(white: 0.10, alpha: 0.10)
                } else {
                    return NSColor(white: 0.98, alpha: 0.05)
                }
            }))
            
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.10), location: 0.0),
                    .init(color: Color.white.opacity(0.02), location: 0.35),
                    .init(color: Color.clear, location: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Window Drag Area
public struct WindowDragArea: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> WindowDragNSView {
        WindowDragNSView()
    }
    
    public func updateNSView(_ nsView: WindowDragNSView, context: Context) {}
}

public class WindowDragNSView: NSView {
    public override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

// MARK: - macOS 27 Floating Terminal Glass Background (True Frosted Translucent Liquid Glass)
public struct MacOS27FloatingTerminalGlassBackground: View {
    var cornerRadius: CGFloat
    
    public init(cornerRadius: CGFloat = 14) {
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        ZStack {
            // 1. Native SwiftUI ultra-thin frosted glass (actively blurs buttons & cards directly underneath)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // 2. Translucent tone layer: vibrant and transparent so colors (blue, orange) glow through
            Color(NSColor(name: nil, dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
                    return NSColor(white: 0.10, alpha: 0.18)
                } else {
                    return NSColor(white: 0.98, alpha: 0.08)
                }
            }))
            
            // 3. Specular liquid glass top sheen (Apple macOS 27 specular reflection)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.12), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.25),
                            .init(color: Color.clear, location: 0.50)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // 4. Subtle inner/outer specular stroke border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.30), location: 0.0),
                            .init(color: Color.white.opacity(0.08), location: 0.40),
                            .init(color: Color.primary.opacity(0.08), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        // 5. Multi-layer floating elevation shadow for genuine floating card feel
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}
