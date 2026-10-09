import Foundation
import SwiftUI

public struct EDLDeviceInfo: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let vendorId: String
    public let productId: String
    public let locationId: String
    public let serialPort: String?
    
    public init(
        id: String,
        name: String = "Qualcomm HS-USB QDLoader 9008",
        vendorId: String = "0x05c6",
        productId: String = "0x9008",
        locationId: String = "",
        serialPort: String? = nil
    ) {
        self.id = id
        self.name = name
        self.vendorId = vendorId
        self.productId = productId
        self.locationId = locationId
        self.serialPort = serialPort
    }
}

public struct EDLEnvironmentStatus: Sendable {
    public let isPython3Available: Bool
    public let python3Path: String
    public let python3Version: String
    public let isLibusbAvailable: Bool
    public let isEdlAvailable: Bool
    public let edlPath: String
    public let edlVersion: String
    
    public var isReady: Bool {
        isPython3Available && isLibusbAvailable && isEdlAvailable
    }
}

public struct EDLPartitionItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let startLBA: String
    public let endLBA: String
    public let sizeInSectors: String
    public let sizeString: String
    public let lun: Int
    
    public init(name: String, startLBA: String, endLBA: String, sizeInSectors: String, sizeString: String, lun: Int = 0) {
        self.name = name
        self.startLBA = startLBA
        self.endLBA = endLBA
        self.sizeInSectors = sizeInSectors
        self.sizeString = sizeString
        self.lun = lun
    }
}

@MainActor
public final class EDLService: ObservableObject {
    public static let shared = EDLService()
    
    @Published public var connectedDevice: EDLDeviceInfo?
    @Published public var environmentStatus: EDLEnvironmentStatus?
    @Published public var isScanning: Bool = false
    @Published public var isFlashing: Bool = false
    @Published public var operationProgress: Double = 0.0
    @Published public var statusMessage: String = ""
    @Published public var parsedPartitions: [EDLPartitionItem] = []
    
    private init() {}
    
    // MARK: - Device Detection
    
    /// Scans USB subsystem via macOS `ioreg` to detect Qualcomm 9008 (VID 0x05c6, PID 0x9008 / 0x900e)
    public func detectConnected9008Device() async -> EDLDeviceInfo? {
        // Run lightweight ioreg query
        do {
            let res = try await ProcessRunner.shared.execute(
                executable: "/usr/sbin/ioreg",
                arguments: ["-r", "-c", "IOUSBHostDevice", "-l"],
                isPolling: true
            )
            
            if res.isSuccess {
                let output = res.stdout
                // Check if Qualcomm vendor ID (decimal 1478 or hex 0x05c6) is present
                // and Product ID (36872 for 0x9008 or 36878 for 0x900e)
                let isQualcomm = output.contains("\"idVendor\" = 1478") || output.contains("0x05c6") || output.contains("\"idVendor\" = 0x5c6")
                let is9008 = output.contains("\"idProduct\" = 36872") || output.contains("0x9008") || output.contains("QDLoader 9008") || output.contains("Qualcomm HS-USB")
                let is900E = output.contains("\"idProduct\" = 36878") || output.contains("0x900e")
                
                if isQualcomm && (is9008 || is900E) {
                    // Extract location ID or serial if possible
                    var locationId = "0x00000000"
                    if let locRange = output.range(of: "\"locationID\" = ") {
                        let sub = output[locRange.upperBound...]
                        let line = sub.prefix(while: { $0 != "\n" && $0 != "\r" && $0 != "," })
                        locationId = line.trimmingCharacters(in: .whitespaces)
                    }
                    
                    // Check for serial port device in /dev
                    let serialPort = detectSerialPort()
                    
                    let devName = is9008 ? "Qualcomm HS-USB QDLoader 9008" : "Qualcomm HS-USB Diagnostics 900E"
                    let dev = EDLDeviceInfo(
                        id: locationId.isEmpty ? "EDL_PORT_9008" : "EDL_\(locationId)",
                        name: devName,
                        vendorId: "0x05c6",
                        productId: is9008 ? "0x9008" : "0x900e",
                        locationId: locationId,
                        serialPort: serialPort
                    )
                    self.connectedDevice = dev
                    return dev
                }
            }
        } catch {
            // ignore scan failure
        }
        
        self.connectedDevice = nil
        return nil
    }
    
