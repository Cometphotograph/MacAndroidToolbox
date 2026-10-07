import Foundation

public enum PackageFilterType: String, CaseIterable, Identifiable, Sendable {
    case thirdParty = "thirdParty"
    case system = "system"
    case all = "all"
    case disabled = "disabled"
    
    public var id: String { rawValue }
    
    @MainActor
    public var title: String {
        switch self {
        case .thirdParty: return L10n("app_filter_third_party")
        case .system: return L10n("app_filter_system")
        case .all: return L10n("app_filter_all")
        case .disabled: return L10n("app_filter_disabled")
        }
    }
}

public struct PackageInfo: Identifiable, Hashable, Sendable {
    public var id: String { packageName }
    public let packageName: String
    public var appName: String
    public var versionName: String
    public var versionCode: String
    public var apkPath: String
    public var isSystem: Bool
    public var isEnabled: Bool
    
    public init(
        packageName: String,
        appName: String = "",
        versionName: String = "",
        versionCode: String = "",
        apkPath: String = "",
        isSystem: Bool = false,
        isEnabled: Bool = true
    ) {
        self.packageName = packageName
        self.appName = appName.isEmpty ? packageName : appName
        self.versionName = versionName
        self.versionCode = versionCode
        self.apkPath = apkPath
        self.isSystem = isSystem
        self.isEnabled = isEnabled
    }
}
