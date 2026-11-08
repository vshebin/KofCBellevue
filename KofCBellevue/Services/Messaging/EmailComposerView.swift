import SwiftUI
import MessageUI
struct EmailComposerView: UIViewControllerRepresentable {
    let email: String
    let subject: String
    let body: String
    let completion: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.mailComposeDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let completion: (String) -> Void
        init(completion: @escaping (String) -> Void) { self.completion = completion }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error { completion("Email failed: " + error.localizedDescription); return }
            switch result {
            case .sent: completion("Email submitted. Delivery is not confirmed.")
            case .saved: completion("Email saved as a draft.")
            case .cancelled: completion("Email cancelled.")
            case .failed: completion("Email failed.")
            @unknown default: completion("Email status unknown.")
            }
        }
    }
}
