import SwiftUI
import ClaudeIPBarCore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("refreshIntervalMinutes", store: UserDefaults(suiteName: AppGroup.identifier))
    private var refreshIntervalMinutes: Int = AppGroup.defaultRefreshIntervalMinutes

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("设置").font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("自动刷新间隔").font(.headline)
                Picker("刷新间隔", selection: $refreshIntervalMinutes) {
                    Text("15 分钟").tag(15)
                    Text("30 分钟（推荐）").tag(30)
                    Text("1 小时").tag(60)
                    Text("2 小时").tag(120)
                    Text("4 小时").tag(240)
                }
                .pickerStyle(.menu)
                Text("Widget 也会按此间隔刷新。系统硬性最小值 15 分钟。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("数据源").font(.headline)
                Text("""
                • 默认出口 IP：1.1.1.1 cdn-cgi/trace
                • Cloudflare 出口 IP：claude.ai cdn-cgi/trace
                • 地理位置 / ASN / ISP：ipinfo.io（免费层）
                • Claude 服务状态：ip.net.coffee/claude/status.json
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("关于").font(.headline)
                Text("Trust Score / 风险等高级数据需要商业 IP 情报 API key，未集成。点击 Widget 跳转原网页查看。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480, height: 380)
    }
}

#Preview {
    SettingsView()
}
