import XCTest
@testable import ClaudeIPBarCore

final class ModelsTests: XCTestCase {

    func testTrustLevelFromScore() {
        XCTAssertEqual(TrustLevel(score: 95).rawValue, "high")
        XCTAssertEqual(TrustLevel(score: 70).rawValue, "high")
        XCTAssertEqual(TrustLevel(score: 69).rawValue, "medium")
        XCTAssertEqual(TrustLevel(score: 50).rawValue, "medium")
        XCTAssertEqual(TrustLevel(score: 49).rawValue, "low")
        XCTAssertEqual(TrustLevel(score: 0).rawValue, "low")
        XCTAssertEqual(TrustLevel(score: nil).rawValue, "unknown")
    }

    func testIPReportRoundTripsThroughJSON() throws {
        // 用整秒时间避免 ISO8601 序列化精度损失
        let original = IPReport(
            fetchedAt: Date(timeIntervalSince1970: 1735689600),  // 2025-01-01 00:00:00 UTC
            defaultExitIP: "1.2.3.4",
            defaultExitGeo: "US · California",
            cloudflareExitIP: "5.6.7.8",
            trustScore: 75,
            isResidential: true,
            asn: "AS13335 Cloudflare",
            isp: "Cloudflare",
            country: "United States",
            countryCode: "US"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(IPReport.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testIPReportCodableWithServiceStatus() throws {
        let status = ClaudeServiceStatus(
            overall: "operational",
            overallIndicator: "operational",
            components: [
                Component(name: "claude.ai", status: "operational", statusCN: "正常运行")
            ],
            fetchedAt: Date()
        )
        let report = IPReport(fetchedAt: Date(), defaultExitIP: "1.2.3.4", serviceStatus: status)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)
        XCTAssertGreaterThan(data.count, 0)
    }
}
