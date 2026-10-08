import Foundation

public struct ChipsetEntry: Sendable {
    public let chineseName: String
    public let englishName: String
    public let codeName: String
    public let manufacturer: String
}

public final class ChipsetDatabase: Sendable {
    public static let shared = ChipsetDatabase()
    
    private let database: [String: ChipsetEntry]
    
    private init() {
        var db: [String: ChipsetEntry] = [:]
        
        // Helper to register chip
        func reg(_ keys: [String], cn: String, en: String, code: String, mfg: String) {
            let entry = ChipsetEntry(chineseName: cn, englishName: en, codeName: code, manufacturer: mfg)
            for k in keys {
                db[k.lowercased()] = entry
            }
        }
        
        // MARK: - Qualcomm Snapdragon (高通 骁龙)
        reg(["sm8750", "sun"],
            cn: "高通 骁龙 8 至尊版 (8 Elite)", en: "Qualcomm Snapdragon 8 Elite",
            code: "SM8750 (Sun)", mfg: "Qualcomm")
        
        reg(["sm8650", "pineapple"],
            cn: "高通 骁龙 8 Gen 3", en: "Qualcomm Snapdragon 8 Gen 3",
            code: "SM8650 (Pineapple)", mfg: "Qualcomm")
        
        reg(["sm8550", "kalama"],
            cn: "高通 骁龙 8 Gen 2", en: "Qualcomm Snapdragon 8 Gen 2",
            code: "SM8550 (Kalama)", mfg: "Qualcomm")
        
        reg(["sm8475", "cape"],
            cn: "高通 骁龙 8+ Gen 1", en: "Qualcomm Snapdragon 8+ Gen 1",
            code: "SM8475 (Cape)", mfg: "Qualcomm")
        
        reg(["sm8450", "taro"],
            cn: "高通 骁龙 8 Gen 1", en: "Qualcomm Snapdragon 8 Gen 1",
            code: "SM8450 (Taro)", mfg: "Qualcomm")
        
        reg(["sm8350", "lahaina"],
            cn: "高通 骁龙 888 / 888+", en: "Qualcomm Snapdragon 888",
            code: "SM8350 (Lahaina)", mfg: "Qualcomm")
        
        reg(["sm8250_ac", "sm8250-ac"],
            cn: "高通 骁龙 870", en: "Qualcomm Snapdragon 870",
            code: "SM8250-AC (Kona)", mfg: "Qualcomm")
        
        reg(["sm8250_ab", "sm8250-ab"],
            cn: "高通 骁龙 865+", en: "Qualcomm Snapdragon 865+",
            code: "SM8250-AB (Kona)", mfg: "Qualcomm")
        
        reg(["sm8250", "kona"],
            cn: "高通 骁龙 865 / 870", en: "Qualcomm Snapdragon 865 / 870",
            code: "SM8250 (Kona)", mfg: "Qualcomm")
        
        reg(["sm8150", "msmnile", "sdm855"],
            cn: "高通 骁龙 855 / 855+", en: "Qualcomm Snapdragon 855",
            code: "SM8150 (Msmnile)", mfg: "Qualcomm")
        
        reg(["sdm845", "napali"],
            cn: "高通 骁龙 845", en: "Qualcomm Snapdragon 845",
            code: "SDM845 (Napali)", mfg: "Qualcomm")
        
        reg(["msm8998"],
            cn: "高通 骁龙 835", en: "Qualcomm Snapdragon 835",
            code: "MSM8998", mfg: "Qualcomm")
        
        reg(["msm8996"],
            cn: "高通 骁龙 820 / 821", en: "Qualcomm Snapdragon 820",
            code: "MSM8996", mfg: "Qualcomm")
        
        reg(["sm7675"],
            cn: "高通 骁龙 7+ Gen 3", en: "Qualcomm Snapdragon 7+ Gen 3",
            code: "SM7675", mfg: "Qualcomm")
        
        reg(["sm7550", "crow"],
            cn: "高通 骁龙 7 Gen 3", en: "Qualcomm Snapdragon 7 Gen 3",
            code: "SM7550 (Crow)", mfg: "Qualcomm")
        
        reg(["sm7475", "marble"],
            cn: "高通 骁龙 7+ Gen 2", en: "Qualcomm Snapdragon 7+ Gen 2",
            code: "SM7475 (Marble)", mfg: "Qualcomm")
        
        reg(["sm7450"],
            cn: "高通 骁龙 7 Gen 1", en: "Qualcomm Snapdragon 7 Gen 1",
            code: "SM7450", mfg: "Qualcomm")
        
        reg(["sm7325", "yupik"],
            cn: "高通 骁龙 778G / 778G+", en: "Qualcomm Snapdragon 778G",
            code: "SM7325 (Yupik)", mfg: "Qualcomm")
        
        reg(["sm7315"],
            cn: "高通 骁龙 782G", en: "Qualcomm Snapdragon 782G",
            code: "SM7315", mfg: "Qualcomm")
        
        reg(["sm7250", "lito"],
            cn: "高通 骁龙 765G / 768G", en: "Qualcomm Snapdragon 765G",
            code: "SM7250 (Lito)", mfg: "Qualcomm")
        
        reg(["sm7225"],
            cn: "高通 骁龙 750G", en: "Qualcomm Snapdragon 750G",
            code: "SM7225", mfg: "Qualcomm")
        
        reg(["sm7150"],
            cn: "高通 骁龙 730 / 732G", en: "Qualcomm Snapdragon 730",
            code: "SM7150", mfg: "Qualcomm")
        
        reg(["sm7125", "atoll"],
            cn: "高通 骁龙 720G", en: "Qualcomm Snapdragon 720G",
            code: "SM7125 (Atoll)", mfg: "Qualcomm")
        
        reg(["sdm710"],
            cn: "高通 骁龙 710", en: "Qualcomm Snapdragon 710",
            code: "SDM710", mfg: "Qualcomm")
        
        reg(["sdm660"],
            cn: "高通 骁龙 660", en: "Qualcomm Snapdragon 660",
            code: "SDM660", mfg: "Qualcomm")
        
        reg(["sdm636"],
            cn: "高通 骁龙 636", en: "Qualcomm Snapdragon 636",
            code: "SDM636", mfg: "Qualcomm")
        
        reg(["sm6450"],
            cn: "高通 骁龙 6 Gen 1", en: "Qualcomm Snapdragon 6 Gen 1",
            code: "SM6450", mfg: "Qualcomm")
        
        reg(["sm6375", "holi"],
            cn: "高通 骁龙 695", en: "Qualcomm Snapdragon 695",
            code: "SM6375 (Holi)", mfg: "Qualcomm")
        
        reg(["sm6225", "bengal"],
            cn: "高通 骁龙 680", en: "Qualcomm Snapdragon 680",
            code: "SM6225 (Bengal)", mfg: "Qualcomm")
        
        reg(["sm6115"],
            cn: "高通 骁龙 662", en: "Qualcomm Snapdragon 662",
            code: "SM6115", mfg: "Qualcomm")
        
        reg(["sm4450", "sky"],
            cn: "高通 骁龙 4 Gen 2", en: "Qualcomm Snapdragon 4 Gen 2",
            code: "SM4450 (Sky)", mfg: "Qualcomm")
        
        reg(["sm4375"],
            cn: "高通 骁龙 4 Gen 1", en: "Qualcomm Snapdragon 4 Gen 1",
            code: "SM4375", mfg: "Qualcomm")
        
        reg(["sm4350"],
            cn: "高通 骁龙 480", en: "Qualcomm Snapdragon 480",
            code: "SM4350", mfg: "Qualcomm")
        
        reg(["qcm6490"],
            cn: "高通 骁龙 QCM6490", en: "Qualcomm QCM6490",
            code: "QCM6490", mfg: "Qualcomm")
            
        // MARK: - MediaTek (联发科 天玑 / Helio)
        reg(["mt6991"],
            cn: "联发科 天玑 9400", en: "MediaTek Dimensity 9400",
            code: "MT6991", mfg: "MediaTek")
        
        reg(["mt6989"],
            cn: "联发科 天玑 9300 / 9300+", en: "MediaTek Dimensity 9300",
            code: "MT6989", mfg: "MediaTek")
        
        reg(["mt6985"],
            cn: "联发科 天玑 9200 / 9200+", en: "MediaTek Dimensity 9200",
            code: "MT6985", mfg: "MediaTek")
        
        reg(["mt6983"],
            cn: "联发科 天玑 9000 / 9000+", en: "MediaTek Dimensity 9000",
            code: "MT6983", mfg: "MediaTek")
        
        reg(["mt6897"],
            cn: "联发科 天玑 8300 / 8300-Ultra", en: "MediaTek Dimensity 8300",
            code: "MT6897", mfg: "MediaTek")
        
        reg(["mt6896"],
            cn: "联发科 天玑 8200 / 8200-Ultra", en: "MediaTek Dimensity 8200",
            code: "MT6896", mfg: "MediaTek")
        
        reg(["mt6895"],
            cn: "联发科 天玑 8100 / 8000", en: "MediaTek Dimensity 8100",
            code: "MT6895", mfg: "MediaTek")
        
        reg(["mt6893"],
            cn: "联发科 天玑 1200", en: "MediaTek Dimensity 1200",
            code: "MT6893", mfg: "MediaTek")
        
        reg(["mt6891"],
            cn: "联发科 天玑 1100", en: "MediaTek Dimensity 1100",
            code: "MT6891", mfg: "MediaTek")
        
        reg(["mt6889"],
            cn: "联发科 天玑 1000 / 1000+", en: "MediaTek Dimensity 1000",
            code: "MT6889", mfg: "MediaTek")
        
        reg(["mt6885"],
            cn: "联发科 天玑 1000L", en: "MediaTek Dimensity 1000L",
            code: "MT6885", mfg: "MediaTek")
        
        reg(["mt6879"],
            cn: "联发科 天玑 1080 / 7020", en: "MediaTek Dimensity 1080",
            code: "MT6879", mfg: "MediaTek")
        
        reg(["mt6877"],
            cn: "联发科 天玑 900 / 920 / 7050", en: "MediaTek Dimensity 900",
            code: "MT6877", mfg: "MediaTek")
        
        reg(["mt6855"],
            cn: "联发科 天玑 930", en: "MediaTek Dimensity 930",
            code: "MT6855", mfg: "MediaTek")
        
        reg(["mt6853"],
            cn: "联发科 天玑 720 / 800U", en: "MediaTek Dimensity 720",
            code: "MT6853", mfg: "MediaTek")
        
        reg(["mt6833"],
            cn: "联发科 天玑 700 / 6020 / 6080", en: "MediaTek Dimensity 700",
            code: "MT6833", mfg: "MediaTek")
        
        reg(["mt6835"],
            cn: "联发科 天玑 6100+", en: "MediaTek Dimensity 6100+",
            code: "MT6835", mfg: "MediaTek")
        
        reg(["mt6789"],
            cn: "联发科 Helio G99", en: "MediaTek Helio G99",
            code: "MT6789", mfg: "MediaTek")
        
        reg(["mt6785"],
            cn: "联发科 Helio G90 / G95", en: "MediaTek Helio G95",
            code: "MT6785", mfg: "MediaTek")
        
        reg(["mt6769"],
            cn: "联发科 Helio G80 / G85 / G88", en: "MediaTek Helio G85",
            code: "MT6769", mfg: "MediaTek")
        
        reg(["mt6768"],
            cn: "联发科 Helio P65", en: "MediaTek Helio P65",
            code: "MT6768", mfg: "MediaTek")
        
        reg(["mt6765"],
            cn: "联发科 Helio P35 / G35", en: "MediaTek Helio P35",
            code: "MT6765", mfg: "MediaTek")
        
        reg(["mt6762"],
            cn: "联发科 Helio P22 / G25", en: "MediaTek Helio P22",
            code: "MT6762", mfg: "MediaTek")
            
        // MARK: - Google Tensor (谷歌)
        reg(["zuma pro", "ripcurrent"],
            cn: "谷歌 Tensor G4", en: "Google Tensor G4",
            code: "Zuma Pro", mfg: "Google")
        
        reg(["zuma"],
            cn: "谷歌 Tensor G3", en: "Google Tensor G3",
            code: "Zuma", mfg: "Google")
        
        reg(["cloudripper", "gs201", "cheetah", "panther"],
            cn: "谷歌 Tensor G2", en: "Google Tensor G2",
            code: "GS201", mfg: "Google")
        
        reg(["whitechapel", "gs101", "raven", "oriole"],
            cn: "谷歌 Tensor G1", en: "Google Tensor G1",
            code: "GS101", mfg: "Google")
            
        // MARK: - Samsung Exynos (三星 猎户座)
        reg(["s5e9945", "universal2400"],
            cn: "三星 Exynos 2400", en: "Samsung Exynos 2400",
            code: "S5E9945", mfg: "Samsung")
        
        reg(["s5e9925", "pamir", "universal2200"],
            cn: "三星 Exynos 2200", en: "Samsung Exynos 2200",
            code: "S5E9925 (Pamir)", mfg: "Samsung")
        
        reg(["s5e9840", "olympus", "universal2100"],
            cn: "三星 Exynos 2100", en: "Samsung Exynos 2100",
            code: "S5E9840 (Olympus)", mfg: "Samsung")
        
        reg(["s5e9830", "universal990"],
            cn: "三星 Exynos 990", en: "Samsung Exynos 990",
            code: "S5E9830", mfg: "Samsung")
        
        reg(["s5e8845"],
            cn: "三星 Exynos 1480", en: "Samsung Exynos 1480",
            code: "S5E8845", mfg: "Samsung")
        
        reg(["s5e8835"],
            cn: "三星 Exynos 1380", en: "Samsung Exynos 1380",
            code: "S5E8835", mfg: "Samsung")
        
        reg(["s5e8825"],
            cn: "三星 Exynos 1280", en: "Samsung Exynos 1280",
            code: "S5E8825", mfg: "Samsung")
            
        // MARK: - HiSilicon Kirin (华为 海思麒麟)
        reg(["kirin9010", "hi36a0"],
            cn: "海思 麒麟 9010", en: "HiSilicon Kirin 9010",
            code: "Kirin 9010", mfg: "HiSilicon")
        
        reg(["kirin9000s"],
            cn: "海思 麒麟 9000S", en: "HiSilicon Kirin 9000S",
            code: "Kirin 9000S", mfg: "HiSilicon")
        
        reg(["kirin9000", "kirin9000e"],
            cn: "海思 麒麟 9000 / 9000E", en: "HiSilicon Kirin 9000",
            code: "Kirin 9000", mfg: "HiSilicon")
        
        reg(["kirin990", "kirin990_5g"],
            cn: "海思 麒麟 990 / 990 5G", en: "HiSilicon Kirin 990",
            code: "Kirin 990", mfg: "HiSilicon")
        
        reg(["kirin985"],
            cn: "海思 麒麟 985", en: "HiSilicon Kirin 985",
            code: "Kirin 985", mfg: "HiSilicon")
        
        reg(["kirin980"],
            cn: "海思 麒麟 980", en: "HiSilicon Kirin 980",
            code: "Kirin 980", mfg: "HiSilicon")
        
        reg(["kirin820"],
            cn: "海思 麒麟 820", en: "HiSilicon Kirin 820",
            code: "Kirin 820", mfg: "HiSilicon")
        
        reg(["kirin810"],
            cn: "海思 麒麟 810", en: "HiSilicon Kirin 810",
            code: "Kirin 810", mfg: "HiSilicon")
        
        reg(["kirin710"],
            cn: "海思 麒麟 710 / 710F", en: "HiSilicon Kirin 710",
            code: "Kirin 710", mfg: "HiSilicon")
            
        // MARK: - Unisoc (紫光展锐)
        reg(["ums9620", "t760", "t770", "t820"],
            cn: "紫光展锐 T820 / T770", en: "Unisoc T820 / T770",
            code: "UMS9620", mfg: "Unisoc")
        
        reg(["ums512", "t618", "t616", "t612", "t610", "t606"],
            cn: "紫光展锐 T618 / T616", en: "Unisoc T618 / T616",
            code: "UMS512", mfg: "Unisoc")
        
        reg(["sc9863a"],
            cn: "紫光展锐 SC9863A", en: "Unisoc SC9863A",
            code: "SC9863A", mfg: "Unisoc")
            
        self.database = db
    }
    
