import Foundation

struct ActivityLimits {
    struct Limit {
        let name: String
        let dailyMax: Int
        let warningAt: Int // Show warning at this percentage
        let icon: String

        var warningThreshold: Int {
            Int(Double(dailyMax) * Double(warningAt) / 100.0)
        }
    }

    static let profileViews = Limit(
        name: "Просмотры профилей",
        dailyMax: 50,
        warningAt: 70,
        icon: "person.crop.circle"
    )

    static let connectionRequests = Limit(
        name: "Приглашения",
        dailyMax: 15,
        warningAt: 60,
        icon: "person.badge.plus"
    )

    static let messages = Limit(
        name: "Сообщения",
        dailyMax: 25,
        warningAt: 75,
        icon: "message.fill"
    )

    static let searches = Limit(
        name: "Поиски",
        dailyMax: 30,
        warningAt: 75,
        icon: "magnifyingglass"
    )

    static let all: [Limit] = [profileViews, connectionRequests, messages, searches]

    // Warm-up mode limits (for new/unblocked accounts)
    struct WarmUpLimits {
        let day: Int
        let profileViews: Int
        let connectionRequests: Int
        let messages: Int

        static let schedule: [WarmUpLimits] = [
            WarmUpLimits(day: 1, profileViews: 5,  connectionRequests: 2,  messages: 3),
            WarmUpLimits(day: 2, profileViews: 10, connectionRequests: 3,  messages: 5),
            WarmUpLimits(day: 3, profileViews: 15, connectionRequests: 5,  messages: 8),
            WarmUpLimits(day: 4, profileViews: 20, connectionRequests: 7,  messages: 12),
            WarmUpLimits(day: 5, profileViews: 30, connectionRequests: 9,  messages: 16),
            WarmUpLimits(day: 6, profileViews: 40, connectionRequests: 12, messages: 20),
            WarmUpLimits(day: 7, profileViews: 50, connectionRequests: 15, messages: 25),
        ]
    }
}
