import SwiftUI

struct CachedProfilesView: View {
    @StateObject private var cacheManager = ProfileCacheManager.shared

    var body: some View {
        List {
                if cacheManager.cachedProfiles.isEmpty {
                    ContentUnavailableView(
                        "Нет сохранённых профилей",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Профили сохраняются автоматически при просмотре в режиме «Призрак»")
                    )
                } else {
                    Section {
                        ForEach(cacheManager.cachedProfiles) { profile in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.headline)
                                if !profile.headline.isEmpty {
                                    Text(profile.headline)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                if !profile.company.isEmpty {
                                    Text(profile.company)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                Text(profile.savedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    cacheManager.deleteProfile(profile)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        Text("\(cacheManager.cachedProfiles.count) профилей")
                    }
                }
            }
            .navigationTitle("Кэш профилей")
            .toolbar {
                if !cacheManager.cachedProfiles.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Очистить") {
                            cacheManager.clearCache()
                        }
                        .foregroundColor(.red)
                    }
                }
        }
    }
}
