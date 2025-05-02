//
//  Email.swift
//  Daily average cost
//
//  Created by 吴天禹 on 2022/3/18.
//
#if os(iOS)
import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation,
                           result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let systemVersion = UIDevice.current.systemVersion
        let systemName = UIDevice.current.systemName
        let deviceModel = UIDevice.current.model
//        let deviceName = UIDevice
        let composeVC = MFMailComposeViewController()
//        composeVC.mailComposeDelegate = self

        // Configure the fields of the interface.
        composeVC.setToRecipients(["ddwty@163.com"])
        composeVC.setSubject("MagiClaw Feedback-" + deviceModel + " " + systemName + systemVersion)
//        composeVC.setMessageBody("", isHTML: false)
         
        // Present the view controller modally.
//        self.present(composeVC, animated: true, completion: nil)
        
        composeVC.mailComposeDelegate = context.coordinator
        return composeVC
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {

    }
}
#endif
