import Foundation
import SwiftUI
import Combine

/// Single Firehose programmer file item
public struct EDLLoaderFileItem: Identifiable, Hashable, Sendable {
    public var id: String { fullPath }
    public let fileName: String
    public let fullPath: String
    public let fileSize: Int64
    public let fileSizeString: String
    public let isELF: Bool
    public let isMBN: Bool
    
    public init(fileName: String, fullPath: String, fileSize: Int64) {
        self.fileName = fileName
        self.fullPath = fullPath
        self.fileSize = fileSize
        
        let lower = fileName.lowercased()
        self.isELF = lower.hasSuffix(".elf") || lower.hasSuffix(".melf") || fileName == "DevprgProgrammer"
        self.isMBN = lower.hasSuffix(".mbn") || lower.hasSuffix(".bin")
        
        let kb = Double(fileSize) / 1024.0
        if kb >= 1024.0 {
            self.fileSizeString = String(format: "%.2f MB", kb / 1024.0)
        } else {
            self.fileSizeString = String(format: "%.1f KB", kb)
        }
    }
}

/// A target model or chipset configuration containing one or more loaders
public struct EDLTargetModel: Identifiable, Hashable, Sendable {
    public var id: String { "\(brand)_\(rawFolderName)\(subVariant != nil ? "_" + subVariant! : "")" }
    public let brand: String
    public let rawFolderName: String
    public let displayName: String
    public let subVariant: String?
    public let folderPath: String
    public let loaders: [EDLLoaderFileItem]
    public let hasDigest: Bool
    public let digestPath: String?
    public let hasSign: Bool
    public let signPath: String?
    public let noticeText: String?
    
    public var primaryLoader: EDLLoaderFileItem? {
        // Prefer DevprgProgrammer.elf / DevprgProgrammer1.elf / DevprgProgrammer.melf / prog_firehose_*.elf
        return loaders.first { $0.fileName.contains("DevprgProgrammer.elf") || $0.fileName.contains("DevprgProgrammer1.elf") }
            ?? loaders.first { $0.fileName.contains("prog_firehose") }
            ?? loaders.first
    }
}

/// Brand group containing models and chipsets
public struct EDLBrandGroup: Identifiable, Hashable, Sendable {
    public var id: String { brandName }
    public let brandName: String
    public let iconSystemName: String
    public let models: [EDLTargetModel]
    
    public var totalLoaderCount: Int {
        models.reduce(0) { $0 + $1.loaders.count }
    }
}

@MainActor
public final class EDLLoaderLibrary: ObservableObject {
    public static let shared = EDLLoaderLibrary()
    
    @Published public var brandGroups: [EDLBrandGroup] = []
    @Published public var isLoaded: Bool = false
    @Published public var resolvedLibraryPath: String? = nil
    @Published public var globalNotice: String = ""
    
    private init() {
        reloadLibrary()
    }
    
    /// Finds the root path where the 9008 loaders library is located
    public static func resolveLibraryDirectory() -> String? {
        let fm = FileManager.default
        
        // 1. User custom path in UserDefaults
        if let custom = UserDefaults.standard.string(forKey: "kCustomEDLLoadersPath"),
           fm.fileExists(atPath: custom) {
            return custom
        }
        
        // 2. App Bundle Resources/Loaders
        if let resPath = Bundle.main.resourcePath {
            let bundleLoaders = (resPath as NSString).appendingPathComponent("Loaders")
            if fm.fileExists(atPath: bundleLoaders) {
                return bundleLoaders
            }
        }
        
        // 3. App Contents/Resources/Loaders
        let appBundleRes = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Loaders").path
        if fm.fileExists(atPath: appBundleRes) {
            return appBundleRes
        }
        
        // 4. Current working directory ./Resources/Loaders
        let cwdLoaders = (fm.currentDirectoryPath as NSString).appendingPathComponent("Resources/Loaders")
        if fm.fileExists(atPath: cwdLoaders) {
            return cwdLoaders
        }
        
        // 5. User workspace path
        let workspaceLoaders = "/Users/comet/写点小程序/mac andriod/Resources/Loaders"
        if fm.fileExists(atPath: workspaceLoaders) {
            return workspaceLoaders
        }
        
        return nil
    }
    
