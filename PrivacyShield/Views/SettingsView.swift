import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack {
            List {
                // Blocking Level
                Section {
                    Picker("Уровень блокировки", selection: $settings.blockingLevel) {
                        ForEach(BlockingLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Уровень защиты")
                } footer: {
                    Text("Параноидальный режим может ломать некоторые функции LinkedIn")
                }

                // Privacy Features
                Section {
                    Toggle(isOn: $settings.stealthMode) {
                        Label("Режим «Призрак»", systemImage: "eye.slash.fill")
                    }
                    Toggle(isOn: $settings.blockReadReceipts) {
                        Label("Блокировать «Прочитано»", systemImage: "eye.trianglebadge.exclamationmark")
                    }
                    Toggle(isOn: $settings.blockTypingIndicator) {
                        Label("Блокировать «Печатает...»", systemImage: "text.cursor")
                    }
                    Toggle(isOn: $settings.cleanLinks) {
                        Label("Очищать ссылки", systemImage: "link.badge.plus")
                    }
                    Toggle(isOn: $settings.blockSearchTracking) {
                        Label("Приватный поиск", systemImage: "magnifyingglass")
                    }
                } header: {
                    Text("Приватность")
                }

                // Anti-Block
                Section {
                    Toggle(isOn: $settings.warmUpMode) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Warm-up режим")
                                Text("Для нового/разблокированного аккаунта")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "flame.fill")
                        }
                    }
                    Toggle(isOn: $settings.preserveCookies) {
                        Label("Сохранять cookies", systemImage: "cylinder.split.1x2.fill")
                    }
                    Toggle(isOn: $settings.showBlockNotifications) {
                        Label("Уведомления о блокировках", systemImage: "bell.fill")
                    }
                } header: {
                    Text("Защита от бана")
                } footer: {
                    Text("Warm-up постепенно увеличивает лимиты в течение 7 дней")
                }

                // Backup
                Section {
                    Toggle(isOn: $settings.autoBackup) {
                        Label("Автобэкап контактов", systemImage: "arrow.clockwise.icloud.fill")
                    }
                } header: {
                    Text("Бэкап")
                }

                // Info
                Section {
                    HStack {
                        Text("User-Agent")
                        Spacer()
                        Text(String(UserAgentManager.shared.stableUserAgent.prefix(30)) + "...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Text("Fingerprint ID")
                        Spacer()
                        Text(FingerprintManager.shared.displayID)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }

                    Button("Сбросить fingerprint и User-Agent") {
                        FingerprintManager.shared.regenerateFingerprint()
                        _ = UserAgentManager.shared.regenerateUserAgent()
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Техническая информация")
                } footer: {
                    Text("Сброс fingerprint создаст новый отпечаток устройства. LinkedIn может воспринять это как новое устройство.")
                }

                // About
                Section {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("О приложении")
                } footer: {
                    Text("ARMANOS — защита вашей приватности в LinkedIn")
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
