import SwiftUI
import ClaudeIPBarCore

struct LargeWidgetView: View {
    let report: IPReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部：默认 + CF 双 IP
            HStack(alignment: .top, spacing: 12) {
                ipBlock(
                    title: "默认出口",
                    icon: "globe",
                    color: .blue,
                    ip: report.defaultExitIP,
                    geo: report.defaultExitGeo
                )
                ipBlock(
                    title: "Cloudflare",
                    icon: "cloud",
                    color: .orange,
                    ip: report.cloudflareExitIP,
                    geo: report.cloudflareExitGeo
                )
            }

            Divider()

            // ASN / ISP / 时区
            VStack(alignment: .leading, spacing: 4) {
                if let asn = report.asn {
                    detailRow("building.2", "ASN", asn)
                }
                if let isp = report.isp {
                    detailRow("antenna.radiowaves.left.and.right", "ISP", isp)
                }
                if let tz = report.timezone {
                    detailRow("clock", "时区", tz)
                }
                if let city = report.city, let region = report.region {
                    detailRow("mappin.and.ellipse", "位置", "\(city), \(region)")
                }
            }

            Divider()

            // Claude 服务状态
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(serviceColor)
                    Text("Claude 服务")
                        .font(.caption.bold())
                    Spacer()
                    if let s = report.serviceStatus {
                        Text(s.displayOverall)
                            .font(.caption2)
                            .foregroundStyle(serviceColor)
                    }
                }
                if let s = report.serviceStatus {
                    ForEach(s.components, id: \.name) { comp in
                        HStack {
                            Circle()
                                .fill(comp.isOperational ? .green : .red)
                                .frame(width: 5, height: 5)
                            Text(comp.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text(comp.statusCN)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // 底部时间
            HStack {
                if report.isStale {
                    Label("数据过期", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("更新于 \(formatTime(report.fetchedAt))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("点击查看 trust score →")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func ipBlock(title: String, icon: String, color: Color, ip: String?, geo: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
            }
            Text(ip ?? "—")
                .font(.system(.body, design: .monospaced).bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let geo {
                Text(geo)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detailRow(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 12)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.bold())
                .lineLimit(1)
        }
    }

    private var serviceColor: Color {
        guard let s = report.serviceStatus else { return .secondary }
        return s.isHealthy ? .green : .red
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
