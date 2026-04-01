import Foundation
import SwiftUI

class AccountHealthScore: ObservableObject {
    static let shared = AccountHealthScore()

    @Published var score: Int = 100
    @Published var factors: [HealthFactor] = []

    private var activityTimestamps: [Date] = []
    private let maxActionsPerMinute = 10

    struct HealthFactor: Identifiable {
        let id = UUID()
        let name: String
        let impact: Int // negative = bad
        let icon: String
        let status: Status

        enum Status {
            case good, warning, danger
        }
    }

    var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 50 { return .yellow }
        return .red
    }

    var scoreEmoji: String {
        if score >= 80 { return "🟢" }
        if score >= 50 { return "🟡" }
        return "🔴"
    }

    var recommendation: String {
        if score >= 80 { return "Аккаунт в безопасности. Продолжайте в том же темпе." }
        if score >= 50 { return "Будьте осторожны. Замедлите активность." }
        return "Высокий риск блокировки! Прекратите действия на 1-2 часа."
    }

    func recordActivity() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.activityTimestamps.append(Date())
            // Keep only last 10 minutes
            let tenMinutesAgo = Date().addingTimeInterval(-600)
            self.activityTimestamps = self.activityTimestamps.filter { $0 > tenMinutesAgo }
            self.recalculateScore()
        }
    }

    func recalculateScore() {
        var newScore = 100
        var newFactors: [HealthFactor] = []

        // Factor 1: Activity rate
        let recentActions = activityTimestamps.filter {
            $0 > Date().addingTimeInterval(-60)
        }.count

        if recentActions > maxActionsPerMinute {
            let penalty = (recentActions - maxActionsPerMinute) * 5
            newScore -= penalty
            newFactors.append(HealthFactor(
                name: "Высокая частота действий",
                impact: -penalty,
                icon: "bolt.fill",
                status: .danger
            ))
        } else {
            newFactors.append(HealthFactor(
                name: "Нормальная частота действий",
                impact: 0,
                icon: "bolt.fill",
                status: .good
            ))
        }

        // Factor 2: Rate limits proximity
        let monitor = RateLimitMonitor.shared
        let profileProgress = monitor.progress(for: .profileViews)
        if profileProgress > 0.9 {
            newScore -= 25
            newFactors.append(HealthFactor(
                name: "Лимит просмотров почти исчерпан",
                impact: -25,
                icon: "person.crop.circle",
                status: .danger
            ))
        } else if profileProgress > 0.7 {
            newScore -= 10
            newFactors.append(HealthFactor(
                name: "Приближение к лимиту просмотров",
                impact: -10,
                icon: "person.crop.circle",
                status: .warning
            ))
        }

        let connProgress = monitor.progress(for: .connectionRequests)
        if connProgress > 0.9 {
            newScore -= 30
            newFactors.append(HealthFactor(
                name: "Лимит приглашений почти исчерпан",
                impact: -30,
                icon: "person.badge.plus",
                status: .danger
            ))
        } else if connProgress > 0.7 {
            newScore -= 15
            newFactors.append(HealthFactor(
                name: "Приближение к лимиту приглашений",
                impact: -15,
                icon: "person.badge.plus",
                status: .warning
            ))
        }

        // Factor 3: IP stability
        let antiBlock = AntiBlockService.shared
        if antiBlock.ipChanged {
            newScore -= 20
            newFactors.append(HealthFactor(
                name: "IP адрес изменился",
                impact: -20,
                icon: "wifi.exclamationmark",
                status: .danger
            ))
        } else {
            newFactors.append(HealthFactor(
                name: "Стабильный IP адрес",
                impact: 0,
                icon: "wifi",
                status: .good
            ))
        }

        // Factor 4: Session age
        let sessionStart = UserDefaults.standard.object(forKey: "privacyshield_session_start") as? Date ?? Date()
        let sessionHours = Date().timeIntervalSince(sessionStart) / 3600
        if sessionHours > 4 {
            newScore -= 10
            newFactors.append(HealthFactor(
                name: "Долгая сессия (>\(Int(sessionHours))ч)",
                impact: -10,
                icon: "clock.fill",
                status: .warning
            ))
        }

        // Factor 5: Warm-up mode
        if SettingsManager.shared.warmUpMode {
            newFactors.append(HealthFactor(
                name: "Warm-up режим активен (день \(monitor.warmUpDay)/7)",
                impact: 0,
                icon: "flame.fill",
                status: .good
            ))
        }

        // Already on main thread (called from recordActivity's DispatchQueue.main.async)
        self.score = max(0, min(100, newScore))
        self.factors = newFactors
    }
}
