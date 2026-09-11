import XCTest
@testable import ClaudeIPBarCore

final class IPPollutionFetcherIntegrationTests: XCTestCase {

    /// 仅在 CI 或显式开启时跑（环境变量 CLAUDEIPBAR_LIVE=1）
    func testLiveFetch() async throws {
        guard ProcessInfo.processInfo.environment["CLAUDEIPBAR_LIVE"] == "1" else {
            throw XCTSkip("Set CLAUDEIPBAR_LIVE=1 to run live network tests")
        }
        let fetcher = IPPollutionFetcher()
        let report = await fetcher.fetch()
        XCTAssertNotNil(report.defaultExitIP, "真实请求应能拿到 IP")

        // 打印结构化数据（demo 用途）
        print("================ ClaudeIPBar Live Report ================")
        print(String(format: "fetchedAt:        %@", ISO8601DateFormatter().string(from: report.fetchedAt)))
        print("defaultExitIP:    \(report.defaultExitIP ?? "nil")")
        print("defaultExitGeo:   \(report.defaultExitGeo ?? "nil")")
        print("cloudflareExitIP: \(report.cloudflareExitIP ?? "nil")")
        print("cloudflareExitGeo:\(report.cloudflareExitGeo ?? "nil")")
        print("asn:              \(report.asn ?? "nil")")
        print("isp:              \(report.isp ?? "nil")")
        print("country:          \(report.country ?? "nil")")
        print("region:           \(report.region ?? "nil")")
        print("city:             \(report.city ?? "nil")")
        print("timezone:         \(report.timezone ?? "nil")")
        if let s = report.serviceStatus {
            print("---")
            print("claude:           \(s.overall) [\(s.overallIndicator)]")
            for c in s.components {
                print("  • \(c.name) → \(c.statusCN)")
            }
        }
        if let err = report.parseError {
            print("parseError:       \(err)")
        }
        print("==========================================================")
    }
}
