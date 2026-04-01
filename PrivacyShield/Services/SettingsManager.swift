import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var blockingLevel: BlockingLevel {
        didSet { UserDefaults.standard.set(blockingLevel.rawValue, forKey: "ps_blocking_level") }
    }

    @Published var preserveCookies: Bool {
        didSet { UserDefaults.standard.set(preserveCookies, forKey: "ps_preserve_cookies") }
    }

    @Published var warmUpMode: Bool {
        didSet {
            UserDefaults.standard.set(warmUpMode, forKey: "ps_warmup_mode")
            if warmUpMode && UserDefaults.standard.object(forKey: "privacyshield_warmup_start") == nil {
                UserDefaults.standard.set(Date(), forKey: "privacyshield_warmup_start")
            }
        }
    }

    @Published var stealthMode: Bool {
        didSet { UserDefaults.standard.set(stealthMode, forKey: "ps_stealth_mode") }
    }

    @Published var blockReadReceipts: Bool {
        didSet { UserDefaults.standard.set(blockReadReceipts, forKey: "ps_block_read_receipts") }
    }

    @Published var blockTypingIndicator: Bool {
        didSet { UserDefaults.standard.set(blockTypingIndicator, forKey: "ps_block_typing") }
    }

    @Published var cleanLinks: Bool {
        didSet { UserDefaults.standard.set(cleanLinks, forKey: "ps_clean_links") }
    }

    @Published var blockSearchTracking: Bool {
        didSet { UserDefaults.standard.set(blockSearchTracking, forKey: "ps_block_search") }
    }

    @Published var autoBackup: Bool {
        didSet { UserDefaults.standard.set(autoBackup, forKey: "ps_auto_backup") }
    }

    @Published var showBlockNotifications: Bool {
        didSet { UserDefaults.standard.set(showBlockNotifications, forKey: "ps_show_notifications") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.blockingLevel = BlockingLevel(rawValue: defaults.string(forKey: "ps_blocking_level") ?? "") ?? .strict
        self.preserveCookies = defaults.object(forKey: "ps_preserve_cookies") as? Bool ?? true
        self.warmUpMode = defaults.bool(forKey: "ps_warmup_mode")
        self.stealthMode = defaults.object(forKey: "ps_stealth_mode") as? Bool ?? true
        self.blockReadReceipts = defaults.object(forKey: "ps_block_read_receipts") as? Bool ?? true
        self.blockTypingIndicator = defaults.object(forKey: "ps_block_typing") as? Bool ?? true
        self.cleanLinks = defaults.object(forKey: "ps_clean_links") as? Bool ?? true
        self.blockSearchTracking = defaults.object(forKey: "ps_block_search") as? Bool ?? true
        self.autoBackup = defaults.bool(forKey: "ps_auto_backup")
        self.showBlockNotifications = defaults.object(forKey: "ps_show_notifications") as? Bool ?? true
    }
}
