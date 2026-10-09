import UIKit

/// Three pages. Skip and the last continue both write the completion flag.
@MainActor
final class OnboardingViewController: UIViewController {
    var onDone: (() -> Void)?
    private let pages: [(String, String, String)] = [
        ("bmk_Onboarding1", "Bond the bay", "Scan a labeled crate, then the slot plate, so the move is witnessed on the manifest."),
        ("bmk_Onboarding2", "Arm, then seat", "A known crate opens an eight second window. Scan the bay plate before it closes."),
        ("bmk_Onboarding3", "Keep the record", "Issued crates older than thirty days show on Lifecycle. Relinquish freezes a crate.")
    ]
    private var index = 0
    private let art = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        art.contentMode = .scaleAspectFit
        art.heightAnchor.constraint(equalToConstant: Gap.steps(28)).isActive = true
        titleLabel.font = Face.title()
        titleLabel.textColor = DesignTokens.inkUI
        titleLabel.numberOfLines = 2
        bodyLabel.font = Face.body()
        bodyLabel.textColor = DesignTokens.mutedUI
        bodyLabel.numberOfLines = 0

        stylePrimary(nextButton, title: "Next")
        nextButton.addTarget(self, action: #selector(advance), for: .touchUpInside)
        stylePlain(skipButton, title: "Skip")
        skipButton.addTarget(self, action: #selector(skip), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [art, titleLabel, bodyLabel, UIView(), skipButton, nextButton])
        stack.axis = .vertical
        stack.spacing = Gap.steps(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Gap.steps(3)),
            stack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Gap.steps(3)),
            stack.topAnchor.constraint(equalTo: guide.topAnchor, constant: Gap.steps(4)),
            stack.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Gap.steps(2))
        ])
        showPage()
    }

    private func showPage() {
        let page = pages[index]
        art.image = UIImage(named: page.0)
        titleLabel.text = page.1
        bodyLabel.text = page.2
        let last = index == pages.count - 1
        let title = last ? "Continue" : "Next"
        var config = nextButton.configuration ?? .filled()
        config.title = title
        nextButton.configuration = config
        nextButton.accessibilityLabel = title
    }

    @objc private func advance() {
        if index + 1 < pages.count {
            index += 1
            showPage()
            return
        }
        Task { await finish() }
    }

    @objc private func skip() {
        Task { await finish() }
    }

    private func finish() async {
        await ManifestDesk.shared.store.finishOnboarding()
        ManifestDesk.shared.noteChanged()
        onDone?()
    }

    private func stylePrimary(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = DesignTokens.accentUI
        config.baseForegroundColor = DesignTokens.bgUI
        config.background.cornerRadius = Curve.chip
        config.background.strokeColor = DesignTokens.inkUI
        config.background.strokeWidth = 1
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        button.configuration = config
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    private func stylePlain(_ button: UIButton, title: String) {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = DesignTokens.inkUI
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        button.configuration = config
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
}
