import SwiftUI
import MessageUI
struct SMSComposerView: UIViewControllerRepresentable {
    let phone: String
    let body: String
    let completion: (String) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phone]
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: (String) -> Void
        init(completion: @escaping (String) -> Void) { self.completion = completion }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            switch result {
            case .sent: completion("SMS submitted. Delivery is not confirmed.")
            case .cancelled: completion("SMS cancelled.")
            case .failed: completion("SMS failed.")
            @unknown default: completion("SMS status unknown.")
            }
        }
    }
}
