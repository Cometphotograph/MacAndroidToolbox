import SwiftUI
import AppKit

public struct OnboardingView: View {
    @ObservedObject var toolConfig = ToolConfig.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var neverRemind: Bool = false
    @State private var isInstallingBrew: Bool = false
    @State private var installLogs: [String] = []
    @State private var installError: String? = nil
    @State private var isCopied: Bool = false
    @State private var activeStep: Int = 0 // 0: Disclaimer, 1: Environment Check
    
    public init() {}
    
    private var areToolsReady: Bool {
        return toolConfig.isAdbAvailable && toolConfig.isFastbootAvailable
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar with Liquid Glass Accent
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.35), Color.blue.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 28
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n("onboarding_title"))
                        .font(.title3.bold())
                    Text(L10n("app_subtitle"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Step Indicator Pills
                HStack(spacing: 6) {
                    stepPill(index: 0, title: L10n("onboarding_disclaimer_title"), icon: "exclamationmark.shield")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    stepPill(index: 1, title: L10n("onboarding_env_title"), icon: "wrench.and.screwdriver")
                }
                
                if generalSettings.hasAcceptedDisclaimer {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .withoutFocusRing()
                    .padding(.leading, 6)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            Divider().opacity(0.3)
            
            // Content Body
            ScrollView {
                VStack(spacing: 20) {
                    if activeStep == 0 {
                        disclaimerSection
                    } else {
                        environmentCheckSection
                    }
                }
                .padding(22)
            }
            
            Divider().opacity(0.3)
            
            // Footer Control Bar
            HStack(spacing: 12) {
                if activeStep == 0 {
                    if generalSettings.hasAcceptedDisclaimer {
                        Button(L10n("btn_cancel")) {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(role: .destructive) {
                            NSApp.terminate(nil)
                        } label: {
                            Text(L10n("onboarding_disagree_quit"))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Button {
                        generalSettings.acceptDisclaimer(neverRemind: neverRemind)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeStep = 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(L10n("onboarding_agree_continue"))
                            Image(systemName: "arrow.right")
                        }
                    }
                    .liquidGlassButton(tint: .blue, prominent: true)
                    .controlSize(.large)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeStep = 0
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text(L10n("onboarding_disclaimer_title"))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    if !areToolsReady {
                        Button {
                            generalSettings.completeOnboarding()
                            dismiss()
                        } label: {
                            Text(L10n("onboarding_skip"))
                        }
                        .liquidGlassButton()
                    }
                    
                    Button {
                        generalSettings.completeOnboarding()
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text(L10n("onboarding_start_app"))
                            Image(systemName: "checkmark")
                        }
                    }
                    .liquidGlassButton(tint: areToolsReady ? .green : .blue, prominent: true)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
        .frame(width: 660, height: 600)
        .background(LiquidBackgroundView())
        .onAppear {
            neverRemind = generalSettings.neverShowDisclaimer
            if generalSettings.hasAcceptedDisclaimer && generalSettings.neverShowDisclaimer {
                activeStep = 1
            } else {
                activeStep = 0
            }
            toolConfig.checkTools()
        }
    }
    
    // MARK: - Step Indicator
    private func stepPill(index: Int, title: String, icon: String) -> some View {
        Button {
            if generalSettings.hasAcceptedDisclaimer || index == 0 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeStep = index
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: activeStep == index ? .bold : .regular))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(activeStep == index ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05))
            .foregroundColor(activeStep == index ? .accentColor : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(activeStep == index ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .withoutFocusRing()
    }
    
    // MARK: - Disclaimer Section
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n("onboarding_disclaimer_title"))
                        .font(.headline)
                    Text("Risk Notice & Terms of Use")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // Red Open-Source & Anti-Resale Notice Banner
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                
                Text(L10n("onboarding_opensource_notice"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
            )
            
            // Styled Scrollable Disclaimer Box
            ScrollView {
                Text(L10n("onboarding_disclaimer_content"))
                    .font(.system(size: 13, weight: .regular))
                    .lineSpacing(5)
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .padding(14)
            }
            .frame(minHeight: 220, maxHeight: 260)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(NSColor.textBackgroundColor).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            // "Don't Remind Again" Checkbox
            HStack {
                Toggle(isOn: $neverRemind) {
                    HStack(spacing: 6) {
                        Text(L10n("onboarding_dont_remind"))
                            .font(.subheadline.bold())
                    }
                }
                .toggleStyle(.checkbox)
                Spacer()
            }
            .padding(.top, 4)
        }
        .liquidGlassCard(cornerRadius: 18, padding: 20)
    }
    
    // MARK: - Environment Check Section
    private var environmentCheckSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "cpu")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n("onboarding_env_title"))
                        .font(.headline)
                    Text(L10n("onboarding_env_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    toolConfig.checkTools()
                } label: {
                    Label(L10n("onboarding_recheck_btn"), systemImage: "arrow.clockwise")
                        .font(.caption.bold())
                }
                .liquidGlassButton()
            }
            
            Divider().opacity(0.3)
            
            // Status Cards for ADB and Fastboot
            VStack(spacing: 10) {
                toolStatusRow(
                    name: "ADB (Android Debug Bridge)",
                    path: toolConfig.adbPath,
                    version: toolConfig.adbVersionString,
                    isReady: toolConfig.isAdbAvailable,
                    readyText: L10n("onboarding_env_adb_ready")
                )
                
                toolStatusRow(
                    name: "Fastboot (Bootloader Flasher)",
                    path: toolConfig.fastbootPath,
                    version: toolConfig.fastbootVersionString,
                    isReady: toolConfig.isFastbootAvailable,
                    readyText: L10n("onboarding_env_fb_ready")
                )
            }
            
            // Installation / Homebrew Guidance Card
            if areToolsReady {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n("onboarding_brew_install_success"))
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                        Text(L10n("dash_scan_manual"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.green.opacity(0.3), lineWidth: 1))
            } else {
                if toolConfig.isHomebrewAvailable {
                    brewInstallActionCard
                } else {
                    brewMissingActionCard
                }
            }
            
            // Live Install Output Terminal
            if isInstallingBrew || !installLogs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(L10n("console_title"), systemImage: "terminal")
                            .font(.caption.bold())
                        Spacer()
                        if isInstallingBrew {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(installLogs, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 110)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .liquidGlassCard(cornerRadius: 18, padding: 20)
    }
    
    // Tool Status Row Component
    private func toolStatusRow(name: String, path: String, version: String, isReady: Bool, readyText: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isReady ? .green : .red)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 13, weight: .bold))
                    Text(isReady ? readyText : L10n("settings_tools_status_not_found"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isReady ? .green : .red)
                }
                
                Text(isReady ? "\(version) • \(path)" : path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isReady ? Color.green.opacity(0.06) : Color.red.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isReady ? Color.green.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Brew Install Action Card
    private var brewInstallActionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "mug.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n("onboarding_brew_detected"))
                        .font(.system(size: 13, weight: .bold))
                    if let brew = toolConfig.homebrewPath {
                        Text(brew)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            
            Button {
                startBrewInstall()
            } label: {
                HStack {
                    if isInstallingBrew {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                        Text(L10n("onboarding_brew_installing"))
                    } else {
                        Image(systemName: "bolt.fill")
                        Text(L10n("onboarding_brew_install_btn"))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .liquidGlassButton(tint: .blue, prominent: true)
            .disabled(isInstallingBrew)
            .controlSize(.large)
        }
        .padding(14)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.blue.opacity(0.25), lineWidth: 1))
    }
    
    // Brew Missing Action Card
    private var brewMissingActionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n("onboarding_brew_missing"))
                        .font(.system(size: 13, weight: .bold))
                    Text(L10n("onboarding_brew_missing_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                // Open Brew Website in Browser
                Button {
                    if let url = URL(string: "https://brew.sh") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "safari")
                        Text(L10n("onboarding_open_brew_website"))
                    }
                }
                .liquidGlassButton(tint: .orange, prominent: true)
                
                // Copy install command to clipboard
                Button {
                    copyBrewInstallCommand()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? L10n("onboarding_cmd_copied") : L10n("onboarding_copy_brew_cmd"))
                    }
                }
                .liquidGlassButton()
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.orange.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - Actions
    private func startBrewInstall() {
        isInstallingBrew = true
        installLogs.removeAll()
        installError = nil
        
        Task {
            do {
                let success = try await toolConfig.installPlatformToolsViaBrew { line in
                    DispatchQueue.main.async {
                        self.installLogs.append(line)
                    }
                }
                DispatchQueue.main.async {
                    self.isInstallingBrew = false
                    if success {
                        self.toolConfig.checkTools()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isInstallingBrew = false
                    self.installError = error.localizedDescription
                    self.installLogs.append("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func copyBrewInstallCommand() {
        let cmd = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}
