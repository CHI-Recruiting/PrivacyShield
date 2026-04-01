import SwiftUI

struct PrivacyChecklistView: View {
    @State private var checks = PrivacyCheckItem.allChecks
    @State private var expandedId: UUID?
    @State private var completedTitles: Set<String> = []

    private let storageKey = "privacyshield_checklist_completed"

    var completedCount: Int {
        checks.filter(\.isCompleted).count
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Выполнено")
                    Spacer()
                    Text("\(completedCount)/\(checks.count)")
                        .font(.headline)
                        .foregroundColor(completedCount == checks.count ? .green : .orange)
                }

                ProgressView(value: Double(completedCount), total: Double(checks.count))
                    .tint(completedCount == checks.count ? .green : .orange)
            }

            ForEach(PrivacyCheckItem.Category.allCases, id: \.rawValue) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(checks.indices.filter { checks[$0].category == category }, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button {
                                    checks[index].isCompleted.toggle()
                                    saveCompletedState()
                                } label: {
                                    Image(systemName: checks[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(checks[index].isCompleted ? .green : .secondary)
                                }

                                VStack(alignment: .leading) {
                                    Text(checks[index].title)
                                        .font(.subheadline.bold())
                                        .strikethrough(checks[index].isCompleted)
                                    Text(checks[index].description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    withAnimation {
                                        if expandedId == checks[index].id {
                                            expandedId = nil
                                        } else {
                                            expandedId = checks[index].id
                                        }
                                    }
                                } label: {
                                    Image(systemName: expandedId == checks[index].id ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }

                            if expandedId == checks[index].id {
                                Text(checks[index].howToFix)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.leading, 32)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Чеклист")
        .onAppear { loadCompletedState() }
    }

    private func saveCompletedState() {
        let titles = Set(checks.filter(\.isCompleted).map(\.title))
        if let data = try? JSONEncoder().encode(Array(titles)) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadCompletedState() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let titles = try? JSONDecoder().decode([String].self, from: data) else { return }
        let titleSet = Set(titles)
        for i in checks.indices {
            checks[i].isCompleted = titleSet.contains(checks[i].title)
        }
    }
}
