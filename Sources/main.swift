import SwiftUI
import AppKit
import Darwin

// MARK: - Single Instance Enforcement (禁止重複開啟)
@MainActor
private func enforceSingleInstance() -> Int32 {
    let lockPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("com.macandroid.toolbox.single_instance.lock")
    let fd = open(lockPath, O_CREAT | O_RDWR, 0o666)
    guard fd >= 0 else {
        return -1
    }
    
    // Attempt non-blocking exclusive flock
    if flock(fd, LOCK_EX | LOCK_NB) != 0 {
        // Another instance is already running!
        
        // 1. Activate the existing running instance
        let currentPid = ProcessInfo.processInfo.processIdentifier
        let bundleId = Bundle.main.bundleIdentifier ?? "com.macandroid.toolbox"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
        
        if let existingApp = runningApps.first(where: { $0.processIdentifier != currentPid }) {
            existingApp.activate(options: .activateIgnoringOtherApps)
        } else {
            // Read PID from lock file if bundleId didn't match (e.g. command line launch)
            var buf = [CChar](repeating: 0, count: 32)
            lseek(fd, 0, SEEK_SET)
            let n = read(fd, &buf, 31)
            if n > 0 {
                buf[n] = 0
                let pidStr = buf.withUnsafeBufferPointer { ptr in
                    String(cString: ptr.baseAddress!)
                }.trimmingCharacters(in: .whitespacesAndNewlines)
                if let pid = pid_t(pidStr), let app = NSRunningApplication(processIdentifier: pid) {
                    app.activate(options: .activateIgnoringOtherApps)
                }
            }
        }
        
        // 2. Display alert informing the user
        let alert = NSAlert()
        alert.messageText = L10n("app_already_running_title")
        alert.informativeText = L10n("app_already_running_desc")
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n("btn_ok"))
        alert.runModal()
        
        // 3. Terminate this duplicate instance
        exit(0)
    }
    
    // First instance: record PID in lock file
    ftruncate(fd, 0)
    let pidStr = "\(ProcessInfo.processInfo.processIdentifier)\n"
    _ = pidStr.withCString { ptr in
        write(fd, ptr, strlen(ptr))
    }
    
    return fd
}

// Global reference holding the lock file descriptor for the app's lifetime
private let gSingleInstanceLockFd = enforceSingleInstance()

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Initialize Status Bar controller
        StatusBarController.shared.setup()
        
        // Apply saved appearance theme
        GeneralSettingsManager.shared.selectedTheme.apply()
        
        // Configure native unified window appearance (Apple HIG)
        DispatchQueue.main.async { [weak self] in
            self?.setupWindowAppearance()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupWindowAppearance()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                for window in NSApp.windows {
                    self?.configureWindow(window)
                }
            }
        }
    }
    
    private func setupWindowAppearance() {
        for window in NSApp.windows {
            configureWindow(window)
        }
    }
    
    private func configureWindow(_ window: NSWindow) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                configureWindow(window)
                window.makeKeyAndOrderFront(self)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // If Menu Bar icon is enabled, keep app alive in background
        return !GeneralSettingsManager.shared.isShowMenuBarIconEnabled
    }
}

struct MacAndroidToolboxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    
    var body: some Scene {
        WindowGroup(L10n("app_name")) {
            MainView()
                .frame(minWidth: 1000, minHeight: 680)
                .environmentObject(languageManager)
                .environmentObject(generalSettings)
                .preferredColorScheme(generalSettings.selectedTheme.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandMenu(L10n("nav_connected_devices")) {
                Button(L10n("tb_refresh")) {
                    DeviceManager.shared.refreshDevices()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("清空日誌記錄") {
                    DeviceManager.shared.clearLogs()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
            }
        }
    }
}

MacAndroidToolboxApp.main()
