import Foundation

public enum LogLevel: String, Codable, CaseIterable, Sendable {
    case info = "INFO"
    case command = "CMD"
    case stdout = "OUT"
    case stderr = "ERR"
    case success = "SUCCESS"
    case warning = "WARN"
    case error = "ERROR"
    
    public var icon: String {
        switch self {
        case .info: return "info.circle"
        case .command: return "terminal"
        case .stdout: return "text.alignleft"
        case .stderr: return "exclamationmark.triangle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

public struct LogEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let text: String
    public let isPolling: Bool
    
    public init(level: LogLevel, text: String, isPolling: Bool = false, timestamp: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.text = text
        self.isPolling = isPolling
    }
    
    public func formattedText(for language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return text.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? text
        case .zhHant:
            return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
        default:
            return text
        }
    }
}
