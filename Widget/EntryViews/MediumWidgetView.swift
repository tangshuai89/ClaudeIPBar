import SwiftUI
import ClaudeIPBarCore

struct MediumWidgetView: View {
    let report: IPReport

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧：默认出口 IP
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    Text("默认")
                        .font(.caption.bold())
                }
                Text(report.defaultExitIP ?? "—")
                    .font(.system(.title3, design: .monospaced).bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let geo = report.defaultExitGeo {
                    Text(geo)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let asn = report.asn {
                    Text(asn)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 右侧：Cloudflare 出口 IP + 服务状态
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "cloud")
                        .foregroundStyle(.orange)
                    Text("CF")
                        .font(.caption.bold())
                    Spacer()
                    if let s = report.serviceStatus {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(s.isHealthy ? .green : .red)
                                .frame(width: 6, height: 6)
                            Text(s.isHealthy ? "正常" : "故障")
                                .font(.caption2)
                                .foregroundStyle(s.isHealthy ? .green : .red)
                        }
                    }
                }
                Text(report.cloudflareExitIP ?? "—")
                    .font(.system(.body, design: .monospaced).bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let geo = report.cloudflareExitGeo {
                    Text(geo)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let s = report.serviceStatus {
                    Text(s.displayOverall)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
    }
}
