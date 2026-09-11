import SwiftUI
import ClaudeIPBarCore

struct SmallWidgetView: View {
    let report: IPReport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Claude IP")
                    .font(.caption.bold())
                Spacer()
                serviceIndicator
            }
            Spacer(minLength: 2)
            Text(report.defaultExitIP ?? "—")
                .font(.system(.title3, design: .monospaced).bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let geo = report.defaultExitGeo, !geo.isEmpty {
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
            Spacer(minLength: 0)
            if report.isStale || report.parseError != nil {
                staleLabel
            } else {
                Text(fetchedAtText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var serviceIndicator: some View {
        Group {
            if let s = report.serviceStatus {
                Circle()
                    .fill(s.isHealthy ? .green : .red)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var staleLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("过期")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    private var fetchedAtText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: report.fetchedAt, relativeTo: Date())
    }
}
