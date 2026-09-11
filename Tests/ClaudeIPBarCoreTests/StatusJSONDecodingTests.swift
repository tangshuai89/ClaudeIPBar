import XCTest
@testable import ClaudeIPBarCore

final class StatusJSONDecodingTests: XCTestCase {

    func testDecodeStatusSample() throws {
        let url = try fixtureURL(name: "status", ext: "json")
        let data = try Data(contentsOf: url)
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
        XCTAssertFalse(wire.overall.isEmpty)
        XCTAssertGreaterThan(wire.components.count, 0)
    }

    private func fixtureURL(name: String, ext: String) throws -> URL {
        if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures") {
            return url
        }
        if let url = Bundle.module.url(forResource: name, withExtension: ext) {
            return url
        }
        throw XCTSkip("Fixture not found: \(name).\(ext)")
    }
}
