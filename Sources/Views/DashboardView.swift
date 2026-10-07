import SwiftUI

public struct DashboardView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @State private var wirelessIP: String = ""
    @State private var wirelessPort: String = "5555"
    @State private var isConnectingWireless: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let device = deviceManager.selectedDevice {
                    // Header Status Card (Liquid Glass)
                    deviceHeaderCard(device)
                    
                    if device.mode == .unauthorized {
                        unauthorizedWarningBanner
                    }
                    
                    // Device Specs Grid (Liquid Glass)
                    specsGrid(device)
                    
                    // Quick Reboot Actions (Liquid Glass)
                    rebootActionsCard(device)
                    
                    // Wireless ADB Section (if in ADB mode)
                    if device.mode == .adb {
                        wirelessAdbCard(device)
                    }
                } else {
                    noDevicePlaceholder
                }
            }
            .padding(16)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(L10n("common_alert")), message: Text(alertMessage ?? ""), dismissButton: .default(Text(L10n("common_ok"))))
        }
    }
    
    // MARK: - Subviews
    private func deviceHeaderCard(_ device: AndroidDevice) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [device.mode.color.opacity(0.3), device.mode.color.opacity(0.05), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 36
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: device.mode.icon)
                    .font(.system(size: 28))
                    .foregroundColor(device.mode.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(device.displayName)
                        .font(.title2.bold())
                    
                    // Liquid Mode Badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(device.mode.color)
                            .frame(width: 7, height: 7)
                        Text(device.mode.title)
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(device.mode.color.opacity(0.15))
                    .foregroundColor(device.mode.color)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(device.mode.color.opacity(0.3), lineWidth: 1))
                    
                    if device.isRooted {
                        Text(L10n("dash_rooted"))
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
                }
                
                HStack(spacing: 14) {
                    Text("\(L10n("dash_serial")) \(device.serial)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    if let slot = device.currentSlot {
                        Text("\(L10n("dash_current_slot")) \(slot.uppercased())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button {
                deviceManager.refreshDevices()
            } label: {
                Label(L10n("tb_refresh"), systemImage: "arrow.clockwise")
            }
            .liquidGlassButton(tint: .blue)
            .disabled(deviceManager.isRefreshing)
        }
        .liquidGlassCard(cornerRadius: 18, padding: 16)
    }
    
    private var unauthorizedWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n("dash_unauthorized_title"))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(L10n("dash_unauthorized_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func specsGrid(_ device: AndroidDevice) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            specCard(
                icon: "sparkles",
                title: L10n("dash_android_version"),
                value: device.androidVersion.isEmpty ? L10n("common_unknown") : "Android \(device.androidVersion)",
                subtitle: device.sdkVersion > 0 ? "SDK API \(device.sdkVersion)" : nil,
                color: .green
            )
            
            specCard(
                icon: "battery.100.bolt",
                title: L10n("dash_battery_status"),
                value: device.batteryLevel >= 0 ? "\(device.batteryLevel)%" : L10n("common_unknown"),
                subtitle: device.batteryTemperature > 0 ? "\(String(format: "%.1f", device.batteryTemperature))°C • \(device.batteryStatusLocalized)" : device.batteryStatusLocalized,
                color: .blue
            )
            
            specCard(
                icon: "display",
                title: L10n("dash_screen_specs"),
                value: device.screenResolution ?? L10n("common_unknown"),
                subtitle: device.screenDensity,
                color: .purple
            )
            
            specCard(
                icon: "shield.checkerboard",
                title: L10n("dash_security_patch"),
                value: device.securityPatch.isEmpty ? L10n("common_unknown") : device.securityPatch,
                subtitle: L10n("dash_security_level"),
                color: .orange
            )
            
            specCard(
                icon: "cpu",
                title: L10n("dash_hardware_model"),
                value: device.product.isEmpty ? device.model : device.product,
                subtitle: device.brand.isEmpty ? nil : "\(L10n("dash_brand")) \(device.brand)",
                color: .mint
            )
            
            specCard(
                icon: "wifi",
                title: L10n("dash_network_ip"),
                value: device.ipAddress ?? L10n("dash_usb_cable"),
                subtitle: device.ipAddress != nil ? L10n("dash_lan_ip") : L10n("dash_physical_line"),
                color: .cyan
            )
        }
    }
    
    private func specCard(icon: String, title: String, value: String, subtitle: String?, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .liquidGlassCard(cornerRadius: 14, padding: 12)
    }
    
    private func rebootActionsCard(_ device: AndroidDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("dash_quick_reboot"), systemImage: "arrow.counterclockwise.circle.fill")
                .font(.headline)
            
            Text(L10n("dash_quick_reboot_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if device.mode == .adb {
                    ForEach(ADBRebootTarget.allCases) { target in
                        Button {
                            performADBReboot(target: target)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: target.icon)
                                    .font(.system(size: 15))
                                    .frame(width: 22)
                                Text(target.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .leading)
                        }
                        .liquidGlassButton()
                    }
                } else if device.mode == .fastboot || device.mode == .fastbootd {
                    ForEach(FastbootRebootTarget.allCases) { target in
                        Button {
                            performFastbootReboot(target: target)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: target.icon)
                                    .font(.system(size: 15))
                                    .frame(width: 22)
                                Text(target.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .leading)
                        }
                        .liquidGlassButton()
                    }
                } else {
                    Button {
                        performADBReboot(target: .system)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15))
                                .frame(width: 22)
                            Text(L10n("dash_reboot_system"))
                                .font(.system(size: 12, weight: .medium))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48, alignment: .leading)
                    }
                    .liquidGlassButton()
                }
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private func wirelessAdbCard(_ device: AndroidDevice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("dash_wireless_adb"), systemImage: "wifi")
                .font(.headline)
            
            Text(L10n("dash_wireless_adb_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 12) {
                Button {
                    enableWirelessTcpIp()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                        Text(L10n("dash_enable_tcpip"))
                            .lineLimit(1)
                    }
                    .frame(height: 24)
                }
                .liquidGlassButton(tint: .blue, prominent: true)
                .fixedSize(horizontal: true, vertical: false)
                
                Divider().frame(height: 24).opacity(0.4)
                
                TextField(L10n("dash_ip_placeholder"), text: $wirelessIP)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 180, maxWidth: 220)
                
                TextField("5555", text: $wirelessPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 55)
                
                Button {
                    connectWirelessDevice()
                } label: {
                    HStack(spacing: 6) {
                        if isConnectingWireless {
                            ProgressView()
                                .scaleEffect(0.65)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        Text(L10n("dash_connect"))
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(height: 24)
                }
                .liquidGlassButton(tint: .mint, prominent: true)
                .fixedSize(horizontal: true, vertical: false)
                .disabled(wirelessIP.isEmpty || isConnectingWireless)
                
                Spacer(minLength: 0)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var noDevicePlaceholder: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "iphone.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
            }
            
            Text(L10n("dash_no_device_title"))
                .font(.title2.bold())
            
            Text(L10n("dash_no_device_guide"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 500)
                .padding()
                .liquidGlassCard(cornerRadius: 14, padding: 14)
            
            Button {
                deviceManager.refreshDevices()
            } label: {
                Label(L10n("dash_scan_manual"), systemImage: "arrow.clockwise")
            }
            .liquidGlassButton(tint: .blue, prominent: true)
            .controlSize(.large)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func performADBReboot(target: ADBRebootTarget) {
        guard let device = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在重啟設備: \(target.rawValue)...")
                try await ADBService.shared.reboot(serial: device.serial, target: target)
                deviceManager.appendLog(level: .success, text: "已發送重啟指令")
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func performFastbootReboot(target: FastbootRebootTarget) {
        guard let device = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在執行 Fastboot 重啟: \(target.rawValue)...")
                try await FastbootService.shared.reboot(serial: device.serial, target: target)
                deviceManager.appendLog(level: .success, text: "已發送 Fastboot 重啟指令")
            } catch {
                deviceManager.appendLog(level: .error, text: "Fastboot 重啟失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func enableWirelessTcpIp() {
        guard let device = deviceManager.selectedDevice else { return }
        Task {
            do {
                let port = Int(wirelessPort) ?? 5555
                deviceManager.appendLog(level: .info, text: "正在為 \(device.serial) 開啟 TCP/IP 監聽 (Port: \(port))...")
                try await ADBService.shared.enableTcpIp(serial: device.serial, port: port)
                deviceManager.appendLog(level: .success, text: "TCP/IP 監聽成功開啟！現在可拔除 USB 傳輸線，輸入手機 Wi-Fi IP 進行無線連接。")
                if let ip = device.ipAddress {
                    wirelessIP = ip
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "開啟 TCP/IP 失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func connectWirelessDevice() {
        isConnectingWireless = true
        Task {
            do {
                let port = Int(wirelessPort) ?? 5555
                deviceManager.appendLog(level: .info, text: "正在嘗試無線連接至 \(wirelessIP):\(port)...")
                let result = try await ADBService.shared.connectWireless(ip: wirelessIP, port: port)
                deviceManager.appendLog(level: .success, text: "無線連接結果: \(result)")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "無線連接失敗: \(error.localizedDescription)")
            }
            isConnectingWireless = false
        }
    }
}
