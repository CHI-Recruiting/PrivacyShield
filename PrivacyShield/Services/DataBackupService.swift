import Foundation
import WebKit

class DataBackupService: ObservableObject {
    static let shared = DataBackupService()

    @Published var contacts: [LinkedInContact] = []
    @Published var backupHistory: [BackupRecord] = []
    @Published var isBackingUp: Bool = false
    @Published var backupProgress: String = ""

    private let contactsKey = "privacyshield_contacts_backup"
    private let historyKey = "privacyshield_backup_history"

    init() {
        loadData()
    }

    // MARK: - Contact Extraction via JavaScript

    /// Extracts contacts from the LinkedIn connections page
    func extractContacts(from webView: WKWebView, completion: @escaping ([LinkedInContact]) -> Void) {
        DispatchQueue.main.async {
            self.isBackingUp = true
            self.backupProgress = "Извлечение контактов..."
        }

        // Multiple selector fallbacks for resilience against LinkedIn DOM changes
        let js = """
        (function() {
            try {
                function findCards() {
                    var selectors = [
                        '.mn-connection-card',
                        '[data-view-name="connection-card"]',
                        '.scaffold-finite-scroll__content li',
                        '.reusable-search__result-container'
                    ];
                    for (var i = 0; i < selectors.length; i++) {
                        var cards = document.querySelectorAll(selectors[i]);
                        if (cards.length > 0) return cards;
                    }
                    return [];
                }
                function getText(el, selectors) {
                    for (var i = 0; i < selectors.length; i++) {
                        var found = el.querySelector(selectors[i]);
                        if (found && found.textContent.trim()) return found.textContent.trim();
                    }
                    return '';
                }
                function getLink(el) {
                    var a = el.querySelector('a[href*="/in/"]') || el.querySelector('a[href*="linkedin.com/in/"]') || el.querySelector('a');
                    return a ? a.href : '';
                }
                var cards = findCards();
                var contacts = [];
                cards.forEach(function(card) {
                    var name = getText(card, ['.mn-connection-card__name', '.entity-result__title-text a span', '[data-anonymize="person-name"]', 'span.t-bold']);
                    var headline = getText(card, ['.mn-connection-card__occupation', '.entity-result__primary-subtitle', '[data-anonymize="headline"]', '.t-black--light']);
                    var link = getLink(card);
                    if (name) {
                        contacts.push({ name: name, headline: headline, profileURL: link });
                    }
                });
                return JSON.stringify(contacts);
            } catch(e) {
                return JSON.stringify([]);
            }
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, error in
            guard let self else { return }

            DispatchQueue.main.async {
                self.isBackingUp = false

                guard let jsonString = result as? String,
                      let data = jsonString.data(using: .utf8),
                      let items = try? JSONDecoder().decode([[String: String]].self, from: data) else {
                    self.backupProgress = "Ошибка извлечения"
                    completion([])
                    return
                }

                let newContacts = items.map { item in
                    LinkedInContact(
                        name: item["name"] ?? "",
                        headline: item["headline"] ?? "",
                        company: "",
                        profileURL: item["profileURL"] ?? ""
                    )
                }

                // Merge with existing, avoiding duplicates
                for contact in newContacts {
                    if !self.contacts.contains(where: { $0.profileURL == contact.profileURL }) {
                        self.contacts.append(contact)
                    }
                }

                self.saveData()
                self.backupProgress = "Сохранено \(self.contacts.count) контактов"
                completion(newContacts)
            }
        }
    }

    // MARK: - Export

    func exportAsCSV() -> URL? {
        var csv = LinkedInContact.csvHeader + "\n"
        for contact in contacts {
            csv += contact.csvRow + "\n"
        }

        let fileName = "linkedin_contacts_\(dateString()).csv"
        let url = exportDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)

            let record = BackupRecord(contactCount: contacts.count, filePath: url.path)
            backupHistory.insert(record, at: 0)
            saveData()

            return url
        } catch {
            print("[PrivacyShield] CSV export failed: \(error)")
            return nil
        }
    }

    func exportAsJSON() -> URL? {
        let fileName = "linkedin_contacts_\(dateString()).json"
        let url = exportDirectory.appendingPathComponent(fileName)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(contacts)
            try data.write(to: url)

            let record = BackupRecord(contactCount: contacts.count, filePath: url.path)
            backupHistory.insert(record, at: 0)
            saveData()

            return url
        } catch {
            print("[PrivacyShield] JSON export failed: \(error)")
            return nil
        }
    }

    // MARK: - Storage

    private var exportDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("Backups")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: contactsKey),
           let saved = try? JSONDecoder().decode([LinkedInContact].self, from: data) {
            contacts = saved
        }
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([BackupRecord].self, from: data) {
            backupHistory = saved
        }
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(contacts) {
            UserDefaults.standard.set(data, forKey: contactsKey)
        }
        if let data = try? JSONEncoder().encode(backupHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: Date())
    }
}
