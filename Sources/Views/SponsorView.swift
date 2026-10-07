import SwiftUI
import AppKit

public func loadResourceImage(named filename: String) -> NSImage? {
    let baseName = (filename as NSString).deletingPathExtension
    let ext = (filename as NSString).pathExtension
    
    // 1. Try Bundle.main url
    if let url = Bundle.main.url(forResource: baseName, withExtension: ext),
       let img = NSImage(contentsOf: url) {
        return img
    }
    
    // 2. Try Bundle.main resourceURL
    if let resUrl = Bundle.main.resourceURL?.appendingPathComponent(filename),
       FileManager.default.fileExists(atPath: resUrl.path),
       let img = NSImage(contentsOf: resUrl) {
        return img
    }
    
    // 3. Try app bundle executable folder sibling ../Resources
    if let execUrl = Bundle.main.executableURL {
        let resPath = execUrl.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/\(filename)")
        if FileManager.default.fileExists(atPath: resPath.path),
           let img = NSImage(contentsOf: resPath) {
            return img
        }
    }
    
    // 4. Try current working directory Resources/
    let cwdPath = FileManager.default.currentDirectoryPath + "/Resources/\(filename)"
    if FileManager.default.fileExists(atPath: cwdPath),
       let img = NSImage(contentsOfFile: cwdPath) {
            return img
    }
    
    // 5. Try candidate workspace project paths
    let candidatePaths = [
        "/Users/comet/mac android/Resources/\(filename)",
        "/Users/comet/mac andriod/Resources/\(filename)",
        "/Users/comet/寫點小程序/mac andriod/Resources/\(filename)",
        "/Users/comet/写点小程序/mac andriod/Resources/\(filename)"
    ]
    for path in candidatePaths {
        if FileManager.default.fileExists(atPath: path),
           let img = NSImage(contentsOfFile: path) {
            return img
        }
    }
    
    return nil
}

public enum SponsorPaymentMethod: String, CaseIterable, Identifiable {
    case alipay
    case wechat
    case paypal
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .alipay: return L10n("sponsor_method_alipay")
        case .wechat: return L10n("sponsor_method_wechat")
        case .paypal: return L10n("sponsor_method_paypal")
        }
    }
    
    @MainActor
    public var subtitle: String {
        switch self {
        case .alipay: return L10n("sponsor_method_alipay_desc")
        case .wechat: return L10n("sponsor_method_wechat_desc")
        case .paypal: return L10n("sponsor_method_paypal_desc")
        }
    }
    
    public var icon: String {
        switch self {
        case .alipay: return "creditcard.fill"
        case .wechat: return "message.fill"
        case .paypal: return "globe.asia.australia.fill"
        }
    }
    
    public var brandColor: Color {
        switch self {
        case .alipay: return Color(red: 0.08, green: 0.49, blue: 0.98)
        case .wechat: return Color(red: 0.09, green: 0.75, blue: 0.35)
        case .paypal: return Color(red: 0.0, green: 0.38, blue: 0.88)
        }
    }
    
    public var filename: String {
        switch self {
        case .alipay: return "sponsor_alipay.png"
        case .wechat: return "sponsor_wechat.jpg"
        case .paypal: return "sponsor_paypal.png"
        }
    }
    
    public func loadNSImage() -> NSImage? {
        return loadResourceImage(named: filename)
    }
}

public struct SponsorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMethod: SponsorPaymentMethod = .alipay
    @State private var showSavedToast: Bool = false
    @State private var leftAvatar: NSImage? = nil
    @State private var rightAvatar: NSImage? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            Divider().opacity(0.3)
            
            ScrollView(showsIndicators: false) {
                contentSection
            }
            
            Divider().opacity(0.3)
            
            footerBar
        }
        .frame(width: 580, height: 690)
        .background(LiquidBackgroundView())
        .onAppear {
            if leftAvatar == nil {
                leftAvatar = loadResourceImage(named: "sponsor_avatar_left.png")
            }
            if rightAvatar == nil {
                rightAvatar = loadResourceImage(named: "sponsor_avatar_right.png")
            }
        }
    }
    
    // MARK: - Header Bar (Edge-hugging cutout illustrations & Centered Heart + Title)
    private var headerBar: some View {
        ZStack(alignment: .top) {
            // Edge-hugging Left & Right Illustrations
            HStack {
                if let img = leftAvatar {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 2, y: 3)
                }
                
                Spacer()
                
                if let img = rightAvatar {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: -2, y: 3)
                }
            }
            .padding(.horizontal, 0)
            .padding(.top, 0)
            
            // Center Content: Heart Icon + Enlarged Title & Subtitle
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pink.opacity(0.4), Color.orange.opacity(0.18), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 22
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 21))
                        .foregroundColor(.pink)
                }
                
                Text(L10n("sponsor_title"))
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(L10n("sponsor_subtitle"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 115)
            .padding(.top, 14)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Scrollable Content Section
    private var contentSection: some View {
        VStack(spacing: 14) {
            methodSelectorTabs
            
            qrCodeCard
            
            // Thank You Footer Banner with larger font size
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .bold))
                Text(L10n("sponsor_copy_tip"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Payment Method Tabs
    private var methodSelectorTabs: some View {
        HStack(spacing: 12) {
            ForEach(SponsorPaymentMethod.allCases) { method in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMethod = method
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: method.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedMethod == method ? .white : method.brandColor)
                        
                        Text(method.title)
                            .font(.system(size: 13, weight: selectedMethod == method ? .bold : .medium))
                            .foregroundColor(selectedMethod == method ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedMethod == method ? method.brandColor : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedMethod == method ? method.brandColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: selectedMethod == method ? method.brandColor.opacity(0.35) : .clear, radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .withoutFocusRing()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }
    
    // MARK: - QR Code Card
    private var qrCodeCard: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 10, y: 4)
                
                if let nsImage = selectedMethod.loadNSImage() {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("收款碼載入中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 285, height: 335)
            
            // Instruction text
            HStack(spacing: 6) {
                Circle()
                    .fill(selectedMethod.brandColor)
                    .frame(width: 8, height: 8)
                
                Text(selectedMethod.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Footer Control Bar (Larger Buttons)
    private var footerBar: some View {
        HStack(spacing: 16) {
            // Save QR Code button (larger)
            Button {
                saveQRCodeToDownloads()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showSavedToast ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(showSavedToast ? .green : .accentColor)
                    Text(showSavedToast ? L10n("sponsor_saved_toast") : L10n("sponsor_save_image"))
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .liquidGlassButton()
            .withoutFocusRing()
            
            Spacer()
            
            // Close button (larger)
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                    Text(L10n("sponsor_close"))
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
            }
            .liquidGlassButton(tint: .blue, prominent: true)
            .keyboardShortcut(.cancelAction)
            .withoutFocusRing()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Save QR Action
    private func saveQRCodeToDownloads() {
        guard let nsImage = selectedMethod.loadNSImage() else { return }
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
        
        let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        let targetUrl = downloadsDir.appendingPathComponent("MacAndroidToolbox_Sponsor_\(selectedMethod.rawValue.capitalized).png")
        
        do {
            try pngData.write(to: targetUrl)
            withAnimation {
                showSavedToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSavedToast = false
                }
            }
        } catch {
            print("Failed to save sponsor QR: \(error)")
        }
    }
}
