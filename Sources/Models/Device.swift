import Foundation
import SwiftUI

public enum DeviceConnectionMode: String, CaseIterable, Identifiable, Sendable {
    case adb = "ADB 模式"
    case fastboot = "Fastboot 模式"
    case fastbootd = "FastbootD 模式"
    case recovery = "Recovery 模式"
    case sideload = "Sideload 刷機模式"
    case unauthorized = "未授權 (請在螢幕點允許)"
    case offline = "離線"
    case edl = "EDL / 9008 模式"
    case unknown = "未知狀態"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .adb: return .green
        case .fastboot, .fastbootd: return .orange
        case .recovery: return .purple
        case .sideload: return .blue
        case .unauthorized: return .yellow
        case .offline: return .gray
        case .edl: return .indigo
        case .unknown: return .secondary
        }
    }
    
    public var icon: String {
        switch self {
        case .adb: return "iphone.gen3"
        case .fastboot, .fastbootd: return "bolt.horizontal.fill"
        case .recovery: return "cross.case.fill"
        case .sideload: return "arrow.down.doc.fill"
        case .unauthorized: return "lock.trianglebadge.exclamationmark"
        case .offline: return "poweroff"
        case .edl: return "cpu"
        case .unknown: return "questionmark.circle"
        }
    }
    
    @MainActor
    public var title: String {
        switch self {
        case .adb: return L10n("mode_adb")
        case .fastboot: return L10n("mode_fastboot")
        case .fastbootd: return L10n("mode_fastbootd")
        case .recovery: return L10n("mode_recovery")
        case .sideload: return L10n("mode_sideload")
        case .unauthorized: return L10n("mode_unauthorized")
        case .offline: return L10n("mode_offline")
        case .edl: return L10n("mode_edl")
        case .unknown: return L10n("mode_unknown")
        }
    }
}

public struct AndroidDevice: Identifiable, Hashable, Sendable {
    public var id: String { serial }
    public var serial: String
    public var mode: DeviceConnectionMode
    public var model: String
    public var brand: String
    public var product: String
    public var androidVersion: String
    public var sdkVersion: Int
    public var securityPatch: String
    public var batteryLevel: Int
    public var batteryTemperature: Double
    public var batteryStatus: String
    public var isRooted: Bool
    public var currentSlot: String?
    public var bootloaderUnlocked: Bool?
    public var screenResolution: String?
    public var screenDensity: String?
    public var ipAddress: String?
    
    public init(
        serial: String,
        mode: DeviceConnectionMode,
        model: String = "Android Device",
        brand: String = "",
        product: String = "",
        androidVersion: String = "",
        sdkVersion: Int = 0,
        securityPatch: String = "",
        batteryLevel: Int = -1,
        batteryTemperature: Double = 0.0,
        batteryStatus: String = "未知",
        isRooted: Bool = false,
        currentSlot: String? = nil,
        bootloaderUnlocked: Bool? = nil,
        screenResolution: String? = nil,
        screenDensity: String? = nil,
        ipAddress: String? = nil
    ) {
        self.serial = serial
        self.mode = mode
        self.model = model
        self.brand = brand
        self.product = product
        self.androidVersion = androidVersion
        self.sdkVersion = sdkVersion
        self.securityPatch = securityPatch
        self.batteryLevel = batteryLevel
        self.batteryTemperature = batteryTemperature
        self.batteryStatus = batteryStatus
        self.isRooted = isRooted
        self.currentSlot = currentSlot
        self.bootloaderUnlocked = bootloaderUnlocked
        self.screenResolution = screenResolution
        self.screenDensity = screenDensity
        self.ipAddress = ipAddress
    }
    
    public var displayName: String {
        if !brand.isEmpty && !model.isEmpty && model != "Android Device" {
            return "\(brand.capitalized) \(model)"
        } else if !model.isEmpty && model != "Android Device" {
            return model
        } else if mode == .fastboot || mode == .fastbootd {
            return "Fastboot 設備 (\(serial))"
        } else {
            return "設備 (\(serial))"
        }
    }
    
    @MainActor
    public var batteryStatusLocalized: String {
        switch batteryStatus {
        case "charging", "充電中", "充电中": return L10n("battery_charging")
        case "discharging", "放電中", "放电中": return L10n("battery_discharging")
        case "not_charging", "未充電", "未充电": return L10n("battery_not_charging")
        case "full", "已充飽", "已充满": return L10n("battery_full")
        case "normal", "正常": return L10n("battery_normal")
        default: return batteryStatus.isEmpty || batteryStatus == "未知" ? L10n("common_unknown") : batteryStatus
        }
    }
}
