import Foundation

class ProfileCacheManager: ObservableObject {
    static let shared = ProfileCacheManager()

    @Published var cachedProfiles: [ProfileData] = []

    private let cacheKey = "privacyshield_profile_cache"

    init() {
        loadCache()
    }

    func saveProfile(_ profile: ProfileData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.cachedProfiles.contains(where: { $0.profileUrl == profile.profileUrl }) {
                self.cachedProfiles = self.cachedProfiles.map {
                    $0.profileUrl == profile.profileUrl ? profile : $0
                }
            } else {
                self.cachedProfiles.insert(profile, at: 0)
            }
            self.persistCache()
        }
    }

    func savePDF(data: Data, for profile: ProfileData) {
        let fileName = profile.id.uuidString + ".pdf"
        let url = cacheDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
    }

    func getPDF(for profile: ProfileData) -> Data? {
        let fileName = profile.id.uuidString + ".pdf"
        let url = cacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    func deleteProfile(_ profile: ProfileData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.cachedProfiles.removeAll { $0.id == profile.id }
            let fileName = profile.id.uuidString + ".pdf"
            let url = self.cacheDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
            self.persistCache()
        }
    }

    func clearCache() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.cachedProfiles.removeAll()
            try? FileManager.default.removeItem(at: self.cacheDirectory)
            try? FileManager.default.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
            self.persistCache()
        }
    }

    var totalCacheSize: String {
        let size = cachedProfiles.count
        return "\(size) профилей"
    }

    // MARK: - Private

    private var cacheDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("ProfileCache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func loadCache() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let profiles = try? JSONDecoder().decode([ProfileData].self, from: data) {
            cachedProfiles = profiles
        }
    }

    private func persistCache() {
        if let data = try? JSONEncoder().encode(cachedProfiles) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
