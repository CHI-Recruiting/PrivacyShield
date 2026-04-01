import Foundation
import WebKit

class StealthBrowsingService {
    static let shared = StealthBrowsingService()

    /// Captures the current page as a PDF for offline viewing
    func capturePageAsPDF(from webView: WKWebView, completion: @escaping (Data?) -> Void) {
        let config = WKPDFConfiguration()
        config.rect = CGRect(origin: .zero, size: CGSize(
            width: webView.scrollView.contentSize.width,
            height: webView.scrollView.contentSize.height
        ))

        webView.createPDF(configuration: config) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure(let error):
                print("[PrivacyShield] PDF capture failed: \(error)")
                completion(nil)
            }
        }
    }

    /// Extracts profile data from the current LinkedIn profile page via JavaScript
    func extractProfileData(from webView: WKWebView, completion: @escaping (ProfileData?) -> Void) {
        // Multiple selector fallbacks for resilience against LinkedIn DOM changes
        let js = """
        (function() {
            try {
                function q(selectors) {
                    for (var i = 0; i < selectors.length; i++) {
                        var el = document.querySelector(selectors[i]);
                        if (el && el.textContent.trim()) return el.textContent.trim();
                    }
                    return '';
                }
                var name = q(['h1.text-heading-xlarge', 'h1[class*="heading"]', '.pv-top-card h1', 'h1']);
                var headline = q(['.text-body-medium[data-anonymize="headline-text"]', '.text-body-medium', '.pv-top-card .text-body-medium', '[data-anonymize="headline-text"]']);
                var location = q(['.text-body-small[data-anonymize="location"]', '.text-body-small.inline.t-black--light', '.pv-top-card .text-body-small', '[data-anonymize="location"]']);
                var company = q(['.pv-text-details__right-panel .inline-show-more-text', '.inline-show-more-text', '.experience-item .pv-entity__secondary-title']);
                var profileUrl = window.location.href;

                return JSON.stringify({
                    name: name,
                    headline: headline,
                    location: location,
                    company: company,
                    profileUrl: profileUrl
                });
            } catch(e) {
                return JSON.stringify({ error: e.message });
            }
        })();
        """

        webView.evaluateJavaScript(js) { result, error in
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                completion(nil)
                return
            }

            if json["error"] != nil {
                completion(nil)
                return
            }

            let profile = ProfileData(
                name: json["name"] ?? "",
                headline: json["headline"] ?? "",
                location: json["location"] ?? "",
                company: json["company"] ?? "",
                profileUrl: json["profileUrl"] ?? ""
            )
            completion(profile)
        }
    }
}

// ProfileData is defined in Models/ProfileData.swift
