import SwiftUI
import UniformTypeIdentifiers

public struct FileManagerView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    
    // Push state
    @State private var localPushPath: String = ""
    @State private var remoteDestinationPath: String = "/sdcard/Download/"
    @State private var isPushing: Bool = false
    
    // Pull state
    @State private var remotePullPath: String = "/sdcard/"
    @State private var isPulling: Bool = false
    
    // Sideload state
    @State private var sideloadZipPath: String = ""
    @State private var isSideloading: Bool = false
    @State private var sideloadProgressText: String = ""
    @State private var showSideloadConfirm: Bool = false
    
    // Screenshot state
    @State private var capturedImage: NSImage? = nil
    @State private var isCapturing: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sideload Flasher Card
                sideloadCard
                
                // File Push & Pull Cards
                HStack(alignment: .top, spacing: 16) {
                    pushFileCard
                    pullFileCard
                }
                
                // Screenshot Capture Card
                screenshotCard
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
    }
    
    // MARK: - Subviews
    private var sideloadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("file_sideload_title"), systemImage: "arrow.down.doc.fill")
            .font(.headline)
            
            Text(L10n("file_sideload_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            HStack(spacing: 10) {
                TextField(L10n("file_sideload_placeholder"), text: $sideloadZipPath)
                    .textFieldStyle(.roundedBorder)
                
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
                .disabled(sideloadZipPath.isEmpty || isSideloading)
            }
            
            if !sideloadProgressText.isEmpty {
                Text("\(L10n("file_progress_current")) \(sideloadProgressText)")
                    .font(.caption.monospaced())
                    .foregroundColor(.blue)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    private var pushFileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("file_push_title"), systemImage: "arrow.up.circle.fill")
                .font(.headline)
            
            Text(L10n("file_push_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n("file_push_source"))
                    .font(.caption.bold())
                HStack {
                    TextField(L10n("file_push_path_placeholder"), text: $localPushPath)
                        .textFieldStyle(.roundedBorder)
                    Button(L10n("fb_browse")) {
                        chooseLocalFileToPush()
                    }
                    .liquidGlassButton()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n("file_push_dest"))
                    .font(.caption.bold())
                TextField("/sdcard/Download/", text: $remoteDestinationPath)
                    .textFieldStyle(.roundedBorder)
            }
            
            Button {
                executePush()
            } label: {
                if isPushing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Label(L10n("file_push_btn"), systemImage: "arrow.up.to.line")
                }
            }
            .liquidGlassButton(tint: .blue, prominent: true)
            .disabled(localPushPath.isEmpty || remoteDestinationPath.isEmpty || isPushing || deviceManager.selectedDevice?.mode != .adb)
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var pullFileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n("file_pull_title"), systemImage: "arrow.down.circle.fill")
                .font(.headline)
            
            Text(L10n("file_pull_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().opacity(0.4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n("file_pull_source"))
                    .font(.caption.bold())
                TextField(L10n("file_pull_path_placeholder"), text: $remotePullPath)
                    .textFieldStyle(.roundedBorder)
            }
            
            Spacer().frame(height: 18)
            
            Button {
                executePull()
            } label: {
                if isPulling {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Label(L10n("file_pull_btn"), systemImage: "arrow.down.to.line")
                }
            }
            .liquidGlassButton(tint: .blue, prominent: true)
            .disabled(remotePullPath.isEmpty || isPulling || deviceManager.selectedDevice?.mode != .adb)
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var screenshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(L10n("file_screenshot_title"), systemImage: "camera.fill")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    captureScreenshot()
                } label: {
                    if isCapturing {
                        ProgressView().scaleEffect(0.6)
                    } else {
                        Label(L10n("file_take_screenshot"), systemImage: "camera")
                    }
                }
                .liquidGlassButton(tint: .blue, prominent: true)
                .disabled(isCapturing || deviceManager.selectedDevice?.mode != .adb)
                
                if capturedImage != nil {
                    Button {
                        copyScreenshot()
                    } label: {
                        Label(L10n("file_copy_clipboard"), systemImage: "doc.on.doc")
                    }
                    .liquidGlassButton()
                    
                    Button {
                        saveScreenshot()
                    } label: {
                        Label(L10n("file_save_screenshot"), systemImage: "square.and.arrow.down")
                    }
                    .liquidGlassButton()
                }
            }
            
            Text(L10n("file_screenshot_desc"))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let image = capturedImage {
                HStack {
                    Spacer()
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .liquidGlassCard(cornerRadius: 16, padding: 16)
    }
    
    // MARK: - Actions
    private func chooseZipFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(filenameExtension: "zip") ?? .data, .data]
        panel.prompt = L10n("panel_choose_flash_zip")
        
        if panel.runModal() == .OK, let url = panel.url {
            sideloadZipPath = url.path
        }
    }
    
    private func chooseLocalFileToPush() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.prompt = L10n("panel_choose_transfer_file")
        
        if panel.runModal() == .OK, let url = panel.url {
            localPushPath = url.path
        }
    }
    
    private func executePush() {
        guard let dev = deviceManager.selectedDevice else { return }
        isPushing = true
        let local = localPushPath
        let remote = remoteDestinationPath
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在傳送 \(local) 至 \(remote)...")
                try await ADBService.shared.pushFile(serial: dev.serial, localPath: local, remotePath: remote)
                deviceManager.appendLog(level: .success, text: "檔案傳送完成！")
            } catch {
                deviceManager.appendLog(level: .error, text: "傳送失敗: \(error.localizedDescription)")
            }
            isPushing = false
        }
    }
    
    private func executePull() {
        guard let dev = deviceManager.selectedDevice else { return }
        let filename = URL(fileURLWithPath: remotePullPath).lastPathComponent
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename.isEmpty ? "pulled_file" : filename
        panel.prompt = L10n("panel_save_to_mac")
        
        if panel.runModal() == .OK, let targetUrl = panel.url {
            isPulling = true
            let remote = remotePullPath
            Task {
                do {
                    deviceManager.appendLog(level: .info, text: "正在下載 \(remote) 至 \(targetUrl.path)...")
                    try await ADBService.shared.pullFile(serial: dev.serial, remotePath: remote, localPath: targetUrl.path)
                    deviceManager.appendLog(level: .success, text: "檔案下載成功！儲存於: \(targetUrl.path)")
                } catch {
                    deviceManager.appendLog(level: .error, text: "下載失敗: \(error.localizedDescription)")
                }
                isPulling = false
            }
        }
    }
    
    private func executeSideload() {
        guard let dev = deviceManager.selectedDevice else { return }
        isSideloading = true
        let zip = sideloadZipPath
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在 Sideload 刷入 \(zip)...")
                try await ADBService.shared.sideload(serial: dev.serial, zipPath: zip) { progress in
                    DispatchQueue.main.async {
                        self.sideloadProgressText = progress
                    }
                }
                deviceManager.appendLog(level: .success, text: "Sideload 刷機完成！")
            } catch {
                deviceManager.appendLog(level: .error, text: "Sideload 刷機失敗: \(error.localizedDescription)")
            }
            isSideloading = false
        }
    }
    
    private func captureScreenshot() {
        guard let dev = deviceManager.selectedDevice else { return }
        isCapturing = true
        
        Task {
            do {
                deviceManager.appendLog(level: .info, text: "正在擷取手機螢幕...")
                let img = try await ADBService.shared.captureScreenshot(serial: dev.serial)
                capturedImage = img
                deviceManager.appendLog(level: .success, text: "螢幕擷取成功！")
            } catch {
                deviceManager.appendLog(level: .error, text: "截圖失敗: \(error.localizedDescription)")
            }
            isCapturing = false
        }
    }
    
    private func copyScreenshot() {
        guard let image = capturedImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        deviceManager.appendLog(level: .success, text: "已複製截圖至剪貼簿")
    }
    
    private func saveScreenshot() {
        guard let image = capturedImage else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Screenshot_\(Int(Date().timeIntervalSince1970)).png"
        panel.allowedContentTypes = [UTType.png]
        panel.prompt = L10n("panel_save")
        
        if panel.runModal() == .OK, let targetUrl = panel.url {
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try? pngData.write(to: targetUrl)
                deviceManager.appendLog(level: .success, text: "截圖已儲存至 \(targetUrl.path)")
            }
        }
    }
}
