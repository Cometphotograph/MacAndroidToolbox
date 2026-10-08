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
            .background(SidebarGlassBackgroundView())
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            ZStack {
                // Liquid Glass Background Ambient Glow
                LiquidDetailGlassBackgroundView()
                
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
                // Apple HIG Header: Software Name + Connection Status
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 12) {
                        Text(L10n("app_name"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        connectionStatusBadge
                    }
                    .padding(.leading, 4)
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
    
    // MARK: - Connection Status Badge (Apple HIG Style)
    @ViewBuilder
    private var connectionStatusBadge: some View {
        if let dev = deviceManager.selectedDevice {
            if deviceManager.devices.count > 1 {
                Menu {
                    ForEach(deviceManager.devices) { d in
                        Button {
                            deviceManager.selectedDevice = d
                        } label: {
                            HStack {
                                Text("\(d.displayName) (\(d.mode.title))")
                                if d.serial == dev.serial {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    connectedPill(dev)
                }
                .menuStyle(.borderlessButton)
            } else {
                connectedPill(dev)
            }
        } else {
            disconnectedPill
        }
    }
    
    private func connectedPill(_ dev: AndroidDevice) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dev.mode.color)
                .frame(width: 7, height: 7)
            
            Text("\(L10n("tb_connected")) - \(dev.displayName) (\(dev.mode.title))")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3.5)
        .background(dev.mode.color.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(dev.mode.color.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var disconnectedPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 7, height: 7)
            
            Text(L10n("tb_no_devices"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3.5)
        .background(Color.primary.opacity(0.04))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
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

