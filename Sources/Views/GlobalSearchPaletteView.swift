import SwiftUI

public struct SearchFeatureItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let section: NavigationSection
    public let icon: String
    public let gradientColors: [Color]
    public let keywords: [String]
    
    public init(
        title: String,
        subtitle: String,
        section: NavigationSection,
        icon: String,
        gradientColors: [Color],
        keywords: [String]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.section = section
        self.icon = icon
        self.gradientColors = gradientColors
        self.keywords = keywords
    }
}

public struct GlobalSearchPaletteView: View {
    @Binding var isPresented: Bool
    var onSelectSection: (NavigationSection) -> Void
    
    @State private var searchText: String = ""
    @FocusState private var isFieldFocused: Bool
    
    // Feature catalogue
    private let allFeatures: [SearchFeatureItem] = [
        // 1. Dashboard
        SearchFeatureItem(
            title: "設備電池健康與溫度監控",
            subtitle: "即時查看電池電量、健康狀況、溫度與充電狀態",
            section: .dashboard,
            icon: "battery.100.bolt",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["電池", "battery", "電量", "溫度", "健康", "充電"]
        ),
        SearchFeatureItem(
            title: "系統版本與詳細規格",
            subtitle: "查看 Android 版本、SDK API 級別、處理器與安全修補程式",
            section: .dashboard,
            icon: "iphone.gen3",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["系統", "版本", "android", "sdk", "規格", "型號"]
        ),
        SearchFeatureItem(
            title: "螢幕解析度與 DPI 調節",
            subtitle: "一鍵修改裝置螢幕密度與自訂解析度",
            section: .dashboard,
            icon: "display",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["螢幕", "屏幕", "dpi", "density", "解析度", "分辨率"]
        ),
        SearchFeatureItem(
            title: "無線 ADB 配對與連線",
            subtitle: "免 USB 數據線透過 Wi-Fi 進行無線調試與配對",
            section: .dashboard,
            icon: "wifi",
            gradientColors: [Color.blue, Color.cyan],
            keywords: ["無線", "wifi", "配對", "網絡", "網路", "tcpip"]
        ),
        
        // 2. Fastboot
        SearchFeatureItem(
            title: "Fastboot 鏡像分區刷入 (Boot / Recovery)",
            subtitle: "線刷 Boot、Recovery、System、Vendor 等分區鏡像",
            section: .fastboot,
            icon: "bolt.horizontal.fill",
            gradientColors: [Color.orange, Color.red],
            keywords: ["fastboot", "刷機", "boot", "recovery", "線刷", "flash", "img"]
        ),
        SearchFeatureItem(
            title: "Bootloader 解鎖與上鎖 (BL)",
            subtitle: "執行 OEM Unlock 或 Flashing Unlock 解除引導鎖",
            section: .fastboot,
            icon: "lock.open.fill",
            gradientColors: [Color.orange, Color.red],
            keywords: ["bl", "bootloader", "解鎖", "unlock", "lock", "oem"]
        ),
        SearchFeatureItem(
            title: "A/B 槽位切換 (Slot Active)",
            subtitle: "查詢與切換目前啟動的分區槽位 (Slot A / Slot B)",
            section: .fastboot,
            icon: "arrow.triangle.swap",
            gradientColors: [Color.orange, Color.red],
            keywords: ["slot", "槽位", "a/b", "分區", "切換", "active"]
        ),
        SearchFeatureItem(
            title: "分區清除與格式化 (Erase / Format)",
            subtitle: "擦除特定分區或格式化 Userdata",
            section: .fastboot,
            icon: "trash.fill",
            gradientColors: [Color.orange, Color.red],
            keywords: ["erase", "format", "格式化", "擦除", "分區", "userdata"]
        ),
        
        // 3. Recovery
        SearchFeatureItem(
            title: "ADB Sideload 線刷卡刷包 (OTA / ROM / Zip)",
            subtitle: "在 Recovery 模式下旁推安裝系統升級包、ROM 或 Magisk",
            section: .recovery,
            icon: "arrow.down.doc.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["sideload", "旁推", "卡刷", "ota", "rom", "zip", "magisk", "刷機"]
        ),
        SearchFeatureItem(
            title: "一鍵重啟至 Recovery 模式",
            subtitle: "透過 ADB 或 Fastboot 發送重啟指令進入 Recovery 界面",
            section: .recovery,
            icon: "cross.case.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["recovery", "rec", "重啟", "雙清", "twrp", "orangefox"]
        ),
        SearchFeatureItem(
            title: "清除 Cache 快取分區",
            subtitle: "清除系統暫存快取分區，解決部分系統異常",
            section: .recovery,
            icon: "wind",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["cache", "快取", "緩存", "雙清", "wipe"]
        ),
        SearchFeatureItem(
            title: "清除 Data / 恢復原廠設定",
            subtitle: "在 Recovery 模式下清除使用者資料，還原出廠狀態",
            section: .recovery,
            icon: "exclamationmark.triangle.fill",
            gradientColors: [Color.purple, Color.indigo],
            keywords: ["wipe", "data", "恢復出廠", "雙清", "三清", "重置"]
        ),
        
        // 4. Shell
        SearchFeatureItem(
            title: "互動式 ADB Shell 終端機",
            subtitle: "直接執行 Android 系統 Linux 命令與自訂腳本",
            section: .shell,
            icon: "apple.terminal",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["shell", "terminal", "終端", "命令", "腳本", "linux", "cmd"]
        ),
        SearchFeatureItem(
            title: "即時 Logcat 日誌抓取",
            subtitle: "即時串流並過濾設備系統日誌、Crash 崩潰堆疊",
            section: .shell,
            icon: "doc.text.magnifyingglass",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["log", "logcat", "日誌", "崩潰", "報錯", "debug"]
        ),
        SearchFeatureItem(
            title: "CPU 與記憶體即時負載監控",
            subtitle: "檢視頂部行程、記憶體佔用與系統負載情況",
            section: .shell,
            icon: "cpu",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["cpu", "記憶體", "ram", "內存", "進程", "top"]
        ),
        SearchFeatureItem(
            title: "系統動畫縮放倍率調節",
            subtitle: "加速或關閉窗口動畫、過渡動畫與動畫時長",
            section: .shell,
            icon: "gauge.with.needle",
            gradientColors: [Color.teal, Color.blue],
            keywords: ["動畫", "加速", "速度", "縮放", "animation", "0.5x"]
        ),
        
        // 5. Apps
        SearchFeatureItem(
            title: "本地 APK 拖曳安裝",
            subtitle: "支援拖曳 APK/APKS 檔案一鍵安裝至裝置",
            section: .apps,
            icon: "arrow.down.app.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["安裝", "apk", "app", "應用", "install", "拖拽"]
        ),
        SearchFeatureItem(
            title: "匯出 / 提取已安裝 APK 安裝包",
            subtitle: "將手機內已安裝的應用提取備份為 APK 檔案至 Mac",
            section: .apps,
            icon: "arrow.up.doc.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["提取", "導出", "備份", "apk", "應用", "export"]
        ),
        SearchFeatureItem(
            title: "第三方應用與系統應用管理",
            subtitle: "過濾檢視已安裝應用清單、套件名稱與版本號",
            section: .apps,
            icon: "app.badge.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["套件", "應用列表", "清單", "package", "系統應用"]
        ),
        SearchFeatureItem(
            title: "停用 / 凍結 / 卸載應用程式",
            subtitle: "停用無用系統預裝或徹底刪除應用程式",
            section: .apps,
            icon: "xmark.bin.fill",
            gradientColors: [Color.green, Color.mint],
            keywords: ["卸載", "停用", "凍結", "刪除", "uninstall", "disable"]
        ),
        
        // 6. Files
        SearchFeatureItem(
            title: "電腦檔案推送到手機 (Push)",
            subtitle: "傳送 Mac 本地檔案或資料夾至手機指定儲存路徑",
            section: .files,
            icon: "arrow.up.circle.fill",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["push", "推送", "上傳", "檔案", "傳輸", "傳送"]
        ),
        SearchFeatureItem(
            title: "從手機下載拉取檔案 (Pull)",
            subtitle: "將手機內任何檔案或資料夾下載儲存至 Mac",
            section: .files,
            icon: "arrow.down.circle.fill",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["pull", "拉取", "下載", "檔案", "儲存", "導出"]
        ),
        SearchFeatureItem(
            title: "手機常用目錄快捷直達",
            subtitle: "一鍵選擇 Download、DCIM 相簿、Screenshots 截圖路徑",
            section: .files,
            icon: "folder.fill",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["目錄", "路徑", "相簿", "下載", "dcim", "download"]
        ),
        SearchFeatureItem(
            title: "手機螢幕截圖與複製",
            subtitle: "一鍵截取手機當前畫面，支援直接複製至 Mac 剪貼簿",
            section: .files,
            icon: "camera.viewfinder",
            gradientColors: [Color.orange, Color.yellow],
            keywords: ["截圖", "截屏", "螢幕", "screenshot", "照片", "複製"]
        ),
        
        // 7. Settings
        SearchFeatureItem(
            title: "軟體外觀主題設置 (深色 / 淺色)",
            subtitle: "自訂切換深色液態玻璃、淺色玻璃或跟隨系統外觀",
            section: .settings,
            icon: "paintbrush.fill",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["主題", "深色", "淺色", "外觀", "暗黑", "theme", "dark"]
        ),
        SearchFeatureItem(
            title: "多語言切換 (支援法語等9種語言)",
            subtitle: "切換繁體中文、簡體中文、英語、法語、日語等",
            section: .settings,
            icon: "globe",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["語言", "language", "法語", "英語", "中文", "日語"]
        ),
        SearchFeatureItem(
            title: "ADB 與 Fastboot 工具路徑檢測",
            subtitle: "檢查本機 Android Platform-tools 工具版本與有效性",
            section: .settings,
            icon: "hammer.fill",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["adb", "fastboot", "工具", "路徑", "platform-tools"]
        ),
        SearchFeatureItem(
            title: "GitHub 開源倉庫與開源聲明",
            subtitle: "造訪專案開源倉庫並查看 MIT 開源許可證",
            section: .settings,
            icon: "link",
            gradientColors: [Color.gray, Color.secondary],
            keywords: ["github", "開源", "倉庫", "repo", "作者", "關於"]
        )
    ]
    
