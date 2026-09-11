import Foundation

/// Cloudflare `cdn-cgi/trace` 响应
/// 文本格式：每行 `key=value`，常见字段：
///   ip=<客户端出口 IP>
///   h=<请求主机，如 claude.ai>
///   colo=<CF 数据中心，如 SIN>
///   loc=<粗略国家，如 MY>
///   uag=<UA>
public struct CDNTrace: Equatable, Sendable {
    public let ip: String
    public let host: String?
    public let colo: String?
    public let loc: String?
    public let ts: String?
    public let uag: String?

    public init(ip: String, host: String?, colo: String?, loc: String?, ts: String?, uag: String?) {
        self.ip = ip
        self.host = host
        self.colo = colo
        self.loc = loc
        self.ts = ts
        self.uag = uag
    }
}

public enum CDNTraceParser {
    public static func parse(_ text: String) -> CDNTrace? {
        var ip: String?
        var host: String?
        var colo: String?
        var loc: String?
        var ts: String?
        var uag: String?
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            switch key {
            case "ip": ip = value
            case "h": host = value
            case "colo": colo = value
            case "loc": loc = value
            case "ts": ts = value
            case "uag": uag = value
            default: break
            }
        }
        guard let ip else { return nil }
        return CDNTrace(ip: ip, host: host, colo: colo, loc: loc, ts: ts, uag: uag)
    }
}
