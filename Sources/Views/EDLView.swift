import SwiftUI
import UniformTypeIdentifiers

public struct EDLView: View {
    @ObservedObject var edlService = EDLService.shared
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var toolConfig = ToolConfig.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var loaderLibrary = EDLLoaderLibrary.shared
    
    // Sub-view tab selection: 0: QFIL, 1: Partition Ops, 2: GPT Explorer, 3: Guide & Env
    @State private var selectedTab: Int = 0
    
    // Global parameters
    @State private var firehoseLoaderPath: String = ""
    @State private var selectedMemoryType: String = "ufs" // "ufs", "emmc", "auto"
    @State private var selectedLun: Int = 0
    
    // Built-in 9008 Loader Library Selection
    @State private var selectedBrand: String = "小米"
    @State private var selectedModelId: String = ""
    @State private var selectedProgrammerPath: String = ""
    @State private var loaderSearchText: String = ""
    @State private var isSendingLoader: Bool = false
    @State private var showLoaderNotice: Bool = false
    
    // Tab 1: QFIL
    @State private var rawprogramPath: String = ""
    @State private var patchPath: String = ""
    @State private var imageDirPath: String = ""
    @State private var showQFILConfirm: Bool = false
    
    // Tab 2: Partition Ops
    @State private var selectedPartitionName: String = "boot"
    @State private var customPartitionName: String = ""
    @State private var singleImagePath: String = ""
    @State private var dumpOutputPath: String = ""
    @State private var showFlashConfirm: Bool = false
    @State private var showEraseConfirm: Bool = false
    
    // Tab 3: GPT Explorer
    @State private var gptFilterText: String = ""
    @State private var isLoadingGPT: Bool = false
    
    // Tab 4: Environment & Guide
    @State private var isInstallingDeps: Bool = false
    @State private var installLogs: String = ""
    @State private var showInstallSheet: Bool = false
    
    public init() {}
    
    var effectivePartition: String {
        if selectedPartitionName == "custom" {
            return customPartitionName.trimmingCharacters(in: .whitespaces)
        }
        return selectedPartitionName
    }
    
    var isDeviceIn9008: Bool {
        return edlService.connectedDevice != nil || deviceManager.selectedDevice?.mode == .edl
    }
    
    var currentBrandGroup: EDLBrandGroup? {
        loaderLibrary.brandGroups.first { $0.brandName == selectedBrand }
    }
    
    var filteredModels: [EDLTargetModel] {
        guard let group = currentBrandGroup else { return [] }
        let query = loaderSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        if query.isEmpty {
            return group.models
        }
        return group.models.filter { model in
            model.displayName.lowercased().contains(query) ||
            model.rawFolderName.lowercased().contains(query) ||
            model.loaders.contains { $0.fileName.lowercased().contains(query) }
        }
    }
    
