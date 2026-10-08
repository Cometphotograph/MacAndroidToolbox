import Foundation
import SwiftUI

public enum ADBRebootTarget: String, CaseIterable, Identifiable, Sendable {
    case system = "重新啟動系統 (System)"
    case recovery = "重啟至 Recovery (恢復模式)"
    case bootloader = "重啟至 Bootloader (Fastboot)"
    case fastbootd = "重啟至 FastbootD (動態分區刷機)"
    case edl = "重啟至 EDL / 9008 (高通深刷模式)"
    case powerOff = "關閉設備電源 (Power Off)"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .system: return "arrow.counterclockwise"
        case .recovery: return "cross.case.fill"
        case .bootloader: return "bolt.horizontal.fill"
        case .fastbootd: return "cpu"
        case .edl: return "flame.fill"
        case .powerOff: return "power"
        }
    }
    
    @MainActor
    public var title: String {
        switch self {
        case .system: return L10n("reboot_target_system")
        case .recovery: return L10n("reboot_target_recovery")
        case .bootloader: return L10n("reboot_target_bootloader")
        case .fastbootd: return L10n("reboot_target_fastbootd")
        case .edl: return L10n("reboot_target_edl")
        case .powerOff: return L10n("reboot_target_poweroff")
        }
    }
}

@MainActor
public final class ADBService {
    public static let shared = ADBService()
    
    private var adbPath: String {
        return ToolConfig.shared.adbPath
    }
    
    private init() {}
    
