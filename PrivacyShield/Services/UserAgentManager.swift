import Foundation
import UIKit

class UserAgentManager {
    static let shared = UserAgentManager()

    private let userAgentKey = "privacyshield_user_agent"

    /// Returns a stable, realistic Safari User-Agent string
    /// Generated once and persisted so LinkedIn always sees the same device
    var stableUserAgent: String {
        if let saved = UserDefaults.standard.string(forKey: userAgentKey) {
            return saved
        }
        let generated = generateRealisticUserAgent()
        UserDefaults.standard.set(generated, forKey: userAgentKey)
        return generated
    }

    /// Regenerate the User-Agent (use sparingly — only when needed)
    func regenerateUserAgent() -> String {
        let generated = generateRealisticUserAgent()
        UserDefaults.standard.set(generated, forKey: userAgentKey)
        return generated
    }

    private func generateRealisticUserAgent() -> String {
        // Realistic Safari on iPhone User-Agent strings
        // Format: CPU version uses underscores, Version/ uses dots with full version
        let variants: [(cpu: String, version: String)] = [
            ("17_5_1", "17.5.1"),
            ("17_6",   "17.6"),
            ("18_0",   "18.0"),
            ("18_1",   "18.1"),
        ]

        let v = variants.randomElement()!
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(v.cpu) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(v.version) Mobile/15E148 Safari/604.1"
    }
}
