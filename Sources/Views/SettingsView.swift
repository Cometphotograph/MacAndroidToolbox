import SwiftUI

public struct SettingsView: View {
    @ObservedObject var toolConfig = ToolConfig.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var selectedSettingsTab: Int = 0
    @State private var showOnboardingSheet: Bool = false
    @State private var showSponsorSheet: Bool = false
    @State private var showEmailCopiedAlert: Bool = false
    @State private var showCopiedToast: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    // Liquid Glass Segmented Header
                    Picker("", selection: $selectedSettingsTab) {
                        Text(L10n("settings_tab_general")).tag(0)
                        Text(L10n("settings_tab_tools")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                    .padding(.top, 4)
                    
                    if selectedSettingsTab == 0 {
                        generalSettingsSection
                    } else {
                        toolBinariesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 220)
            }
            .scrollContentBackground(.hidden)
            
            // Floating liquid glass copy toast prompt
            if showCopiedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n("email_copied_toast"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView()
                .preferredColorScheme(generalSettings.selectedTheme.colorScheme)
        }
        .sheet(isPresented: $showSponsorSheet) {
            SponsorView()
                .preferredColorScheme(generalSettings.selectedTheme.colorScheme)
        }
        .alert(isPresented: $showEmailCopiedAlert) {
            Alert(
                title: Text(L10n("email_copied_title")),
                message: Text(L10n("email_copied_msg")),
                dismissButton: .default(Text(L10n("common_ok")))
            )
        }
    }
    
