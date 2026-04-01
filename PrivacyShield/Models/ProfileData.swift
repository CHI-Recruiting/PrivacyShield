import Foundation

struct ProfileData: Identifiable, Codable {
    let id: UUID
    let name: String
    let headline: String
    let location: String
    let company: String
    let profileUrl: String
    let savedAt: Date

    init(name: String, headline: String = "", location: String = "",
         company: String = "", profileUrl: String = "") {
        self.id = UUID()
        self.name = name
        self.headline = headline
        self.location = location
        self.company = company
        self.profileUrl = profileUrl
        self.savedAt = Date()
    }
}