    var currentSelectedModel: EDLTargetModel? {
        currentBrandGroup?.models.first { $0.id == selectedModelId }
            ?? filteredModels.first
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header: Qualcomm 9008 Status & Quick Reset
                statusHeaderCard
                
                // Firehose Loader & Sahara Handshake Card
                firehoseLoaderCard
                
                // Liquid Glass Segmented Navigation Tab
                tabPickerBar
                
                // Tab Content
                switch selectedTab {
                case 0:
                    qfilFlashingSection
                case 1:
                    partitionOperationsSection
                case 2:
                    gptExplorerSection
                case 3:
                    guideAndEnvironmentSection
                default:
                    EmptyView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 64)
            .padding(.bottom, 220)
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            Task {
                _ = await edlService.checkEnvironment()
                _ = await edlService.detectConnected9008Device()
                loaderLibrary.reloadLibrary()
                
                // Auto match brand if device is available
                if let dev = deviceManager.selectedDevice {
                    let brand = dev.brand.lowercased()
                    if brand.contains("xiaomi") || brand.contains("redmi") {
                        selectedBrand = "小米"
                    } else if brand.contains("oppo") || brand.contains("oneplus") || brand.contains("realme") {
                        selectedBrand = "欧加"
                    } else if brand.contains("meizu") {
                        selectedBrand = "魅族"
                    } else if brand.contains("blackshark") {
                        selectedBrand = "黑鲨"
                    } else if brand.contains("nubia") || brand.contains("zte") || brand.contains("redmagic") {
                        selectedBrand = "努比亚"
                    } else if brand.contains("lenovo") || brand.contains("motorola") || brand.contains("moto") {
                        selectedBrand = "联想"
                    } else if brand.contains("asus") || brand.contains("rog") {
                        selectedBrand = "华硕"
                    } else if brand.contains("lg") {
                        selectedBrand = "LG"
                    }
                }
                
                // Auto select first model in brand if path is empty
                if firehoseLoaderPath.isEmpty, let group = currentBrandGroup, let firstModel = group.models.first {
                    selectedModelId = firstModel.id
                    selectedProgrammerPath = firstModel.primaryLoader?.fullPath ?? ""
                    firehoseLoaderPath = selectedProgrammerPath
                    if selectedProgrammerPath.contains("_emmc") {
                        selectedMemoryType = "emmc"
                    } else if selectedProgrammerPath.contains("_ufs") {
                        selectedMemoryType = "ufs"
                    }
                }
            }
        }
        .confirmationDialog(
            L10n("edl_confirm_qfil_title"),
            isPresented: $showQFILConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n("edl_start_flash"), role: .destructive) {
                executeQFILFlash()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(L10n("edl_confirm_qfil_msg"))
        }
        .confirmationDialog(
            String(format: L10n("edl_confirm_flash_part_title"), effectivePartition),
            isPresented: $showFlashConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n("edl_confirm_write"), role: .destructive) {
                executeSinglePartitionFlash()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(String(format: L10n("edl_confirm_flash_part_msg"), effectivePartition, singleImagePath))
        }
        .confirmationDialog(
            String(format: L10n("edl_confirm_erase_part_title"), effectivePartition),
            isPresented: $showEraseConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n("edl_confirm_erase"), role: .destructive) {
                executeSinglePartitionErase()
            }
            Button(L10n("common_cancel"), role: .cancel) {}
        } message: {
            Text(String(format: L10n("edl_confirm_erase_part_msg"), effectivePartition))
        }
    }
    
    // MARK: - Header Status Card
    private var statusHeaderCard: some View {
        HStack(spacing: 16) {
            // Glowing Chipset Avatar (54x54)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isDeviceIn9008 ? Color.red : Color.secondary).opacity(0.32),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 32
                        )
                    )
                    .frame(width: 54, height: 54)
                
                Circle()
                    .fill((isDeviceIn9008 ? Color.red : Color.secondary).opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "cpu.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isDeviceIn9008 ? .red : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(L10n("edl_title"))
                        .font(.title3.bold())
                    
                    // Unified Status Capsule Badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(isDeviceIn9008 ? Color.red : Color.secondary)
                            .frame(width: 7, height: 7)
                        Text(isDeviceIn9008 ? L10n("edl_device_connected") : L10n("edl_no_device"))
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3.5)
                    .background((isDeviceIn9008 ? Color.red : Color.secondary).opacity(0.12))
                    .foregroundColor(isDeviceIn9008 ? .red : .secondary)
                    .clipShape(Capsule())
                }
                
                Group {
                    if let dev = edlService.connectedDevice {
                        Text("\(dev.name) • VID: \(dev.vendorId) PID: \(dev.productId)\(dev.serialPort != nil ? " • " + dev.serialPort! : "")")
                    } else {
                        Text(L10n("edl_header_guide_tip"))
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            }
            
            Spacer()
            
            // Trailing Action Button
            if isDeviceIn9008 {
                HStack(spacing: 8) {
                    Button {
                        executeRebootDevice()
                    } label: {
                        Label(L10n("edl_btn_reset_device"), systemImage: "arrow.triangle.2.circlepath")
                    }
                    .liquidGlassButton(tint: .red, prominent: true)
                    .disabled(edlService.isFlashing)
                    
                    Button {
                        Task {
                            _ = await edlService.detectConnected9008Device()
                            DeviceManager.shared.refreshDevices()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help(L10n("common_refresh"))
                    .disabled(edlService.isFlashing)
                }
            } else {
                Button {
                    Task {
                        _ = await edlService.detectConnected9008Device()
                        DeviceManager.shared.refreshDevices()
                    }
                } label: {
                    Label(L10n("edl_btn_refresh"), systemImage: "arrow.clockwise")
                }
                .liquidGlassButton(tint: .red, prominent: true)
                .disabled(edlService.isFlashing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Firehose Loader & Sahara Handshake Card
    private var firehoseLoaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Header with Count Badge and Notice Button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(L10n("edl_loader_file"))
                                .font(.headline)
                            
                            Text(L10n("edl_loader_count_badge"))
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        Text(L10n("edl_loader_desc"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showLoaderNotice.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showLoaderNotice ? "chevron.up.circle.fill" : "info.circle")
                        Text(L10n("edl_loader_notice_title"))
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
            }
            
            // 2. Expandable Notice Banner
            if showLoaderNotice {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(L10n("edl_loader_notice_btn"))
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    Text(loaderLibrary.globalNotice)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let modelNotice = currentSelectedModel?.noticeText, !modelNotice.isEmpty {
                        Divider().opacity(0.3)
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text(String(format: L10n("edl_model_notice_prefix"), modelNotice))
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
            Divider().opacity(0.3)
            
            // 3. Brand Chips Horizontal Scroll
            VStack(alignment: .leading, spacing: 6) {
                Text("\(L10n("edl_loader_brand")):")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(loaderLibrary.brandGroups) { group in
                            Button {
                                selectedBrand = group.brandName
                                if let firstModel = group.models.first {
                                    selectedModelId = firstModel.id
                                    selectedProgrammerPath = firstModel.primaryLoader?.fullPath ?? ""
                                    firehoseLoaderPath = selectedProgrammerPath
                                    if selectedProgrammerPath.contains("_emmc") {
                                        selectedMemoryType = "emmc"
                                    } else if selectedProgrammerPath.contains("_ufs") {
                                        selectedMemoryType = "ufs"
                                    }
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(group.localizedDisplayName)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("\(group.models.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background((selectedBrand == group.brandName ? Color.white : Color.primary).opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedBrand == group.brandName
                                        ? Color.orange.opacity(0.85)
                                        : Color.primary.opacity(0.07)
                                )
                                .foregroundColor(selectedBrand == group.brandName ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // 4. Model Selection & Search Row
            VStack(alignment: .leading, spacing: 6) {
                Text("\(L10n("edl_loader_chip_or_model")):")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    // Search filter
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        TextField(L10n("edl_filter_loaders"), text: $loaderSearchText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                        if !loaderSearchText.isEmpty {
                            Button {
                                loaderSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 240)
                    
                    // Model Dropdown
                    Picker("", selection: $selectedModelId) {
                        ForEach(filteredModels) { model in
                            Text(model.localizedDisplayName).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedModelId) { newId in
                        if let model = currentBrandGroup?.models.first(where: { $0.id == newId }) {
                            selectedProgrammerPath = model.primaryLoader?.fullPath ?? ""
                            firehoseLoaderPath = selectedProgrammerPath
                            if selectedProgrammerPath.contains("_emmc") {
                                selectedMemoryType = "emmc"
                            } else if selectedProgrammerPath.contains("_ufs") {
                                selectedMemoryType = "ufs"
                            }
                        }
                    }
                    
                    // Programmer binary dropdown (if current model has > 1 loaders)
                    if let model = currentSelectedModel, model.loaders.count > 1 {
                        Picker("", selection: $selectedProgrammerPath) {
                            ForEach(model.loaders) { loader in
                                Text("\(loader.fileName) (\(loader.fileSizeString))").tag(loader.fullPath)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 240)
                        .onChange(of: selectedProgrammerPath) { newPath in
                            firehoseLoaderPath = newPath
                        }
                    }
                }
            }
            
            // 5. Badges & Tag Info
            if let model = currentSelectedModel {
                HStack(spacing: 8) {
                    if model.hasDigest || model.hasSign {
                        let sigFiles = "\(model.hasDigest ? "Digest.elf " : "")\(model.hasSign ? "Sign.bin" : "")".trimmingCharacters(in: .whitespaces)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text(String(format: L10n("edl_signature_equipped"), sigFiles))
                                .font(.caption2.bold())
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    if let loader = model.loaders.first(where: { $0.fullPath == firehoseLoaderPath }) ?? model.primaryLoader {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text("\(loader.fileName) • \(loader.fileSizeString)")
                                .font(.caption2.monospaced())
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
            
            Divider().opacity(0.3)
            
            // 6. Manual File Path Input
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n("edl_loader_current_path"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    TextField(L10n("edl_loader_placeholder"), text: $firehoseLoaderPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    
                    Button(L10n("fb_browse")) {
                        chooseFirehoseLoader()
                    }
                    .liquidGlassButton()
                }
            }
            
            Divider().opacity(0.3)
            
            // 7. Storage Parameters & Action Button Row (Generous spacing, non-overlapping)
            HStack(alignment: .center, spacing: 20) {
                // Storage Type (Menu style, eliminates cramping)
                HStack(spacing: 8) {
                    Text("\(L10n("edl_memory_type")):")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedMemoryType) {
                        Text(L10n("edl_mem_ufs")).tag("ufs")
                        Text(L10n("edl_mem_emmc")).tag("emmc")
                        Text(L10n("edl_mem_auto")).tag("auto")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 175)
                }
                
                // LUN Selection (only shown for UFS)
                if selectedMemoryType == "ufs" {
                    HStack(spacing: 8) {
                        Text(L10n("edl_lun_partition"))
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedLun) {
                            Text(L10n("edl_lun_0")).tag(0)
                            Text(L10n("edl_lun_1")).tag(1)
                            Text(L10n("edl_lun_2")).tag(2)
                            Text(L10n("edl_lun_3")).tag(3)
                            Text(L10n("edl_lun_4")).tag(4)
                            Text(L10n("edl_lun_5")).tag(5)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 165)
                    }
                }
                
                Spacer()
                
                // Prominent SEND LOADER Action Button
                Button {
                    executeSendLoader()
                } label: {
                    HStack(spacing: 6) {
                        if isSendingLoader {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(L10n("edl_sending_loader"))
                        } else {
                            Image(systemName: "bolt.badge.automatic.fill")
                            Text(L10n("edl_btn_send_loader"))
                        }
                    }
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                }
                .liquidGlassButton(tint: .orange, prominent: true)
                .disabled(isSendingLoader || edlService.isFlashing || firehoseLoaderPath.isEmpty)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 18)
    }
    
    // MARK: - Tab Picker Bar
    private var tabPickerBar: some View {
        Picker("", selection: $selectedTab) {
            Label(L10n("edl_tab_qfil"), systemImage: "sparkles.rectangle.stack.fill").tag(0)
            Label(L10n("edl_tab_partition"), systemImage: "square.split.2x2.fill").tag(1)
            Label(L10n("edl_tab_gpt"), systemImage: "tablecells.fill").tag(2)
            Label(L10n("edl_tab_guide"), systemImage: "wrench.and.screwdriver.fill").tag(3)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 620)
    }
    
    // MARK: - Tab 1: QFIL Full Flashing
    private var qfilFlashingSection: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(L10n("edl_qfil_title"), systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    Spacer()
                    Text("Qualcomm Firehose QFIL Emulation")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(L10n("edl_qfil_intro"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().opacity(0.4)
                
                // 1. RawProgram XML
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("edl_rawprogram_xml"))
                        .font(.caption.bold())
                    
                    HStack(spacing: 10) {
                        TextField("rawprogram0.xml / rawprogram_unsparse.xml...", text: $rawprogramPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseRawprogramFile()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // 2. Patch XML
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("edl_patch_xml"))
                        .font(.caption.bold())
                    
                    HStack(spacing: 10) {
                        TextField("patch0.xml...", text: $patchPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            choosePatchFile()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // 3. Firmware Image Folder
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n("edl_images_folder"))
                        .font(.caption.bold())
                    
                    HStack(spacing: 10) {
                        TextField(L10n("edl_images_folder_placeholder"), text: $imageDirPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseImagesFolder()
                        }
                        .liquidGlassButton()
                    }
                }
                
                // Start Flashing Button
                HStack {
                    Spacer()
                    
                    Button {
                        showQFILConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            if edlService.isFlashing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text(L10n("edl_btn_start_qfil"))
                        }
                        .padding(.horizontal, 16)
                    }
                    .liquidGlassButton(tint: .red, prominent: true)
                    .disabled(edlService.isFlashing || rawprogramPath.isEmpty || imageDirPath.isEmpty)
                }
                .padding(.top, 8)
            }
            .liquidGlassCard(cornerRadius: 16, padding: 18)
        }
    }
    
    // MARK: - Tab 2: Partition Operations
    private var partitionOperationsSection: some View {
        VStack(spacing: 18) {
            // Partition Selector & Presets
            VStack(alignment: .leading, spacing: 14) {
                Label(L10n("edl_part_ops_title"), systemImage: "square.split.2x2.fill")
                    .font(.headline)
                
                Text(L10n("edl_part_ops_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let presets = ["boot", "init_boot", "recovery", "vbmeta", "vendor_boot", "modem", "abl", "xbl", "super", "persist", "dtbo", "custom"]
                        ForEach(presets, id: \.self) { part in
                            Button {
                                selectedPartitionName = part
                            } label: {
                                Text(part)
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        selectedPartitionName == part
                                            ? Color.red.opacity(0.85)
                                            : Color.primary.opacity(0.08)
                                    )
                                    .foregroundColor(selectedPartitionName == part ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if selectedPartitionName == "custom" {
                    HStack(spacing: 10) {
                        Text("\(L10n("fb_custom_partition")):")
                            .font(.caption.bold())
                        TextField(L10n("fb_custom_partition_hint"), text: $customPartitionName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                Divider().opacity(0.4)
                
                // Action 1: Write Partition Image
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: L10n("edl_action_write_title"), effectivePartition))
                        .font(.caption.bold())
                    
                    HStack(spacing: 10) {
                        TextField(L10n("edl_image_file_path"), text: $singleImagePath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("fb_browse")) {
                            chooseSingleImageFile()
                        }
                        .liquidGlassButton()
                        
                        Button {
                            showFlashConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.to.line")
                                Text(L10n("edl_btn_write"))
                            }
                        }
                        .liquidGlassButton(tint: .red, prominent: true)
                        .disabled(edlService.isFlashing || singleImagePath.isEmpty || effectivePartition.isEmpty)
                    }
                }
                
                Divider().opacity(0.4)
                
                // Action 2: Dump Partition to Local File
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: L10n("edl_action_dump_title"), effectivePartition))
                        .font(.caption.bold())
                    
                    HStack(spacing: 10) {
                        TextField(L10n("edl_dump_output_path"), text: $dumpOutputPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(L10n("edl_btn_choose_save")) {
                            chooseDumpSaveLocation()
                        }
                        .liquidGlassButton()
                        
                        Button {
                            executeSinglePartitionDump()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.to.line")
                                Text(L10n("edl_btn_dump"))
                            }
                        }
                        .liquidGlassButton(tint: .blue)
                        .disabled(edlService.isFlashing || dumpOutputPath.isEmpty || effectivePartition.isEmpty)
                    }
                }
                
                Divider().opacity(0.4)
                
                // Action 3: Erase Partition
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: L10n("edl_action_erase_title"), effectivePartition))
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    
                    HStack {
                        Text(L10n("edl_erase_warning"))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button {
                            showEraseConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                Text(L10n("edl_btn_erase"))
                            }
                        }
                        .liquidGlassButton(tint: .red)
                        .disabled(edlService.isFlashing || effectivePartition.isEmpty)
                    }
                }
            }
            .liquidGlassCard(cornerRadius: 16, padding: 18)
        }
    }
    
    // MARK: - Tab 3: GPT Explorer
    private var gptExplorerSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(L10n("edl_gpt_title"), systemImage: "tablecells.fill")
                        .font(.headline)
                    Spacer()
                    
                    Button {
                        executePrintGPT()
                    } label: {
                        HStack(spacing: 4) {
                            if isLoadingGPT {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(L10n("edl_btn_read_gpt"))
                        }
                    }
                    .liquidGlassButton(tint: .indigo, prominent: true)
                    .disabled(isLoadingGPT || edlService.isFlashing)
                }
                
                Text(L10n("edl_gpt_intro"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Search filter
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L10n("common_search"), text: $gptFilterText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                // Partition List Table
                if edlService.parsedPartitions.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(L10n("edl_gpt_empty_tip"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    let filtered = edlService.parsedPartitions.filter {
                        gptFilterText.isEmpty || $0.name.localizedCaseInsensitiveContains(gptFilterText)
                    }
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text(L10n("edl_table_partition"))
                                .font(.caption.bold())
                                .frame(width: 140, alignment: .leading)
                            Text(L10n("edl_table_start"))
                                .font(.caption.bold())
                                .frame(width: 100, alignment: .leading)
                            Text(L10n("edl_table_end"))
                                .font(.caption.bold())
                                .frame(width: 100, alignment: .leading)
                            Text(L10n("edl_table_size"))
                                .font(.caption.bold())
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Text(L10n("edl_table_action"))
                                .font(.caption.bold())
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        
                        Divider().opacity(0.4)
                        
                        ForEach(filtered) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .frame(width: 140, alignment: .leading)
                                Text(item.startLBA)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 100, alignment: .leading)
                                Text(item.endLBA)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 100, alignment: .leading)
                                Text(item.sizeString)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .frame(width: 100, alignment: .leading)
                                
                                Spacer()
                                
                                Button(L10n("edl_btn_select_part")) {
                                    selectedPartitionName = "custom"
                                    customPartitionName = item.name
                                    selectedTab = 1
                                }
                                .font(.caption2)
                                .buttonStyle(.plain)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.primary.opacity(0.02))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .liquidGlassCard(cornerRadius: 16, padding: 18)
        }
    }
    
    // MARK: - Tab 4: Guide & Environment
    private var guideAndEnvironmentSection: some View {
        VStack(spacing: 18) {
            // Environment Diagnostics Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(L10n("edl_env_title"), systemImage: "stethoscope")
                        .font(.headline)
                    Spacer()
                    
                    Button {
                        Task {
                            _ = await edlService.checkEnvironment()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text(L10n("settings_recheck"))
                        }
                    }
                    .liquidGlassButton()
                }
                
                Text(L10n("edl_env_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().opacity(0.4)
                
                // Status items
                if let env = edlService.environmentStatus {
                    envStatusRow(
                        title: L10n("edl_env_python3_title"),
                        detail: env.isPython3Available ? "\(env.python3Path) (\(env.localizedPythonVersion))" : L10n("edl_env_not_found"),
                        isReady: env.isPython3Available
                    )
                    envStatusRow(
                        title: L10n("edl_env_libusb_title"),
                        detail: env.isLibusbAvailable ? L10n("edl_env_libusb_ready") : L10n("edl_env_libusb_missing"),
                        isReady: env.isLibusbAvailable
                    )
                    envStatusRow(
                        title: L10n("edl_env_core_title"),
                        detail: env.isEdlAvailable ? "\(env.edlPath) (\(env.localizedEdlVersion))" : L10n("edl_env_core_missing"),
                        isReady: env.isEdlAvailable
                    )
                }
                
                // Action Buttons: One-click install, Browse local edl, Open folder
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            executeInstallDependencies()
                        } label: {
                            HStack(spacing: 6) {
                                if isInstallingDeps {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(L10n("edl_btn_install_deps"))
                            }
                        }
                        .liquidGlassButton(tint: .blue, prominent: true)
                        .disabled(isInstallingDeps)
                        
                        Button {
                            chooseLocalEdlPath()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "folder.badge.gearshape")
                                Text(L10n("edl_btn_browse_path"))
                            }
                        }
                        .liquidGlassButton()
                        
                        Button {
                            openAppSupportDirectory()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.right.square")
                                Text(L10n("edl_btn_open_folder"))
                            }
                        }
                        .liquidGlassButton()
                    }
                    
                    Text(L10n("edl_install_deps_tip"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .liquidGlassCard(cornerRadius: 16, padding: 18)
            
            // 9008 Rescue Knowledge Guide Card
            VStack(alignment: .leading, spacing: 14) {
                Label(L10n("edl_guide_title"), systemImage: "book.fill")
                    .font(.headline)
                
                Text(L10n("edl_guide_intro"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().opacity(0.4)
                
                guideSectionItem(
                    number: "1",
                    title: L10n("edl_guide_step1_title"),
                    content: L10n("edl_guide_step1_desc")
                )
                
                guideSectionItem(
                    number: "2",
                    title: L10n("edl_guide_step2_title"),
                    content: L10n("edl_guide_step2_desc")
                )
                
                guideSectionItem(
                    number: "3",
                    title: L10n("edl_guide_step3_title"),
                    content: L10n("edl_guide_step3_desc")
                )
                
                guideSectionItem(
                    number: "4",
                    title: L10n("edl_guide_step4_title"),
                    content: L10n("edl_guide_step4_desc")
                )
                
                guideSectionItem(
                    number: "5",
                    title: L10n("edl_guide_step5_title"),
                    content: L10n("edl_guide_step5_desc")
                )
            }
            .liquidGlassCard(cornerRadius: 16, padding: 18)
        }
    }
    
    private func envStatusRow(title: String, detail: String, isReady: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isReady ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isReady ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
    
    private func guideSectionItem(number: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(.system(size: 11, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
    
    // MARK: - Actions
    
    private func executeSendLoader() {
        guard !firehoseLoaderPath.isEmpty else {
            deviceManager.appendLog(level: .warning, text: "⚠️ 请先选择或指定 Firehose 引导文件。")
            return
        }
        
        isSendingLoader = true
        Task {
            deviceManager.appendLog(level: .info, text: "==> [Sahara] 准备向设备发送 Firehose 引导: \(firehoseLoaderPath)")
            do {
                let success = try await edlService.sendLoader(
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType,
                    onOutput: { line in
                        Task { @MainActor in
                            deviceManager.appendLog(level: .info, text: line)
                        }
                    }
                )
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 Firehose 引导发送成功！设备已建立 Firehose 握手并处于就绪状态。")
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ Firehose 引导发送失败。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 发送引导异常: \(error.localizedDescription)")
                deviceManager.appendLog(level: .warning, text: "💡 避坑提示：\n1. 若通讯握手失败，请尝试更换另一个引导文件（如 DevprgProgrammer2 等）；\n2. 若此前已发送过引导，必须先长按电源键重启手机重新进入 9008 端口释放连接；\n3. 欧加等带签名机型若失败，可尝试在目录排除 Digest.elf 与 Sign.bin 后重试。")
            }
            isSendingLoader = false
        }
    }
    
    private func chooseFirehoseLoader() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n("panel_choose_firehose_loader")
        if panel.runModal() == .OK, let url = panel.url {
            firehoseLoaderPath = url.path
        }
    }
    
    private func chooseRawprogramFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n("panel_choose_rawprogram")
        if panel.runModal() == .OK, let url = panel.url {
            rawprogramPath = url.path
            // Auto match patch0.xml and image dir in same folder
            let folder = url.deletingLastPathComponent()
            let folderPath = folder.path
            imageDirPath = folderPath
            
            let patchCandidate = folder.appendingPathComponent("patch0.xml").path
            if FileManager.default.fileExists(atPath: patchCandidate) {
                patchPath = patchCandidate
            }
            
            // Auto match firehose loader if present
            if firehoseLoaderPath.isEmpty {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: folderPath) {
                    for f in contents {
                        if (f.hasPrefix("prog_firehose") || f.hasPrefix("prog_emmc") || f.hasPrefix("prog_ufs")) && (f.hasSuffix(".elf") || f.hasSuffix(".mbn") || f.hasSuffix(".bin")) {
                            firehoseLoaderPath = folder.appendingPathComponent(f).path
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func choosePatchFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n("panel_choose_patch")
        if panel.runModal() == .OK, let url = panel.url {
            patchPath = url.path
        }
    }
    
    private func chooseImagesFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = L10n("panel_choose_images_folder")
        if panel.runModal() == .OK, let url = panel.url {
            imageDirPath = url.path
        }
    }
    
    private func chooseSingleImageFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = String(format: L10n("panel_choose_partition_image"), effectivePartition)
        if panel.runModal() == .OK, let url = panel.url {
            singleImagePath = url.path
        }
    }
    
    private func chooseDumpSaveLocation() {
        let panel = NSSavePanel()
        panel.title = String(format: L10n("panel_choose_dump_location"), effectivePartition)
        panel.nameFieldStringValue = "\(effectivePartition).img"
        if panel.runModal() == .OK, let url = panel.url {
            dumpOutputPath = url.path
        }
    }
    
    private func executeQFILFlash() {
        Task {
            deviceManager.appendLog(level: .info, text: "==> 开始执行 QFIL 全盘线刷...")
            do {
                let success = try await edlService.flashQFIL(
                    rawprogramXml: rawprogramPath,
                    patchXml: patchPath,
                    imageDir: imageDirPath,
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType
                )
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 QFIL 全盘线刷成功！")
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ QFIL 全盘线刷失败，请查看控制台日志。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ QFIL 错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeSinglePartitionFlash() {
        Task {
            deviceManager.appendLog(level: .info, text: "==> 开始向 \(effectivePartition) 写入镜像: \(singleImagePath)")
            do {
                let success = try await edlService.flashPartition(
                    partition: effectivePartition,
                    imagePath: singleImagePath,
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType,
                    lun: selectedLun
                )
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 \(effectivePartition) 分区写入成功！")
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ \(effectivePartition) 分区写入失败。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 写入错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeSinglePartitionDump() {
        Task {
            deviceManager.appendLog(level: .info, text: "==> 开始提取 \(effectivePartition) 分区备份...")
            do {
                let success = try await edlService.dumpPartition(
                    partition: effectivePartition,
                    outputPath: dumpOutputPath,
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType,
                    lun: selectedLun
                )
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 \(effectivePartition) 分区提取成功，保存至: \(dumpOutputPath)")
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ \(effectivePartition) 分区提取失败。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 提取错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeSinglePartitionErase() {
        Task {
            deviceManager.appendLog(level: .warning, text: "==> 正在擦除 \(effectivePartition) 分区...")
            do {
                let success = try await edlService.erasePartition(
                    partition: effectivePartition,
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType,
                    lun: selectedLun
                )
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 \(effectivePartition) 分区擦除成功！")
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ \(effectivePartition) 分区擦除失败。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 擦除错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func executePrintGPT() {
        isLoadingGPT = true
        Task {
            deviceManager.appendLog(level: .info, text: "==> 正在读取设备 GPT 分区表...")
            do {
                let parts = try await edlService.printGPT(
                    loader: firehoseLoaderPath,
                    memoryType: selectedMemoryType,
                    lun: selectedLun
                )
                deviceManager.appendLog(level: .success, text: "🎉 GPT 分区表解析成功，共获取到 \(parts.count) 个物理分区。")
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 读取 GPT 分区表失败: \(error.localizedDescription)")
            }
            isLoadingGPT = false
        }
    }
    
    private func executeRebootDevice() {
        Task {
            deviceManager.appendLog(level: .info, text: "==> 正在发送 9008 复位命令，重启设备...")
            do {
                let success = try await edlService.rebootDevice(loader: firehoseLoaderPath)
                if success {
                    deviceManager.appendLog(level: .success, text: "🎉 重启命令发送成功！设备正在退出 9008 模式...")
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    deviceManager.refreshDevices()
                } else {
                    deviceManager.appendLog(level: .error, text: "❌ 复位重启命令执行失败，请检查连接或引导文件。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 重启错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeInstallDependencies() {
        isInstallingDeps = true
        Task {
            deviceManager.appendLog(level: .info, text: "==> 正在配置 Qualcomm 9008 / EDL 依赖套件...")
            do {
                let ok = try await edlService.installDependenciesViaBrew { line in
                    Task { @MainActor in
                        DeviceManager.shared.appendLog(level: .info, text: line)
                    }
                }
                if ok {
                    deviceManager.appendLog(level: .success, text: "🎉 EDL 运行环境配置完毕！")
                } else {
                    deviceManager.appendLog(level: .warning, text: "⚠️ 自动安装未全部成功，请尝试在终端手动执行。")
                }
            } catch {
                deviceManager.appendLog(level: .error, text: "❌ 配置失败: \(error.localizedDescription)")
            }
            isInstallingDeps = false
        }
    }
    
    private func chooseLocalEdlPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = L10n("edl_choose_edl_prompt")
        panel.prompt = L10n("common_select")
        
        if panel.runModal() == .OK, let url = panel.url {
            ToolConfig.shared.edlPath = url.path
            Task {
                _ = await edlService.checkEnvironment()
                ToolConfig.shared.checkTools()
            }
        }
    }
    
    private func openAppSupportDirectory() {
        let path = EDLService.appSupportDirectory
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
}
