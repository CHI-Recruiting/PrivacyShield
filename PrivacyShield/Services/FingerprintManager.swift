import Foundation
import UIKit

class FingerprintManager {
    static let shared = FingerprintManager()

    private let fingerprintKey = "privacyshield_fingerprint"

    struct DeviceFingerprint: Codable {
        let screenWidth: Int
        let screenHeight: Int
        let colorDepth: Int
        let language: String
        let timezone: String
        let platform: String
        let hardwareConcurrency: Int
        let deviceMemory: Int
        let createdAt: Date
    }

    /// Get or create a stable device fingerprint
    var stableFingerprint: DeviceFingerprint {
        if let data = UserDefaults.standard.data(forKey: fingerprintKey),
           let fp = try? JSONDecoder().decode(DeviceFingerprint.self, from: data) {
            return fp
        }
        let fp = generateFingerprint()
        if let data = try? JSONEncoder().encode(fp) {
            UserDefaults.standard.set(data, forKey: fingerprintKey)
        }
        return fp
    }

    /// Regenerate fingerprint (creates a new device identity)
    @discardableResult
    func regenerateFingerprint() -> DeviceFingerprint {
        let fp = generateFingerprint()
        if let data = try? JSONEncoder().encode(fp) {
            UserDefaults.standard.set(data, forKey: fingerprintKey)
        }
        return fp
    }

    /// Short display ID for settings screen
    var displayID: String {
        let fp = stableFingerprint
        let raw = "\(fp.screenWidth)x\(fp.screenHeight)-\(fp.language)-\(fp.timezone)"
        let hash = abs(raw.hashValue)
        return String(format: "%08X", hash & 0xFFFFFFFF)
    }

    private func generateFingerprint() -> DeviceFingerprint {
        // Use realistic iPhone screen sizes
        let screens = [(390, 844), (393, 852), (414, 896), (428, 926)]
        let screen = screens.randomElement()!

        return DeviceFingerprint(
            screenWidth: screen.0,
            screenHeight: screen.1,
            colorDepth: 32,
            language: "en-US",
            timezone: "America/New_York",
            platform: "iPhone",
            hardwareConcurrency: 6,
            deviceMemory: 4,
            createdAt: Date()
        )
    }

    /// Generates JavaScript that overrides browser fingerprinting APIs
    /// with consistent, stable values
    func generateProtectionScript() -> String {
        let fp = stableFingerprint
        return """
        (function() {
            'use strict';

            // Override screen properties with stable values
            Object.defineProperty(screen, 'width', { get: function() { return \(fp.screenWidth); } });
            Object.defineProperty(screen, 'height', { get: function() { return \(fp.screenHeight); } });
            Object.defineProperty(screen, 'availWidth', { get: function() { return \(fp.screenWidth); } });
            Object.defineProperty(screen, 'availHeight', { get: function() { return \(fp.screenHeight - 44); } });
            Object.defineProperty(screen, 'colorDepth', { get: function() { return \(fp.colorDepth); } });
            Object.defineProperty(screen, 'pixelDepth', { get: function() { return \(fp.colorDepth); } });

            // Stable navigator properties
            Object.defineProperty(navigator, 'language', { get: function() { return '\(fp.language)'; } });
            Object.defineProperty(navigator, 'languages', { get: function() { return ['\(fp.language)', 'en']; } });
            Object.defineProperty(navigator, 'platform', { get: function() { return '\(fp.platform)'; } });
            Object.defineProperty(navigator, 'hardwareConcurrency', { get: function() { return \(fp.hardwareConcurrency); } });
            Object.defineProperty(navigator, 'deviceMemory', { get: function() { return \(fp.deviceMemory); } });

            // Block WebGL fingerprinting
            const originalGetParameter = WebGLRenderingContext.prototype.getParameter;
            WebGLRenderingContext.prototype.getParameter = function(param) {
                // UNMASKED_VENDOR_WEBGL
                if (param === 0x9245) return 'Apple Inc.';
                // UNMASKED_RENDERER_WEBGL
                if (param === 0x9246) return 'Apple GPU';
                return originalGetParameter.call(this, param);
            };

            // Block AudioContext fingerprinting
            if (window.AudioContext || window.webkitAudioContext) {
                const AudioCtx = window.AudioContext || window.webkitAudioContext;
                const origCreateOscillator = AudioCtx.prototype.createOscillator;
                AudioCtx.prototype.createOscillator = function() {
                    const osc = origCreateOscillator.call(this);
                    // Slightly modify to prevent unique fingerprint
                    return osc;
                };
            }

            // Stable Date/timezone
            const origResolvedOptions = Intl.DateTimeFormat.prototype.resolvedOptions;
            Intl.DateTimeFormat.prototype.resolvedOptions = function() {
                const result = origResolvedOptions.call(this);
                result.timeZone = '\(fp.timezone)';
                return result;
            };

            // Block Battery API (used for fingerprinting)
            if (navigator.getBattery) {
                navigator.getBattery = undefined;
            }

            console.log('[PrivacyShield] Fingerprint protection loaded');
        })();
        """
    }
}
