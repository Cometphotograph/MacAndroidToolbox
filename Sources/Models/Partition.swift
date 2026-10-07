import Foundation

public struct PartitionItem: Identifiable, Hashable, Sendable {
    public var id: String { name }
    public let name: String
    public let title: String
    public let description: String
    public let isCritical: Bool
    
    public init(name: String, title: String, description: String, isCritical: Bool = false) {
        self.name = name
        self.title = title
        self.description = description
        self.isCritical = isCritical
    }
}

public struct PartitionCatalog: Sendable {
    public static let standardPartitions: [PartitionItem] = [
        PartitionItem(name: "boot", title: "Boot (引導分區)", description: "包含核心 (Kernel) 與 ramdisk，常規 Root (Magisk/KernelSU/APatch) 刷寫此分區", isCritical: false),
        PartitionItem(name: "init_boot", title: "Init Boot (新版引導分區)", description: "Android 13+ 機型專用 ramdisk 引導分區，新機 Root 請刷此分區", isCritical: false),
        PartitionItem(name: "recovery", title: "Recovery (恢復分區)", description: "第三方 TWRP / OrangeFox 或原廠恢復系統", isCritical: false),
        PartitionItem(name: "vbmeta", title: "VBMeta (驗證元數據)", description: "Android 簽名驗證分區，刷寫自訂 ROM 時常需禁用驗證", isCritical: true),
        PartitionItem(name: "vbmeta_system", title: "VBMeta System", description: "系統簽名驗證子分區", isCritical: true),
        PartitionItem(name: "vbmeta_vendor", title: "VBMeta Vendor", description: "廠商簽名驗證子分區", isCritical: true),
        PartitionItem(name: "vendor_boot", title: "Vendor Boot", description: "廠商引導配置分區", isCritical: false),
        PartitionItem(name: "dtbo", title: "DTBO (設備樹)", description: "設備樹覆蓋分區", isCritical: false),
        PartitionItem(name: "system", title: "System (系統分區)", description: "Android 核心操作系統檔案", isCritical: true),
        PartitionItem(name: "vendor", title: "Vendor (廠商分區)", description: "晶片廠商驅動與專屬二進位檔案", isCritical: true),
        PartitionItem(name: "super", title: "Super (動態分區集合)", description: "Android 10+ 動態分區 (包含 system/vendor/product)", isCritical: true),
        PartitionItem(name: "radio", title: "Radio / Modem (基帶通訊)", description: "行動通訊基帶與信號射頻韌體", isCritical: true),
        PartitionItem(name: "userdata", title: "Userdata (用戶資料)", description: "使用者所有個人資料與應用安裝目錄 (注意：抹除會遺失資料)", isCritical: true)
    ]
}
