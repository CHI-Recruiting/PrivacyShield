import Foundation

struct PrivacyCheckItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let howToFix: String
    let category: Category
    var isCompleted: Bool = false

    enum Category: String, CaseIterable {
        case ios = "Настройки iOS"
        case linkedin = "Настройки LinkedIn"
        case browser = "Браузер"
        case network = "Сеть"
    }

    static let allChecks: [PrivacyCheckItem] = [
        // iOS Settings
        PrivacyCheckItem(
            title: "Отключить отслеживание",
            description: "Запретить LinkedIn запрашивать отслеживание",
            howToFix: "Настройки → Конфиденциальность → Отслеживание → Выключить для LinkedIn",
            category: .ios
        ),
        PrivacyCheckItem(
            title: "Запретить геолокацию",
            description: "LinkedIn не нужна ваша точная геопозиция",
            howToFix: "Настройки → LinkedIn → Геопозиция → Никогда",
            category: .ios
        ),
        PrivacyCheckItem(
            title: "Запретить доступ к контактам",
            description: "LinkedIn синхронизирует вашу телефонную книгу",
            howToFix: "Настройки → LinkedIn → Контакты → Выключить",
            category: .ios
        ),
        PrivacyCheckItem(
            title: "Запретить доступ к камере",
            description: "Камера не нужна для основного использования",
            howToFix: "Настройки → LinkedIn → Камера → Выключить",
            category: .ios
        ),

        // LinkedIn Settings
        PrivacyCheckItem(
            title: "Приватный режим просмотра",
            description: "Скрыть ваше имя при просмотре профилей",
            howToFix: "LinkedIn → Settings → Visibility → Profile viewing options → Private mode",
            category: .linkedin
        ),
        PrivacyCheckItem(
            title: "Отключить рекламную аналитику",
            description: "Запретить LinkedIn использовать ваши данные для рекламы",
            howToFix: "LinkedIn → Settings → Advertising data → Все переключатели выключить",
            category: .linkedin
        ),
        PrivacyCheckItem(
            title: "Отключить синхронизацию контактов",
            description: "Запретить LinkedIn синхронизировать контакты",
            howToFix: "LinkedIn → Settings → Syncing options → Sync contacts → Off",
            category: .linkedin
        ),
        PrivacyCheckItem(
            title: "Отключить сторонние данные",
            description: "Запретить LinkedIn получать данные от партнёров",
            howToFix: "LinkedIn → Settings → Advertising data → Third-party data → Off",
            category: .linkedin
        ),
        PrivacyCheckItem(
            title: "Очистить интересы",
            description: "Удалить данные о ваших интересах",
            howToFix: "LinkedIn → Settings → Advertising data → Interest categories → Очистить",
            category: .linkedin
        ),

        // Browser
        PrivacyCheckItem(
            title: "Удалить приложение LinkedIn",
            description: "Использовать только PrivacyShield вместо официального приложения",
            howToFix: "Удалите приложение LinkedIn из iPhone",
            category: .browser
        ),

        // Network
        PrivacyCheckItem(
            title: "Стабильное подключение",
            description: "Не переключайте VPN/Wi-Fi во время использования LinkedIn",
            howToFix: "Используйте одну сеть для всей сессии LinkedIn",
            category: .network
        ),
    ]
}
