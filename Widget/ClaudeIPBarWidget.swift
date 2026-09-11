import WidgetKit
import SwiftUI
import ClaudeIPBarCore

@main
struct ClaudeIPBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClaudeIPBarWidget()
    }
}

struct ClaudeIPBarWidget: Widget {
    let kind: String = "ClaudeIPBarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IPReportProvider()) { entry in
            IPReportWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Claude IP")
        .description("显示默认出口 IP、Cloudflare 出口 IP、地理位置、ASN、ISP 与 Claude 服务状态")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct IPReportEntry: TimelineEntry {
    let date: Date
    let report: IPReport
}

struct IPReportWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: IPReportEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(report: entry.report)
        case .systemMedium:
            MediumWidgetView(report: entry.report)
        case .systemLarge:
            LargeWidgetView(report: entry.report)
        default:
            SmallWidgetView(report: entry.report)
        }
    }
}