    public func resolve(
        socModel: String?,
        boardPlatform: String?,
        socManufacturer: String?,
        hardware: String?,
        cpuinfoHardware: String?,
        isChinese: Bool = true
    ) -> (displayName: String, codeName: String?) {
        // Collect candidate keys to check against database
        var keysToCheck: [String] = []
        
        // 1. From /proc/cpuinfo (often has exact sub-model like SM8250_AC)
        if let ci = cpuinfoHardware?.lowercased() {
            let tokens = ci.components(separatedBy: CharacterSet.alphanumerics.inverted)
            for token in tokens where token.count >= 4 {
                keysToCheck.append(token)
            }
        }
        
        // 2. From ro.soc.model
        if let sm = socModel?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !sm.isEmpty {
            keysToCheck.append(sm)
            keysToCheck.append(sm.replacingOccurrences(of: "-", with: "_"))
            keysToCheck.append(sm.replacingOccurrences(of: "_", with: "-"))
        }
        
        // 3. From ro.board.platform
        if let bp = boardPlatform?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !bp.isEmpty {
            keysToCheck.append(bp)
        }
        
        // 4. From ro.hardware or chipname
        if let hw = hardware?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !hw.isEmpty {
            keysToCheck.append(hw)
        }
        
        // Look up in database
        for key in keysToCheck {
            if let entry = database[key] {
                let name = isChinese ? entry.chineseName : entry.englishName
                var code = entry.codeName
                
                // If we have boardPlatform and it's not already in code, append
                if let bp = boardPlatform, !bp.isEmpty, !code.lowercased().contains(bp.lowercased()) {
                    code += " (\(bp.capitalized))"
                }
                return (name, code)
            }
        }
        
        // MARK: - Smart Fallback for unlisted chipsets
        let mfg = socManufacturer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let model = socModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let platform = boardPlatform?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hw = hardware?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let mfgLower = mfg.lowercased()
        let hwLower = hw.lowercased()
        
        if mfgLower.contains("qualcomm") || hwLower.contains("qcom") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "高通 骁龙 \(id)" : "Qualcomm Snapdragon \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : (!hw.isEmpty ? hw : nil)
            return (name, code)
        } else if mfgLower.contains("mediatek") || hwLower.contains("mtk") || hwLower.contains("mt") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "联发科 \(id)" : "MediaTek \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : nil
            return (name, code)
        } else if mfgLower.contains("google") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "谷歌 Tensor \(id)" : "Google Tensor \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : nil
            return (name, code)
        } else if mfgLower.contains("samsung") || hwLower.contains("exynos") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "三星 Exynos \(id)" : "Samsung Exynos \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : nil
            return (name, code)
        } else if mfgLower.contains("hisilicon") || hwLower.contains("kirin") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "海思 麒麟 \(id)" : "HiSilicon Kirin \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : nil
            return (name, code)
        } else if mfgLower.contains("unisoc") || hwLower.contains("sprd") {
            let id = !model.isEmpty ? model : (!platform.isEmpty ? platform : hw)
            let name = isChinese ? "紫光展锐 \(id)" : "Unisoc \(id)"
            let code = !platform.isEmpty && platform != id ? "代号: \(platform)" : nil
            return (name, code)
        }
        
        // If some identifiers exist
        if !model.isEmpty {
            let prefix = !mfg.isEmpty ? "\(mfg) " : ""
            let name = "\(prefix)\(model)"
            let code = !platform.isEmpty ? "代号: \(platform)" : nil
            return (name, code)
        } else if !platform.isEmpty {
            let name = platform.uppercased()
            let code = !hw.isEmpty ? "硬件: \(hw)" : nil
            return (name, code)
        } else if !hw.isEmpty {
            return (hw.uppercased(), nil)
        }
        
        // Unknown
        return (isChinese ? "未知芯片平台" : "Unknown SoC", nil)
    }
}
