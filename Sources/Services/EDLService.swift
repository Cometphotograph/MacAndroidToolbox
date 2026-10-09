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
    
    @MainActor
    public var localizedPythonVersion: String {
        if !isPython3Available {
            return L10n("edl_env_not_found")
        }
        let currentLang = LanguageManager.shared.currentLanguage
        if python3Version.contains("专属沙箱") || python3Version.contains("專屬沙箱") || python3Version.contains("Sandbox") {
            let ver = python3Version.replacingOccurrences(of: "专属沙箱 ", with: "")
                .replacingOccurrences(of: "專屬沙箱 ", with: "")
                .replacingOccurrences(of: "Dedicated Sandbox ", with: "")
            if currentLang.isChinese {
                return (currentLang == .zhHant ? "專屬沙箱 " : "专属沙箱 ") + ver
            } else {
                return "Dedicated Sandbox " + ver
            }
        }
        return python3Version
    }
    
    @MainActor
    public var localizedEdlVersion: String {
        if !isEdlAvailable {
            return L10n("edl_env_not_ready")
        }
        let currentLang = LanguageManager.shared.currentLanguage
        if edlVersion.contains("CLI") {
            if currentLang.isChinese {
                return currentLang == .zhHant ? "CLI 獨立執行" : "CLI 独立运行"
            } else {
                return "Standalone CLI Executable"
            }
        } else if edlVersion.contains("edl.py") {
            if currentLang.isChinese {
                return currentLang == .zhHant ? "edl.py 腳本執行" : "edl.py 脚本运行"
            } else {
                return "edl.py Python Script"
            }
        } else if edlVersion.contains("edlclient") {
            if currentLang.isChinese {
                return currentLang == .zhHant ? "Python 模組 (edlclient)" : "Python 模块 (edlclient)"
            } else {
                return "Python Module (edlclient)"
            }
        }
        return edlVersion
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
    
    // MARK: - Dedicated Environment Paths
    public static var appSupportDirectory: String {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let base = urls.first {
            return base.appendingPathComponent("MacAndroidToolbox").path
        }
        return "\(NSHomeDirectory())/Library/Application Support/MacAndroidToolbox"
    }
    
    public static var edlEnvDirectory: String {
        return "\(appSupportDirectory)/edl_env"
    }
    
    public static var edlRepoDirectory: String {
        return "\(appSupportDirectory)/edl_repo"
    }
    
    public static var edlVenvPython: String {
        return "\(edlEnvDirectory)/bin/python3"
    }
    
    public static var edlVenvPip: String {
        return "\(edlEnvDirectory)/bin/pip"
    }
    
    public static var edlVenvEdlBinary: String {
        return "\(edlEnvDirectory)/bin/edl"
    }
    
    public static var edlRepoScript: String {
        return "\(edlRepoDirectory)/edl.py"
    }
    
    // MARK: - Environment Check
    
    public func checkEnvironment() async -> EDLEnvironmentStatus {
        let config = ToolConfig.shared
        
        // 1. Check Python 3 (prefer dedicated venv if available)
        var pyPath = config.python3Path
        var pyVer = ""
        var isPyOk = false
        
        let venvPy = Self.edlVenvPython
        if FileManager.default.isExecutableFile(atPath: venvPy) {
            if let venvRes = try? await ProcessRunner.shared.execute(
                executable: venvPy,
                arguments: ["--version"],
                isPolling: true
            ), venvRes.isSuccess {
                pyPath = venvPy
                pyVer = "专属沙箱 " + venvRes.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                isPyOk = true
                config.python3Path = venvPy
            }
        }
        
        if !isPyOk {
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
                        config.python3Path = autoPy
                    }
                }
            }
        }
        
        // 2. Check libusb (via filesystem paths or system frameworks)
        var isLibusbOk = false
        let libusbPaths = [
            "/opt/homebrew/opt/libusb/lib/libusb-1.0.dylib",
            "/usr/local/opt/libusb/lib/libusb-1.0.dylib",
            "/opt/homebrew/lib/libusb-1.0.dylib",
            "/usr/local/lib/libusb-1.0.dylib",
            "/usr/lib/libusb-1.0.dylib"
        ]
        for p in libusbPaths {
            if FileManager.default.fileExists(atPath: p) {
                isLibusbOk = true
                break
            }
        }
        
        // 3. Check EDL tool availability
        var edlPath = config.edlPath
        var isEdlOk = false
        var edlVer = ""
        
        let venvEdl = Self.edlVenvEdlBinary
        let repoEdl = Self.edlRepoScript
        
        if !FileManager.default.fileExists(atPath: edlPath) {
            if FileManager.default.isExecutableFile(atPath: venvEdl) {
                edlPath = venvEdl
                config.edlPath = venvEdl
            } else if FileManager.default.fileExists(atPath: repoEdl) {
                edlPath = repoEdl
                config.edlPath = repoEdl
            }
        }
        
        let env = ["PYTHONPATH": "\(Self.edlRepoDirectory):" + (ProcessInfo.processInfo.environment["PYTHONPATH"] ?? "")]
        
        if FileManager.default.isExecutableFile(atPath: edlPath) && !edlPath.hasSuffix(".py") {
            if let res = try? await ProcessRunner.shared.execute(executable: edlPath, arguments: ["-h"], isPolling: true),
               (res.isSuccess || res.stdout.contains("Qualcomm") || res.stdout.contains("edl.py") || res.stdout.contains("usage:")) {
                isEdlOk = true
                edlVer = "CLI 独立运行"
            }
        } else if edlPath.hasSuffix(".py") && FileManager.default.fileExists(atPath: edlPath) {
            if isPyOk {
                if let res = try? await ProcessRunner.shared.execute(
                    executable: pyPath,
                    arguments: [edlPath, "-h"],
                    environment: env,
                    isPolling: true
                ), (res.isSuccess || res.stdout.contains("Qualcomm") || res.stdout.contains("edl.py") || res.stdout.contains("usage:")) {
                    isEdlOk = true
                    edlVer = "edl.py 脚本运行"
                }
            }
        } else if isPyOk {
            if let modRes = try? await ProcessRunner.shared.execute(
                executable: pyPath,
                arguments: ["-c", "import edlclient; print('OK')"],
                environment: env,
                isPolling: true
            ), modRes.stdout.contains("OK") {
                isEdlOk = true
                edlVer = "Python 模块 (edlclient)"
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
    
    // MARK: - Dependency Auto-Installer (PEP 668 Isolated Environment)
    
    public func installDependenciesViaBrew(onOutput: (@Sendable (String) -> Void)? = nil) async throws -> Bool {
        // Step 1: Ensure libusb
        onOutput?("==> [1/5] 检查底层 USB 驱动库 libusb-1.0...")
        var hasLibusb = false
        let libusbPaths = [
            "/opt/homebrew/opt/libusb/lib/libusb-1.0.dylib",
            "/usr/local/opt/libusb/lib/libusb-1.0.dylib",
            "/opt/homebrew/lib/libusb-1.0.dylib",
            "/usr/local/lib/libusb-1.0.dylib"
        ]
        for p in libusbPaths {
            if FileManager.default.fileExists(atPath: p) {
                hasLibusb = true
                break
            }
        }
        
        if hasLibusb {
            onOutput?("✅ [EDL] 检测到系统已存在 libusb-1.0 驱动，跳过重复安装。")
        } else if let brew = ToolConfig.detectHomebrewPath() {
            onOutput?("==> [EDL] 正在通过 Homebrew 安装底层驱动库 libusb...")
            let libusbRes = try await ProcessRunner.shared.execute(
                executable: brew,
                arguments: ["install", "libusb"],
                environment: ["HOMEBREW_NO_AUTO_UPDATE": "1"],
                onOutput: onOutput
            )
            if !libusbRes.isSuccess {
                onOutput?("⚠️ [EDL] libusb 安装警告: \(libusbRes.stderr.isEmpty ? libusbRes.stdout : libusbRes.stderr)")
            } else {
                onOutput?("✅ [EDL] libusb 安装成功！")
            }
        } else {
            onOutput?("⚠️ [EDL] 未检测到 Homebrew，请确认系统已安装 libusb 或前往 brew.sh 安装。")
        }
        
        // Step 2: Determine Base Python
        onOutput?("==> [2/5] 检测系统 Python 3 解释器...")
        let pyCandidates = [
            ToolConfig.shared.python3Path,
            "/opt/homebrew/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3",
            "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        
        var validBasePy: String? = nil
        for candidate in pyCandidates {
            guard FileManager.default.fileExists(atPath: candidate) else { continue }
            if let verRes = try? await ProcessRunner.shared.execute(executable: candidate, arguments: ["--version"], isPolling: true),
               verRes.isSuccess {
                validBasePy = candidate
                onOutput?("✅ [EDL] 找到基础 Python 3: \(candidate) (\(verRes.stdout.trimmingCharacters(in: .whitespacesAndNewlines)))")
                break
            }
        }
        
        guard let resolvedPy = validBasePy else {
            onOutput?("❌ [EDL] 未在系统中检测到可用的 Python 3，请先安装 Python 3。")
            return false
        }
        
        // Step 3: Setup App Support directory & Python virtual environment (venv)
        onOutput?("==> [3/5] 准备专属沙箱虚拟环境 (彻底规避 PEP 668 系统环境锁定)...")
        let appSupport = Self.appSupportDirectory
        let edlEnv = Self.edlEnvDirectory
        let edlRepo = Self.edlRepoDirectory
        let venvPy = Self.edlVenvPython
        let venvPip = Self.edlVenvPip
        
        try? FileManager.default.createDirectory(atPath: appSupport, withIntermediateDirectories: true)
        
        var isVenvReady = false
        if FileManager.default.isExecutableFile(atPath: venvPy) && FileManager.default.isExecutableFile(atPath: venvPip) {
            onOutput?("✅ [EDL] 检测到已有专属虚拟沙箱环境: \(edlEnv)")
            isVenvReady = true
        } else {
            onOutput?("==> [EDL] 正在创建专属虚拟环境: \(edlEnv)...")
            let venvRes = try await ProcessRunner.shared.execute(
                executable: resolvedPy,
                arguments: ["-m", "venv", edlEnv],
                onOutput: onOutput
            )
            if venvRes.isSuccess && FileManager.default.isExecutableFile(atPath: venvPip) {
                onOutput?("✅ [EDL] 虚拟沙箱环境创建成功！")
                isVenvReady = true
            } else {
                onOutput?("⚠️ [EDL] 虚拟环境创建受阻，将使用全局 Python 并附带 --break-system-packages 参数。")
                isVenvReady = false
            }
        }
        
        let targetPip = isVenvReady ? venvPip : resolvedPy
        let isDirectPip = isVenvReady
        
        // Step 4: Install Python packages
        onOutput?("==> [4/5] 正在安装 EDL 核心协议依赖套件 (pyusb, pyserial, docopt, pycryptodome, lxml, colorama)...")
        let requiredPackages = ["pyusb", "pyserial", "docopt", "pycryptodome", "lxml", "colorama", "requests", "passlib"]
        
        var pipArgs: [String] = []
        if isDirectPip {
            pipArgs = ["install", "--upgrade", "-i", "https://pypi.tuna.tsinghua.edu.cn/simple"] + requiredPackages
        } else {
            pipArgs = ["-m", "pip", "install", "--break-system-packages", "--upgrade", "-i", "https://pypi.tuna.tsinghua.edu.cn/simple"] + requiredPackages
        }
        
        var pipRes = try await ProcessRunner.shared.execute(
            executable: targetPip,
            arguments: pipArgs,
            onOutput: onOutput
        )
        
        if !pipRes.isSuccess {
            onOutput?("⚠️ [EDL] 清华镜像连接异常，正在尝试官方 PyPI 源安装...")
            let fallbackArgs = isDirectPip
                ? ["install", "--upgrade"] + requiredPackages
                : ["-m", "pip", "install", "--break-system-packages", "--upgrade"] + requiredPackages
            
            pipRes = try await ProcessRunner.shared.execute(
                executable: targetPip,
                arguments: fallbackArgs,
                onOutput: onOutput
            )
        }
        
        if !pipRes.isSuccess {
            onOutput?("⚠️ [EDL] 依赖包安装警告: \(pipRes.stderr.isEmpty ? pipRes.stdout : pipRes.stderr)")
        } else {
            onOutput?("✅ [EDL] 核心依赖库安装完成！")
        }
        
        // Step 5: Setup bkerler/edl repository
        onOutput?("==> [5/5] 配置 bkerler/edl 官方源码套件...")
        let gitCandidates = ["/opt/homebrew/bin/git", "/usr/bin/git", ToolConfig.autoDetectPath(binary: "git")]
        var effectiveGit: String? = nil
        for g in gitCandidates {
            if FileManager.default.isExecutableFile(atPath: g) {
                effectiveGit = g
                break
            }
        }
        
        let repoScript = Self.edlRepoScript
        if FileManager.default.fileExists(atPath: repoScript) {
            onOutput?("==> [EDL] 检测到已有 EDL 仓库源码，尝试检查更新...")
            if let git = effectiveGit {
                _ = try? await ProcessRunner.shared.execute(
                    executable: git,
                    arguments: ["-C", edlRepo, "pull"],
                    onOutput: onOutput
                )
            }
        } else if let git = effectiveGit {
            onOutput?("==> [EDL] 正在从 GitHub 克隆 bkerler/edl 仓库 (深度为 1)...")
            var cloneRes = try await ProcessRunner.shared.execute(
                executable: git,
                arguments: ["clone", "--depth", "1", "https://github.com/bkerler/edl.git", edlRepo],
                onOutput: onOutput
            )
            if !cloneRes.isSuccess {
                onOutput?("⚠️ [EDL] GitHub 直连受阻，正在尝试加速镜像通道...")
                cloneRes = try await ProcessRunner.shared.execute(
                    executable: git,
                    arguments: ["clone", "--depth", "1", "https://ghproxy.net/https://github.com/bkerler/edl.git", edlRepo],
                    onOutput: onOutput
                )
            }
            if cloneRes.isSuccess {
                onOutput?("✅ [EDL] bkerler/edl 仓库克隆成功！")
            }
        }
        
        // If repo exists, install in editable mode so 'edl' CLI entry point is created in venv
        if FileManager.default.fileExists(atPath: "\(edlRepo)/pyproject.toml") {
            onOutput?("==> [EDL] 正在注册 edl CLI 命令...")
            let installArgs = isDirectPip
                ? ["install", "-e", edlRepo, "--no-deps"]
                : ["-m", "pip", "install", "--break-system-packages", "-e", edlRepo, "--no-deps"]
            let installRes = try await ProcessRunner.shared.execute(
                executable: targetPip,
                arguments: installArgs,
                onOutput: onOutput
            )
            if installRes.isSuccess {
                onOutput?("✅ [EDL] edl CLI 命令行程序注册成功！")
            }
        }
        
        // Update tool configurations
        let venvEdl = Self.edlVenvEdlBinary
        if FileManager.default.isExecutableFile(atPath: venvEdl) {
            ToolConfig.shared.edlPath = venvEdl
        } else if FileManager.default.fileExists(atPath: repoScript) {
            ToolConfig.shared.edlPath = repoScript
        }
        
        if isVenvReady {
            ToolConfig.shared.python3Path = venvPy
        } else {
            ToolConfig.shared.python3Path = resolvedPy
        }
        
        ToolConfig.shared.checkTools()
        let finalStatus = await checkEnvironment()
        
        if finalStatus.isEdlAvailable {
            onOutput?("🎉 [EDL] 运行环境配置完毕，EDL 工具链已就绪！")
            return true
        } else {
            onOutput?("⚠️ [EDL] 环境安装流程结束。若未能自动识别，您可在界面中手动选择 edl.py 脚本。")
            return true
        }
    }
    
    // MARK: - Command Execution Helper
    
    public func buildEdlInvocation(args: [String]) -> (executable: String, arguments: [String], environment: [String: String]?) {
        let config = ToolConfig.shared
        var edlPath = config.edlPath
        var pyPath = config.python3Path
        
        let venvEdl = Self.edlVenvEdlBinary
        let repoScript = Self.edlRepoScript
        let venvPy = Self.edlVenvPython
        
        if !FileManager.default.fileExists(atPath: edlPath) {
            if FileManager.default.isExecutableFile(atPath: venvEdl) {
                edlPath = venvEdl
            } else if FileManager.default.fileExists(atPath: repoScript) {
                edlPath = repoScript
            }
        }
        
        if !FileManager.default.isExecutableFile(atPath: pyPath) && FileManager.default.isExecutableFile(atPath: venvPy) {
            pyPath = venvPy
        }
        
        let env = ["PYTHONPATH": "\(Self.edlRepoDirectory):" + (ProcessInfo.processInfo.environment["PYTHONPATH"] ?? "")]
        
        if FileManager.default.isExecutableFile(atPath: edlPath) && !edlPath.hasSuffix(".py") {
            return (executable: edlPath, arguments: args, environment: env)
        } else if edlPath.hasSuffix(".py") && FileManager.default.fileExists(atPath: edlPath) {
            return (executable: pyPath, arguments: [edlPath] + args, environment: env)
        } else {
            return (executable: edlPath.isEmpty ? "edl" : edlPath, arguments: args, environment: env)
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
            environment: invocation.environment,
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
            arguments: invocation.arguments,
            environment: invocation.environment
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
