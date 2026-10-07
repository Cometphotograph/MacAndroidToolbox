import Foundation

public struct CommandResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    
    public var isSuccess: Bool {
        return exitCode == 0
    }
}

private final class SafeDataBox: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()
    
    func append(_ newBytes: Data) {
        lock.lock()
        data.append(newBytes)
        lock.unlock()
    }
    
    func read() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

public final class ProcessRunner: @unchecked Sendable {
    public static let shared = ProcessRunner()
    
    public var logHandler: (@Sendable (LogLevel, String, _ isPolling: Bool) -> Void)?
    
    private init() {}
    
    @discardableResult
    public func execute(
        executable: String,
        arguments: [String],
        currentDirectory: String? = nil,
        environment: [String: String]? = nil,
        isPolling: Bool = false,
        onOutput: (@Sendable (String) -> Void)? = nil
    ) async throws -> CommandResult {
        let cmdString = "\(URL(fileURLWithPath: executable).lastPathComponent) \(arguments.joined(separator: " "))"
        logHandler?(.command, "$ \(cmdString)", isPolling)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                
                if let currentDirectory = currentDirectory {
                    process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
                }
                
                var env = ProcessInfo.processInfo.environment
                env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + (env["PATH"] ?? "")
                if let customEnv = environment {
                    for (k, v) in customEnv {
                        env[k] = v
                    }
                }
                process.environment = env
                
                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe
                
                let stdoutBox = SafeDataBox()
                let stderrBox = SafeDataBox()
                
                outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stdoutBox.append(data)
                        if let str = String(data: data, encoding: .utf8) {
                            let lines = str.components(separatedBy: .newlines)
                            for line in lines where !line.isEmpty {
                                self?.logHandler?(.stdout, line, isPolling)
                                onOutput?(line)
                            }
                        }
                    }
                }
                
                errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        stderrBox.append(data)
                        if let str = String(data: data, encoding: .utf8) {
                            let lines = str.components(separatedBy: .newlines)
                            for line in lines where !line.isEmpty {
                                self?.logHandler?(.stderr, line, isPolling)
                                onOutput?(line)
                            }
                        }
                    }
                }
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    // Stop observation handlers
                    outPipe.fileHandleForReading.readabilityHandler = nil
                    errPipe.fileHandleForReading.readabilityHandler = nil
                    
                    // Read any leftover bytes
                    let remainingOut = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let remainingErr = errPipe.fileHandleForReading.readDataToEndOfFile()
                    stdoutBox.append(remainingOut)
                    stderrBox.append(remainingErr)
                    
                    let outString = String(data: stdoutBox.read(), encoding: .utf8) ?? ""
                    let errString = String(data: stderrBox.read(), encoding: .utf8) ?? ""
                    
                    let code = process.terminationStatus
                    if code == 0 {
                        self.logHandler?(.success, "指令執行完成 (結束代碼 0)", isPolling)
                    } else {
                        self.logHandler?(.error, "指令執行失敗 (結束代碼 \(code))", isPolling)
                    }
                    
                    let result = CommandResult(stdout: outString, stderr: errString, exitCode: code)
                    continuation.resume(returning: result)
                } catch {
                    outPipe.fileHandleForReading.readabilityHandler = nil
                    errPipe.fileHandleForReading.readabilityHandler = nil
                    self.logHandler?(.error, "無法啟動處理序: \(error.localizedDescription)", isPolling)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
