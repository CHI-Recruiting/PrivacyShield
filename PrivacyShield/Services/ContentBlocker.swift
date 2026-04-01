import Foundation
import WebKit

class ContentBlocker {
    static let shared = ContentBlocker()

    private var contentRuleList: WKContentRuleList?

    func compileBlockList(completion: @escaping (WKContentRuleList?) -> Void) {
        guard let url = Bundle.main.url(forResource: "blocklist", withExtension: "json"),
              let jsonString = try? String(contentsOf: url) else {
            completion(nil)
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "PrivacyShieldBlockList",
            encodedContentRuleList: jsonString
        ) { [weak self] ruleList, error in
            if let error = error {
                print("[PrivacyShield] Failed to compile block list: \(error)")
            }
            self?.contentRuleList = ruleList
            completion(ruleList)
        }
    }

    func apply(to configuration: WKWebViewConfiguration) {
        if let ruleList = contentRuleList {
            configuration.userContentController.add(ruleList)
        }
    }

    /// Injects privacy JavaScript files based on user settings.
    /// privacy_shield.js is the unified XHR/fetch interceptor — always injected but with
    /// settings-based flags so it can skip categories at runtime.
    /// Other scripts (sendBeacon, WebSocket, canvas) are conditionally injected.
    func injectPrivacyScripts(into userContentController: WKUserContentController, settings: SettingsManager) {
        // Build settings flags for the unified interceptor
        let settingsJS = """
        window.__privacyShieldSettings = {
            blockReadReceipts: \(settings.blockReadReceipts),
            blockTypingIndicator: \(settings.blockTypingIndicator),
            blockSearchTracking: \(settings.blockSearchTracking),
            stealthMode: \(settings.stealthMode),
            cleanLinks: \(settings.cleanLinks)
        };
        """
        let settingsScript = WKUserScript(
            source: settingsJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(settingsScript)

        // Always inject unified interceptor (it reads settings flags internally)
        injectScript(named: "privacy_shield", into: userContentController)

        // Conditionally inject stealth browsing (sendBeacon, canvas, battery)
        if settings.stealthMode {
            injectScript(named: "stealth_browsing", into: userContentController)
        }

        // Conditionally inject message privacy (WebSocket blocking)
        if settings.blockReadReceipts || settings.blockTypingIndicator {
            injectScript(named: "message_privacy", into: userContentController)
        }
    }

    private func injectScript(named fileName: String, into userContentController: WKUserContentController) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "js"),
              let source = try? String(contentsOf: url) else { return }
        let script = WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(script)
    }

    /// Builds a comprehensive content rule list JSON string for additional dynamic rules
    func buildDynamicRules(for level: BlockingLevel) -> String {
        var rules: [[String: Any]] = []

        // Always block known trackers
        let alwaysBlock = [
            "px\\.ads\\.linkedin\\.com",
            "snap\\.licdn\\.com",
            "dc\\.ads\\.linkedin\\.com",
            "ads\\.linkedin\\.com",
            "tr\\.lnkd\\.in"
        ]

        for pattern in alwaysBlock {
            rules.append([
                "trigger": ["url-filter": pattern],
                "action": ["type": "block"]
            ])
        }

        if level == .strict || level == .paranoid {
            // Block third-party analytics
            let thirdParty = [
                "google-analytics\\.com",
                "googletagmanager\\.com",
                "facebook\\.com",
                "doubleclick\\.net"
            ]
            for pattern in thirdParty {
                rules.append([
                    "trigger": ["url-filter": pattern],
                    "action": ["type": "block"]
                ])
            }
        }

        if level == .paranoid {
            // Block all third-party requests
            rules.append([
                "trigger": [
                    "url-filter": ".*",
                    "unless-domain": ["*linkedin.com", "*licdn.com"]
                ],
                "action": ["type": "block"]
            ])
        }

        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }
}

enum BlockingLevel: String, CaseIterable {
    case soft = "Мягкий"
    case strict = "Жёсткий"
    case paranoid = "Параноидальный"

    var description: String {
        switch self {
        case .soft: return "Блокирует только трекеры LinkedIn"
        case .strict: return "Блокирует все трекеры + сторонние скрипты"
        case .paranoid: return "Блокирует всё кроме LinkedIn. Максимальная защита"
        }
    }
}
