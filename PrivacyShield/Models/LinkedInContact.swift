import Foundation

struct LinkedInContact: Identifiable, Codable {
    let id: UUID
    let name: String
    let headline: String
    let company: String
    let profileURL: String
    let email: String?
    let savedAt: Date

    init(name: String, headline: String = "", company: String = "",
         profileURL: String = "", email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.headline = headline
        self.company = company
        self.profileURL = profileURL
        self.email = email
        self.savedAt = Date()
    }

    var csvRow: String {
        let fields = [name, headline, company, profileURL, email ?? ""]
        return fields.map { field in
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }.joined(separator: ",")
    }

    static let csvHeader = "\"Name\",\"Headline\",\"Company\",\"Profile URL\",\"Email\""
}

struct BackupRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let contactCount: Int
    let messageCount: Int
    let postCount: Int
    let filePath: String?

    init(contactCount: Int, messageCount: Int = 0, postCount: Int = 0, filePath: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.contactCount = contactCount
        self.messageCount = messageCount
        self.postCount = postCount
        self.filePath = filePath
    }
}
