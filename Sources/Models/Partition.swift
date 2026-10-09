import Foundation

public struct PartitionItem: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let titleKey: String
    public let descKey: String
    public let isCritical: Bool
    
    public init(name: String, titleKey: String, descKey: String, isCritical: Bool = false) {
        self.name = name
        self.titleKey = titleKey
        self.descKey = descKey
        self.isCritical = isCritical
    }
    
    @MainActor
    public var title: String {
        L10n(titleKey)
    }
    
    @MainActor
    public var description: String {
        L10n(descKey)
    }
}

public struct PartitionCatalog: Sendable {
    public static let standardPartitions: [PartitionItem] = [
        PartitionItem(name: "boot", titleKey: "part_boot_title", descKey: "part_boot_desc", isCritical: false),
        PartitionItem(name: "init_boot", titleKey: "part_init_boot_title", descKey: "part_init_boot_desc", isCritical: false),
        PartitionItem(name: "recovery", titleKey: "part_recovery_title", descKey: "part_recovery_desc", isCritical: false),
        PartitionItem(name: "vbmeta", titleKey: "part_vbmeta_title", descKey: "part_vbmeta_desc", isCritical: true),
        PartitionItem(name: "vbmeta_system", titleKey: "part_vbmeta_system_title", descKey: "part_vbmeta_system_desc", isCritical: true),
        PartitionItem(name: "vbmeta_vendor", titleKey: "part_vbmeta_vendor_title", descKey: "part_vbmeta_vendor_desc", isCritical: true),
        PartitionItem(name: "vendor_boot", titleKey: "part_vendor_boot_title", descKey: "part_vendor_boot_desc", isCritical: false),
        PartitionItem(name: "dtbo", titleKey: "part_dtbo_title", descKey: "part_dtbo_desc", isCritical: false),
        PartitionItem(name: "system", titleKey: "part_system_title", descKey: "part_system_desc", isCritical: true),
        PartitionItem(name: "vendor", titleKey: "part_vendor_title", descKey: "part_vendor_desc", isCritical: true),
        PartitionItem(name: "super", titleKey: "part_super_title", descKey: "part_super_desc", isCritical: true),
        PartitionItem(name: "radio", titleKey: "part_radio_title", descKey: "part_radio_desc", isCritical: true),
        PartitionItem(name: "userdata", titleKey: "part_userdata_title", descKey: "part_userdata_desc", isCritical: true)
    ]
}
