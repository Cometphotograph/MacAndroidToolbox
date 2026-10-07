import Foundation

public enum FastbootRebootTarget: String, CaseIterable, Identifiable, Sendable {
    case system = "重啟至系統 (System)"
    case bootloader = "重啟至 Bootloader"
    case recovery = "重啟至 Recovery (恢復模式)"
    case fastbootd = "重啟至 FastbootD (動態分區模式)"
    case edl = "重啟至 EDL / 9008 (急救深刷)"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .system: return "arrow.counterclockwise"
        case .bootloader: return "bolt.horizontal.fill"
        case .recovery: return "cross.case.fill"
        case .fastbootd: return "cpu"
        case .edl: return "flame.fill"
        }
    }
    
    @MainActor
    public var title: String {
        switch self {
        case .system: return L10n("reboot_target_system")
        case .bootloader: return L10n("reboot_target_bootloader")
        case .recovery: return L10n("reboot_target_recovery")
        case .fastbootd: return L10n("reboot_target_fastbootd")
        case .edl: return L10n("reboot_target_edl")
        }
    }
}

public enum BootloaderUnlockType: String, CaseIterable, Identifiable, Sendable {
    case standard = "現代標準解鎖 (flashing unlock)"
    case critical = "關鍵分區解鎖 (flashing unlock_critical)"
    case legacyOem = "傳統 OEM 解鎖 (oem unlock)"
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .standard: return L10n("fb_unlock_standard")
        case .critical: return L10n("fb_unlock_critical")
        case .legacyOem: return L10n("fb_unlock_legacy_oem")
        }
    }
}

public struct FastbootVariable: Identifiable, Hashable, Sendable {
    public var id: String { key }
    public let key: String
    public let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

@MainActor
public final class FastbootService {
    public static let shared = FastbootService()
    
    private var fastbootPath: String {
        return ToolConfig.shared.fastbootPath
    }
    
    private init() {}
    
    // MARK: - Device Discovery
    public func getDevices(isPolling: Bool = true) async -> [AndroidDevice] {
        guard ToolConfig.shared.isFastbootAvailable else { return [] }
        
        do {
            let res = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["devices"], isPolling: isPolling)
            var devices: [AndroidDevice] = []
            
            let combined = res.stdout + "\n" + res.stderr
            let lines = combined.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { continue }
                
                let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 2 else { continue }
                
                let serial = parts[0]
                let modeString = parts[1]
                
                var mode: DeviceConnectionMode = .fastboot
                if modeString.contains("fastbootd") {
                    mode = .fastbootd
                }
                
                var dev = AndroidDevice(
                    serial: serial,
                    mode: mode,
                    model: "Fastboot Device"
                )
                
                await enrichFastbootDeviceInfo(&dev, isPolling: isPolling)
                devices.append(dev)
            }
            return devices
        } catch {
            return []
        }
    }
    
    private func enrichFastbootDeviceInfo(_ device: inout AndroidDevice, isPolling: Bool = true) async {
        let serial = device.serial
        
        // Product
        if let product = await getVariable(serial: serial, name: "product", isPolling: isPolling), !product.isEmpty {
            device.product = product
            device.model = product.capitalized
        }
        
        // Slot
        if let slot = await getVariable(serial: serial, name: "current-slot", isPolling: isPolling), !slot.isEmpty {
            device.currentSlot = slot
        }
        
        // Bootloader Unlock Status
        if let unlockedStr = await getVariable(serial: serial, name: "unlocked", isPolling: isPolling) {
            device.bootloaderUnlocked = (unlockedStr.lowercased() == "yes" || unlockedStr == "true")
        }
        
        // Is Userspace (FastbootD)
        if let isUserspace = await getVariable(serial: serial, name: "is-userspace", isPolling: isPolling), isUserspace == "yes" {
            device.mode = .fastbootd
        }
    }
    
    public func getVariable(serial: String, name: String, isPolling: Bool = false) async -> String? {
        guard let res = try? await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "getvar", name], isPolling: isPolling) else {
            return nil
        }
        
        let combined = res.stdout + "\n" + res.stderr
        for line in combined.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("\(name):") {
                let parts = trimmed.components(separatedBy: "\(name):")
                if parts.count >= 2 {
                    return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    public func getAllVariables(serial: String) async -> [FastbootVariable] {
        guard let res = try? await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "getvar", "all"]) else {
            return []
        }
        
        var vars: [FastbootVariable] = []
        let combined = res.stdout + "\n" + res.stderr
        
        for line in combined.components(separatedBy: .newlines) {
            var trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("(bootloader)") {
                trimmed = trimmed.replacingOccurrences(of: "(bootloader)", with: "").trimmingCharacters(in: .whitespaces)
            }
            guard !trimmed.isEmpty, trimmed.contains(":") else { continue }
            
            let parts = trimmed.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !key.isEmpty && key != "all" && key != "Finished" {
                    vars.append(FastbootVariable(key: key, value: value))
                }
            }
        }
        return vars.sorted { $0.key < $1.key }
    }
    
    // MARK: - Flashing Operations
    public func flashPartition(
        serial: String,
        partition: String,
        filePath: String,
        disableVerity: Bool = false,
        slotSuffix: String? = nil
    ) async throws {
        var finalPartition = partition
        if let slot = slotSuffix, !slot.isEmpty && !finalPartition.contains("_") {
            finalPartition = "\(partition)_\(slot)"
        }
        
        var args = ["-s", serial]
        if disableVerity && partition.contains("vbmeta") {
            args.append(contentsOf: ["--disable-verity", "--disable-verification"])
        }
        args.append(contentsOf: ["flash", finalPartition, filePath])
        
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: args)
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func bootTemporary(serial: String, filePath: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "boot", filePath])
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func erasePartition(serial: String, partition: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "erase", partition])
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func formatPartition(serial: String, partition: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "format", partition])
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func setActiveSlot(serial: String, slot: String) async throws {
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "--set-active=\(slot)"])
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    // MARK: - Bootloader Lock & Unlock
    public func unlockBootloader(serial: String, type: BootloaderUnlockType) async throws {
        var args = ["-s", serial]
        switch type {
        case .standard:
            args.append(contentsOf: ["flashing", "unlock"])
        case .critical:
            args.append(contentsOf: ["flashing", "unlock_critical"])
        case .legacyOem:
            args.append(contentsOf: ["oem", "unlock"])
        }
        
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: args)
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    public func lockBootloader(serial: String) async throws {
        var result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "flashing", "lock"])
        if !result.isSuccess {
            result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: ["-s", serial, "oem", "lock"])
        }
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
    
    // MARK: - Reboot
    public func reboot(serial: String, target: FastbootRebootTarget) async throws {
        var args = ["-s", serial]
        switch target {
        case .system:
            args.append("reboot")
        case .bootloader:
            args.append(contentsOf: ["reboot", "bootloader"])
        case .recovery:
            args.append(contentsOf: ["reboot", "recovery"])
        case .fastbootd:
            args.append(contentsOf: ["reboot", "fastboot"])
        case .edl:
            args.append(contentsOf: ["oem", "edl"])
        }
        
        let result = try await ProcessRunner.shared.execute(executable: fastbootPath, arguments: args)
        if !result.isSuccess {
            let errorMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            throw NSError(domain: "FastbootError", code: Int(result.exitCode), userInfo: [NSLocalizedDescriptionKey: errorMsg.trimmingCharacters(in: .whitespacesAndNewlines)])
        }
    }
}