    private func detectSerialPort() -> String? {
        let fileManager = FileManager.default
        let devDir = "/dev"
        guard let files = try? fileManager.contentsOfDirectory(atPath: devDir) else { return nil }
        
        for file in files {
            if file.hasPrefix("cu.usbserial") || file.hasPrefix("cu.usbmodem") {
                return "/dev/\(file)"
            }
        }
        return nil
    }
    
    // MARK: - Environment Check
    
    public func checkEnvironment() async -> EDLEnvironmentStatus {
        let config = ToolConfig.shared
        
        // 1. Check Python 3
        var pyPath = config.python3Path
        var pyVer = ""
        var isPyOk = false
        
        do {
            let pyRes = try await ProcessRunner.shared.execute(
                executable: pyPath,
                arguments: ["--version"],
                isPolling: true
            )
            if pyRes.isSuccess {
                pyVer = pyRes.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                isPyOk = true
            }
        } catch {
            // fallback check
            let autoPy = ToolConfig.autoDetectPath(binary: "python3")
            if autoPy != pyPath {
                if let pyRes = try? await ProcessRunner.shared.execute(
                    executable: autoPy,
                    arguments: ["--version"],
                    isPolling: true
                ), pyRes.isSuccess {
                    pyVer = pyRes.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    pyPath = autoPy
                    isPyOk = true
                }
            }
        }
        
        // 2. Check libusb (via brew or filesystem)
        var isLibusbOk = false
        let libusbPaths = [
            "/opt/homebrew/opt/libusb/lib/libusb-1.0.dylib",
            "/usr/local/opt/libusb/lib/libusb-1.0.dylib",
            "/opt/homebrew/lib/libusb-1.0.dylib",
            "/usr/local/lib/libusb-1.0.dylib"
        ]
        for p in libusbPaths {
            if FileManager.default.fileExists(atPath: p) {
                isLibusbOk = true
                break
            }
        }
        
        // 3. Check EDL tool availability
        let edlPath = config.edlPath
        var isEdlOk = false
        var edlVer = ""
        
        // Check if edl executable directly exists
        if FileManager.default.isExecutableFile(atPath: edlPath) {
            isEdlOk = true
            edlVer = "CLI Executable"
        } else {
            // Check if edl python module is runnable
            if isPyOk {
                if let modRes = try? await ProcessRunner.shared.execute(
                    executable: pyPath,
                    arguments: ["-c", "import edl; print('OK')"],
                    isPolling: true
                ), modRes.stdout.contains("OK") {
                    isEdlOk = true
                    edlVer = "Python Module"
                }
            }
        }
        
        let status = EDLEnvironmentStatus(
            isPython3Available: isPyOk,
            python3Path: pyPath,
            python3Version: pyVer.isEmpty ? "未找到" : pyVer,
            isLibusbAvailable: isLibusbOk,
            isEdlAvailable: isEdlOk,
            edlPath: edlPath,
            edlVersion: edlVer.isEmpty ? "未就绪" : edlVer
        )
        self.environmentStatus = status
        return status
    }
    
    // MARK: - Dependency Auto-Installer
    
