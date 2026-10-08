import SwiftUI
import AppKit

// MARK: - Liquid Glass Design System
public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var isInteractive: Bool
    
    public init(cornerRadius: CGFloat = 16, padding: CGFloat = 14, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.isInteractive = isInteractive
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Frosted glass core
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle ambient fluid color wash
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Specular highlight edge
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.45), location: 0.0),
                                    .init(color: Color.white.opacity(0.15), location: 0.35),
                                    .init(color: Color.white.opacity(0.05), location: 0.7),
                                    .init(color: Color.white.opacity(0.2), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

public struct LiquidGlassGroupBoxStyle: GroupBoxStyle {
    var cornerRadius: CGFloat = 16
    
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            configuration.label
                .font(.headline)
                .foregroundColor(.primary)
            
            configuration.content
        }
        .liquidGlassCard(cornerRadius: cornerRadius, padding: 14)
    }
}

public struct LiquidGlassButtonStyle: ButtonStyle {
    var tintColor: Color? = nil
    var isProminent: Bool = false
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (tintColor ?? Color.accentColor).opacity(0.85),
                                        (tintColor ?? Color.accentColor).opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.thinMaterial)
                    }
                    
                    // Specular glass rim
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isProminent ? 0.6 : 0.35),
                                    Color.white.opacity(isProminent ? 0.15 : 0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .foregroundColor(isProminent ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: (tintColor ?? Color.black).opacity(isProminent ? 0.25 : 0.06), radius: 4, x: 0, y: 2)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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

// MARK: - Sidebar Frosted Glass Background (Apple Settings style with subtle cool gray)
public struct SidebarGlassBackgroundView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // 1. Native macOS sidebar frosted glass (blurs wallpaper/windows behind)
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
            
            // 2. Apple System Settings subtle cool gray tint
            Color(NSColor.windowBackgroundColor).opacity(0.55)
            Color.primary.opacity(0.04)
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
            
            // 2. Translucent control surface for contrast and legibility
            Color(NSColor.controlBackgroundColor).opacity(0.68)
            
            // 3. Subtle ambient fluid light
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.04), Color.cyan.opacity(0.02), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: w * 0.35
                        )
                    )
                    .frame(width: w * 0.6, height: w * 0.6)
                    .position(x: w * 0.85, y: h * 0.45)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.04), Color.indigo.opacity(0.02), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: w * 0.4
                        )
                    )
                    .frame(width: w * 0.7, height: w * 0.7)
                    .position(x: w * 0.15, y: h * 0.80)
                    .blur(radius: 60)
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

// View Extensions for convenience
public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 16, padding: CGFloat = 14) -> some View {
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
