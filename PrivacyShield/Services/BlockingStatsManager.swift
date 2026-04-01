import Foundation
import SwiftUI

class BlockingStatsManager: ObservableObject {
    static let shared = BlockingStatsManager()

    @Published var totalBlocked: Int = 0
    @Published var todayBlocked: Int = 0
    @Published var blockedByCategory: [String: Int] = [:]
    @Published var recentBlocked: [BlockedRequest] = []

    private let statsKey = "privacyshield_stats"
    private let todayKey = "privacyshield_today_stats"
    private let todayDateKey = "privacyshield_today_date"

    init() {
        loadStats()
        resetTodayIfNeeded()
    }

    func recordBlocked(url: String, category: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.totalBlocked += 1
            self.todayBlocked += 1
            self.blockedByCategory[category, default: 0] += 1

            let request = BlockedRequest(
                url: url,
                category: category,
                timestamp: Date()
            )
            self.recentBlocked.insert(request, at: 0)
            if self.recentBlocked.count > 100 {
                self.recentBlocked = Array(self.recentBlocked.prefix(100))
            }

            self.saveStats()
        }
    }

    private func loadStats() {
        totalBlocked = UserDefaults.standard.integer(forKey: statsKey)
        todayBlocked = UserDefaults.standard.integer(forKey: todayKey)
        if let data = UserDefaults.standard.data(forKey: "privacyshield_categories"),
           let categories = try? JSONDecoder().decode([String: Int].self, from: data) {
            blockedByCategory = categories
        }
    }

    private func saveStats() {
        UserDefaults.standard.set(totalBlocked, forKey: statsKey)
        UserDefaults.standard.set(todayBlocked, forKey: todayKey)
        UserDefaults.standard.set(
            DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none),
            forKey: todayDateKey
        )
        if let data = try? JSONEncoder().encode(blockedByCategory) {
            UserDefaults.standard.set(data, forKey: "privacyshield_categories")
        }
    }

    private func resetTodayIfNeeded() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let saved = UserDefaults.standard.string(forKey: todayDateKey)
        if saved != today {
            todayBlocked = 0
            saveStats()
        }
    }

    func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "read_receipt": return "Прочитано"
        case "typing_indicator": return "Печатает..."
        case "profile_view": return "Просмотр профиля"
        case "search_analytics": return "Поиск"
        case "beacon": return "Маячок"
        case "impression": return "Показы"
        case "send_beacon": return "Beacon API"
        case "analytics": return "Аналитика"
        case "message_tracking": return "Сообщения"
        case "websocket_tracking": return "WebSocket"
        case "search_history": return "История поиска"
        case "typeahead_tracking": return "Автодополнение"
        case "stealth_fetch": return "Скрытый трекинг"
        case "navigation_block": return "Навигация"
        default: return category
        }
    }
}
