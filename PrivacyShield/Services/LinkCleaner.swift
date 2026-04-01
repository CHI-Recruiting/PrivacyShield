import Foundation

struct LinkCleaner {
    /// LinkedIn tracking parameters to remove from URLs
    private static let trackingParams: Set<String> = [
        "trk", "trkInfo", "lipi", "lici", "src",
        "trackingId", "refId", "eBP", "recommendedFlavor",
        "midToken", "midSig", "trkEmail", "connectionOf",
        "orig", "anchorTopic", "contextUrn",
        // General tracking params
        "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term",
        "fbclid", "gclid", "msclkid", "dclid",
        "_ga", "_gl", "mc_cid", "mc_eid"
    ]

    /// Removes tracking parameters from a URL
    static func clean(url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems, !queryItems.isEmpty else {
            return url
        }

        let cleaned = queryItems.filter { item in
            !trackingParams.contains(item.name)
        }

        components.queryItems = cleaned.isEmpty ? nil : cleaned
        return components.url ?? url
    }

    /// Checks if a URL contains tracking parameters
    static func hasTrackingParams(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return false
        }
        return queryItems.contains { trackingParams.contains($0.name) }
    }

    /// Returns the count of tracking parameters found in a URL
    static func trackingParamCount(in url: URL) -> Int {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return 0
        }
        return queryItems.filter { trackingParams.contains($0.name) }.count
    }
}
