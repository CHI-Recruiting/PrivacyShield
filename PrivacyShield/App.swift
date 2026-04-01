import SwiftUI

@main
struct PrivacyShieldApp: App {
    @StateObject private var blockingStats = BlockingStatsManager.shared
    @StateObject private var rateLimitMonitor = RateLimitMonitor.shared
    @StateObject private var accountHealth = AccountHealthScore.shared
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blockingStats)
                .environmentObject(rateLimitMonitor)
                .environmentObject(accountHealth)
                .environmentObject(settingsManager)
        }
    }
}
