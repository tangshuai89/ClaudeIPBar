import Foundation

/// Claude 服务整体状态
public struct ClaudeServiceStatus: Codable, Equatable, Sendable {
    public let overall: String
    public let overallIndicator: String       // "operational" / "minor" / "major" / "critical"
    public let components: [Component]
    public let fetchedAt: Date

    public init(overall: String, overallIndicator: String, components: [Component], fetchedAt: Date) {
        self.overall = overall
        self.overallIndicator = overallIndicator
        self.components = components
        self.fetchedAt = fetchedAt
    }

    public var isHealthy: Bool {
        overallIndicator == "operational"
    }

    /// 中文名（如果 fetch 自 status.json，已含 status_cn）
    public var displayOverall: String {
        components.first(where: { $0.status == overall })?.statusCN ?? overall
    }
}

public struct Component: Codable, Equatable, Sendable {
    public let name: String
    public let status: String
    public let statusCN: String

    public init(name: String, status: String, statusCN: String) {
        self.name = name
        self.status = status
        self.statusCN = statusCN
    }

    public var isOperational: Bool {
        status == "operational"
    }
}