    public func installDependenciesViaBrew(onOutput: (@Sendable (String) -> Void)? = nil) async throws -> Bool {
        guard let brew = ToolConfig.detectHomebrewPath() else {
            throw NSError(domain: "EDLServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "系统中未检测到 Homebrew，请先安装 Homebrew 或手动安装 libusb 与 edl。"])
        }
        
        onOutput?("==> [EDL] 正在通过 Homebrew 安装底层驱动库 libusb...")
        let libusbRes = try await ProcessRunner.shared.execute(
            executable: brew,
            arguments: ["install", "libusb"],
            environment: ["HOMEBREW_NO_AUTO_UPDATE": "1"],
            onOutput: onOutput
        )
        
        if !libusbRes.isSuccess {
            onOutput?("⚠️ [EDL] libusb 安装失败，请检查终端网络或权限。")
            return false
        }
        
        let py = ToolConfig.shared.python3Path
        onOutput?("==> [EDL] 正在通过 pip3 安装 pyusb, pyserial 及 edl 核心套件...")
        let pipRes = try await ProcessRunner.shared.execute(
            executable: py,
            arguments: ["-m", "pip", "install", "--upgrade", "pyusb", "pyserial", "edl"],
            onOutput: onOutput
        )
        
        if pipRes.isSuccess {
            onOutput?("🎉 [EDL] 依赖套件安装成功！正在重新自检环境...")
            _ = await checkEnvironment()
            return true
        } else {
            onOutput?("⚠️ [EDL] pip3 安装失败: \(pipRes.stderr.isEmpty ? pipRes.stdout : pipRes.stderr)")
            return false
        }
    }
    
    // MARK: - Command Execution Helper
    
    private func buildEdlInvocation(args: [String]) -> (executable: String, arguments: [String]) {
        let config = ToolConfig.shared
        let edlPath = config.edlPath
        
        if FileManager.default.isExecutableFile(atPath: edlPath) && !edlPath.hasSuffix(".py") {
            return (executable: edlPath, arguments: args)
        } else if edlPath.hasSuffix(".py") && FileManager.default.fileExists(atPath: edlPath) {
            return (executable: config.python3Path, arguments: [edlPath] + args)
        } else {
            // Default to running as python module or system command
            return (executable: config.python3Path, arguments: ["-m", "edl"] + args)
        }
    }
    
    // MARK: - Core Operations
    
    /// Sends Firehose Loader to device via Sahara protocol
    public func sendLoader(
        loader: String,
        memoryType: String = "ufs",
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在向设备发送 Firehose 引导文件 (Sahara 握手)..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        guard !loader.isEmpty else {
            throw NSError(domain: "EDLError", code: 1, userInfo: [NSLocalizedDescriptionKey: "引导文件路径不能为空，请先选择 Firehose 引导文件。"])
        }
        
        var cmdArgs: [String] = []
        cmdArgs.append("--loader=\(loader)")
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        
        onOutput?("==> [EDL/Sahara] 开始通过 Sahara 协议握手并发送 Firehose 引导: \(loader)")
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments,
            onOutput: onOutput
        )
        
        let fullOutput = (res.stdout + "\n" + res.stderr)
        let isSuccess = res.isSuccess || fullOutput.contains("Successfully uploaded programmer") || fullOutput.contains("Firehose mode") || fullOutput.contains("Target:")
        
        if isSuccess {
            onOutput?("🎉 [EDL/Sahara] 引导文件加载成功！Firehose 协议握手完成。")
            return true
        } else {
            let errText = res.stderr.isEmpty ? res.stdout : res.stderr
            throw NSError(domain: "EDLError", code: 2, userInfo: [NSLocalizedDescriptionKey: errText.isEmpty ? "Sahara 引导发送失败，请检查连接或更换引导程序。" : errText])
        }
    }
    /// Reads GPT Partition Table (Print GPT)
    public func printGPT(
        loader: String,
        memoryType: String = "ufs",
        lun: Int? = 0
    ) async throws -> [EDLPartitionItem] {
        isFlashing = true
        statusMessage = "正在读取 GPT 分区表..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["printgpt"]
        if !loader.isEmpty {
            cmdArgs.append("--loader=\(loader)")
        }
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        if let lun = lun, lun >= 0 {
            cmdArgs.append("--lun=\(lun)")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        guard res.isSuccess else {
            throw NSError(domain: "EDLError", code: 2, userInfo: [NSLocalizedDescriptionKey: res.stderr.isEmpty ? res.stdout : res.stderr])
        }
        
        let items = parsePrintGPTOutput(res.stdout, lun: lun ?? 0)
        self.parsedPartitions = items
        return items
    }
    
    /// Writes an image to a partition
    public func flashPartition(
        partition: String,
        imagePath: String,
        loader: String,
        memoryType: String = "ufs",
        lun: Int? = 0
    ) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在向 \(partition) 分区写入镜像..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["w", partition, imagePath]
        if !loader.isEmpty {
            cmdArgs.append("--loader=\(loader)")
        }
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        if let lun = lun, lun >= 0 {
            cmdArgs.append("--lun=\(lun)")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        return res.isSuccess
    }
    
    /// Reads / Dumps a partition to a local file
    public func dumpPartition(
        partition: String,
        outputPath: String,
        loader: String,
        memoryType: String = "ufs",
        lun: Int? = 0
    ) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在提取 \(partition) 分区备份..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["r", partition, outputPath]
        if !loader.isEmpty {
            cmdArgs.append("--loader=\(loader)")
        }
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        if let lun = lun, lun >= 0 {
            cmdArgs.append("--lun=\(lun)")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        return res.isSuccess
    }
    
    /// Erases a partition
    public func erasePartition(
        partition: String,
        loader: String,
        memoryType: String = "ufs",
        lun: Int? = 0
    ) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在擦除 \(partition) 分区..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["e", partition]
        if !loader.isEmpty {
            cmdArgs.append("--loader=\(loader)")
        }
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        if let lun = lun, lun >= 0 {
            cmdArgs.append("--lun=\(lun)")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        return res.isSuccess
    }
    
    /// QFIL Full XML Flashing (rawprogram*.xml + patch*.xml + image folder)
    public func flashQFIL(
        rawprogramXml: String,
        patchXml: String,
        imageDir: String,
        loader: String,
        memoryType: String = "ufs"
    ) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在执行 QFIL 全盘线刷..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["qfil", rawprogramXml, patchXml, imageDir]
        if !loader.isEmpty {
            cmdArgs.append("--loader=\(loader)")
        }
        if !memoryType.isEmpty && memoryType.lowercased() != "auto" {
            cmdArgs.append("--memory=\(memoryType.lowercased())")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        return res.isSuccess
    }
    
    /// Reboots / Resets device out of 9008 EDL mode
    public func rebootDevice(loader: String? = nil) async throws -> Bool {
        isFlashing = true
        statusMessage = "正在退出 9008 模式并重启设备..."
        defer {
            isFlashing = false
            statusMessage = "就绪"
        }
        
        var cmdArgs = ["reset"]
        if let ldr = loader, !ldr.isEmpty {
            cmdArgs.append("--loader=\(ldr)")
        }
        
        let invocation = buildEdlInvocation(args: cmdArgs)
        let res = try await ProcessRunner.shared.execute(
            executable: invocation.executable,
            arguments: invocation.arguments
        )
        
        return res.isSuccess
    }
    
    // MARK: - GPT Parser
    
    private func parsePrintGPTOutput(_ output: String, lun: Int) -> [EDLPartitionItem] {
        var items: [EDLPartitionItem] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("---") || trimmed.hasPrefix("Partition") || trimmed.hasPrefix("Total") {
                continue
            }
            
            // Common edl printgpt output format:
            // PartName: <name> Start: <hex> End: <hex> Sectors: <num>
            // or table format: name  start_lba  end_lba  sectors
            let components = trimmed.split(separator: " ").map(String.init).filter { !$0.isEmpty }
            if components.count >= 4 {
                let name = components[0]
                let start = components[1]
                let end = components[2]
                let sectors = components[3]
                
                // Calculate size in MB if sectors is an integer
                var sizeText = "\(sectors) 扇区"
                if let sectorCount = Int(sectors) {
                    let bytes = sectorCount * 512
                    let mb = Double(bytes) / (1024.0 * 1024.0)
                    if mb >= 1024.0 {
                        sizeText = String(format: "%.2f GB", mb / 1024.0)
                    } else {
                        sizeText = String(format: "%.1f MB", mb)
                    }
                }
                
                items.append(EDLPartitionItem(
                    name: name,
                    startLBA: start,
                    endLBA: end,
                    sizeInSectors: sectors,
                    sizeString: sizeText,
                    lun: lun
                ))
            }
        }
        
        return items
    }
}
