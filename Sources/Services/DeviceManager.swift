import Foundation
import SwiftUI
import Combine

@MainActor
public class DeviceManager: ObservableObject {
    public static let shared = DeviceManager()
    
    @Published public var devices: [AndroidDevice] = []
    @Published public var selectedDevice: AndroidDevice?
    @Published public var logs: [LogEntry] = []
    @Published public var isRefreshing: Bool = false
    @Published public var isBusy: Bool = false
    @Published public var statusMessage: String = "就緒"
    @Published public var logFilter: LogLevel? = nil
    
    private var pollTimer: Timer?
    
    private init() {
        ProcessRunner.shared.logHandler = { [weak self] level, text, isPolling in
            DispatchQueue.main.async {
                self?.appendLog(level: level, text: text, isPolling: isPolling)
            }
        }
        
        appendLog(level: .info, text: "Mac Android 刷機與除錯工具箱已啟動")
        startAutoPolling()
        refreshDevices()
    }
    
    public func startAutoPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isBusy, !self.isRefreshing else { return }
                self.refreshDevices(silent: true)
            }
        }
    }
    
    public func stopAutoPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    public func appendLog(level: LogLevel, text: String, isPolling: Bool = false) {
        if isPolling && !GeneralSettingsManager.shared.isShowPollingLogsEnabled {
            return
        }
        let entry = LogEntry(level: level, text: text, isPolling: isPolling)
        logs.append(entry)
        if logs.count > 1500 {
            logs.removeFirst(200)
        }
    }
    
    public func clearLogs() {
        logs.removeAll()
        appendLog(level: .info, text: "日誌已清空")
    }
    
    public func refreshDevices(silent: Bool = false) {
        if !silent {
            isRefreshing = true
            appendLog(level: .info, text: "正在掃描連接的 Android 設備 (ADB & Fastboot)...")
        }
        
        Task {
            let adbDevs = await ADBService.shared.getDevices(isPolling: true)
            let fbDevs = await FastbootService.shared.getDevices(isPolling: true)
            
            // Deduplicate devices if any
            var allDevs: [AndroidDevice] = []
            var seenSerials = Set<String>()
            
            for dev in fbDevs {
                if !seenSerials.contains(dev.serial) {
                    allDevs.append(dev)
                    seenSerials.insert(dev.serial)
                }
            }
            
            for dev in adbDevs {
                if !seenSerials.contains(dev.serial) {
                    allDevs.append(dev)
                    seenSerials.insert(dev.serial)
                }
            }
            
            self.devices = allDevs
            
            // Maintain selection or select first
            if let current = self.selectedDevice, let matched = allDevs.first(where: { $0.serial == current.serial }) {
                self.selectedDevice = matched
            } else {
                self.selectedDevice = allDevs.first
            }
            
            if !silent {
                self.isRefreshing = false
                if allDevs.isEmpty {
                    self.appendLog(level: .warning, text: "未檢測到任何連接的設備。請檢查 USB 線與調試授權。")
                } else {
                    self.appendLog(level: .success, text: "檢測完成，找到 \(allDevs.count) 台設備。")
                }
            }
            
            StatusBarController.shared.rebuildMenu()
        }
    }
}
