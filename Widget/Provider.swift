import WidgetKit
import SwiftUI
import ClaudeIPBarCore

struct IPReportProvider: TimelineProvider {

    func placeholder(in context: Context) -> IPReportEntry {
        IPReportEntry(date: Date(), report: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (IPReportEntry) -> Void) {
        let report = AppGroupDataStore.shared.loadReport() ?? .placeholder
        completion(IPReportEntry(date: Date(), report: report))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IPReportEntry>) -> Void) {
        let report = AppGroupDataStore.shared.loadReport() ?? .placeholder
        let now = Date()

        // 下一个 entry 时间：min(refreshInterval, 30 min)
        let intervalMin = AppGroupDataStore.shared.refreshIntervalMinutes
        let nextDate = now.addingTimeInterval(TimeInterval(intervalMin * 60))

        // 30 分钟后再刷一次（兜底，防止单次 timeline 失效）
        let policyDate = now.addingTimeInterval(30 * 60)

        let entry = IPReportEntry(date: nextDate, report: report)
        let policy: TimelineReloadPolicy = .after(policyDate)

        AppLog.widget.info("Timeline: next=\(nextDate, privacy: .public) policy=\(policyDate, privacy: .public)")
        completion(Timeline(entries: [entry], policy: policy))
    }
}

extension IPReport {
    /// Widget 快照用占位数据
    static let placeholder: IPReport = IPReport(
        fetchedAt: Date(),
        defaultExitIP: "103.175.16.100",
        defaultExitGeo: "Cyberjaya, Selangor, MY",
        cloudflareExitIP: "103.175.16.100",
        cloudflareExitGeo: "Cyberjaya, Selangor, MY",
        trustScore: nil,
        asn: "AS55720",
        isp: "Gigabit Hosting",
        country: "MY",
        countryCode: "MY",
        region: "Selangor",
        city: "Cyberjaya",
        timezone: "Asia/Kuala_Lumpur",
        serviceStatus: ClaudeServiceStatus(
            overall: "operational",
            overallIndicator: "operational",
            components: [
                Component(name: "claude.ai", status: "operational", statusCN: "正常运行"),
                Component(name: "Claude API", status: "operational", statusCN: "正常运行")
            ],
            fetchedAt: Date()
        )
    )
}
