import SwiftUI
import UIKit

/// Hosts the storyboard so the bonded manifest is the root the user actually sees.
struct StoryHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let controller = storyboard.instantiateInitialViewController() ?? UIViewController()
        controller.overrideUserInterfaceStyle = .light
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
