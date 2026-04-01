import SwiftUI

struct ActivityMonitorView: View {
    @EnvironmentObject var rateLimitMonitor: RateLimitMonitor
    @EnvironmentObject var accountHealth: AccountHealthScore
    @StateObject private var antiBlock = AntiBlockService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Health Score Card
                    healthScoreCard

                    // IP Status
                    if antiBlock.ipChanged {
                        ipWarningCard
                    }

                    // Block Detection
                    if antiBlock.isBlockDetected {
                        blockDetectedCard
                    }

                    // Rate Limits
                    rateLimitsCard

                    // Health Factors
                    healthFactorsCard

                    // Cached Profiles Link
                    NavigationLink {
                        CachedProfilesView()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .foregroundColor(.blue)
                            Text("Кэш профилей")
                            Spacer()
                            Text(ProfileCacheManager.shared.totalCacheSize)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Монитор защиты")
        }
    }

    // MARK: - Components

    private var healthScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Здоровье аккаунта")
                    .font(.headline)
                Spacer()
                Text(accountHealth.scoreEmoji)
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: Double(accountHealth.score) / 100.0)
                    .stroke(accountHealth.scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: accountHealth.score)

                VStack {
                    Text("\(accountHealth.score)")
                        .font(.system(size: 36, weight: .bold))
                    Text("из 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(accountHealth.recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if rateLimitMonitor.isWarmUpMode {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Warm-up: день \(rateLimitMonitor.warmUpDay) из 7")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var ipWarningCard: some View {
        HStack {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.red)
                .font(.title2)
            VStack(alignment: .leading) {
                Text("IP адрес изменился!")
                    .font(.headline)
                    .foregroundColor(.red)
                Text("Было: \(antiBlock.previousIP)\nСтало: \(antiBlock.currentIP)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("OK") {
                antiBlock.dismissIPWarning()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private var blockDetectedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Обнаружена блокировка!")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            Text(antiBlock.blockReason)
                .font(.subheadline)
            Button("Понятно") {
                antiBlock.dismissBlockWarning()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    private var rateLimitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Лимиты сегодня")
                .font(.headline)

            rateLimitRow(
                icon: "person.crop.circle",
                name: "Просмотры",
                current: rateLimitMonitor.profileViews,
                limit: rateLimitMonitor.currentLimit(for: .profileViews),
                action: .profileViews
            )
            rateLimitRow(
                icon: "person.badge.plus",
                name: "Приглашения",
                current: rateLimitMonitor.connectionRequests,
                limit: rateLimitMonitor.currentLimit(for: .connectionRequests),
                action: .connectionRequests
            )
            rateLimitRow(
                icon: "message.fill",
                name: "Сообщения",
                current: rateLimitMonitor.messagesSent,
                limit: rateLimitMonitor.currentLimit(for: .messages),
                action: .messages
            )
            rateLimitRow(
                icon: "magnifyingglass",
                name: "Поиски",
                current: rateLimitMonitor.searches,
                limit: rateLimitMonitor.currentLimit(for: .searches),
                action: .searches
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func rateLimitRow(icon: String, name: String, current: Int, limit: Int, action: RateLimitMonitor.ActionType) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundColor(rateLimitMonitor.progressColor(for: action))
                Text(name)
                    .font(.subheadline)
                Spacer()
                Text("\(current)/\(limit)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(rateLimitMonitor.progressColor(for: action))
            }
            ProgressView(value: rateLimitMonitor.progress(for: action))
                .tint(rateLimitMonitor.progressColor(for: action))
        }
    }

    private var healthFactorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Факторы риска")
                .font(.headline)

            ForEach(accountHealth.factors) { factor in
                HStack {
                    Image(systemName: factor.icon)
                        .foregroundColor(factorColor(factor.status))
                        .frame(width: 24)
                    Text(factor.name)
                        .font(.subheadline)
                    Spacer()
                    if factor.impact != 0 {
                        Text("\(factor.impact)")
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func factorColor(_ status: AccountHealthScore.HealthFactor.Status) -> Color {
        switch status {
        case .good: return .green
        case .warning: return .yellow
        case .danger: return .red
        }
    }
}
