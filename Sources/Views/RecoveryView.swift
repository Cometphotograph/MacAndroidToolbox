import SwiftUI
import UniformTypeIdentifiers

public struct RecoveryView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    // Sideload state
    @State private var sideloadZipPath: String = ""
    @State private var isSideloading: Bool = false
    @State private var sideloadProgressText: String = ""
    @State private var showSideloadConfirm: Bool = false
    @State private var autoRebootAfterSideload: Bool = false
    
    // Wipe / Danger state
    @State private var showWipeConfirm: Bool = false
    @State private var isOperating: Bool = false
    
    public init() {}
    
    private var isDeviceInRecovery: Bool {
        guard let mode = deviceManager.selectedDevice?.mode else { return false }
        return mode == .recovery || mode == .sideload
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Recovery Status & Fast Navigation Banner
                recoveryStatusBanner
                
                // 2. Sideload Flasher Card
                sideloadCard
                
                // 3. Recovery Quick Actions Card
                recoveryActionsCard
                
                // 4. Recovery Manual Guide
                recoveryGuideCard
            }
            .padding(16)
        }
        .confirmationDialog(
            L10n("file_sideload_confirm_title"),
            isPresented: $showSideloadConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n("file_sideload_start_btn"), role: .destructive) {
                executeSideload()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("file_sideload_confirm_msg"))
        }
        .confirmationDialog(
            L10n("rec_wipe_confirm_title"),
            isPresented: $showWipeConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n("rec_wipe_data"), role: .destructive) {
                executeWipeData()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("rec_wipe_confirm_msg"))
        }
    }
    
    // MARK: - Recovery Status Banner
    private var recoveryStatusBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isDeviceInRecovery ? Color.purple.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isDeviceInRecovery ? "cross.case.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isDeviceInRecovery ? .purple : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(L10n("rec_status_title"))
                        .font(.headline)
                    
                    if let dev = deviceManager.selectedDevice {
                        Text(dev.mode.title)
                            .font(.caption.bold())
                            .foregroundColor(dev.mode.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(dev.mode.color.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Text(isDeviceInRecovery ? "設備已就緒，可隨時執行 Sideload 旁推或分區維護指令。" : "當前設備不在 Recovery 模式中。如需刷機或雙清，請先重啟進入 Recovery。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isDeviceInRecovery {
                Button {
                    rebootToRecovery()
                } label: {
                    Label(L10n("rec_reboot_to_rec"), systemImage: "arrow.clockwise")
                }
                .liquidGlassButton(tint: .purple, prominent: true)
                .disabled(deviceManager.selectedDevice == nil || isOperating)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Sideload Card
    private var sideloadCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(L10n("file_sideload_title"), systemImage: "arrow.down.doc.fill")
                    .font(.headline)
                
                Spacer()
                
                Text("ZIP / OTA / ROM")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.ultraThinMaterial))
            }
            
            Text(L10n("file_sideload_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.3)
            
            // File input row
            HStack(spacing: 10) {
                TextField(L10n("file_sideload_placeholder"), text: $sideloadZipPath)
                    .textFieldStyle(.roundedBorder)
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        guard let provider = providers.first else { return false }
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async {
                                    self.sideloadZipPath = url.path
                                }
                            }
                        }
                        return true
                    }
                
                Button(L10n("file_browse_zip")) {
                    chooseZipFile()
                }
                .liquidGlassButton()
                
                Button {
                    showSideloadConfirm = true
                } label: {
                    if isSideloading {
                        ProgressView().scaleEffect(0.6)
                            .frame(width: 80)
                    } else {
                        Label(L10n("file_sideload_btn"), systemImage: "bolt.fill")
                    }
                }
                .liquidGlassButton(tint: .purple, prominent: true)
                .disabled(sideloadZipPath.isEmpty || isSideloading || deviceManager.selectedDevice == nil)
            }
            
            // Options
            HStack(spacing: 16) {
                Toggle("刷入完成後自動重啟系統 (Reboot System)", isOn: $autoRebootAfterSideload)
                    .font(.subheadline)
                
                Spacer()
            }
            
            // Progress display
            if !sideloadProgressText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(L10n("file_progress_current")) \(sideloadProgressText)")
                            .font(.caption.monospaced())
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                    ProgressView(value: parseProgressPercent(sideloadProgressText), total: 100)
                        .progressViewStyle(.linear)
                }
                .padding(.top, 4)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Recovery Quick Actions
    private var recoveryActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Recovery 常用電源與維護指令", systemImage: "gearshape.2.fill")
                .font(.headline)
            
            Text("快速控制設備從 Recovery 切換至其他模式，或執行清理維護。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.3)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                Button {
                    rebootToSystem()
                } label: {
                    Label(L10n("rec_reboot_to_sys"), systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                .disabled(deviceManager.selectedDevice == nil || isOperating)
                
                Button {
                    rebootToBootloader()
                } label: {
                    Label(L10n("rec_reboot_to_bl"), systemImage: "bolt.horizontal.fill")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                .disabled(deviceManager.selectedDevice == nil || isOperating)
                
                Button {
                    executeWipeCache()
                } label: {
                    Label(L10n("rec_wipe_cache"), systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                .disabled(deviceManager.selectedDevice == nil || isOperating)
                
                Button {
                    showWipeConfirm = true
                } label: {
                    Label(L10n("rec_wipe_data"), systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton(tint: .red, prominent: false)
                .disabled(deviceManager.selectedDevice == nil || isOperating)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Recovery Guide Card
    private var recoveryGuideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("rec_guide_title"), systemImage: "questionmark.circle.fill")
                .font(.headline)
            
            Text(L10n("rec_guide_body"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Helpers & Actions
    private func chooseZipFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType.zip,
            UTType(filenameExtension: "zip")!
        ]
        panel.prompt = L10n("common_confirm")
        
        if panel.runModal() == .OK, let url = panel.url {
            sideloadZipPath = url.path
        }
    }
    
    private func parseProgressPercent(_ text: String) -> Double {
        // e.g. "Serving: 45%" or "(~45%)"
        if let match = text.range(of: #"\d+"#, options: .regularExpression) {
            return Double(text[match]) ?? 0
        }
        return 0
    }
    
    private func executeSideload() {
        guard let dev = deviceManager.selectedDevice else { return }
        isSideloading = true
        let zip = sideloadZipPath
        let autoReboot = autoRebootAfterSideload
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在 Sideload 刷入 \(zip)...")
                try await ADBService.shared.sideload(serial: dev.serial, zipPath: zip) { progress in
                    DispatchQueue.main.async {
                        self.sideloadProgressText = progress
                    }
                }
                deviceManager.appendLog(level: .success, text: "Sideload 刷機成功完成！")
                
                if autoReboot {
                    deviceManager.appendLog(level: .info, text: "正在自動重啟系統...")
                    try? await ADBService.shared.reboot(serial: dev.serial, target: .system)
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "Sideload 刷機失敗: \(error.localizedDescription)")
            }
            isSideloading = false
        }
    }
    
    private func rebootToRecovery() {
        guard let dev = deviceManager.selectedDevice else { return }
        isOperating = true
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在發送指令重啟至 Recovery...")
                try await ADBService.shared.reboot(serial: dev.serial, target: .recovery)
                deviceManager.appendLog(level: .success, text: "重啟至 Recovery 指令已發送")
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟失敗: \(error.localizedDescription)")
            }
            isOperating = false
        }
    }
    
    private func rebootToSystem() {
        guard let dev = deviceManager.selectedDevice else { return }
        isOperating = true
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在發送指令重啟至系統...")
                try await ADBService.shared.reboot(serial: dev.serial, target: .system)
                deviceManager.appendLog(level: .success, text: "重啟指令已發送")
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟失敗: \(error.localizedDescription)")
            }
            isOperating = false
        }
    }
    
    private func rebootToBootloader() {
        guard let dev = deviceManager.selectedDevice else { return }
        isOperating = true
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在發送指令重啟至 Bootloader...")
                try await ADBService.shared.reboot(serial: dev.serial, target: .bootloader)
                deviceManager.appendLog(level: .success, text: "重啟至 Bootloader 指令已發送")
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟失敗: \(error.localizedDescription)")
            }
            isOperating = false
        }
    }
    
    private func executeWipeCache() {
        guard let dev = deviceManager.selectedDevice else { return }
        isOperating = true
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在發送清除 Cache 指令...")
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "recovery --wipe_cache || true")
                deviceManager.appendLog(level: .success, text: "清除 Cache 指令執行完成")
            } catch {
                deviceManager.appendLog(level: .error, text: "清除 Cache 失敗: \(error.localizedDescription)")
            }
            isOperating = false
        }
    }
    
    private func executeWipeData() {
        guard let dev = deviceManager.selectedDevice else { return }
        isOperating = true
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在發送恢復出廠設定 (Wipe Data) 指令...")
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "recovery --wipe_data || true")
                deviceManager.appendLog(level: .success, text: "恢復出廠設定指令已發送")
            } catch {
                deviceManager.appendLog(level: .error, text: "執行失敗: \(error.localizedDescription)")
            }
            isOperating = false
        }
    }
}
