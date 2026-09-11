import Foundation

/// Trust Score 风险等级
public enum TrustLevel: String, Codable, Equatable, Sendable, CaseIterable {
    case high      // ≥ 70
    case medium    // 50-69
    case low       // < 50
    case unknown

    public init(score: Int?) {
        guard let s = score else { self = .unknown; return }
        if s >= 70 { self = .high }
        else if s >= 50 { self = .medium }
        else { self = .low }
    }

    public var displayName: String {
        switch self {
        case .high: return "安全"
        case .medium: return "一般"
        case .low: return "高风险"
        case .unknown: return "未知"
        }
    }
}

/// IP 报告核心数据模型
public struct IPReport: Codable, Equatable, Sendable {
    public let fetchedAt: Date

    // MARK: 出口 IP
    public let defaultExitIP: String?
    public let defaultExitGeo: String?
    public let cloudflareExitIP: String?
    public let cloudflareExitGeo: String?

    // MARK: 风险画像
    public let trustScore: Int?
    public let isResidential: Bool?
    public let isDatacenter: Bool?
    public let isMobile: Bool?
    public let isTor: Bool?
    public let isHighRisk: Bool?
    public let isVPN: Bool?
    public let isProxy: Bool?
    public let isPublicProxy: Bool?
    public let isWebProxy: Bool?
    public let isSearchEngineBot: Bool?

    // MARK: 网络信息
    public let asn: String?
    public let isp: String?
    public let organization: String?
    public let country: String?
    public let countryCode: String?
    public let region: String?
    public let city: String?
    public let timezone: String?

    // MARK: 服务状态
    public let serviceStatus: ClaudeServiceStatus?

    // MARK: 错误
    public let parseError: String?
    public let isStale: Bool

    public init(
        fetchedAt: Date,
        defaultExitIP: String? = nil,
        defaultExitGeo: String? = nil,
        cloudflareExitIP: String? = nil,
        cloudflareExitGeo: String? = nil,
        trustScore: Int? = nil,
        isResidential: Bool? = nil,
        isDatacenter: Bool? = nil,
        isMobile: Bool? = nil,
        isTor: Bool? = nil,
        isHighRisk: Bool? = nil,
        isVPN: Bool? = nil,
        isProxy: Bool? = nil,
        isPublicProxy: Bool? = nil,
        isWebProxy: Bool? = nil,
        isSearchEngineBot: Bool? = nil,
        asn: String? = nil,
        isp: String? = nil,
        organization: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        region: String? = nil,
        city: String? = nil,
        timezone: String? = nil,
        serviceStatus: ClaudeServiceStatus? = nil,
        parseError: String? = nil,
        isStale: Bool = false
    ) {
        self.fetchedAt = fetchedAt
        self.defaultExitIP = defaultExitIP
        self.defaultExitGeo = defaultExitGeo
        self.cloudflareExitIP = cloudflareExitIP
        self.cloudflareExitGeo = cloudflareExitGeo
        self.trustScore = trustScore
        self.isResidential = isResidential
        self.isDatacenter = isDatacenter
        self.isMobile = isMobile
        self.isTor = isTor
        self.isHighRisk = isHighRisk
        self.isVPN = isVPN
        self.isProxy = isProxy
        self.isPublicProxy = isPublicProxy
        self.isWebProxy = isWebProxy
        self.isSearchEngineBot = isSearchEngineBot
        self.asn = asn
        self.isp = isp
        self.organization = organization
        self.country = country
        self.countryCode = countryCode
        self.region = region
        self.city = city
        self.timezone = timezone
        self.serviceStatus = serviceStatus
        self.parseError = parseError
        self.isStale = isStale
    }

    public var trustLevel: TrustLevel {
        TrustLevel(score: trustScore)
    }

    public var hasParseError: Bool {
        parseError != nil
    }

    /// 是否所有关键字段都缺失（解析完全失败）
    public var isCompletelyFailed: Bool {
        defaultExitIP == nil && trustScore == nil && asn == nil
    }
}

extension IPReport {
    /// 空 report（首次启动 / 解析完全失败兜底）
    public static let empty = IPReport(fetchedAt: .distantPast, parseError: "暂无数据")
}
