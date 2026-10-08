import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case dashboard
    case fastboot
    case recovery
    case shell
    case apps
    case files
    case settings
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .dashboard: return L10n("nav_dashboard")
        case .fastboot: return L10n("nav_fastboot")
        case .recovery: return L10n("nav_recovery")
        case .shell: return L10n("nav_shell")
        case .apps: return L10n("nav_apps")
        case .files: return L10n("nav_files")
        case .settings: return L10n("nav_settings")
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "iphone.gen3"
        case .fastboot: return "bolt.horizontal.fill"
        case .recovery: return "cross.case.fill"
        case .shell: return "apple.terminal"
        case .apps: return "app.badge.fill"
        case .files: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    public var gradientColors: [Color] {
        switch self {
        case .dashboard:
            return [Color(red: 0.10, green: 0.55, blue: 1.0), Color(red: 0.0, green: 0.70, blue: 1.0)]
        case .fastboot:
            return [Color(red: 1.0, green: 0.58, blue: 0.0), Color(red: 1.0, green: 0.38, blue: 0.0)]
        case .recovery:
            return [Color(red: 0.68, green: 0.32, blue: 0.88), Color(red: 0.52, green: 0.22, blue: 0.78)]
        case .shell:
            return [Color(red: 0.20, green: 0.32, blue: 0.45), Color(red: 0.12, green: 0.22, blue: 0.35)]
        case .apps:
            return [Color(red: 0.20, green: 0.78, blue: 0.35), Color(red: 0.15, green: 0.65, blue: 0.28)]
        case .files:
            return [Color(red: 0.98, green: 0.75, blue: 0.15), Color(red: 0.95, green: 0.60, blue: 0.08)]
        case .settings:
            return [Color(red: 0.55, green: 0.58, blue: 0.62), Color(red: 0.42, green: 0.45, blue: 0.48)]
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
    @State private var showSearchPalette: Bool = false
    @State private var hoveredSection: NavigationSection? = nil
    @State private var isSidebarVisible: Bool = true
    
    public init() {}
    
    public var body: some View {
        ZStack {
            NavigationSplitView {
                // MARK: - Native Apple Notes Style Sidebar
                VStack(spacing: 0) {
                    // Top Liquid Glass Header (Traffic lights + Search + Toggle)
                    sidebarTopHeader
                    
                    // Navigation Items & Connected Devices
                    ScrollView {
                        VStack(alignment: .leading, spacing: 3.5) {
                            // Section 1: Main Navigation Header
                            Text(L10n("nav_main_navigation"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.horizontal, 14)
                                .padding(.top, 6)
                                .padding(.bottom, 2)
                            
                            // 7 Feature Sections in Exact User Specified Order
                            ForEach(NavigationSection.allCases) { section in
                                navigationItemRow(section)
                            }
                            
                            // Section 2: Connected Devices Header
                            connectedDevicesHeader
                            
                            // Connected Devices List
                            connectedDevicesList
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 16)
                    }
                }
                .background(SidebarGlassBackgroundView())
                .navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 300)
            } detail: {
                // MARK: - Detail Content Canvas
                ZStack {
                    // Liquid Glass Background Ambient Glow
                    LiquidDetailGlassBackgroundView()
                    
                    VStack(spacing: 0) {
                        // Main Detail Content Area
                        Group {
                            switch selectedSection ?? .dashboard {
                            case .dashboard:
                                DashboardView()
                            case .fastboot:
                                FastbootView()
                            case .recovery:
                                RecoveryView()
                            case .shell:
                                ShellToolsView()
                            case .apps:
                                AppManagerView()
                            case .files:
                                FileManagerView()
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
                            if !isSidebarVisible {
                                // Glass Sidebar Expand Button when sidebar is collapsed
                                GlassCircleButton(
                                    systemImage: "sidebar.leading",
                                    tooltip: L10n("tb_toggle_sidebar"),
                                    size: 26
                                ) {
                                    toggleSidebar()
                                }
                            }
                            
                            Text(L10n("app_name"))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            
                            connectionStatusBadge
                        }
                        .padding(.leading, 4)
                    }
                    
                    // Quick Search Shortcut Trigger
                    ToolbarItem(placement: .primaryAction) {
                        GlassCircleButton(
                            systemImage: "magnifyingglass",
                            tooltip: L10n("search_title") + " (Cmd+K)",
                            size: 26
                        ) {
                            withAnimation(.easeOut(duration: 0.15)) {
                                showSearchPalette = true
                            }
                        }
                    }
                }
            }
            
            // Global Feature Search Modal (Cmd+K)
            if showSearchPalette {
                GlobalSearchPaletteView(
                    isPresented: $showSearchPalette,
                    onSelectSection: { section in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedSection = section
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(999)
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
        // Keyboard Shortcut Cmd+K for Global Search
        .background(
            Button("") {
                withAnimation(.easeOut(duration: 0.15)) {
                    showSearchPalette.toggle()
                }
            }
            .keyboardShortcut("k", modifiers: .command)
            .opacity(0)
        )
    }
    
    // MARK: - Sidebar Top Header (Glass Traffic Lights + Search + Toggle)
    private var sidebarTopHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            // Liquid Glass Specular Traffic Lights (Apple HIG)
            GlassTrafficLightsView()
                .padding(.leading, 6)
            
            Spacer()
            
            // Circular Glass Global Search Button (Search in-app features)
            GlassCircleButton(
                systemImage: "magnifyingglass",
                tooltip: L10n("search_title") + " (Cmd+K)"
            ) {
                withAnimation(.easeOut(duration: 0.15)) {
                    showSearchPalette = true
                }
            }
            
            // Circular Glass Sidebar Toggle Button
            GlassCircleButton(
                systemImage: "sidebar.leading",
                tooltip: L10n("tb_toggle_sidebar")
            ) {
                toggleSidebar()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
    
    // MARK: - Navigation Item Row (Apple Notes / HIG Spacing & Style)
    private func navigationItemRow(_ section: NavigationSection) -> some View {
        let isSelected = selectedSection == section
        let isHovered = hoveredSection == section
        
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedSection = section
            }
        } label: {
            HStack(spacing: 10) {
                // Apple Squircle Icon with Vibrant Gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: section.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 26, height: 26)
                .shadow(
                    color: isSelected ? Color.clear : section.gradientColors.first!.opacity(0.25),
                    radius: 2,
                    y: 1
                )
                
                // Section Title (SF Pro 13pt Medium)
                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                // Active Section Pill Indicator
                if section == .recovery, let dev = deviceManager.selectedDevice, (dev.mode == .recovery || dev.mode == .sideload) {
                    Text("REC")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.purple.opacity(isSelected ? 0.3 : 0.15)))
                        .foregroundColor(isSelected ? .white : .purple)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if isSelected {
                        // Vibrant selection capsule with specular top highlight
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 4, x: 0, y: 1.5)
                    } else if isHovered {
                        // Subtle interactive hover highlight
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredSection = hovering ? section : nil
        }
    }
    
    // MARK: - Connected Devices Section Header
    private var connectedDevicesHeader: some View {
        HStack {
            Text(L10n("nav_connected_devices"))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary.opacity(0.8))
            
            Spacer()
            
            if !deviceManager.devices.isEmpty {
                Text("\(deviceManager.devices.count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 2)
    }
    
    // MARK: - Connected Devices List
    @ViewBuilder
    private var connectedDevicesList: some View {
        if deviceManager.devices.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "cable.connector.slash")
                    .foregroundColor(.secondary)
                Text(L10n("nav_no_devices"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(deviceManager.selectedDevice?.serial == dev.serial ? Color.primary.opacity(0.06) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Toggle Sidebar Action
    private func toggleSidebar() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            isSidebarVisible.toggle()
        }
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
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
