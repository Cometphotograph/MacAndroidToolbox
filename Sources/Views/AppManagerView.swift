import SwiftUI
import UniformTypeIdentifiers

public struct AppManagerView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    @State private var packages: [PackageInfo] = []
    @State private var isLoading: Bool = false
    @State private var filterType: PackageFilterType = .thirdParty
    @State private var searchText: String = ""
    
    // Install state
    @State private var installApkPath: String = ""
    @State private var isInstalling: Bool = false
    @State private var allowDowngrade: Bool = true
    @State private var grantPermissions: Bool = true
    @State private var replaceExisting: Bool = true
    
    // Selected package for action confirmation
    @State private var packageToUninstall: PackageInfo? = nil
    @State private var showUninstallAlert: Bool = false
    @State private var keepDataOnUninstall: Bool = false
    
    public init() {}
    
    var filteredPackages: [PackageInfo] {
        packages.filter { pkg in
            searchText.isEmpty || pkg.packageName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Install APK Card (Liquid Glass)
            installCard
            
            // Package List Controls (Liquid Glass)
            listControlBar
            
            // Packages List / Table
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("正在讀取設備應用清單...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if packages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(deviceManager.selectedDevice?.mode == .adb ? L10n("app_empty_hint_adb") : L10n("app_empty_hint_no_adb"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if deviceManager.selectedDevice?.mode == .adb {
                        Button(L10n("app_load_btn")) {
                            loadPackages()
                        }
                        .liquidGlassButton(tint: .blue, prominent: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                packageListView
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 220)
        .onAppear {
            if packages.isEmpty && deviceManager.selectedDevice?.mode == .adb {
                loadPackages()
            }
        }
        .confirmationDialog(
            String(format: L10n("app_uninstall_confirm_title"), packageToUninstall?.packageName ?? ""),
            isPresented: $showUninstallAlert,
            titleVisibility: .visible
        ) {
            Button(L10n("app_confirm_uninstall_btn"), role: .destructive) {
                if let pkg = packageToUninstall {
                    executeUninstall(pkg)
                }
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("app_uninstall_confirm_msg"))
        }
    }
    
    // MARK: - Subviews
    private var installCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n("app_install_card"), systemImage: "arrow.down.app.fill")
                .font(.headline)
            
            HStack(spacing: 10) {
                TextField(L10n("app_install_placeholder"), text: $installApkPath)
                    .textFieldStyle(.roundedBorder)
                
                Button(L10n("app_browse_apk")) {
                    chooseApkFile()
                }
                .liquidGlassButton()
                
                Button {
                    executeInstall()
                } label: {
                    if isInstalling {
                        ProgressView().scaleEffect(0.6)
                            .frame(width: 60)
                    } else {
                        Label(L10n("app_install_btn"), systemImage: "plus.app")
                    }
                }
                .liquidGlassButton(tint: .blue, prominent: true)
                .disabled(installApkPath.isEmpty || isInstalling || deviceManager.selectedDevice?.mode != .adb)
            }
            
            HStack(spacing: 16) {
                Toggle(L10n("app_downgrade"), isOn: $allowDowngrade)
                Toggle(L10n("app_grant_perms"), isOn: $grantPermissions)
                Toggle(L10n("app_replace"), isOn: $replaceExisting)
            }
            .font(.caption)
        }
        .liquidGlassCard(cornerRadius: 16, padding: 14)
    }
    
    private var listControlBar: some View {
        HStack(spacing: 12) {
            Picker("", selection: $filterType) {
                ForEach(PackageFilterType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 380)
            .onChange(of: filterType) { _ in
                loadPackages()
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L10n("app_search_placeholder"), text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            
            Button {
                loadPackages()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(L10n("tb_refresh"))
            .liquidGlassButton()
            .disabled(isLoading || deviceManager.selectedDevice?.mode != .adb)
        }
    }
    
    private var packageListView: some View {
        List {
            ForEach(filteredPackages) { pkg in
                HStack(spacing: 12) {
                    Image(systemName: pkg.isSystem ? "gearshape.fill" : "app.fill")
                        .font(.system(size: 20))
                        .foregroundColor(pkg.isSystem ? .secondary : .blue)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(pkg.packageName)
                                .font(.headline)
                                .textSelection(.enabled)
                            
                            if pkg.isSystem {
                                Text(L10n("app_system_tag"))
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(pkg.apkPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    // Liquid Glass Action Buttons
                    HStack(spacing: 6) {
                        Button {
                            launchApp(pkg)
                        } label: {
                            Image(systemName: "play.fill")
                        }
                        .help(L10n("app_launch"))
                        .buttonStyle(.borderless)
                        
                        Button {
                            forceStopApp(pkg)
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .help(L10n("app_force_stop"))
                        .buttonStyle(.borderless)
                        
                        Button {
                            clearData(pkg)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help(L10n("app_clear_data"))
                        .buttonStyle(.borderless)
                        
                        Button {
                            toggleFreeze(pkg)
                        } label: {
                            Image(systemName: pkg.isEnabled ? "snowflake" : "sun.max.fill")
                        }
                        .help(pkg.isEnabled ? L10n("app_freeze") : L10n("app_unfreeze"))
                        .buttonStyle(.borderless)
                        .foregroundColor(pkg.isEnabled ? .cyan : .orange)
                        
                        Button {
                            extractApk(pkg)
                        } label: {
                            Image(systemName: "arrow.down.circle")
                        }
                        .help(L10n("app_extract"))
                        .buttonStyle(.borderless)
                        
                        Button {
                            packageToUninstall = pkg
                            showUninstallAlert = true
                        } label: {
                            Image(systemName: "xmark.bin.fill")
                        }
                        .help(L10n("app_uninstall"))
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .scrollContentBackground(.hidden)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Actions
    private func chooseApkFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "apk") ?? .data, .data]
        panel.prompt = "選擇 APK"
        
        if panel.runModal() == .OK, let url = panel.url {
            installApkPath = url.path
        }
    }
    
    private func loadPackages() {
        guard let dev = deviceManager.selectedDevice, dev.mode == .adb else { return }
        isLoading = true
        let filter = filterType
        
        Task {
            deviceManager.appendLog(level: .info, text: "正在讀取 [\(filter.rawValue)] 清單...")
            let list = await ADBService.shared.listPackages(serial: dev.serial, filter: filter)
            packages = list
            isLoading = false
            deviceManager.appendLog(level: .success, text: "讀取完畢，共 \(list.count) 個套件。")
        }
    }
    
    private func executeInstall() {
        guard let dev = deviceManager.selectedDevice else { return }
        isInstalling = true
        let path = installApkPath
        let downgrade = allowDowngrade
        let grant = grantPermissions
        let replace = replaceExisting
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在安裝 APK: \(path)...")
                try await ADBService.shared.installApp(
                    serial: dev.serial,
                    apkPath: path,
                    allowDowngrade: downgrade,
                    grantPermissions: grant,
                    replace: replace
                )
                deviceManager.appendLog(level: .success, text: "APK 安裝成功！")
                loadPackages()
            } catch {
                deviceManager.appendLog(level: .error, text: "安裝失敗: \(error.localizedDescription)")
            }
            isInstalling = false
        }
    }
    
    private func executeUninstall(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在解除安裝: \(pkg.packageName)...")
                try await ADBService.shared.uninstallApp(serial: dev.serial, packageName: pkg.packageName, keepData: keepDataOnUninstall)
                deviceManager.appendLog(level: .success, text: "已成功解除安裝 \(pkg.packageName)！")
                loadPackages()
            } catch {
                deviceManager.appendLog(level: .error, text: "解除安裝失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func launchApp(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在啟動 \(pkg.packageName)...")
                try await ADBService.shared.launchApp(serial: dev.serial, packageName: pkg.packageName)
                deviceManager.appendLog(level: .success, text: "已發送啟動指令")
            } catch {
                deviceManager.appendLog(level: .error, text: "啟動失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func forceStopApp(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在強制停止 \(pkg.packageName)...")
                try await ADBService.shared.forceStopApp(serial: dev.serial, packageName: pkg.packageName)
                deviceManager.appendLog(level: .success, text: "已強制停止應用")
            } catch {
                deviceManager.appendLog(level: .error, text: "操作失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func clearData(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在清空應用資料: \(pkg.packageName)...")
                try await ADBService.shared.clearAppData(serial: dev.serial, packageName: pkg.packageName)
                deviceManager.appendLog(level: .success, text: "應用資料已清空")
            } catch {
                deviceManager.appendLog(level: .error, text: "清空失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleFreeze(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        let shouldEnable = !pkg.isEnabled
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在\(shouldEnable ? "啟用" : "停用") \(pkg.packageName)...")
                try await ADBService.shared.setAppEnabled(serial: dev.serial, packageName: pkg.packageName, enable: shouldEnable)
                deviceManager.appendLog(level: .success, text: "操作成功")
                loadPackages()
            } catch {
                deviceManager.appendLog(level: .error, text: "操作失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func extractApk(_ pkg: PackageInfo) {
        guard let dev = deviceManager.selectedDevice else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(pkg.packageName).apk"
        panel.prompt = L10n("panel_save_apk")
        
        if panel.runModal() == .OK, let targetUrl = panel.url {
            Task {
                do {
                    deviceManager.appendLog(level: .info, text: "正在導出 \(pkg.apkPath) 至 \(targetUrl.path)...")
                    try await ADBService.shared.pullFile(serial: dev.serial, remotePath: pkg.apkPath, localPath: targetUrl.path)
                    deviceManager.appendLog(level: .success, text: "APK 導出成功！檔案位於 \(targetUrl.path)")
                } catch {
                    deviceManager.appendLog(level: .error, text: "導出失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}
