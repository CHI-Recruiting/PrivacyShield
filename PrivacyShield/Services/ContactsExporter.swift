import Foundation
import UIKit

class ContactsExporter {

    /// Shares a file using UIActivityViewController
    static func share(fileURL: URL, from viewController: UIViewController? = nil) {
        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        let vc = viewController ?? topViewController()
        vc?.present(activityVC, animated: true)
    }

    /// Shares text content directly
    static func shareText(_ text: String, from viewController: UIViewController? = nil) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        let vc = viewController ?? topViewController()
        vc?.present(activityVC, animated: true)
    }

    /// Finds the top view controller for presenting share sheet
    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }

        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
