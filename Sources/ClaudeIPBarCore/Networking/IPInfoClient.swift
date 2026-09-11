import Foundation

/// ipinfo.io 响应（免费层即可）
public struct IPInfo: Decodable, Equatable, Sendable {
    public let ip: String
    public let city: String?
    public let region: String?
    public let country: String?          // "MY"
    public let countryName: String?      // 未在免费层直出，下面通过 country code 解析
    public let loc: String?              // "lat,lng"
    public let org: String?              // "AS55720 Gigabit Hosting Sdn Bhd"
    public let postal: String?
    public let timezone: String?
    public let hostname: String?
    public let anycast: Bool?

    enum CodingKeys: String, CodingKey {
        case ip, city, region, country, loc, org, postal, timezone, hostname, anycast
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ip = try c.decode(String.self, forKey: .ip)
        city = try c.decodeIfPresent(String.self, forKey: .city)
        region = try c.decodeIfPresent(String.self, forKey: .region)
        country = try c.decodeIfPresent(String.self, forKey: .country)
        loc = try c.decodeIfPresent(String.self, forKey: .loc)
        org = try c.decodeIfPresent(String.self, forKey: .org)
        postal = try c.decodeIfPresent(String.self, forKey: .postal)
        timezone = try c.decodeIfPresent(String.self, forKey: .timezone)
        hostname = try c.decodeIfPresent(String.self, forKey: .hostname)
        anycast = try c.decodeIfPresent(Bool.self, forKey: .anycast)
        countryName = nil  // ipinfo 免费层不直出 country name
    }

    /// "AS55720 Gigabit Hosting Sdn Bhd" → asn = "AS55720", isp = "Gigabit Hosting Sdn Bhd"
    public var asn: String? {
        guard let org else { return nil }
        let comps = org.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        return comps.first.map(String.init)
    }

    public var isp: String? {
        guard let org else { return nil }
        let comps = org.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard comps.count > 1 else { return nil }
        return String(comps[1])
    }

    public var latitude: Double? {
        loc?.split(separator: ",").first.flatMap { Double($0) }
    }

    public var longitude: Double? {
        loc?.split(separator: ",").last.flatMap { Double($0) }
    }

    /// "Cyberjaya, Selangor, MY" 这种短格式
    public var shortGeo: String? {
        var parts: [String] = []
        if let city, !city.isEmpty { parts.append(city) }
        if let region, !region.isEmpty, region != city { parts.append(region) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

public struct IPInfoClient {
    public let baseURL: URL
    public let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://ipinfo.io")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public enum FetchError: Error, LocalizedError {
        case http(Int)
        case empty
        case decode(Error)

        public var errorDescription: String? {
            switch self {
            case .http(let code): return "ipinfo.io HTTP \(code)"
            case .empty: return "ipinfo.io 返回空"
            case .decode(let e): return "ipinfo.io 解析失败: \(e.localizedDescription)"
            }
        }
    }

    public func fetch(ip: String) async throws -> IPInfo {
        let url = baseURL.appendingPathComponent("\(ip)/json")
        var req = URLRequest(url: url)
        req.setValue("ClaudeIPBar/1.0 (https://github.com/blacksweaters/ClaudeIPBar)", forHTTPHeaderField: "User-Agent")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 10
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw FetchError.empty }
        guard (200..<300).contains(http.statusCode) else { throw FetchError.http(http.statusCode) }
        do {
            return try JSONDecoder().decode(IPInfo.self, from: data)
        } catch {
            throw FetchError.decode(error)
        }
    }
}
