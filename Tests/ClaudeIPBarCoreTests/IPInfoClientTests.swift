import XCTest
@testable import ClaudeIPBarCore

final class IPInfoClientTests: XCTestCase {

    func testParseIPInfo() throws {
        let json = """
        {
          "ip": "103.175.16.100",
          "city": "Cyberjaya",
          "region": "Selangor",
          "country": "MY",
          "loc": "2.9228,101.6572",
          "org": "AS55720 Gigabit Hosting Sdn Bhd",
          "postal": "63100",
          "timezone": "Asia/Kuala_Lumpur"
        }
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.ip, "103.175.16.100")
        XCTAssertEqual(info.city, "Cyberjaya")
        XCTAssertEqual(info.region, "Selangor")
        XCTAssertEqual(info.country, "MY")
        XCTAssertEqual(info.loc, "2.9228,101.6572")
        XCTAssertEqual(info.org, "AS55720 Gigabit Hosting Sdn Bhd")
        XCTAssertEqual(info.postal, "63100")
        XCTAssertEqual(info.timezone, "Asia/Kuala_Lumpur")
    }

    func testASNParsing() throws {
        let json = """
        {"ip": "1.2.3.4", "org": "AS55720 Gigabit Hosting Sdn Bhd"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.asn, "AS55720")
        XCTAssertEqual(info.isp, "Gigabit Hosting Sdn Bhd")
    }

    func testASNParsingWithoutSpace() throws {
        let json = """
        {"ip": "1.2.3.4", "org": "AS15169"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.asn, "AS15169")
        XCTAssertNil(info.isp)
    }

    func testShortGeo() throws {
        let json = """
        {"ip": "1.2.3.4", "city": "Cyberjaya", "region": "Selangor", "country": "MY"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.shortGeo, "Cyberjaya, Selangor, MY")
    }

    func testShortGeoMissingFields() throws {
        let json = """
        {"ip": "1.2.3.4", "country": "MY"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.shortGeo, "MY")
    }

    func testLatLng() throws {
        let json = """
        {"ip": "1.2.3.4", "loc": "2.9228,101.6572"}
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(IPInfo.self, from: json)
        XCTAssertEqual(info.latitude, 2.9228)
        XCTAssertEqual(info.longitude, 101.6572)
    }
}
