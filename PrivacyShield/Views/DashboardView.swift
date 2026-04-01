import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var blockingStats: BlockingStatsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Stats Cards
                    HStack(spacing: 12) {
                        statCard(
                            title: "Сегодня",
                            value: "\(blockingStats.todayBlocked)",
                            icon: "shield.fill",
                            color: .green
                        )
                        statCard(
                            title: "Всего",
                            value: "\(blockingStats.totalBlocked)",
                            icon: "shield.checkered",
                            color: .blue
                        )
                    }

                    // Category Breakdown
                    if !blockingStats.blockedByCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("По категориям")
                                .font(.headline)

                            ForEach(
                                blockingStats.blockedByCategory.sorted { $0.value > $1.value },
                                id: \.key
                            ) { category, count in
                                HStack {
                                    Text(blockingStats.categoryDisplayName(category))
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.subheadline.bold().monospacedDigit())
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }

                    // Recent Blocked
                    if !blockingStats.recentBlocked.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Последние блокировки")
                                .font(.headline)

                            ForEach(blockingStats.recentBlocked.prefix(20)) { request in
                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    VStack(alignment: .leading) {
                                        Text(blockingStats.categoryDisplayName(request.category))
                                            .font(.caption.bold())
                                        Text(request.url.prefix(60) + (request.url.count > 60 ? "..." : ""))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(request.timeAgo)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }

                    // Privacy Checklist Link
                    NavigationLink {
                        PrivacyChecklistView()
                    } label: {
                        HStack {
                            Image(systemName: "checklist")
                                .foregroundColor(.blue)
                            Text("Чеклист приватности")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Статистика")
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 32, weight: .bold).monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
