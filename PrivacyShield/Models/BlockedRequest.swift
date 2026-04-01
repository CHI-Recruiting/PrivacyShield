import Foundation

struct BlockedRequest: Identifiable, Codable {
    let id: UUID
    let url: String
    let category: String
    let timestamp: Date

    init(url: String, category: String, timestamp: Date) {
        self.id = UUID()
        self.url = url
        self.category = category
        self.timestamp = timestamp
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "\(Int(interval))с назад" }
        if interval < 3600 { return "\(Int(interval / 60))м назад" }
        if interval < 86400 { return "\(Int(interval / 3600))ч назад" }
        return "\(Int(interval / 86400))д назад"
    }
}