    private var filteredFeatures: [SearchFeatureItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return allFeatures
        }
        return allFeatures.filter { item in
            item.title.lowercased().contains(q) ||
            item.subtitle.lowercased().contains(q) ||
            item.keywords.contains { $0.lowercased().contains(q) } ||
            item.section.title.lowercased().contains(q)
        }
    }
    
    public init(isPresented: Binding<Bool>, onSelectSection: @escaping (NavigationSection) -> Void) {
        self._isPresented = isPresented
        self.onSelectSection = onSelectSection
    }
    
    public var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isPresented = false
                    }
                }
            
            // Spotlight Glass Card
            VStack(spacing: 0) {
                // Search Input Header
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField(L10n("search_placeholder"), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .focused($isFieldFocused)
                        .onSubmit {
                            if let first = filteredFeatures.first {
                                selectFeature(first)
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("ESC")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider().opacity(0.3)
                
                // Results List
                if filteredFeatures.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 30)
                        
                        Text(L10n("search_no_results"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(filteredFeatures) { item in
                                resultRow(item)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 380)
                }
            }
            .frame(width: 540)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.75))
                    
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.25), radius: 30, x: 0, y: 15)
            .padding(.bottom, 100)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }
    
    private func resultRow(_ item: SearchFeatureItem) -> some View {
        Button {
            selectFeature(item)
        } label: {
            HStack(spacing: 12) {
                // Section Squircle Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: item.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(item.section.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                            )
                    }
                    
                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectFeature(_ item: SearchFeatureItem) {
        withAnimation(.easeOut(duration: 0.15)) {
            isPresented = false
            onSelectSection(item.section)
        }
    }
}
