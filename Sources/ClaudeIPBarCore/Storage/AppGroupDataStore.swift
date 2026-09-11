import Foundation

/// App Group 共享数据读写
public final class AppGroupDataStore {

    public static let shared = AppGroupDataStore()

    private let defaults: UserDefaults
    private let fileManager: FileManager

    public init(
        suiteName: String = AppGroup.identifier,
        fileManager: FileManager = .default
    ) {
        // 在 SPM 测试环境下可能没有 App Group entitlement，fallback 到 .standard
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.fileManager = fileManager
    }

    // MARK: - Keys

    private enum Key {
        static let report = "currentReport"
        static let lastFetchedAt = "lastFetchedAt"
        static let refreshIntervalMinutes = "refreshIntervalMinutes"
    }

    // MARK: - Report

    public func saveReport(_ report: IPReport) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            defaults.set(data, forKey: Key.report)
            defaults.set(report.fetchedAt.timeIntervalSince1970, forKey: Key.lastFetchedAt)
            AppLog.store.info("Saved report: trustScore=\(report.trustScore ?? -1, privacy: .public)")
        } catch {
            AppLog.store.error("Failed to save report: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func loadReport() -> IPReport? {
        guard let data = defaults.data(forKey: Key.report) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var report = try decoder.decode(IPReport.self, from: data)
            // 加载时判断是否 stale（>2h 视为过期）
            if Date().timeIntervalSince(report.fetchedAt) > 2 * 3600 {
                report = IPReport(
                    fetchedAt: report.fetchedAt,
                    defaultExitIP: report.defaultExitIP,
                    defaultExitGeo: report.defaultExitGeo,
                    cloudflareExitIP: report.cloudflareExitIP,
                    cloudflareExitGeo: report.cloudflareExitGeo,
                    trustScore: report.trustScore,
                    isResidential: report.isResidential,
                    isDatacenter: report.isDatacenter,
                    isMobile: report.isMobile,
                    isTor: report.isTor,
                    isHighRisk: report.isHighRisk,
                    isVPN: report.isVPN,
                    isProxy: report.isProxy,
                    isPublicProxy: report.isPublicProxy,
                    isWebProxy: report.isWebProxy,
                    isSearchEngineBot: report.isSearchEngineBot,
                    asn: report.asn,
                    isp: report.isp,
                    organization: report.organization,
                    country: report.country,
                    countryCode: report.countryCode,
                    region: report.region,
                    city: report.city,
                    timezone: report.timezone,
                    serviceStatus: report.serviceStatus,
                    parseError: report.parseError,
                    isStale: true
                )
            }
            return report
        } catch {
            AppLog.store.error("Failed to load report: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    public var lastFetchedAt: Date? {
        let interval = defaults.double(forKey: Key.lastFetchedAt)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    // MARK: - Settings

    public var refreshIntervalMinutes: Int {
        get {
            let v = defaults.integer(forKey: Key.refreshIntervalMinutes)
            return v == 0 ? AppGroup.defaultRefreshIntervalMinutes : v
        }
        set {
            let clamped = max(AppGroup.minRefreshIntervalMinutes, min(AppGroup.maxRefreshIntervalMinutes, newValue))
            defaults.set(clamped, forKey: Key.refreshIntervalMinutes)
        }
    }
}
