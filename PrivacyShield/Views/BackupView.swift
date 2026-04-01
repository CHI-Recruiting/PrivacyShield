import SwiftUI

struct BackupView: View {
    @StateObject private var backupService = DataBackupService.shared
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showExportOptions = false

    var body: some View {
        NavigationStack {
            List {
                // Status Section
                Section {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text("Сохранённых контактов")
                                .font(.subheadline)
                            Text("\(backupService.contacts.count)")
                                .font(.title2.bold())
                        }
                    }

                    if backupService.isBackingUp {
                        HStack {
                            ProgressView()
                            Text(backupService.backupProgress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Статус")
                }

                // Actions
                Section {
                    Button {
                        showExportOptions = true
                    } label: {
                        Label("Экспортировать контакты", systemImage: "square.and.arrow.up")
                    }
                    .disabled(backupService.contacts.isEmpty)

                    NavigationLink {
                        ContactListView(contacts: backupService.contacts)
                    } label: {
                        Label("Просмотреть контакты", systemImage: "list.bullet")
                    }
                    .disabled(backupService.contacts.isEmpty)
                } header: {
                    Text("Действия")
                } footer: {
                    Text("Для загрузки контактов откройте LinkedIn → My Network → Connections в браузере приложения")
                }

                // Backup History
                if !backupService.backupHistory.isEmpty {
                    Section {
                        ForEach(backupService.backupHistory) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(record.contactCount) контактов")
                                    .font(.subheadline.bold())
                                Text(record.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("История бэкапов")
                    }
                }
            }
            .navigationTitle("Бэкап данных")
            .confirmationDialog("Формат экспорта", isPresented: $showExportOptions) {
                Button("CSV (для Excel/Google Sheets)") {
                    if let url = backupService.exportAsCSV() {
                        ContactsExporter.share(fileURL: url)
                    }
                }
                Button("JSON (для разработчиков)") {
                    if let url = backupService.exportAsJSON() {
                        ContactsExporter.share(fileURL: url)
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
        }
    }
}

struct ContactListView: View {
    let contacts: [LinkedInContact]
    @State private var searchText = ""

    var filteredContacts: [LinkedInContact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.headline.localizedCaseInsensitiveContains(searchText) ||
            $0.company.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredContacts) { contact in
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                if !contact.headline.isEmpty {
                    Text(contact.headline)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if !contact.company.isEmpty {
                    Text(contact.company)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 2)
        }
        .searchable(text: $searchText, prompt: "Поиск контактов")
        .navigationTitle("Контакты (\(contacts.count))")
    }
}
