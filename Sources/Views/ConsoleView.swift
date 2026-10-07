import SwiftUI

public struct ConsoleView: View {
    @ObservedObject var deviceManager = DeviceManager.shared
    @ObservedObject var generalSettings = GeneralSettingsManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel? = nil
    @State private var autoScroll: Bool = true
    
    public init() {}
    
    var filteredLogs: [LogEntry] {
        deviceManager.logs.filter { entry in
            if !generalSettings.isShowPollingLogsEnabled && entry.isPolling {
                return false
            }
            let matchesLevel = (selectedLevel == nil) || (entry.level == selectedLevel)
            let matchesSearch = searchText.isEmpty || entry.text.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header / Control bar (Frosted Glass)
            HStack(spacing: 12) {
                Label(L10n("console_title"), systemImage: "terminal.fill")
                    .font(.subheadline.bold())
                
                Spacer()
                
                // Search box
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L10n("console_filter"), text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 140)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
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
                .frame(width: 120)
                
                Toggle(L10n("console_show_polling"), isOn: $generalSettings.isShowPollingLogsEnabled)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .help(L10n("settings_show_polling_desc"))
                
                Toggle(L10n("console_auto_scroll"), isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                
                // Copy button
                Button {
                    copyAllLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .help(L10n("console_copy_all"))
                .buttonStyle(.borderless)
                
                // Clear button
                Button {
                    deviceManager.clearLogs()
                } label: {
                    Image(systemName: "trash")
                }
                .help(L10n("console_clear"))
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            Divider().opacity(0.3)
            
            // Console output area
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
                                
                                Text(entry.text)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(textColor(for: entry.level))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .id(entry.id)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 1)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .background(Color(NSColor.textBackgroundColor).opacity(0.8))
                .onChange(of: deviceManager.logs.count) { _ in
                    if autoScroll, let last = filteredLogs.last {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
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
        let text = filteredLogs.map { "[\($0.level.rawValue)] \($0.text)" }.joined(separator: "\n")
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