    // MARK: - General Settings
    private var generalSettingsSection: some View {
        VStack(spacing: 18) {
            // About & Version Card (Liquid Glass style)
            aboutAppCard
            
            // Environment & Disclaimer Guide Quick Action
            HStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n("settings_open_onboarding"))
                        .font(.subheadline.bold())
                    Text(L10n("settings_open_onboarding_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showOnboardingSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver")
                        Text(L10n("onboarding_env_title"))
                    }
                }
                .liquidGlassButton(tint: .blue)
            }
            .liquidGlassCard(cornerRadius: 16, padding: 14)
            
            // General Preferences Card
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(L10n("settings_tab_general"), systemImage: "gearshape.2.fill")
                        .font(.headline)
                    Spacer()
                }
                
                Divider().opacity(0.4)
                
                // Language Picker
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(L10n("settings_language"), systemImage: "globe")
                            .font(.subheadline.bold())
                        Spacer()
                        Picker("", selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    Text(L10n("settings_language_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().opacity(0.4)
                
                // Appearance Theme Switcher (浅色模式、深色模式、跟随系统)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(L10n("theme_setting_title"), systemImage: "circle.righthalf.filled")
                            .font(.subheadline.bold())
                        Spacer()
                        
                        // Unified Segmented Control (Icon + Text combined in single button)
                        HStack(spacing: 2) {
                            ForEach(AppTheme.allCases) { theme in
                                let isSelected = generalSettings.selectedTheme == theme
                                Button {
                                    generalSettings.selectedTheme = theme
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: theme.icon)
                                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : .secondary)
                                        
                                        Text(theme.title)
                                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .white : .primary)
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .contentShape(Rectangle())
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSelected ? Color.blue : Color.primary.opacity(0.001))
                                    )
                                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 2, y: 1)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                                .withoutFocusRing()
                            }
                        }
                        .padding(3)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    Text(L10n("theme_setting_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().opacity(0.4)
                
                // Launch at Login Toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $generalSettings.isLaunchAtLoginEnabled) {
                        Label(L10n("settings_launch_at_login"), systemImage: "power")
                            .font(.subheadline.bold())
                    }
                    .toggleStyle(.switch)
                    
                    Text(L10n("settings_launch_at_login_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().opacity(0.4)
                
                // Show in Menu Bar Toggle
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Toggle(isOn: $generalSettings.isShowMenuBarIconEnabled) {
                            HStack(spacing: 8) {
                                Label(L10n("settings_show_menu_bar"), systemImage: "menubar.arrow.up.rectangle")
                                    .font(.subheadline.bold())
                                
                                // Mini Android Robot Preview Badge
                                HStack(spacing: 3) {
                                    Image(systemName: "iphone.gen3")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("Android")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .clipShape(Capsule())
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    
                    Text(L10n("settings_show_menu_bar_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().opacity(0.4)
                
                // Show Polling Logs Toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $generalSettings.isShowPollingLogsEnabled) {
                        Label(L10n("settings_show_polling"), systemImage: "terminal")
                            .font(.subheadline.bold())
                    }
                    .toggleStyle(.switch)
                    
                    Text(L10n("settings_show_polling_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider().opacity(0.4)
                
                // Author Credit Row & Sponsor
                HStack {
                    Label(L10n("settings_author"), systemImage: "person.crop.circle.fill")
                        .font(.subheadline.bold())
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Link(destination: URL(string: "https://space.bilibili.com/432147890?spm_id_from=333.337.0.0")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "play.tv.fill")
                                    .font(.caption)
                                Text("bilibili@EchoIM_")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.pink.opacity(0.12))
                            .foregroundColor(.pink)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.pink.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Link(destination: URL(string: "https://github.com/Cometphotograph/MacAndroidToolbox")!) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.caption)
                                Text("GitHub")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.primary.opacity(0.08))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        // Matching style Email control (blue tint with border)
                        Button {
                            copyAuthorEmail()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption)
                                Text("magicalgirlkrea@gmail.com")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help("点击复制作者邮箱: magicalgirlkrea@gmail.com")
                        
                        Button {
                            showSponsorSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(L10n("sponsor_btn"))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .liquidGlassCard(cornerRadius: 16, padding: 16)
            
            // Connection Guide Card
            connectionGuideGroup
        }
    }
    
    // MARK: - About & Version Card
    private var aboutAppCard: some View {
        HStack(spacing: 18) {
            // App Icon with specular glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.green.opacity(0.3), Color.cyan.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)
                
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(L10n("app_name"))
                        .font(.title2.bold())
                    
                    // Version Tag (v1.0.2)
                    Text(languageManager.appVersion)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                    
                    Text("Build \(languageManager.appBuild)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(L10n("app_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Author Tag & Link + Sponsor Button
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("\(L10n("settings_author")): ")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Link(destination: URL(string: "https://space.bilibili.com/432147890?spm_id_from=333.337.0.0")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.tv.fill")
                                    .font(.system(size: 10))
                                Text("bilibili@EchoIM_")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.pink.opacity(0.12))
                            .foregroundColor(.pink)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.pink.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Link(destination: URL(string: "https://github.com/Cometphotograph/MacAndroidToolbox")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 10))
                                Text("GitHub")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.08))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        // Matching style Email control (blue tint with border)
                        Button {
                            copyAuthorEmail()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 10))
                                Text("magicalgirlkrea@gmail.com")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help("点击复制作者邮箱: magicalgirlkrea@gmail.com")
                    }
                    
                    // Sponsor Button
                    Button {
                        showSponsorSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(L10n("sponsor_btn"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
                
                Text(L10n("app_copyright"))
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.top, 1)
            }
            
            Spacer()
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Tool Binaries Section
    private var toolBinariesSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Label(L10n("settings_tab_tools"), systemImage: "wrench.and.screwdriver.fill")
                    .font(.headline)
                
                Text(L10n("settings_tools_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().opacity(0.4)
                
                // ADB Path
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n("settings_adb_path"))
                            .font(.caption.bold())
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(toolConfig.isAdbAvailable ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(toolConfig.adbVersionString)
                                .font(.caption)
                                .foregroundColor(toolConfig.isAdbAvailable ? .green : .red)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        TextField(L10n("settings_adb_path"), text: $toolConfig.adbPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseAdbPath()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // Fastboot Path
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n("settings_fastboot_path"))
                            .font(.caption.bold())
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(toolConfig.isFastbootAvailable ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(toolConfig.fastbootVersionString)
                                .font(.caption)
                                .foregroundColor(toolConfig.isFastbootAvailable ? .green : .red)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        TextField(L10n("settings_fastboot_path"), text: $toolConfig.fastbootPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseFastbootPath()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // EDL (Qualcomm 9008) Path
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n("settings_edl_path"))
                            .font(.caption.bold())
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(toolConfig.isEdlAvailable ? Color.green : Color.orange)
                                .frame(width: 8, height: 8)
                            Text(toolConfig.edlVersionString)
                                .font(.caption)
                                .foregroundColor(toolConfig.isEdlAvailable ? .green : .orange)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        TextField(L10n("settings_edl_path"), text: $toolConfig.edlPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseEdlPath()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // Python 3 Path
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n("settings_python3_path"))
                            .font(.caption.bold())
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(toolConfig.isPython3Available ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(toolConfig.python3VersionString)
                                .font(.caption)
                                .foregroundColor(toolConfig.isPython3Available ? .green : .red)
                        }
                    }
                    
                    HStack(spacing: 10) {
                        TextField(L10n("settings_python3_path"), text: $toolConfig.python3Path)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            choosePython3Path()
                        }
                        .liquidGlassButton()
                    }
                }
                
                HStack(spacing: 12) {
                    Button(L10n("settings_recheck")) {
                        toolConfig.checkTools()
                    }
                    .liquidGlassButton(tint: .blue, prominent: true)
                    
                    Button(L10n("settings_autodetect")) {
                        toolConfig.resetToDefaults()
                    }
                    .liquidGlassButton()
                    
                    Button {
                        showOnboardingSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text(L10n("settings_open_onboarding"))
                        }
                    }
                    .liquidGlassButton(tint: .indigo)
                }
            }
            .liquidGlassCard(cornerRadius: 16, padding: 16)
        }
    }
    
    // MARK: - Guide Group
    private var connectionGuideGroup: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n("guide_title"), systemImage: "questionmark.circle.fill")
                .font(.headline)
            
            Divider().opacity(0.4)
            
            guideItem(
                number: "1",
                title: L10n("guide_item_1_title"),
                content: L10n("guide_item_1_content")
            )
            
            Divider().opacity(0.4)
            
            guideItem(
                number: "2",
                title: L10n("guide_item_2_title"),
                content: L10n("guide_item_2_content")
            )
            
            Divider().opacity(0.4)
            
            guideItem(
                number: "3",
                title: L10n("guide_item_3_title"),
                content: L10n("guide_item_3_content")
            )
            
            Divider().opacity(0.4)
            
            guideItem(
                number: "4",
                title: L10n("guide_item_4_title"),
                content: L10n("guide_item_4_content")
            )
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private func guideItem(number: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.blue))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func chooseAdbPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "選擇 adb 二進位檔案"
        
        if panel.runModal() == .OK, let url = panel.url {
            toolConfig.adbPath = url.path
            toolConfig.checkTools()
        }
    }
    
    private func chooseFastbootPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "選擇 fastboot 二進位檔案"
        
        if panel.runModal() == .OK, let url = panel.url {
            toolConfig.fastbootPath = url.path
            toolConfig.checkTools()
        }
    }
    
    private func chooseEdlPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "選擇 edl 執行檔或 edl.py 腳本"
        
        if panel.runModal() == .OK, let url = panel.url {
            toolConfig.edlPath = url.path
            toolConfig.checkTools()
        }
    }
    
    private func choosePython3Path() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.prompt = "選擇 python3 二進位檔案"
        
        if panel.runModal() == .OK, let url = panel.url {
            toolConfig.python3Path = url.path
            toolConfig.checkTools()
        }
    }
    
    private func copyAuthorEmail() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("magicalgirlkrea@gmail.com", forType: .string)
        showEmailCopiedAlert = true
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                showCopiedToast = false
            }
        }
    }
}