    // MARK: - Device Discovery
    public func getDevices(isPolling: Bool = true) async -> [AndroidDevice] {
        guard ToolConfig.shared.isAdbAvailable else { return [] }
        
        do {
            let res = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["devices", "-l"], isPolling: isPolling)
            var devices: [AndroidDevice] = []
            
            let lines = res.stdout.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("List of devices") || trimmed.hasPrefix("*") {
                    continue
                }
                
                let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 2 else { continue }
                
                let serial = parts[0]
                let stateString = parts[1]
                
                var mode: DeviceConnectionMode = .unknown
                switch stateString {
                case "device": mode = .adb
                case "unauthorized": mode = .unauthorized
                case "recovery": mode = .recovery
                case "sideload": mode = .sideload
                case "offline": mode = .offline
                case "bootloader", "fastboot": mode = .fastboot
                default: mode = .unknown
                }
                
                var model = "Android Device"
                var product = ""
                var brand = ""
                
                for part in parts.dropFirst(2) {
                    if part.hasPrefix("model:") {
                        model = part.replacingOccurrences(of: "model:", with: "").replacingOccurrences(of: "_", with: " ")
                    } else if part.hasPrefix("product:") {
                        product = part.replacingOccurrences(of: "product:", with: "")
                    } else if part.hasPrefix("device:") {
                        brand = part.replacingOccurrences(of: "device:", with: "")
                    }
                }
                
                var dev = AndroidDevice(
                    serial: serial,
                    mode: mode,
                    model: model,
                    brand: brand,
                    product: product
                )
                
                if mode == .adb {
                    await enrichDeviceInfo(&dev, isPolling: isPolling)
                }
                
                devices.append(dev)
            }
            return devices
        } catch {
            return []
        }
    }
    
    private func enrichDeviceInfo(_ device: inout AndroidDevice, isPolling: Bool = true) async {
        let serial = device.serial
        
        // Brand & Model
        if let brand = try? await runShellSimple(serial: serial, command: "getprop ro.product.brand", isPolling: isPolling), !brand.isEmpty {
            device.brand = brand.capitalized
        }
        if let model = try? await runShellSimple(serial: serial, command: "getprop ro.product.model", isPolling: isPolling), !model.isEmpty {
            device.model = model
        }
        
        // Android & SDK version
        if let ver = try? await runShellSimple(serial: serial, command: "getprop ro.build.version.release", isPolling: isPolling) {
            device.androidVersion = ver
        }
        if let sdkStr = try? await runShellSimple(serial: serial, command: "getprop ro.build.version.sdk", isPolling: isPolling), let sdk = Int(sdkStr) {
            device.sdkVersion = sdk
        }
        if let patch = try? await runShellSimple(serial: serial, command: "getprop ro.build.version.security_patch", isPolling: isPolling) {
            device.securityPatch = patch
        }
        
        // Battery Stats
        if let batteryOut = try? await runShellSimple(serial: serial, command: "dumpsys battery", isPolling: isPolling) {
            parseBattery(batteryOut, into: &device)
        }
        
        // Root check
        if let rootCheck = try? await runShellSimple(serial: serial, command: "which su", isPolling: isPolling), rootCheck.contains("su") {
            device.isRooted = true
        }
        
        // Display Resolution & Density
        if let wmSize = try? await runShellSimple(serial: serial, command: "wm size", isPolling: isPolling) {
            device.screenResolution = wmSize.replacingOccurrences(of: "Physical size: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let wmDensity = try? await runShellSimple(serial: serial, command: "wm density", isPolling: isPolling) {
            device.screenDensity = wmDensity.replacingOccurrences(of: "Physical density: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines) + " dpi"
        }
        
        // IP Address
        if let ipOut = try? await runShellSimple(serial: serial, command: "ip route", isPolling: isPolling) {
            for line in ipOut.components(separatedBy: .newlines) {
                if line.contains("src ") {
                    let parts = line.components(separatedBy: " ")
                    if let idx = parts.firstIndex(of: "src"), idx + 1 < parts.count {
                        device.ipAddress = parts[idx + 1]
                        break
                    }
                }
            }
        }
        
        // SoC / Chipset Info
        let socCmd = "echo [sm]:$(getprop ro.soc.model); echo [bp]:$(getprop ro.board.platform); echo [mf]:$(getprop ro.soc.manufacturer); echo [hw]:$(getprop ro.hardware); echo [hc]:$(getprop ro.hardware.chipname); echo [ci]:$(grep Hardware /proc/cpuinfo | head -n 1)"
        if let socOut = try? await runShellSimple(serial: serial, command: socCmd, isPolling: isPolling) {
            parseSocInfo(socOut, into: &device)
        }
    }
    
    private func parseSocInfo(_ output: String, into device: inout AndroidDevice) {
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[sm]:") {
                let val = trimmed.replacingOccurrences(of: "[sm]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { device.socModel = val }
            } else if trimmed.hasPrefix("[bp]:") {
                let val = trimmed.replacingOccurrences(of: "[bp]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { device.boardPlatform = val }
            } else if trimmed.hasPrefix("[mf]:") {
                let val = trimmed.replacingOccurrences(of: "[mf]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { device.socManufacturer = val }
            } else if trimmed.hasPrefix("[hw]:") {
                let val = trimmed.replacingOccurrences(of: "[hw]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { device.hardwareChip = val }
            } else if trimmed.hasPrefix("[hc]:") {
                let val = trimmed.replacingOccurrences(of: "[hc]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty && device.socModel == nil { device.socModel = val }
            } else if trimmed.hasPrefix("[ci]:") {
                let val = trimmed.replacingOccurrences(of: "[ci]:", with: "").trimmingCharacters(in: .whitespaces)
                if !val.isEmpty { device.cpuinfoHardware = val }
            }
        }
    }
    
    private func parseBattery(_ output: String, into device: inout AndroidDevice) {
        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("level:") {
                if let val = Int(trimmed.replacingOccurrences(of: "level:", with: "").trimmingCharacters(in: .whitespaces)) {
                    device.batteryLevel = val
                }
            } else if trimmed.hasPrefix("temperature:") {
                if let val = Double(trimmed.replacingOccurrences(of: "temperature:", with: "").trimmingCharacters(in: .whitespaces)) {
                    device.batteryTemperature = val / 10.0
                }
            } else if trimmed.hasPrefix("status:") {
                let statusVal = trimmed.replacingOccurrences(of: "status:", with: "").trimmingCharacters(in: .whitespaces)
                switch statusVal {
                case "2": device.batteryStatus = "充電中"
                case "3": device.batteryStatus = "放電中"
                case "4": device.batteryStatus = "未充電"
                case "5": device.batteryStatus = "已充飽"
                default: device.batteryStatus = "正常"
                }
            }
        }
    }
    
    // MARK: - Reboot Commands
    public func reboot(serial: String, target: ADBRebootTarget) async throws {
        var args = ["-s", serial]
        switch target {
        case .system:
            args.append("reboot")
        case .recovery:
            args.append(contentsOf: ["reboot", "recovery"])
        case .bootloader:
            args.append(contentsOf: ["reboot", "bootloader"])
        case .fastbootd:
            args.append(contentsOf: ["reboot", "fastboot"])
        case .edl:
            args.append(contentsOf: ["reboot", "edl"])
        case .powerOff:
            args.append(contentsOf: ["shell", "reboot", "-p"])
        }
        
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: args)
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? "重啟指令執行失敗" : result.stderr])
        }
    }
    
    // MARK: - Wireless ADB
    public func enableTcpIp(serial: String, port: Int = 5555) async throws {
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "tcpip", "\(port)"])
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr])
        }
    }
    
    public func connectWireless(ip: String, port: Int = 5555) async throws -> String {
        let target = "\(ip):\(port)"
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["connect", target])
        if !result.isSuccess || result.stdout.contains("unable to connect") || result.stdout.contains("failed to connect") {
            throw NSError(domain: "ADBError", code: 1, userInfo: [NSLocalizedDescriptionKey: result.stdout.isEmpty ? result.stderr : result.stdout])
        }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func disconnectWireless(target: String) async throws {
        _ = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["disconnect", target])
    }
    
    // MARK: - Package Management
    public func listPackages(serial: String, filter: PackageFilterType) async -> [PackageInfo] {
        var filterArg = ""
        switch filter {
        case .thirdParty: filterArg = "-3"
        case .system: filterArg = "-s"
        case .disabled: filterArg = "-d"
        case .all: filterArg = ""
        }
        
        var args = ["-s", serial, "shell", "pm", "list", "packages", "-f"]
        if !filterArg.isEmpty {
            args.append(filterArg)
        }
        
        guard let result = try? await ProcessRunner.shared.execute(executable: adbPath, arguments: args) else {
            return []
        }
        
        var packages: [PackageInfo] = []
        let lines = result.stdout.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("package:") else { continue }
            
            let content = trimmed.replacingOccurrences(of: "package:", with: "")
            let parts = content.components(separatedBy: "=")
            if parts.count >= 2 {
                let path = parts.dropLast().joined(separator: "=")
                let pkgName = parts.last ?? ""
                let isSystem = path.hasPrefix("/system/") || path.hasPrefix("/product/") || path.hasPrefix("/apex/")
                packages.append(PackageInfo(
                    packageName: pkgName,
                    apkPath: path,
                    isSystem: isSystem,
                    isEnabled: filter != .disabled
                ))
            }
        }
        return packages.sorted { $0.packageName < $1.packageName }
    }
    
    public func installApp(
        serial: String,
        apkPath: String,
        allowDowngrade: Bool = true,
        grantPermissions: Bool = true,
        replace: Bool = true
    ) async throws {
        var args = ["-s", serial, "install"]
        if replace { args.append("-r") }
        if allowDowngrade { args.append("-d") }
        if grantPermissions { args.append("-g") }
        args.append(apkPath)
        
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: args)
        if !result.isSuccess || !result.stdout.contains("Success") {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func uninstallApp(serial: String, packageName: String, keepData: Bool = false) async throws {
        var args = ["-s", serial, "uninstall"]
        if keepData { args.append("-k") }
        args.append(packageName)
        
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: args)
        if !result.isSuccess || !result.stdout.contains("Success") {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }
    
    public func clearAppData(serial: String, packageName: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", "pm", "clear", packageName])
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr])
        }
    }
    
    public func forceStopApp(serial: String, packageName: String) async throws {
        _ = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", "am", "force-stop", packageName])
    }
    
    public func launchApp(serial: String, packageName: String) async throws {
        _ = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1"])
    }
    
    public func setAppEnabled(serial: String, packageName: String, enable: Bool) async throws {
        let action = enable ? "enable" : "disable-user --user 0"
        let parts = action.components(separatedBy: " ")
        var args = ["-s", serial, "shell", "pm"]
        args.append(contentsOf: parts)
        args.append(packageName)
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: args)
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr])
        }
    }
    
    // MARK: - File Transfer & Sideload
    public func pushFile(serial: String, localPath: String, remotePath: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "push", localPath, remotePath])
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr])
        }
    }
    
    public func pullFile(serial: String, remotePath: String, localPath: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "pull", remotePath, localPath])
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr])
        }
    }
    
    public func sideload(serial: String, zipPath: String, onProgress: (@Sendable (String) -> Void)? = nil) async throws {
        let result = try await ProcessRunner.shared.execute(
            executable: adbPath,
            arguments: ["-s", serial, "sideload", zipPath],
            onOutput: onProgress
        )
        if !result.isSuccess {
            throw NSError(domain: "ADBError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: result.stderr.isEmpty ? result.stdout : result.stderr])
        }
    }
    
    // MARK: - Screenshot Capture
    public func captureScreenshot(serial: String) async throws -> NSImage {
        let tempRemotePath = "/sdcard/screen_temp_\(Int(Date().timeIntervalSince1970)).png"
        let tempLocalPath = "/tmp/screen_temp_\(Int(Date().timeIntervalSince1970)).png"
        
        defer {
            try? FileManager.default.removeItem(atPath: tempLocalPath)
            Task { @MainActor in
                _ = try? await ProcessRunner.shared.execute(executable: self.adbPath, arguments: ["-s", serial, "shell", "rm", tempRemotePath])
            }
        }
        
        let capRes = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", "screencap", "-p", tempRemotePath])
        if !capRes.isSuccess {
            throw NSError(domain: "ADBError", code: 1, userInfo: [NSLocalizedDescriptionKey: "螢幕擷取失敗"])
        }
        
        let pullRes = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "pull", tempRemotePath, tempLocalPath])
        if !pullRes.isSuccess {
            throw NSError(domain: "ADBError", code: 2, userInfo: [NSLocalizedDescriptionKey: "擷取檔案傳輸失敗"])
        }
        
        guard let image = NSImage(contentsOfFile: tempLocalPath) else {
            throw NSError(domain: "ADBError", code: 3, userInfo: [NSLocalizedDescriptionKey: "無法載入擷取圖像"])
        }
        
        return image
    }
    
    // MARK: - Shell Helpers
    public func executeShell(serial: String, command: String) async throws -> String {
        let result = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", command])
        return result.stdout.isEmpty ? result.stderr : result.stdout
    }
    
    private func runShellSimple(serial: String, command: String, isPolling: Bool = false) async throws -> String {
        let res = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["-s", serial, "shell", command], isPolling: isPolling)
        return res.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func restartServer() async throws {
        _ = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["kill-server"])
        _ = try await ProcessRunner.shared.execute(executable: adbPath, arguments: ["start-server"])
    }
}