    /// Scans and reloads all brands, chipsets, and programmer files
    public func reloadLibrary() {
        guard let rootPath = EDLLoaderLibrary.resolveLibraryDirectory() else {
            self.resolvedLibraryPath = nil
            self.brandGroups = []
            self.isLoaded = false
            return
        }
        
        self.resolvedLibraryPath = rootPath
        let fm = FileManager.default
        
        // Check global notice file
        let noticePath = (rootPath as NSString).appendingPathComponent("注意事项及欧加.txt")
        if let noticeContent = try? String(contentsOfFile: noticePath, encoding: .utf8) {
            self.globalNotice = noticeContent.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            self.globalNotice = "DevprgProgrammer 发送 Firehose 引导通讯握手失败时请尝试换另一个。\n若已发送过引导，要换其他 DevprgProgrammer 尝试时，需先将设备重启重新进入 9008 端口释放连接，否则 Sahara 通讯无法释放。"
        }
        
        let brandOrder = ["小米", "欧加", "魅族", "黑鲨", "努比亚", "联想", "华硕", "LG"]
        var loadedGroups: [EDLBrandGroup] = []
        
        guard let brandDirs = try? fm.contentsOfDirectory(atPath: rootPath) else {
            self.brandGroups = []
            self.isLoaded = false
            return
        }
        
        for brand in brandOrder {
            guard brandDirs.contains(brand) else { continue }
            let brandPath = (rootPath as NSString).appendingPathComponent(brand)
            
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: brandPath, isDirectory: &isDir), isDir.boolValue else { continue }
            
            let models = parseBrandModels(brand: brand, brandPath: brandPath)
            if !models.isEmpty {
                let icon = brandIcon(for: brand)
                loadedGroups.append(EDLBrandGroup(
                    brandName: brand,
                    iconSystemName: icon,
                    models: models
                ))
            }
        }
        
