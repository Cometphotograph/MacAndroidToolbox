import SwiftUI

public struct ShellToolsView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    // Custom command state
    @State private var commandInput: String = ""
    @State private var commandOutput: String = ""
    @State private var isExecuting: Bool = false
    
    // Display tweak state
    @State private var customDensity: String = ""
    @State private var customResolution: String = ""
    
    // Preset commands
    var presets: [(String, String)] {
        [
            (L10n("shell_preset_cpu"), "cat /proc/cpuinfo"),
            (L10n("shell_preset_disk"), "df -h"),
            (L10n("shell_preset_props"), "getprop"),
            (L10n("shell_preset_battery"), "dumpsys battery"),
            (L10n("shell_preset_mem"), "dumpsys meminfo"),
            (L10n("shell_preset_clear_proxy"), "settings put global http_proxy :0"),
            (L10n("shell_preset_get_proxy"), "settings get global http_proxy")
        ]
    }
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Tweaks Card (Liquid Glass)
                quickTweaksCard
                
                // Display Tuning Card (Liquid Glass)
                displayTuningCard
                
                // Custom Interactive Shell Card (Liquid Glass)
                interactiveShellCard
            }
            .padding(16)
        }
    }
    
    // MARK: - Subviews
    private var quickTweaksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n("shell_tweaks_title"), systemImage: "wand.and.stars")
                .font(.headline)
            
            Text(L10n("shell_tweaks_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                Button {
                    runPreset("dumpsys battery")
                } label: {
                    Label(L10n("shell_btn_battery"), systemImage: "battery.100")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                
                Button {
                    toggleDemoMode(enable: true)
                } label: {
                    Label(L10n("shell_btn_demo_on"), systemImage: "sparkles.tv")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton(tint: .mint)
                
                Button {
                    toggleDemoMode(enable: false)
                } label: {
                    Label(L10n("shell_btn_demo_off"), systemImage: "xmark.tv")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                
                Button {
                    restartAdbServer()
                } label: {
                    Label(L10n("shell_btn_restart_adb"), systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                
                Button {
                    runPreset("settings put global http_proxy :0")
                } label: {
                    Label(L10n("shell_btn_clear_proxy"), systemImage: "network.slash")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
                
                Button {
                    runPreset("dumpsys meminfo")
                } label: {
                    Label(L10n("shell_btn_meminfo"), systemImage: "memorychip")
                        .frame(maxWidth: .infinity)
                }
                .liquidGlassButton()
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var displayTuningCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n("shell_display_title"), systemImage: "display.2")
                .font(.headline)
            
            Text(L10n("shell_display_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 20) {
                // Density
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("shell_custom_dpi_label"))
                        .font(.caption.bold())
                    HStack {
                        TextField("420", text: $customDensity)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        
                        Button(L10n("shell_apply_dpi")) {
                            applyDensity()
                        }
                        .liquidGlassButton(tint: .blue, prominent: true)
                        .disabled(customDensity.isEmpty)
                        
                        Button(L10n("shell_reset_default")) {
                            resetDensity()
                        }
                        .liquidGlassButton()
                    }
                }
                
                Divider().frame(height: 50).opacity(0.4)
                
                // Resolution
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("shell_custom_res_label"))
                        .font(.caption.bold())
                    HStack {
                        TextField("1080x2400", text: $customResolution)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        
                        Button(L10n("shell_apply_res")) {
                            applyResolution()
                        }
                        .liquidGlassButton(tint: .blue, prominent: true)
                        .disabled(customResolution.isEmpty)
                        
                        Button(L10n("shell_reset_default")) {
                            resetResolution()
                        }
                        .liquidGlassButton()
                    }
                }
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var interactiveShellCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("shell_terminal_title"), systemImage: "apple.terminal")
                .font(.headline)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 10) {
                Text("adb shell")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                
                TextField(L10n("shell_terminal_prompt"), text: $commandInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        executeCustomCommand()
                    }
                
                Button {
                    executeCustomCommand()
                } label: {
                    if isExecuting {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Text(L10n("shell_execute"))
                    }
                }
                .liquidGlassButton(tint: .blue, prominent: true)
                .disabled(commandInput.isEmpty || isExecuting || deviceManager.selectedDevice?.mode != .adb)
                
                Menu(L10n("shell_presets")) {
                    ForEach(presets, id: \.1) { item in
                        Button(item.0) {
                            commandInput = item.1
                            executeCustomCommand()
                        }
                    }
                }
                .menuStyle(.borderedButton)
            }
            
            // Shell Output Viewer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n("shell_output"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    if !commandOutput.isEmpty {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(commandOutput, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("複製輸出")
                        
                        Button {
                            commandOutput = ""
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .help("清空輸出")
                    }
                }
                
                ScrollView {
                    Text(commandOutput.isEmpty ? L10n("shell_waiting") : commandOutput)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(commandOutput.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor).opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Actions
    private func executeCustomCommand() {
        guard let dev = deviceManager.selectedDevice, dev.mode == .adb else { return }
        isExecuting = true
        let cmd = commandInput
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在執行 Shell: \(cmd)...")
                let out = try await ADBService.shared.executeShell(serial: dev.serial, command: cmd)
                commandOutput = out
                deviceManager.appendLog(level: .success, text: "Shell 指令執行完成")
            } catch {
                commandOutput = "錯誤: \(error.localizedDescription)"
                deviceManager.appendLog(level: .error, text: "執行失敗: \(error.localizedDescription)")
            }
            isExecuting = false
        }
    }
    
    private func runPreset(_ cmd: String) {
        commandInput = cmd
        executeCustomCommand()
    }
    
    private func applyDensity() {
        guard let dev = deviceManager.selectedDevice, let density = Int(customDensity) else { return }
        Task {
            do {
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "wm density \(density)")
                deviceManager.appendLog(level: .success, text: "已修改螢幕 DPI 為 \(density)")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "修改 DPI 失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetDensity() {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "wm density reset")
                deviceManager.appendLog(level: .success, text: "已重置螢幕 DPI 為系統預設")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "重置 DPI 失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func applyResolution() {
        guard let dev = deviceManager.selectedDevice else { return }
        let res = customResolution.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "wm size \(res)")
                deviceManager.appendLog(level: .success, text: "已修改螢幕解析度為 \(res)")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "修改解析度失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetResolution() {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "wm size reset")
                deviceManager.appendLog(level: .success, text: "已重置螢幕解析度為硬體預設")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "重置解析度失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleDemoMode(enable: Bool) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                if enable {
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "settings put global sysui_demo_allowed 1")
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command enter")
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1200")
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false")
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4")
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command notifications -e visible false")
                    deviceManager.appendLog(level: .success, text: "已開啟 Android 乾淨展示模式")
                } else {
                    _ = try await ADBService.shared.executeShell(serial: dev.serial, command: "am broadcast -a com.android.systemui.demo -e command exit")
                    deviceManager.appendLog(level: .success, text: "已退出 Android 展示模式")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "切換展示模式失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func restartAdbServer() {
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在重啟 ADB 伺服器...")
                try await ADBService.shared.restartServer()
                deviceManager.appendLog(level: .success, text: "ADB 伺服器重啟完成")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟伺服器失敗: \(error.localizedDescription)")
            }
        }
    }
}
