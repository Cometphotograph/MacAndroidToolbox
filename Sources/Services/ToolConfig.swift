import Foundation

@MainActor
public final class ToolConfig: ObservableObject {
    public static let shared = ToolConfig()
    
    private let kAdbPathKey = "kCustomAdbPath"
    private let kFastbootPathKey = "kCustomFastbootPath"
    private let kEdlPathKey = "kCustomEdlPath"
    private let kPython3PathKey = "kCustomPython3Path"
    
    @Published public var adbPath: String {
        didSet {
            UserDefaults.standard.set(adbPath, forKey: kAdbPathKey)
        }
    }
    
    @Published public var fastbootPath: String {
        didSet {
            UserDefaults.standard.set(fastbootPath, forKey: kFastbootPathKey)
        }
    }
    
    @Published public var edlPath: String {
        didSet {
            UserDefaults.standard.set(edlPath, forKey: kEdlPathKey)
        }
    }
    
    @Published public var python3Path: String {
        didSet {
            UserDefaults.standard.set(python3Path, forKey: kPython3PathKey)
        }
    }
    
    @Published public var adbVersionString: String = ""
    @Published public var fastbootVersionString: String = ""
    @Published public var edlVersionString: String = ""
    @Published public var python3VersionString: String = ""
    @Published public var isAdbAvailable: Bool = false
    @Published public var isFastbootAvailable: Bool = false
    @Published public var isEdlAvailable: Bool = false
    @Published public var isPython3Available: Bool = false
    @Published public var homebrewPath: String? = nil
    
    public var isHomebrewAvailable: Bool {
        return homebrewPath != nil
    }
    
    public init() {
        let savedAdb = UserDefaults.standard.string(forKey: kAdbPathKey)
        let savedFastboot = UserDefaults.standard.string(forKey: kFastbootPathKey)
        let savedEdl = UserDefaults.standard.string(forKey: kEdlPathKey)
        let savedPython3 = UserDefaults.standard.string(forKey: kPython3PathKey)
        
        self.adbPath = savedAdb ?? ToolConfig.autoDetectPath(binary: "adb")
        self.fastbootPath = savedFastboot ?? ToolConfig.autoDetectPath(binary: "fastboot")
        self.edlPath = savedEdl ?? ToolConfig.autoDetectPath(binary: "edl")
        self.python3Path = savedPython3 ?? ToolConfig.autoDetectPath(binary: "python3")
        self.homebrewPath = ToolConfig.detectHomebrewPath()
        
        checkTools()
    }
    
    public nonisolated static func autoDetectPath(binary: String) -> String {
        let appSupport = "\(NSHomeDirectory())/Library/Application Support/MacAndroidToolbox"
        var searchLocations: [String] = []
        
        if binary == "edl" {
            searchLocations = [
                "\(appSupport)/edl_env/bin/edl",
                "\(appSupport)/edl_repo/edl.py",
                "/opt/homebrew/bin/edl",
                "/usr/local/bin/edl"
            ]
        } else if binary == "python3" {
            searchLocations = [
                "\(appSupport)/edl_env/bin/python3",
                "/opt/homebrew/bin/python3",
                "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3",
                "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3",
                "/Library/Frameworks/Python.framework/Versions/3.10/bin/python3",
                "/usr/local/bin/python3",
                "/usr/bin/python3"
            ]
        } else {
            searchLocations = [
                "/opt/homebrew/bin/\(binary)",
                "/usr/local/bin/\(binary)",
                "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/\(binary)",
                "/Applications/Android Studio.app/Contents/plugins/android/lib/platform-tools/\(binary)",
                "/usr/bin/\(binary)"
            ]
        }
        
        for location in searchLocations {
            if FileManager.default.fileExists(atPath: location) && (FileManager.default.isExecutableFile(atPath: location) || location.hasSuffix(".py")) {
                return location
            }
        }
        
        return binary
    }
    
