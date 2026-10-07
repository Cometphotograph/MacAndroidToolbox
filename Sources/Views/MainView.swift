import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case dashboard
    case fastboot
    case apps
    case files
    case shell
    case settings
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .dashboard: return L10n("nav_dashboard")
        case .fastboot: return L10n("nav_fastboot")
        case .apps: return L10n("nav_apps")
        case .files: return L10n("nav_files")
        case .shell: return L10n("nav_shell")
        case .settings: return L10n("nav_settings")
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "iphone"
        case .fastboot: return "bolt.horizontal.fill"
        case .apps: return "app.badge"
        case .files: return "folder.fill"
        case .shell: return "apple.terminal"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    @ObservedObject var toolConfig = ToolConfig.shared
    @State private var selectedSection: NavigationSection? = .dashboard
    @State private var isConsoleExpanded: Bool = true
    @State private var showOnboarding: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            // Native HIG Sidebar with Liquid Glass Background
            List(selection: $selectedSection) {
                Section(L10n("nav_main_navigation")) {
                    ForEach(NavigationSection.allCases) { section in
                        NavigationLink(value: section) {
                            Label {
                                Text(section.title)
                                    .font(.system(size: 13, weight: selectedSection == section ? .semibold : .regular))
                            } icon: {
                                Image(systemName: section.icon)
                                    .foregroundColor(selectedSection == section ? .accentColor : .blue)
                            }
                        }
                    }
                }
                
                Section {
                    if deviceManager.devices.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "cable.connector.slash")
                                .foregroundColor(.secondary)
                            Text(L10n("nav_no_devices"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(deviceManager.devices) { dev in
                            Button {
                                deviceManager.selectedDevice = dev
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(dev.mode.color)
                                        .frame(width: 8, height: 8)
                                        .shadow(color: dev.mode.color.opacity(0.8), radius: 2)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(dev.displayName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .lineLimit(1)
                                        Text("\(dev.serial) (\(dev.mode.title))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if deviceManager.selectedDevice?.serial == dev.serial {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text(L10n("nav_connected_devices"))
                        Spacer()
                        if !deviceManager.devices.isEmpty {
                            Text("\(deviceManager.devices.count)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(.ultraThinMaterial))
                                .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(LiquidBackgroundView())
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            ZStack {
                // Liquid Glass Background Ambient Glow
                LiquidBackgroundView()
                
                VStack(spacing: 0) {
                    // Main Detail Content
                    Group {
                        switch selectedSection ?? .dashboard {
                        case .dashboard:
                            DashboardView()
                        case .fastboot:
                            FastbootView()
                        case .apps:
                            AppManagerView()
                        case .files:
                            FileManagerView()
                        case .shell:
                            ShellToolsView()
                        case .settings:
                            SettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom Console Drawer (Liquid Glass)
                    if isConsoleExpanded {
                        Divider().opacity(0.3)
                        ConsoleView()
                            .frame(height: 220)
                    }
                }
            }
            .toolbar {
                // Device Selector (Aligned to 16pt margin matching content cards below)
                ToolbarItem(placement: .navigation) {
                    Picker(L10n("tb_select_device"), selection: Binding(
                        get: { deviceManager.selectedDevice?.serial ?? "" },
                        set: { newSerial in
                            if let matched = deviceManager.devices.first(where: { $0.serial == newSerial }) {
                                deviceManager.selectedDevice = matched
                            }
                        }
                    )) {
                        if deviceManager.devices.isEmpty {
                            Text(L10n("tb_no_devices")).tag("")
                        } else {
                            ForEach(deviceManager.devices) { dev in
                                Text("\(dev.displayName) (\(dev.mode.title))")
                                    .tag(dev.serial)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 330)
                    .padding(.leading, 8)
                }
                
                // Refresh Devices
                ToolbarItem(placement: .automatic) {
                    Button {
                        deviceManager.refreshDevices()
                    } label: {
                        Label(L10n("tb_refresh"), systemImage: "arrow.clockwise")
                    }
                    .help("\(L10n("tb_refresh")) (Cmd+R)")
                    .keyboardShortcut("r", modifiers: .command)
                }
                
                // Device Connection Mode Badge (Liquid Pill)
                ToolbarItem(placement: .status) {
                    if let dev = deviceManager.selectedDevice {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(dev.mode.color)
                                .frame(width: 7, height: 7)
                            Text(dev.mode.title)
                                .font(.caption.bold())
                                .foregroundColor(dev.mode.color)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            Capsule()
                                .stroke(dev.mode.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // Toggle Console Drawer
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation {
                            isConsoleExpanded.toggle()
                        }
                    } label: {
                        Label(
                            isConsoleExpanded ? L10n("tb_collapse_log") : L10n("tb_expand_log"),
                            systemImage: isConsoleExpanded ? "terminal.fill" : "terminal"
                        )
                    }
                    .help(isConsoleExpanded ? L10n("tb_collapse_log") : L10n("tb_expand_log"))
                }
            }
        }
        .preferredColorScheme(generalSettings.selectedTheme.colorScheme)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
                .preferredColorScheme(generalSettings.selectedTheme.colorScheme)
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        // Show disclaimer if user hasn't checked "Never remind again" or hasn't accepted yet
        let needsDisclaimer = !generalSettings.neverShowDisclaimer || !generalSettings.hasAcceptedDisclaimer
        // Show environment check if onboarding not completed and tools are missing
        let needsEnvCheck = !generalSettings.hasCompletedOnboarding && (!toolConfig.isAdbAvailable || !toolConfig.isFastbootAvailable)
        
        if needsDisclaimer || needsEnvCheck {
            showOnboarding = true
        }
    }
}

