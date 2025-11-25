import MessageUI
import SwiftUI
import UIKit

extension SettingsView {
  struct MailComposeView: UIViewControllerRepresentable {
    let onFinish: (MFMailComposeResult) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
      let composer = MFMailComposeViewController()
      composer.mailComposeDelegate = context.coordinator
      composer.setToRecipients(["support@msg-team.com"])
      composer.setSubject("[SleepShield] - Feedback")
      composer.setMessageBody("""
      
      ---
      App Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
      iOS Version: \(UIDevice.current.systemVersion)
      Device: \(UIDevice.current.model)
      Report ID: \(AnalyticsClient.shared.getUserID()?.data(using: .utf8)?.base64EncodedString() ?? "N/A")
      """, isHTML: false)
      
      return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
      Coordinator(onFinish: onFinish)
    }
    
    @MainActor
    final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
      let onFinish: (MFMailComposeResult) -> Void
      
      init(onFinish: @escaping (MFMailComposeResult) -> Void) {
        self.onFinish = onFinish
      }
      
      func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        onFinish(result)
      }
    }
  }
}
