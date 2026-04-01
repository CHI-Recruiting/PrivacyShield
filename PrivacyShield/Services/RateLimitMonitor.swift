import Foundation
import SwiftUI

class RateLimitMonitor: ObservableObject {
    static let shared = RateLimitMonitor()

    @Published var profileViews: Int = 0
    @Published var connectionRequests: Int = 0
    @Published var messagesSent: Int = 0
    @Published var searches: Int = 0
    @Published var showWarning: Bool = false
    @Published var warningMessage: String = ""

    private let storageKey = "privacyshield_rate_limits"
    private let dateKey = "privacyshield_rate_date"

    var isWarmUpMode: Bool {
        guard SettingsManager.shared.warmUpMode else { return false }
        // Auto-disable warm-up after 7 days
        if warmUpDay >= 7 {
            DispatchQueue.main.async {
                SettingsManager.shared.warmUpMode = false
            }
            return false
        }
        return true
    }

    var warmUpDay: Int {
        let startDate = UserDefaults.standard.object(forKey: "privacyshield_warmup_start") as? Date ?? Date()
        return min(7, (Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0) + 1)
    }

    init() {
        resetIfNewDay()
        loadCounts()
    }

    func recordAction(for url: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let urlString = url.absoluteString.lowercased()

            // Check /search BEFORE /in/ to avoid "/in/search" ambiguity
            if urlString.contains("/search") {
                self.searches += 1
                self.checkLimit(current: self.searches, limit: self.currentLimit(for: .searches), name: "поисков", warningPercent: ActivityLimits.searches.warningAt)
            } else if urlString.contains("/in/") || urlString.contains("/profile/") {
                self.profileViews += 1
                self.checkLimit(current: self.profileViews, limit: self.currentLimit(for: .profileViews), name: "просмотров профилей", warningPercent: ActivityLimits.profileViews.warningAt)
            } else if urlString.contains("/invitation") || urlString.contains("connect") {
                self.connectionRequests += 1
                self.checkLimit(current: self.connectionRequests, limit: self.currentLimit(for: .connectionRequests), name: "приглашений", warningPercent: ActivityLimits.connectionRequests.warningAt)
            } else if urlString.contains("/messaging") || urlString.contains("/msg/") {
                self.messagesSent += 1
                self.checkLimit(current: self.messagesSent, limit: self.currentLimit(for: .messages), name: "сообщений", warningPercent: ActivityLimits.messages.warningAt)
            }

            self.saveCounts()
        }
    }

    enum ActionType {
        case profileViews, connectionRequests, messages, searches
    }

    func currentLimit(for action: ActionType) -> Int {
        if isWarmUpMode {
            let day = warmUpDay
            let schedule = ActivityLimits.WarmUpLimits.schedule
            let index = max(0, day - 1)
            let warmUp = index < schedule.count ? schedule[index] : schedule[schedule.count - 1]

            switch action {
            case .profileViews: return warmUp.profileViews
            case .connectionRequests: return warmUp.connectionRequests
            case .messages: return warmUp.messages
            case .searches: return min(ActivityLimits.searches.dailyMax, warmUp.profileViews)
            }
        }

        switch action {
        case .profileViews: return ActivityLimits.profileViews.dailyMax
        case .connectionRequests: return ActivityLimits.connectionRequests.dailyMax
        case .messages: return ActivityLimits.messages.dailyMax
        case .searches: return ActivityLimits.searches.dailyMax
        }
    }

    func progress(for action: ActionType) -> Double {
        let current: Int
        switch action {
        case .profileViews: current = profileViews
        case .connectionRequests: current = connectionRequests
        case .messages: current = messagesSent
        case .searches: current = searches
        }
        let limit = currentLimit(for: action)
        return min(1.0, Double(current) / Double(limit))
    }

    func progressColor(for action: ActionType) -> Color {
        let p = progress(for: action)
        if p < 0.7 { return .green }
        if p < 0.9 { return .yellow }
        return .red
    }

    private func checkLimit(current: Int, limit: Int, name: String, warningPercent: Int = 70) {
        let warningThreshold = Int(Double(limit) * Double(warningPercent) / 100.0)

        if current >= limit {
            showWarning(message: "⛔️ Лимит \(name) достигнут! (\(current)/\(limit)) Остановитесь!")
        } else if current >= warningThreshold {
            let remaining = limit - current
            showWarning(message: "⚠️ \(name): осталось \(remaining) из \(limit)")
        }
    }

    private func showWarning(message: String) {
        DispatchQueue.main.async {
            self.warningMessage = message
            withAnimation { self.showWarning = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { self.showWarning = false }
            }
        }
    }

    private func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: Date())
        let saved = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        let savedDay = Calendar.current.startOfDay(for: saved)

        if today != savedDay {
            profileViews = 0
            connectionRequests = 0
            messagesSent = 0
            searches = 0
            UserDefaults.standard.set(today, forKey: dateKey)
            saveCounts()
        }
    }

    private func loadCounts() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            profileViews = counts["profileViews"] ?? 0
            connectionRequests = counts["connectionRequests"] ?? 0
            messagesSent = counts["messagesSent"] ?? 0
            searches = counts["searches"] ?? 0
        }
    }

    private func saveCounts() {
        let counts: [String: Int] = [
            "profileViews": profileViews,
            "connectionRequests": connectionRequests,
            "messagesSent": messagesSent,
            "searches": searches
        ]
        if let data = try? JSONEncoder().encode(counts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
