import AppKit
import SwiftUI

@MainActor
public final class StatusBarController: NSObject {
    public static let shared = StatusBarController()
    
    private var statusItem: NSStatusItem?
    
    private override init() {
        super.init()
    }
    
    public func setup() {
        if GeneralSettingsManager.shared.isShowMenuBarIconEnabled {
            createStatusItem()
        }
    }
    
    public func updateVisibility(enabled: Bool) {
        if enabled {
            if statusItem == nil {
                createStatusItem()
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = createAndroidRobotIcon()
            button.imagePosition = .imageOnly
            button.toolTip = L10n("app_name")
        }
        
        self.statusItem = item
        rebuildMenu()
    }
    
    public func rebuildMenu() {
        guard let item = statusItem else { return }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let devices = DeviceManager.shared.devices
        let selectedDev = DeviceManager.shared.selectedDevice
        
        // Header / Status Item
        if devices.isEmpty {
            let noDevItem = NSMenuItem(title: L10n("nav_no_devices"), action: nil, keyEquivalent: "")
            noDevItem.isEnabled = false
            menu.addItem(noDevItem)
        } else {
            let title = selectedDev != nil ? "📱 \(selectedDev!.displayName) (\(selectedDev!.mode.title))" : String(format: L10n("menu_connected_count"), devices.count)
            let devItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            devItem.isEnabled = false
            menu.addItem(devItem)
            
            // Submenu for Quick Reboots
            let rebootSubmenu = NSMenu()
            
            let rbSystem = NSMenuItem(title: L10n("reboot_target_system"), action: #selector(rebootSystem), keyEquivalent: "")
            rbSystem.target = self
            rebootSubmenu.addItem(rbSystem)
            
            let rbRecovery = NSMenuItem(title: L10n("reboot_target_recovery"), action: #selector(rebootRecovery), keyEquivalent: "")
            rbRecovery.target = self
            rebootSubmenu.addItem(rbRecovery)
            
            let rbBootloader = NSMenuItem(title: L10n("reboot_target_bootloader"), action: #selector(rebootBootloader), keyEquivalent: "")
            rbBootloader.target = self
            rebootSubmenu.addItem(rbBootloader)
            
            let rbFastbootD = NSMenuItem(title: L10n("reboot_target_fastbootd"), action: #selector(rebootFastbootD), keyEquivalent: "")
            rbFastbootD.target = self
            rebootSubmenu.addItem(rbFastbootD)
            
            let rebootParent = NSMenuItem(title: "⚡️ \(L10n("dash_quick_reboot"))...", action: nil, keyEquivalent: "")
            menu.setSubmenu(rebootSubmenu, for: rebootParent)
            menu.addItem(rebootParent)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Main Window
        let openWindowItem = NSMenuItem(title: L10n("menu_open_main"), action: #selector(openMainWindow), keyEquivalent: "o")
        openWindowItem.target = self
        menu.addItem(openWindowItem)
        
        // Refresh Devices
        let refreshItem = NSMenuItem(title: L10n("menu_refresh"), action: #selector(refreshDevicesAction), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit Application
        let quitItem = NSMenuItem(title: L10n("menu_quit"), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        item.menu = menu
    }
    
    // MARK: - Actions
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
    
    @objc private func refreshDevicesAction() {
        DeviceManager.shared.refreshDevices()
    }
    
    @objc private func rebootSystem() {
        guard let dev = DeviceManager.shared.selectedDevice else { return }
        Task {
            if dev.mode == .fastboot || dev.mode == .fastbootd {
                try? await FastbootService.shared.reboot(serial: dev.serial, target: .system)
            } else {
                try? await ADBService.shared.reboot(serial: dev.serial, target: .system)
            }
        }
    }
    
    @objc private func rebootRecovery() {
        guard let dev = DeviceManager.shared.selectedDevice else { return }
        Task {
            if dev.mode == .fastboot || dev.mode == .fastbootd {
                try? await FastbootService.shared.reboot(serial: dev.serial, target: .recovery)
            } else {
                try? await ADBService.shared.reboot(serial: dev.serial, target: .recovery)
            }
        }
    }
    
    @objc private func rebootBootloader() {
        guard let dev = DeviceManager.shared.selectedDevice else { return }
        Task {
            if dev.mode == .fastboot || dev.mode == .fastbootd {
                try? await FastbootService.shared.reboot(serial: dev.serial, target: .bootloader)
            } else {
                try? await ADBService.shared.reboot(serial: dev.serial, target: .bootloader)
            }
        }
    }
    
    @objc private func rebootFastbootD() {
        guard let dev = DeviceManager.shared.selectedDevice else { return }
        Task {
            if dev.mode == .fastboot || dev.mode == .fastbootd {
                try? await FastbootService.shared.reboot(serial: dev.serial, target: .fastbootd)
            } else {
                try? await ADBService.shared.reboot(serial: dev.serial, target: .fastbootd)
            }
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Android Robot Icon Generator for macOS Menu Bar
    private func createAndroidRobotIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.clear(CGRect(origin: .zero, size: size))
        
        // Draw Antennas
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.6)
        ctx.setLineCap(.round)
        
        // Left antenna
        ctx.move(to: CGPoint(x: 5.5, y: 12.0))
        ctx.addLine(to: CGPoint(x: 3.2, y: 15.5))
        ctx.strokePath()
        
        // Right antenna
        ctx.move(to: CGPoint(x: 12.5, y: 12.0))
        ctx.addLine(to: CGPoint(x: 14.8, y: 15.5))
        ctx.strokePath()
        
        // Draw Android Head (Dome)
        let headCenter = CGPoint(x: 9.0, y: 3.5)
        let headRadius: CGFloat = 6.8
        
        ctx.setFillColor(NSColor.black.cgColor)
        ctx.addArc(center: headCenter, radius: headRadius, startAngle: 0, endAngle: .pi, clockwise: false)
        ctx.fillPath()
        
        // Cut out Eyes
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        let eyeSize: CGFloat = 1.6
        ctx.fillEllipse(in: CGRect(x: 5.2, y: 6.2, width: eyeSize, height: eyeSize))
        ctx.fillEllipse(in: CGRect(x: 11.2, y: 6.2, width: eyeSize, height: eyeSize))
        ctx.restoreGState()
        
        image.unlockFocus()
        image.isTemplate = true // Automatically inverts color with macOS dark/light mode
        return image
    }
}
