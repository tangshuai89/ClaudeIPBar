import Foundation

/// 顶层 fetcher：组合 4 个数据源（默认 trace / CF trace / ipinfo / status.json）→ IPReport
public struct IPPollutionFetcher {

    public let session: URLSession
    public let ipInfo: IPInfoClient
    public let statusURL: URL

    public init(
        session: URLSession = .shared,
        ipInfo: IPInfoClient = IPInfoClient(),
        statusURL: URL = URL(string: "https://ip.net.coffee/claude/status.json")!
    ) {
        self.session = session
        self.ipInfo = ipInfo
        self.statusURL = statusURL
    }

    public enum FetchError: Error, LocalizedError {
        case defaultTraceUnavailable
        case cfTraceUnavailable
        case serviceStatus(String)

        public var errorDescription: String? {
            switch self {
            case .defaultTraceUnavailable: return "默认出口 IP 拉取失败"
            case .cfTraceUnavailable: return "Cloudflare 出口 IP 拉取失败"
            case .serviceStatus(let s): return "服务状态拉取失败: \(s)"
            }
        }
    }

    /// 主入口：拉 4 个数据源 → 拼装 IPReport
    public func fetch() async -> IPReport {
        let now = Date()
        AppLog.fetcher.info("Starting fetch...")

        async let defaultTraceTask: CDNTrace? = fetchTrace("https://1.1.1.1/cdn-cgi/trace", label: "default")
        async let cfTraceTask: CDNTrace? = fetchTrace("https://claude.ai/cdn-cgi/trace", label: "cf")
        async let statusTask: Result<ClaudeServiceStatus, Error> = fetchServiceStatus()

        let defaultTrace = await defaultTraceTask
        let cfTrace = await cfTraceTask
        let statusResult = await statusTask

        // 任一 trace 失败 → 仍继续，但 parseError 标记
        var parseError: String?
        if defaultTrace == nil && cfTrace == nil {
            return IPReport(
                fetchedAt: now,
                parseError: "无法获取任何出口 IP",
                isStale: true
            )
        }
        if defaultTrace == nil {
            parseError = "默认出口 IP 拉取失败"
        }
        if cfTrace == nil {
            parseError = (parseError ?? "") + (parseError == nil ? "" : "；") + "CF 出口 IP 拉取失败"
        }

        // IPinfo（两个 IP 各自查，并行）
        async let defaultInfoTask = fetchIPInfoSafe(ip: defaultTrace?.ip)
        async let cfInfoTask = fetchIPInfoSafe(ip: cfTrace?.ip)
        let (defaultInfo, cfInfo) = await (defaultInfoTask, cfInfoTask)

        // 拼装
        let defaultIP = defaultTrace?.ip
        let defaultGeo = defaultInfo?.shortGeo
        let defaultAsn = defaultInfo?.asn
        let defaultIsp = defaultInfo?.isp
        let defaultCountry = defaultInfo?.countryName ?? defaultInfo?.country
        let defaultRegion = defaultInfo?.region
        let defaultCity = defaultInfo?.city
        let defaultTimezone = defaultInfo?.timezone

        let cfIP = cfTrace?.ip
        let cfGeo = cfInfo?.shortGeo
        let cfAsn = cfInfo?.asn
        let cfIsp = cfInfo?.isp

        // Service status
        let serviceStatus: ClaudeServiceStatus?
        switch statusResult {
        case .success(let s): serviceStatus = s
        case .failure(let e):
            serviceStatus = nil
            AppLog.fetcher.warning("Service status failed: \(e.localizedDescription, privacy: .public)")
        }

        let report = IPReport(
            fetchedAt: now,
            defaultExitIP: defaultIP,
            defaultExitGeo: defaultGeo,
            cloudflareExitIP: cfIP,
            cloudflareExitGeo: cfGeo,
            trustScore: nil,           // 不算（需要 key）
            isResidential: nil,
            isDatacenter: nil,
            isMobile: nil,
            isTor: nil,
            isHighRisk: nil,
            isVPN: nil,
            isProxy: nil,
            isPublicProxy: nil,
            isWebProxy: nil,
            isSearchEngineBot: nil,
            asn: defaultAsn,
            isp: defaultIsp,
            organization: defaultInfo?.org,
            country: defaultInfo?.country,           // 2-letter code
            countryCode: defaultInfo?.country,       // 2-letter code
            region: defaultRegion,
            city: defaultCity,
            timezone: defaultTimezone,
            serviceStatus: serviceStatus,
            parseError: parseError,
            isStale: parseError != nil
        )
        AppLog.fetcher.info("Fetch done: defaultIP=\(defaultIP ?? "nil", privacy: .public) cfIP=\(cfIP ?? "nil", privacy: .public)")
        return report
    }

    // MARK: - Private helpers

    private func fetchTrace(_ urlString: String, label: String) async -> CDNTrace? {
        guard let url = URL(string: urlString) else { return nil }
        var req = URLRequest(url: url)
        req.setValue("ClaudeIPBar/1.0", forHTTPHeaderField: "User-Agent")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 8
        do {
            let (data, _) = try await session.data(for: req)
            guard let text = String(data: data, encoding: .utf8) else { return nil }
            return CDNTraceParser.parse(text)
        } catch {
            AppLog.fetcher.warning("\(label, privacy: .public) trace failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func fetchIPInfoSafe(ip: String?) async -> IPInfo? {
        guard let ip, !ip.isEmpty else { return nil }
        do {
            return try await ipInfo.fetch(ip: ip)
        } catch {
            AppLog.fetcher.warning("ipinfo \(ip, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func fetchServiceStatus() async -> Result<ClaudeServiceStatus, Error> {
        var req = URLRequest(url: statusURL)
        req.setValue("ClaudeIPBar/1.0", forHTTPHeaderField: "User-Agent")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return .failure(FetchError.serviceStatus("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"))
            }
            struct Wire: Decodable {
                let overall: String
                let overall_indicator: String
                let components: [WireComp]
            }
            struct WireComp: Decodable {
                let name: String
                let status: String
                let status_cn: String
            }
            let wire = try JSONDecoder().decode(Wire.self, from: data)
            return .success(ClaudeServiceStatus(
                overall: wire.overall,
                overallIndicator: wire.overall_indicator,
                components: wire.components.map {
                    Component(name: $0.name, status: $0.status, statusCN: $0.status_cn)
                },
                fetchedAt: Date()
            ))
        } catch {
            return .failure(error)
        }
    }
}
