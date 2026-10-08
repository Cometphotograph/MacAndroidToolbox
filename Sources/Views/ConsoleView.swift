import SwiftUI

public struct ConsoleView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel? = nil
    @State private var autoScroll: Bool = true
    
    public var onClose: (() -> Void)? = nil
    
    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }
    
    var filteredLogs: [LogEntry] {
        deviceManager.logs.filter { entry in
            if !generalSettings.isShowPollingLogsEnabled && entry.isPolling {
                return false
            }
            let matchesLevel = (selectedLevel == nil) || (entry.level == selectedLevel)
            let formatted = entry.formattedText(for: languageManager.currentLanguage)
            let matchesSearch = searchText.isEmpty ||
                                entry.text.localizedCaseInsensitiveContains(searchText) ||
                                formatted.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Control bar (macOS 27 Liquid Glass Toolbar)
            HStack(spacing: 10) {
                // Title + Terminal Icon + Count Capsule
                HStack(spacing: 6) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text(L10n("console_title"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text("\(filteredLogs.count)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .fixedSize(horizontal: true, vertical: false)
                
                Spacer(minLength: 8)
                
                // Search box (Liquid Glass Pill)
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    TextField(L10n("console_filter"), text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5))
                        .frame(minWidth: 90, maxWidth: 120)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
                
                // Level Picker
                Picker("", selection: $selectedLevel) {
                    Text(L10n("console_all_levels")).tag(LogLevel?.none)
                    Divider()
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(LogLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 100)
                
                // Toggle Show Polling
                Toggle(L10n("console_show_polling"), isOn: $generalSettings.isShowPollingLogsEnabled)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .help(L10n("settings_show_polling_desc"))
                
                // Toggle Auto Scroll
                Toggle(L10n("console_auto_scroll"), isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                // Copy button
                Button {
                    copyAllLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .help(L10n("console_copy_all"))
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.primary.opacity(0.05)))
                
                // Clear button
                Button {
                    deviceManager.clearLogs()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                }
                .help(L10n("console_clear"))
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.primary.opacity(0.05)))
                
                // Close / Fold Button
                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .help("收起终端")
                    .buttonStyle(.plain)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.07)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.clear)
            
            // Subtle frosted separator line
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 1)
            
            // Console output area (Crisp high-contrast monospaced log stream)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredLogs) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.timestamp, style: .time)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 65, alignment: .leading)
                                
                                LogBadge(level: entry.level)
                                
                                Text(entry.formattedText(for: languageManager.currentLanguage))
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(textColor(for: entry.level))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .id(entry.id)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 1)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .background(Color.clear)
                .onChange(of: deviceManager.logs.count) { _ in
                    if autoScroll, let last = filteredLogs.last {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(MacOS27FloatingTerminalGlassBackground(cornerRadius: 14))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func textColor(for level: LogLevel) -> Color {
        switch level {
        case .command: return .cyan
        case .stdout: return .primary
        case .stderr: return .red
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .secondary
        }
    }
    
    private func copyAllLogs() {
        let text = filteredLogs.map { "[\($0.level.rawValue)] \($0.formattedText(for: languageManager.currentLanguage))" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct LogBadge: View {
    let level: LogLevel
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: level.icon)
                .font(.system(size: 9))
            Text(level.rawValue)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .foregroundColor(badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .frame(width: 62, alignment: .center)
    }
    
    private var badgeColor: Color {
        switch level {
        case .command: return .blue
        case .stdout: return .secondary
        case .stderr: return .pink
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .gray
        }
    }
}

