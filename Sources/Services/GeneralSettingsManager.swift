import Foundation
import SwiftUI
import ServiceManagement

public enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .system: return L10n("theme_system")
        case .light: return L10n("theme_light")
        case .dark: return L10n("theme_dark")
        }
    }
    
    public var icon: String {
        switch self {
        case .system: return "circle.righthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    @MainActor
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            let isDark = GeneralSettingsManager.isSystemInDarkMode
            return isDark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    @MainActor
    public func apply() {
        guard let app = NSApp else { return }
        let targetAppearance: NSAppearance?
        switch self {
        case .system:
            targetAppearance = nil
        case .light:
            targetAppearance = NSAppearance(named: .aqua)
        case .dark:
            targetAppearance = NSAppearance(named: .darkAqua)
        }
        app.appearance = targetAppearance
        for window in app.windows {
            window.appearance = targetAppearance
            window.invalidateShadow()
            window.contentView?.needsLayout = true
            window.contentView?.needsDisplay = true
        }
    }
}

@MainActor
public final class GeneralSettingsManager: ObservableObject {
    public static let shared = GeneralSettingsManager()
    
    private let kSelectedThemeKey = "kSelectedAppTheme"
    private let kLaunchAtLoginKey = "kLaunchAtLoginKey"
    private let kShowMenuBarIconKey = "kShowMenuBarIconKey"
    private let kShowPollingLogsKey = "kShowPollingLogsKey"
    private let kHasAcceptedDisclaimerKey = "kHasAcceptedDisclaimerKey"
    private let kNeverShowDisclaimerKey = "kNeverShowDisclaimerKey"
    private let kHasCompletedOnboardingKey = "kHasCompletedOnboardingKey"
    
    public static var isSystemInDarkMode: Bool {
        if let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") {
            return style.caseInsensitiveCompare("dark") == .orderedSame
        }
        if let app = NSApp, app.appearance == nil {
            return app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }
    
    @Published public var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: kSelectedThemeKey)
            selectedTheme.apply()
            objectWillChange.send()
        }
    }
    
    @Published public var isLaunchAtLoginEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLaunchAtLoginEnabled, forKey: kLaunchAtLoginKey)
            applyLaunchAtLogin(isLaunchAtLoginEnabled)
        }
    }
    
    @Published public var isShowMenuBarIconEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShowMenuBarIconEnabled, forKey: kShowMenuBarIconKey)
            StatusBarController.shared.updateVisibility(enabled: isShowMenuBarIconEnabled)
        }
    }
    
    @Published public var isShowPollingLogsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShowPollingLogsEnabled, forKey: kShowPollingLogsKey)
        }
    }
    
    @Published public var hasAcceptedDisclaimer: Bool {
        didSet {
            UserDefaults.standard.set(hasAcceptedDisclaimer, forKey: kHasAcceptedDisclaimerKey)
        }
    }
    
    @Published public var neverShowDisclaimer: Bool {
        didSet {
            UserDefaults.standard.set(neverShowDisclaimer, forKey: kNeverShowDisclaimerKey)
        }
    }
    
    @Published public var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: kHasCompletedOnboardingKey)
        }
    }
    
    private init() {
        // Read defaults
        let savedThemeRaw = UserDefaults.standard.string(forKey: kSelectedThemeKey) ?? AppTheme.system.rawValue
        let theme = AppTheme(rawValue: savedThemeRaw) ?? .system
        let savedLaunchAtLogin = UserDefaults.standard.bool(forKey: kLaunchAtLoginKey)
        let savedShowMenuBar = UserDefaults.standard.object(forKey: kShowMenuBarIconKey) == nil ? true : UserDefaults.standard.bool(forKey: kShowMenuBarIconKey)
        let savedShowPollingLogs = UserDefaults.standard.bool(forKey: kShowPollingLogsKey)
        let savedAcceptedDisclaimer = UserDefaults.standard.bool(forKey: kHasAcceptedDisclaimerKey)
        let savedNeverShowDisclaimer = UserDefaults.standard.bool(forKey: kNeverShowDisclaimerKey)
        let savedCompletedOnboarding = UserDefaults.standard.bool(forKey: kHasCompletedOnboardingKey)
        
        self.selectedTheme = theme
        self.isLaunchAtLoginEnabled = savedLaunchAtLogin
        self.isShowMenuBarIconEnabled = savedShowMenuBar
        self.isShowPollingLogsEnabled = savedShowPollingLogs
        self.hasAcceptedDisclaimer = savedAcceptedDisclaimer
        self.neverShowDisclaimer = savedNeverShowDisclaimer
        self.hasCompletedOnboarding = savedCompletedOnboarding
        
        // Check actual SMAppService status if available
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled {
                self.isLaunchAtLoginEnabled = true
            }
        }
        
        // Listen to system appearance changes
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.selectedTheme == .system {
                    self.selectedTheme.apply()
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    private func applyLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                        DeviceManager.shared.appendLog(level: .info, text: "已設定開機自動啟動")
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                        DeviceManager.shared.appendLog(level: .info, text: "已關閉開機自動啟動")
                    }
                }
            } catch {
                DeviceManager.shared.appendLog(level: .warning, text: "設定開機啟動狀態失敗: \(error.localizedDescription)")
            }
        }
    }
    
    public func acceptDisclaimer(neverRemind: Bool) {
        self.hasAcceptedDisclaimer = true
        self.neverShowDisclaimer = neverRemind
    }
    
    public func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
}
