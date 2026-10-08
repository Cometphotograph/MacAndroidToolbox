import SwiftUI
import UniformTypeIdentifiers

public struct FastbootView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    // Flashing state
    @State private var selectedPartitionName: String = "boot"
    @State private var customPartitionName: String = ""
    @State private var selectedFilePath: String = ""
    @State private var disableVerity: Bool = false
    @State private var targetSlot: String = "current"
    @State private var isFlashing: Bool = false
    @State private var showFlashConfirmation: Bool = false
    
    // Boot temporary state
    @State private var temporaryBootFilePath: String = ""
    @State private var isBooting: Bool = false
    
    // Erase / Format state
    @State private var erasePartitionName: String = "userdata"
    @State private var showEraseConfirmation: Bool = false
    @State private var isErasing: Bool = false
    
    // Unlock state
    @State private var selectedUnlockType: BootloaderUnlockType = .standard
    @State private var showUnlockConfirmation: Bool = false
    @State private var showLockConfirmation: Bool = false
    
    // Variables table state
    @State private var fastbootVariables: [FastbootVariable] = []
    @State private var varSearchText: String = ""
    @State private var isLoadingVars: Bool = false
    
    public init() {}
    
    var effectivePartition: String {
        if selectedPartitionName == "custom" {
            return customPartitionName.trimmingCharacters(in: .whitespaces)
        }
        return selectedPartitionName
    }
    
    var isDeviceInFastboot: Bool {
        guard let dev = deviceManager.selectedDevice else { return false }
        return dev.mode == .fastboot || dev.mode == .fastbootd
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Warning / Switch to Fastboot if currently in ADB mode
                if !isDeviceInFastboot {
                    notInFastbootBanner
                }
                
                // Device Fastboot Status & Slot Control
                fastbootStatusCard
                
                // Partition Flashing Card
                partitionFlashingCard
                
                // Boot Temporary Image Card
                temporaryBootCard
                
                // Partition Erase & Format Card
                eraseAndFormatCard
                
                // Bootloader Unlock / Lock Card
                bootloaderUnlockCard
                
                // Fastboot Variables Card
                variablesCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 220)
        }
        .scrollContentBackground(.hidden)
        .confirmationDialog(
            String(format: L10n("fb_confirm_flash_title"), effectivePartition),
            isPresented: $showFlashConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n("fb_confirm_flash_btn"), role: .destructive) {
                executeFlash()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(String(format: L10n("fb_confirm_flash_msg"), effectivePartition))
        }
        .confirmationDialog(
            String(format: L10n("fb_confirm_erase_title"), erasePartitionName),
            isPresented: $showEraseConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n("fb_confirm_erase_btn"), role: .destructive) {
                executeErase()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("fb_confirm_erase_msg"))
        }
        .confirmationDialog(
            L10n("fb_confirm_unlock_title"),
            isPresented: $showUnlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n("fb_confirm_unlock_btn"), role: .destructive) {
                executeUnlock()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("fb_confirm_unlock_msg"))
        }
        .confirmationDialog(
            L10n("fb_confirm_lock_title"),
            isPresented: $showLockConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n("fb_confirm_lock_btn"), role: .destructive) {
                executeLock()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("fb_confirm_lock_msg"))
        }
    }
    
    // MARK: - Subviews
    private var notInFastbootBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n("fb_not_in_fastboot"))
                    .font(.headline)
                Text(L10n("fb_not_in_fastboot_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                rebootToBootloader()
            } label: {
                Label(L10n("fb_reboot_to_fastboot"), systemImage: "bolt.fill")
            }
            .liquidGlassButton(tint: .orange, prominent: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var fastbootStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n("fb_status_slots"), systemImage: "bolt.horizontal.circle.fill")
                .font(.headline)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 20) {
                HStack {
                    Text(L10n("fb_current_slot"))
                        .foregroundColor(.secondary)
                    Text(deviceManager.selectedDevice?.currentSlot?.uppercased() ?? L10n("fb_slot_unknown_or_non_ab"))
                        .font(.headline)
                }
                
                Divider().frame(height: 16).opacity(0.4)
                
                HStack {
                    Text(L10n("fb_bl_status"))
                        .foregroundColor(.secondary)
                    if let unlocked = deviceManager.selectedDevice?.bootloaderUnlocked {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(unlocked ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(unlocked ? L10n("fb_unlocked") : L10n("fb_locked"))
                                .font(.headline)
                                .foregroundColor(unlocked ? .green : .red)
                        }
                    } else {
                        Text(L10n("fb_status_unknown"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Slot switches
                HStack(spacing: 8) {
                    Button(L10n("fb_switch_slot_a")) {
                        setActiveSlot("a")
                    }
                    .liquidGlassButton()
                    
                    Button(L10n("fb_switch_slot_b")) {
                        setActiveSlot("b")
                    }
                    .liquidGlassButton()
                }
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var partitionFlashingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(L10n("fb_partition_flash"), systemImage: "square.and.arrow.down.on.square.fill")
                .font(.headline)
            
            Text(L10n("fb_partition_flash_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            // Partition Picker
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n("fb_target_partition"))
                    .font(.caption.bold())
                
                HStack(spacing: 12) {
                    Picker("", selection: $selectedPartitionName) {
                        ForEach(PartitionCatalog.standardPartitions) { item in
                            Text("\(item.title) [\(item.name)]").tag(item.name)
                        }
                        Divider()
                        Text(L10n("fb_custom_partition")).tag("custom")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)
                    
                    if selectedPartitionName == "custom" {
                        TextField(L10n("fb_custom_partition_prompt"), text: $customPartitionName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker(L10n("fb_target_slot_picker"), selection: $targetSlot) {
                        Text(L10n("fb_slot_current_default")).tag("current")
                        Text("Slot A (_a)").tag("a")
                        Text("Slot B (_b)").tag("b")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
            }
            
            // Partition description
            if let matched = PartitionCatalog.standardPartitions.first(where: { $0.name == selectedPartitionName }) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text(matched.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // File selector
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n("fb_image_path"))
                    .font(.caption.bold())
                
                HStack(spacing: 10) {
                    TextField(L10n("fb_image_placeholder"), text: $selectedFilePath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(L10n("fb_browse")) {
                        chooseFile()
                    }
                    .liquidGlassButton()
                }
            }
            
            // Options & Action
            HStack {
                if selectedPartitionName.contains("vbmeta") {
                    Toggle(L10n("fb_disable_avb"), isOn: $disableVerity)
                        .font(.caption)
                }
                
                Spacer()
                
                Button {
                    showFlashConfirmation = true
                } label: {
                    if isFlashing {
                        ProgressView().scaleEffect(0.7)
                            .frame(width: 80)
                    } else {
                        Label(L10n("fb_start_flash"), systemImage: "bolt.fill")
                    }
                }
                .liquidGlassButton(tint: .blue, prominent: true)
                .disabled(selectedFilePath.isEmpty || effectivePartition.isEmpty || isFlashing)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var temporaryBootCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("fb_temp_boot"), systemImage: "play.circle.fill")
                .font(.headline)
            
            Text(L10n("fb_temp_boot_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 10) {
                TextField(L10n("fb_temp_boot_placeholder"), text: $temporaryBootFilePath)
                    .textFieldStyle(.roundedBorder)
                
                Button(L10n("fb_browse")) {
                    chooseTemporaryBootFile()
                }
                .liquidGlassButton()
                
                Button {
                    executeTemporaryBoot()
                } label: {
                    if isBooting {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Label(L10n("fb_temp_boot_action"), systemImage: "play.fill")
                    }
                }
                .liquidGlassButton(tint: .mint, prominent: true)
                .disabled(temporaryBootFilePath.isEmpty || isBooting)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var eraseAndFormatCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("fb_erase_format"), systemImage: "trash.circle.fill")
                .font(.headline)
            
            Text(L10n("fb_erase_format_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 12) {
                Picker("", selection: $erasePartitionName) {
                    Text(L10n("fb_part_userdata")).tag("userdata")
                    Text(L10n("fb_part_cache")).tag("cache")
                    Text(L10n("fb_part_metadata")).tag("metadata")
                    Text(L10n("fb_part_boot")).tag("boot")
                    Text(L10n("fb_part_recovery")).tag("recovery")
                }
                .pickerStyle(.menu)
                .frame(width: 240)
                
                Button(L10n("fb_erase_btn")) {
                    showEraseConfirmation = true
                }
                .liquidGlassButton(tint: .red, prominent: false)
                
                Button(L10n("fb_format_btn")) {
                    executeFormat()
                }
                .liquidGlassButton(tint: .orange, prominent: false)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var bootloaderUnlockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("fb_bl_unlock_card"), systemImage: "lock.open.trianglebadge.exclamationmark.fill")
                .font(.headline)
            
            Text(L10n("fb_bl_unlock_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Red warning banner prioritizing official manufacturer channels
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                
                Text(L10n("fb_bl_unlock_official_tip"))
                    .font(.caption.bold())
                    .foregroundColor(.red)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.red.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            
            Divider().opacity(0.4)
            
            HStack(spacing: 14) {
                Picker("", selection: $selectedUnlockType) {
                    ForEach(BootloaderUnlockType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 300)
                
                Button {
                    showUnlockConfirmation = true
                } label: {
                    Label(L10n("fb_bl_unlock_btn"), systemImage: "lock.open.fill")
                }
                .liquidGlassButton(tint: .red, prominent: true)
                
                Divider().frame(height: 20).opacity(0.4)
                
                Button {
                    showLockConfirmation = true
                } label: {
                    Label(L10n("fb_bl_lock_btn"), systemImage: "lock.fill")
                }
                .liquidGlassButton(tint: .blue, prominent: false)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var variablesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("fb_vars_card"), systemImage: "list.bullet.rectangle.fill")
                .font(.headline)
            
            Divider().opacity(0.4)
            
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L10n("fb_vars_search"), text: $varSearchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                
                Button {
                    loadFastbootVariables()
                } label: {
                    if isLoadingVars {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Label(L10n("fb_vars_load"), systemImage: "arrow.clockwise")
                    }
                }
                .liquidGlassButton(tint: .blue)
                .disabled(isLoadingVars)
            }
            
            // Variables Table
            let filtered = fastbootVariables.filter {
                varSearchText.isEmpty ||
                $0.key.localizedCaseInsensitiveContains(varSearchText) ||
                $0.value.localizedCaseInsensitiveContains(varSearchText)
            }
            
            if filtered.isEmpty {
                Text(fastbootVariables.isEmpty ? L10n("fb_vars_empty_hint") : L10n("fb_vars_no_match"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                Table(filtered) {
                    TableColumn(L10n("fb_var_name"), value: \.key)
                        .width(min: 150, ideal: 220)
                    TableColumn(L10n("fb_var_val"), value: \.value)
                        .width(min: 200, ideal: 350)
                }
                .frame(height: 200)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Actions
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "img") ?? .data, UTType(filenameExtension: "bin") ?? .data, .data]
        panel.prompt = L10n("panel_choose_image")
        
        if panel.runModal() == .OK, let url = panel.url {
            selectedFilePath = url.path
        }
    }
    
    private func chooseTemporaryBootFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "img") ?? .data, .data]
        panel.prompt = L10n("panel_choose_boot_image")
        
        if panel.runModal() == .OK, let url = panel.url {
            temporaryBootFilePath = url.path
        }
    }
    
    private func executeFlash() {
        guard let dev = deviceManager.selectedDevice else { return }
        isFlashing = true
        let slot = targetSlot == "current" ? nil : targetSlot
        let partition = effectivePartition
        let filePath = selectedFilePath
        let verity = disableVerity
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "開始刷寫分區 [\(partition)]，檔案: \(filePath)...")
                try await FastbootService.shared.flashPartition(
                    serial: dev.serial,
                    partition: partition,
                    filePath: filePath,
                    disableVerity: verity,
                    slotSuffix: slot
                )
                deviceManager.appendLog(level: .success, text: "分區 [\(partition)] 刷寫成功！")
            } catch {
                deviceManager.appendLog(level: .error, text: "刷寫失敗: \(error.localizedDescription)")
            }
            isFlashing = false
        }
    }
    
    private func executeTemporaryBoot() {
        guard let dev = deviceManager.selectedDevice else { return }
        isBooting = true
        let path = temporaryBootFilePath
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在臨時引導開機映像: \(path)...")
                try await FastbootService.shared.bootTemporary(serial: dev.serial, filePath: path)
                deviceManager.appendLog(level: .success, text: "臨時引導指令已發送至設備！")
            } catch {
                deviceManager.appendLog(level: .error, text: "臨時引導失敗: \(error.localizedDescription)")
            }
            isBooting = false
        }
    }
    
    private func executeErase() {
        guard let dev = deviceManager.selectedDevice else { return }
        let part = erasePartitionName
        
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在抹除分區 [\(part)]...")
                try await FastbootService.shared.erasePartition(serial: dev.serial, partition: part)
                deviceManager.appendLog(level: .success, text: "分區 [\(part)] 抹除完成！")
            } catch {
                deviceManager.appendLog(level: .error, text: "抹除失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeFormat() {
        guard let dev = deviceManager.selectedDevice else { return }
        let part = erasePartitionName
        
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在格式化分區 [\(part)]...")
                try await FastbootService.shared.formatPartition(serial: dev.serial, partition: part)
                deviceManager.appendLog(level: .success, text: "分區 [\(part)] 格式化完成！")
            } catch {
                deviceManager.appendLog(level: .error, text: "格式化失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func setActiveSlot(_ slot: String) {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在將槽位切換為 Slot \(slot.uppercased())...")
                try await FastbootService.shared.setActiveSlot(serial: dev.serial, slot: slot)
                deviceManager.appendLog(level: .success, text: "已切換至 Slot \(slot.uppercased())！")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "切換槽位失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeUnlock() {
        guard let dev = deviceManager.selectedDevice else { return }
        let type = selectedUnlockType
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在發送解鎖指令 (\(type.rawValue))...")
                try await FastbootService.shared.unlockBootloader(serial: dev.serial, type: type)
                deviceManager.appendLog(level: .success, text: "解鎖指令已發送！請在手機螢幕上按音量鍵確認解鎖。")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "解鎖失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeLock() {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .warning, text: "正在發送回鎖指令...")
                try await FastbootService.shared.lockBootloader(serial: dev.serial)
                deviceManager.appendLog(level: .success, text: "回鎖指令已發送！請在手機螢幕上按音量鍵確認上鎖。")
                deviceManager.refreshDevices()
            } catch {
                deviceManager.appendLog(level: .error, text: "回鎖失敗: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFastbootVariables() {
        guard let dev = deviceManager.selectedDevice else { return }
        isLoadingVars = true
        Task {
            let vars = await FastbootService.shared.getAllVariables(serial: dev.serial)
            fastbootVariables = vars
            isLoadingVars = false
        }
    }
    
    private func rebootToBootloader() {
        guard let dev = deviceManager.selectedDevice else { return }
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在重啟設備進入 Bootloader...")
                try await ADBService.shared.reboot(serial: dev.serial, target: .bootloader)
                deviceManager.appendLog(level: .success, text: "已發送進入 Bootloader 指令")
            } catch {
                deviceManager.appendLog(level: .error, text: "重啟失敗: \(error.localizedDescription)")
            }
        }
    }
}