        // Also check any extra brand dirs not in predefined list
        for dir in brandDirs.sorted() {
            if !brandOrder.contains(dir) && !dir.hasPrefix(".") && !dir.hasSuffix(".txt") {
                let extraPath = (rootPath as NSString).appendingPathComponent(dir)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: extraPath, isDirectory: &isDir), isDir.boolValue {
                    let models = parseBrandModels(brand: dir, brandPath: extraPath)
                    if !models.isEmpty {
                        loadedGroups.append(EDLBrandGroup(
                            brandName: dir,
                            iconSystemName: "cpu.fill",
                            models: models
                        ))
                    }
                }
            }
        }
        
        self.brandGroups = loadedGroups
        self.isLoaded = !loadedGroups.isEmpty
    }
    
    private func parseBrandModels(brand: String, brandPath: String) -> [EDLTargetModel] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: brandPath) else { return [] }
        
        var models: [EDLTargetModel] = []
        
        for entry in entries.sorted() {
            if entry.hasPrefix(".") || entry.hasPrefix("A0_") {
                continue
            }
            
            let entryPath = (brandPath as NSString).appendingPathComponent(entry)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: entryPath, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            
            // Check if there are sub-variant directories (e.g. 黑鲨3 -> 8G运存 / 12G运存)
            let subEntries = (try? fm.contentsOfDirectory(atPath: entryPath)) ?? []
            let subDirs = subEntries.filter { sub in
                var subIsDir: ObjCBool = false
                let sp = (entryPath as NSString).appendingPathComponent(sub)
                return fm.fileExists(atPath: sp, isDirectory: &subIsDir) && subIsDir.boolValue && !sub.hasPrefix(".")
            }
            
            if !subDirs.isEmpty {
                // Nested models (e.g., 黑鲨3/8G运存)
                for sub in subDirs.sorted() {
                    let subPath = (entryPath as NSString).appendingPathComponent(sub)
                    if let parsed = parseSingleModelFolder(
                        brand: brand,
                        rawFolderName: entry,
                        subVariant: sub,
                        folderPath: subPath
                    ) {
                        models.append(parsed)
                    }
                }
            } else {
                // Normal direct folder
                if let parsed = parseSingleModelFolder(
                    brand: brand,
                    rawFolderName: entry,
                    subVariant: nil,
                    folderPath: entryPath
                ) {
                    models.append(parsed)
                }
            }
        }
        
        return models
    }
    
    private func parseSingleModelFolder(
        brand: String,
        rawFolderName: String,
        subVariant: String?,
        folderPath: String
    ) -> EDLTargetModel? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: folderPath) else { return nil }
        
        var loaders: [EDLLoaderFileItem] = []
        var hasDigest = false
        var digestPath: String? = nil
        var hasSign = false
        var signPath: String? = nil
        var noticeText: String? = nil
        
        for file in files.sorted() {
            if file.hasPrefix(".") { continue }
            let filePath = (folderPath as NSString).appendingPathComponent(file)
            
            if file.hasPrefix("Digest") {
                hasDigest = true
                digestPath = filePath
                continue
            }
            if file.hasPrefix("Sign") {
                hasSign = true
                signPath = filePath
                continue
            }
            if file.hasSuffix(".txt") || file.hasSuffix(".md") {
                if let text = try? String(contentsOfFile: filePath, encoding: .utf8) {
                    noticeText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                continue
            }
            
            // Check if it's a valid programmer binary (.elf, .melf, .mbn, or DevprgProgrammer)
            let lower = file.lowercased()
            let isProg = lower.hasSuffix(".elf") || lower.hasSuffix(".melf") || lower.hasSuffix(".mbn") || file == "DevprgProgrammer"
            
            if isProg {
                let attr = (try? fm.attributesOfItem(atPath: filePath)) ?? [:]
                let size = (attr[.size] as? Int64) ?? 0
                loaders.append(EDLLoaderFileItem(
                    fileName: file,
                    fullPath: filePath,
                    fileSize: size
                ))
            }
        }
        
        guard !loaders.isEmpty else { return nil }
        
        let friendlyName = formatFriendlyDisplayName(brand: brand, rawName: rawFolderName, subVariant: subVariant)
        
        return EDLTargetModel(
            brand: brand,
            rawFolderName: rawFolderName,
            displayName: friendlyName,
            subVariant: subVariant,
            folderPath: folderPath,
            loaders: loaders,
            hasDigest: hasDigest,
            digestPath: digestPath,
            hasSign: hasSign,
            signPath: signPath,
            noticeText: noticeText
        )
    }
    
    private func brandIcon(for brand: String) -> String {
        switch brand {
        case "小米": return "bolt.shield.fill"
        case "欧加": return "shield.lefthalf.filled"
        case "魅族": return "m.circle.fill"
        case "黑鲨": return "gamecontroller.fill"
        case "努比亚": return "flame.fill"
        case "联想": return "laptopcomputer"
        case "华硕": return "cross.fill"
        case "LG": return "tv.fill"
        default: return "cpu.fill"
        }
    }
    
    private func formatFriendlyDisplayName(brand: String, rawName: String, subVariant: String?) -> String {
        let variantSuffix = (subVariant != nil && !subVariant!.isEmpty) ? " (\(subVariant!))" : ""
        
        // 1. Chipset lookup dictionary
        let chipMap: [String: String] = [
            "SM8750_8Elite": "SM8750 (骁龙 8 至尊版 / 8 Elite)",
            "SM8735_8sGen4": "SM8735 (骁龙 8s Gen 4)",
            "SM8650_8Gen3": "SM8650 (骁龙 8 Gen 3)",
            "SM8550_8Gen2_8Gen2-LeadingVersion-领先版": "SM8550 (骁龙 8 Gen 2 / 领先版)",
            "SM8475_8Gen1Plus_8+": "SM8475 (骁龙 8+ Gen 1)",
            "SM8450_8Gen1": "SM8450 (骁龙 8 Gen 1)",
            "SM8350_888_888Plus": "SM8350 (骁龙 888 / 888+)",
            "SM8250_865_870": "SM8250 (骁龙 865 / 870)",
            "SM8150_855": "SM8150 (骁龙 855 / 855+)",
            "MSM8998_835": "MSM8998 (骁龙 835)",
            "SDM845": "SDM845 (骁龙 845)",
            "SM7675_7+Gen3": "SM7675 (骁龙 7+ Gen 3)",
            "SM7550_7Gen3": "SM7550 (骁龙 7 Gen 3)",
            "SM7475_7+Gen2": "SM7475 (骁龙 7+ Gen 2)",
            "SM7435_7sGen2": "SM7435 (骁龙 7s Gen 2)",
            "SM7325_778G": "SM7325 (骁龙 778G / 778G+)",
            "SM7225_750G": "SM7225 (骁龙 750G)",
            "SDM765": "SDM765 (骁龙 765 / 765G)",
            "SDM730": "SDM730 (骁龙 730 / 730G)",
            "SDM712": "SDM712 (骁龙 712)",
            "SDM710": "SDM710 (骁龙 710)",
            "SDM680": "SDM680 (骁龙 680)",
            "SDM675": "SDM675 (骁龙 675)",
            "SDM675_678_730_730G_732_765_765G_768G": "SDM675/678/730/765 多机型通用",
            "SDM670_710_712": "SDM670/710/712 多机型通用",
            "SDM636": "SDM636 (骁龙 636)",
            "SDM632": "SDM632 (骁龙 632)",
            "MSM8976Plus_660": "MSM8976 Pro (骁龙 660)",
            "SM6450_6Gen1": "SM6450 (骁龙 6 Gen 1)",
            "SM6375_695_6sGen3": "SM6375 (骁龙 695 / 6s Gen 3)",
            "SM6125_665": "SM6125 (骁龙 665)",
            "SM6115_662_6sGen1": "SM6115 (骁龙 662 / 6s Gen 1)",
            "SDM450": "SDM450 (骁龙 450)",
            "SDM439": "SDM439 (骁龙 439)",
            "SM4350_480": "SM4350 (骁龙 480 / 480+)",
            "SM4250_460": "SM4250 (骁龙 460)",
            "MSM8953_625": "MSM8953 (骁龙 625)"
        ]
        
        if let chip = chipMap[rawName] {
            return "\(chip)\(variantSuffix)"
        }
        
        // 2. Nubia / ZTE model lookup
        let nubiaMap: [String: String] = [
            "NX789J": "NX789J (红魔 10 Pro / 10 Pro+)",
            "NX769J": "NX769J (红魔 9 Pro / 9 Pro+)",
            "NX729J": "NX729J (红魔 8 Pro / 8 Pro+)",
            "NX709S": "NX709S (红魔 7S Pro)",
            "NX709J": "NX709J (红魔 7 Pro)",
            "NX701J": "NX701J (努比亚 Z40 Pro / 中兴 Axon 40 Ultra)",
            "NX679S": "NX679S (红魔 7S)",
            "NX679J": "NX679J (红魔 7)",
            "NX669S": "NX669S (红魔 6S Pro)",
            "NX669J": "NX669J (红魔 6 / 6 Pro)",
            "NX666J": "NX666J (红魔 6R)",
            "NX659J": "NX659J (红魔 5G / 5S)",
            "NX651J": "NX651J (努比亚 Play 5G / 红魔 5G Lite)",
            "NX629J": "NX629J (红魔 3 / 3S)",
            "NX619J": "NX619J (努比亚 X)",
            "NX616J": "NX616J (红魔 Mars)",
            "NX609J": "NX609J (努比亚 Z18)",
            "NX606J": "NX606J (红魔一代)",
            "NX563J": "NX563J (努比亚 Z17)",
            "NP01J": "NP01J (红魔电竞平板一代)",
            "NP02J": "NP02J (努比亚 Pad 3D 二代 / 红魔平板 3D 探索版)",
            "NP03J": "NP03J (红魔电竞平板 Pro / 努比亚平板 Pro)",
            "NP05J": "NP05J (红魔电竞平板 3 Pro)",
            "ailsa_ii-ZTE_A2017": "中兴天机 7 (Axon 7 / A2017)",
            "P875A02": "P875A02 (红魔 9S Pro+ / 努比亚 Z60 Ultra 领先版)",
            "P870A01": "P870A01 (努比亚 Z60S Pro)",
            "P865A02": "P865A02 (红魔 8S Pro / 努比亚 Z50S Pro)",
            "P855A23": "P855A23 (努比亚 Z50 Ultra)",
            "P855A01": "P855A01 (努比亚 Z50)",
            "P845A02": "P845A02 (红魔 7S 系列)",
            "P768A02": "P768A02 (努比亚 Z40S Pro)",
            "P725A12": "P725A12 (中兴远航系列)",
            "PQ83A01": "PQ83A01 (红魔电竞平板)",
            "TP1803": "TP1803 (中兴 5G CPE/路由器)"
        ]
        
        if let nubia = nubiaMap[rawName] {
            return "\(nubia)\(variantSuffix)"
        }
        
        // 3. Asus ROG models
        let asusMap: [String: String] = [
            "ROG1": "ROG Phone 1 (ZS600KL)",
            "ROG2": "ROG Phone 2 (ZS660KL)",
            "ROG5_5S_5Pro_5SPro_5至尊版": "ROG Phone 5 / 5S / 5 Pro / 5S Pro / 至尊版",
            "ZenFone7_ZS670KS": "ZenFone 7 / 7 Pro (ZS670KS / ZS671KS)"
        ]
        if let asus = asusMap[rawName] {
            return "\(asus)\(variantSuffix)"
        }
        
        // 4. Lenovo models
        let lenovoMap: [String: String] = [
            "K30-T": "联想乐檬 K3 (K30-T)",
            "L38012": "联想 K5 Pro (L38012)",
            "L38111": "联想 Z6 青春版 (L38111)",
            "L70081": "拯救者电竞手机 2 Pro (L70081)",
            "L71061": "拯救者 Y70 (L71061)",
            "L71091": "拯救者 Y90 (L71091)",
            "L79031": "拯救者电竞手机 Pro 一代 (L79031)",
            "TB322FC_TB322FU": "拯救者 Y700 平板二代 (TB322FC/FU)",
            "TB-9707F": "拯救者 Y700 平板一代 (TB-9707F)"
        ]
        if let lenovo = lenovoMap[rawName] {
            return "\(lenovo)\(variantSuffix)"
        }
        
        // Default cleaned name
        let clean = rawName.replacingOccurrences(of: "_", with: " ")
        return "\(clean)\(variantSuffix)"
    }
}
