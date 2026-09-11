import SwiftUI
import ClaudeIPBarCore

struct ContentView: View {
    @EnvironmentObject var store: ReportStore
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    if let err = store.lastError, !err.isEmpty {
                        parseErrorBanner(err)
                    }
                    defaultIPCard
                    cloudflareIPCard
                    serviceStatusCard
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "network")
                .font(.title2)
                .foregroundStyle(.tint)
            Text("ClaudeIPBar")
                .font(.title2.bold())
            Spacer()
            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("立即刷新 (⌘R)")
            .disabled(store.isLoading)
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .help("设置")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Cards

    private var defaultIPCard: some View {
        IPCard(
            title: "默认出口 IP",
            icon: "globe",
            ip: store.report.defaultExitIP,
            geo: store.report.defaultExitGeo,
            asn: store.report.asn,
            isp: store.report.isp,
            accent: .blue
        )
    }

    private var cloudflareIPCard: some View {
        IPCard(
            title: "Cloudflare 出口 IP",
            icon: "cloud",
            ip: store.report.cloudflareExitIP,
            geo: store.report.cloudflareExitGeo,
            asn: nil,
            isp: nil,
            accent: .orange
        )
    }

    private var serviceStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.shield")
                    .foregroundStyle(serviceStatusColor)
                Text("Claude 服务状态")
                    .font(.headline)
                Spacer()
                if let status = store.report.serviceStatus {
                    Text(status.displayOverall)
                        .font(.subheadline)
                        .foregroundStyle(serviceStatusColor)
                }
            }
            if let status = store.report.serviceStatus {
                ForEach(status.components, id: \.name) { comp in
                    HStack {
                        Circle()
                            .fill(comp.isOperational ? .green : .red)
                            .frame(width: 6, height: 6)
                        Text(comp.name)
                            .font(.subheadline)
                        Spacer()
                        Text(comp.statusCN)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("服务状态未拉取")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var serviceStatusColor: Color {
        guard let s = store.report.serviceStatus else { return .secondary }
        return s.isHealthy ? .green : .red
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if let fetchedAt = store.report.fetchedAt as Date?, fetchedAt > .distantPast {
                Text("最后更新: \(fetchedAt, formatter: Self.relativeFormatter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("尚未拉取")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("打开原网页") {
                if let url = URL(string: "https://ip.net.coffee/claude/") {
                    NSWorkspace.shared.open(url)
                }
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func parseErrorBanner(_ msg: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text("部分数据拉取失败").font(.subheadline.bold())
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
}

// MARK: - IPCard

private struct IPCard: View {
    let title: String
    let icon: String
    let ip: String?
    let geo: String?
    let asn: String?
    let isp: String?
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(accent)
                Text(title)
                    .font(.headline)
                Spacer()
                if let ip {
                    Text(ip)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            if let geo, !geo.isEmpty {
                Label(geo, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                if let asn {
                    Label(asn, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let isp {
                    Label(isp, systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if ip == nil {
                Text("未获取")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
        .environmentObject(ReportStore())
}
