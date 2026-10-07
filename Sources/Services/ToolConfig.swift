import Foundation

@MainActor
public final class ToolConfig: ObservableObject {
    public static let shared = ToolConfig()
    
    private let kAdbPathKey = "kCustomAdbPath"
    private let kFastbootPathKey = "kCustomFastbootPath"
    
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
    
    @Published public var adbVersionString: String = ""
    @Published public var fastbootVersionString: String = ""
    @Published public var isAdbAvailable: Bool = false
    @Published public var isFastbootAvailable: Bool = false
    @Published public var homebrewPath: String? = nil
    
    public var isHomebrewAvailable: Bool {
        return homebrewPath != nil
    }
    
    public init() {
        let savedAdb = UserDefaults.standard.string(forKey: kAdbPathKey)
        let savedFastboot = UserDefaults.standard.string(forKey: kFastbootPathKey)
        
        self.adbPath = savedAdb ?? ToolConfig.autoDetectPath(binary: "adb")
        self.fastbootPath = savedFastboot ?? ToolConfig.autoDetectPath(binary: "fastboot")
        self.homebrewPath = ToolConfig.detectHomebrewPath()
        
        checkTools()
    }
    
    public nonisolated static func autoDetectPath(binary: String) -> String {
        let searchLocations = [
            "/opt/homebrew/bin/\(binary)",
            "/usr/local/bin/\(binary)",
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/\(binary)",
            "/Applications/Android Studio.app/Contents/plugins/android/lib/platform-tools/\(binary)",
            "/usr/bin/\(binary)"
        ]
        
        for location in searchLocations {
            if FileManager.default.fileExists(atPath: location) && FileManager.default.isExecutableFile(atPath: location) {
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
        homebrewPath = ToolConfig.detectHomebrewPath()
        checkTools()
    }
    
    public func checkTools() {
        let adb = self.adbPath
        let fb = self.fastbootPath
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let adbVer = ToolConfig.runVersionCheck(path: adb, arg: "version")
            let fastbootVer = ToolConfig.runVersionCheck(path: fb, arg: "--version")
            
            DispatchQueue.main.async {
                self?.adbVersionString = adbVer ?? "未找到 ADB 二進位檔案"
                self?.isAdbAvailable = adbVer != nil
                self?.fastbootVersionString = fastbootVer ?? "未找到 Fastboot 二進位檔案"
                self?.isFastbootAvailable = fastbootVer != nil
            }
        }
    }
    
    private nonisolated static func runVersionCheck(path: String, arg: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = [arg]
        process.standardOutput = pipe
        process.standardError = pipe
        
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
}
