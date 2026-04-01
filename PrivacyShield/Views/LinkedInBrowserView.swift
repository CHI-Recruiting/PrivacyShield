import SwiftUI
import WebKit

struct LinkedInBrowserView: View {
    @EnvironmentObject var blockingStats: BlockingStatsManager
    @EnvironmentObject var rateLimitMonitor: RateLimitMonitor
    @EnvironmentObject var accountHealth: AccountHealthScore
    @State private var urlString = "https://www.linkedin.com"
    @State private var isLoading = false
    @State private var showBlockedBanner = false
    @State private var lastBlockedCategory = ""
    @State private var healthScore: Int = 100

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                LinkedInWebView(
                    urlString: $urlString,
                    isLoading: $isLoading,
                    onBlocked: { category, url in
                        blockingStats.recordBlocked(url: url, category: category)
                        showBlockedNotification(category: category)
                    },
                    onNavigation: { url in
                        rateLimitMonitor.recordAction(for: url)
                        accountHealth.recordActivity()
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                // Blocked notification banner
                if showBlockedBanner {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .foregroundColor(.white)
                        Text("Заблокировано: \(blockingStats.categoryDisplayName(lastBlockedCategory))")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(blockingStats.todayBlocked)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Rate limit warning
                if rateLimitMonitor.showWarning {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(rateLimitMonitor.warningMessage)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accountHealth.scoreColor)
                            .frame(width: 8, height: 8)
                        Text("PrivacyShield")
                            .font(.headline)
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(blockingStats.todayBlocked)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    private func showBlockedNotification(category: String) {
        lastBlockedCategory = category
        withAnimation(.easeInOut(duration: 0.3)) {
            showBlockedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showBlockedBanner = false
            }
        }
    }
}

// MARK: - WKWebView Wrapper

struct LinkedInWebView: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var isLoading: Bool
    var onBlocked: (String, String) -> Void
    var onNavigation: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // Add message handler for JS → Swift communication
        userContentController.add(context.coordinator, name: "privacyShield")

        // Inject fingerprint protection FIRST (before any other script can read real values)
        let fingerprintScript = FingerprintManager.shared.generateProtectionScript()
        let fpUserScript = WKUserScript(
            source: fingerprintScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(fpUserScript)

        // Inject privacy scripts with settings-based conditional injection
        ContentBlocker.shared.injectPrivacyScripts(
            into: userContentController,
            settings: SettingsManager.shared
        )

        configuration.userContentController = userContentController
        configuration.applicationNameForUserAgent = ""
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = UserAgentManager.shared.stableUserAgent
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        // Compile content blocker rules FIRST, then load LinkedIn
        // This prevents trackers from slipping through before rules are ready
        ContentBlocker.shared.compileBlockList { ruleList in
            if let ruleList = ruleList {
                webView.configuration.userContentController.add(ruleList)
            }
            // Load LinkedIn only AFTER rules are compiled
            if let url = URL(string: self.urlString) {
                webView.load(URLRequest(url: url))
            }
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: LinkedInWebView

        init(parent: LinkedInWebView) {
            self.parent = parent
        }

        // Handle messages from injected JavaScript
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String,
                  type == "blocked",
                  let category = body["category"] as? String,
                  let url = body["url"] as? String else { return }

            parent.onBlocked(category, url)
        }

        // Navigation delegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView,
                      decidePolicyFor navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Clean tracking parameters from URL
            let cleanedURL = LinkCleaner.clean(url: url)
            if cleanedURL != url {
                decisionHandler(.cancel)
                webView.load(URLRequest(url: cleanedURL))
                return
            }

            // Track navigation for rate limiting
            parent.onNavigation(url)

            // Block navigation to known tracker domains
            let host = url.host ?? ""
            let trackerDomains = [
                "px.ads.linkedin.com",
                "dc.ads.linkedin.com",
                "ads.linkedin.com",
                "snap.licdn.com",
                "tr.lnkd.in"
            ]

            if trackerDomains.contains(where: { host.contains($0) }) {
                parent.onBlocked("navigation_block", url.absoluteString)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }
    }
}
