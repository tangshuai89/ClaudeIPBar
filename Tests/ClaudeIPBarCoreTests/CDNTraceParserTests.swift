import XCTest
@testable import ClaudeIPBarCore

final class CDNTraceParserTests: XCTestCase {

    func testParseRealTrace() throws {
        let sample = """
        fl=965f56
        h=1.1.1.1
        ip=103.175.16.100
        ts=1789091168.000
        visit_scheme=https
        uag=curl/8.7.1
        colo=SIN
        sliver=none
        http=http/2
        loc=MY
        tls=TLSv1.3
        sni=off
        warp=off
        gateway=off
        rbi=off
        kex=X25519
        """
        let trace = CDNTraceParser.parse(sample)
        XCTAssertNotNil(trace)
        XCTAssertEqual(trace?.ip, "103.175.16.100")
        XCTAssertEqual(trace?.host, "1.1.1.1")
        XCTAssertEqual(trace?.colo, "SIN")
        XCTAssertEqual(trace?.loc, "MY")
        XCTAssertEqual(trace?.uag, "curl/8.7.1")
    }

    func testParseClaudeTrace() throws {
        let sample = """
        fl=965f56
        h=claude.ai
        ip=103.175.16.100
        ts=1789091168.000
        visit_scheme=https
        uag=curl/8.7.1
        colo=SIN
        loc=MY
        """
        let trace = CDNTraceParser.parse(sample)
        XCTAssertEqual(trace?.host, "claude.ai")
        XCTAssertEqual(trace?.ip, "103.175.16.100")
    }

    func testParseEmptyReturnsNil() {
        XCTAssertNil(CDNTraceParser.parse(""))
    }

    func testParseMissingIPReturnsNil() {
        let sample = "h=1.1.1.1\ncolo=SIN"
        XCTAssertNil(CDNTraceParser.parse(sample))
    }

    func testParseTrimsWhitespace() {
        let sample = "  ip = 1.2.3.4  \ncolo=SIN"
        let trace = CDNTraceParser.parse(sample)
        XCTAssertEqual(trace?.ip, "1.2.3.4")
    }
}
