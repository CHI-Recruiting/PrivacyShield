import Foundation
import Network
import SwiftUI

class AntiBlockService: ObservableObject {
    static let shared = AntiBlockService()

    @Published var currentIP: String = ""
    @Published var previousIP: String = ""
    @Published var ipChanged: Bool = false
    @Published var isBlockDetected: Bool = false
    @Published var blockReason: String = ""

    private let ipStorageKey = "privacyshield_last_ip"
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.privacyshield.network")

    init() {
        previousIP = UserDefaults.standard.string(forKey: ipStorageKey) ?? ""
        startNetworkMonitoring()
    }

    // MARK: - IP Monitoring

    func checkIP() {
        let url = URL(string: "https://api.ipify.org?format=json")!
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }

            if let error = error {
                print("[PrivacyShield] IP check failed: \(error.localizedDescription)")
                return
            }

            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let ip = json["ip"] else {
                print("[PrivacyShield] IP check: invalid response")
                return
            }

            DispatchQueue.main.async {
                self.previousIP = self.currentIP
                self.currentIP = ip

                if !self.previousIP.isEmpty && self.previousIP != ip {
                    self.ipChanged = true
                }

                UserDefaults.standard.set(ip, forKey: self.ipStorageKey)
            }
        }.resume()
    }

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.checkIP()
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Block Detection

    func checkForBlock(statusCode: Int, responseBody: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if statusCode == 403 {
                self.isBlockDetected = true
                self.blockReason = "LinkedIn вернул 403 (Запрещено). Возможно, аккаунт ограничен."
            } else if statusCode == 429 {
                self.isBlockDetected = true
                self.blockReason = "LinkedIn вернул 429 (Слишком много запросов). Замедлите активность!"
            } else if responseBody.contains("challenge") || responseBody.contains("captcha") {
                self.isBlockDetected = true
                self.blockReason = "LinkedIn показывает CAPTCHA. Это признак подозрительной активности."
            } else if responseBody.contains("restricted") || responseBody.contains("temporarily limited") {
                self.isBlockDetected = true
                self.blockReason = "LinkedIn ограничил ваш аккаунт. Прекратите действия и подождите."
            }
        }
    }

    func dismissBlockWarning() {
        DispatchQueue.main.async {
            self.isBlockDetected = false
            self.blockReason = ""
        }
    }

    func dismissIPWarning() {
        DispatchQueue.main.async {
            self.ipChanged = false
        }
    }

    // MARK: - Session Consistency

    /// Checks if the current session looks consistent to LinkedIn
    var sessionConsistencyScore: Int {
        var score = 100

        // IP changed during session
        if ipChanged { score -= 30 }

        // Check if user agent is stable
        if UserDefaults.standard.string(forKey: "privacyshield_user_agent") == nil {
            score -= 20
        }

        // Check if cookies are preserved
        if !SettingsManager.shared.preserveCookies {
            score -= 15
        }

        return max(0, score)
    }
}
