import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LinkedInBrowserView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("LinkedIn")
                }
                .tag(0)

            ActivityMonitorView()
                .tabItem {
                    Image(systemName: "shield.checkered")
                    Text("Монитор")
                }
                .tag(1)

            BackupView()
                .tabItem {
                    Image(systemName: "externaldrive.badge.checkmark")
                    Text("Бэкап")
                }
                .tag(2)

            DashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Статистика")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Настройки")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