    public nonisolated static func detectHomebrewPath() -> String? {
        let locations = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ]
        for loc in locations {
            if FileManager.default.fileExists(atPath: loc) && FileManager.default.isExecutableFile(atPath: loc) {
                return loc
            }
        }
        return nil
    }
    
    public func installPlatformToolsViaBrew(onOutput: (@Sendable (String) -> Void)? = nil) async throws -> Bool {
        guard let brew = ToolConfig.detectHomebrewPath() else {
            throw NSError(domain: "ToolConfigError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Homebrew not found on system"])
        }
        
        onOutput?("==> 正在使用 Homebrew 安裝 android-platform-tools...")
        onOutput?("==> 執行: \(brew) install --cask android-platform-tools")
        
        let result = try await ProcessRunner.shared.execute(
            executable: brew,
            arguments: ["install", "--cask", "android-platform-tools"],
            environment: ["HOMEBREW_NO_AUTO_UPDATE": "1"],
            onOutput: onOutput
        )
        
        if result.isSuccess {
            onOutput?("==> android-platform-tools 安裝成功！正在重新整理工具路徑...")
            self.resetToDefaults()
            DeviceManager.shared.refreshDevices()
            return true
        } else {
            let err = result.stderr.isEmpty ? result.stdout : result.stderr
            onOutput?("==> 安裝失敗: \(err)")
            return false
        }
    }
    
    public func resetToDefaults() {
        adbPath = ToolConfig.autoDetectPath(binary: "adb")
        fastbootPath = ToolConfig.autoDetectPath(binary: "fastboot")
        edlPath = ToolConfig.autoDetectPath(binary: "edl")
        python3Path = ToolConfig.autoDetectPath(binary: "python3")
        homebrewPath = ToolConfig.detectHomebrewPath()
        checkTools()
    }
    
    public func checkTools() {
        let adb = self.adbPath
        let fb = self.fastbootPath
        let edl = self.edlPath
        let py3 = self.python3Path
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let adbVer = ToolConfig.runVersionCheck(path: adb, arg: "version")
            let fastbootVer = ToolConfig.runVersionCheck(path: fb, arg: "--version")
            let py3Ver = ToolConfig.runVersionCheck(path: py3, arg: "--version")
            
            var edlVer: String? = nil
            if edl.hasSuffix(".py") && FileManager.default.fileExists(atPath: edl) {
                edlVer = ToolConfig.runProcessOutput(executable: py3, arguments: [edl, "-h"])
            } else if FileManager.default.isExecutableFile(atPath: edl) {
                edlVer = ToolConfig.runVersionCheck(path: edl, arg: "-h")
            }
            
            DispatchQueue.main.async {
                self?.adbVersionString = adbVer ?? "未找到 ADB 二進位檔案"
                self?.isAdbAvailable = adbVer != nil
                self?.fastbootVersionString = fastbootVer ?? "未找到 Fastboot 二進位檔案"
                self?.isFastbootAvailable = fastbootVer != nil
                self?.python3VersionString = py3Ver ?? "未找到 Python 3"
                self?.isPython3Available = py3Ver != nil
                self?.edlVersionString = (edlVer != nil) ? "EDL 可用" : "未找到 EDL 模組"
                self?.isEdlAvailable = edlVer != nil
            }
        }
    }
    
    public nonisolated static func runProcessOutput(executable: String, arguments: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        let appSupport = "\(NSHomeDirectory())/Library/Application Support/MacAndroidToolbox"
        env["PYTHONPATH"] = "\(appSupport)/edl_repo:" + (env["PYTHONPATH"] ?? "")
        process.environment = env
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                return output.components(separatedBy: .newlines).first
            }
        } catch {
            return nil
        }
        return nil
    }
    
    private nonisolated static func runVersionCheck(path: String, arg: String) -> String? {
        return runProcessOutput(executable: path, arguments: [arg])
    }
}
