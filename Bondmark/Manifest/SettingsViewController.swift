import UIKit

/// Export, contact, reset, and the introduction. Pushed from the manifest gear.
@MainActor
final class SettingsViewController: UIViewController {
    private let store = ManifestDesk.shared.store
    private let stack = UIStackView()
    private var resetting = false
    private let contactURL = URL(string: "https://bondmark-manifest.pro/contact-us")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        navigationItem.title = "Settings"
        stack.axis = .vertical
        stack.spacing = Gap.steps(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .onDrag
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: guide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: Gap.steps(2)),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -Gap.steps(2)),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: Gap.steps(2)),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -Gap.steps(2)),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -Gap.steps(4))
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(redraw), name: .manifestChanged, object: nil)
        render()
    }

    @objc private func redraw() { render() }

    private func render() {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let heading = UILabel()
        heading.font = Face.title()
        heading.textColor = DesignTokens.inkUI
        heading.numberOfLines = 2
        heading.text = "The record"
        stack.addArrangedSubview(heading)

        if let message = store.restoreNotice, !message.isEmpty {
            stack.addArrangedSubview(body(message))
            stack.addArrangedSubview(action("Try again", accent: true, action: #selector(retryLoad)))
        }

        if store.chart.items.isEmpty && store.restoreNotice == nil {
            let art = UIImageView(image: UIImage(named: "bmk_EmptyList"))
            art.contentMode = .scaleAspectFit
            art.isAccessibilityElement = false
            art.heightAnchor.constraint(equalToConstant: Gap.steps(16)).isActive = true
            stack.addArrangedSubview(art)
            let title = UILabel()
            title.font = Face.title()
            title.textColor = DesignTokens.inkUI
            title.numberOfLines = 2
            title.text = "Nothing to export yet"
            stack.addArrangedSubview(title)
            stack.addArrangedSubview(body("Scan a crate on the manifest. The ledger can be exported after that."))
        } else {
            let seats = Figures.whole(store.chart.seatMarks.count)
            let crates = Figures.whole(store.chart.items.count)
            stack.addArrangedSubview(body("\(crates) crates on the ledger. \(seats) seats witnessed."))
        }

        let plate = UIStackView()
        plate.axis = .vertical
        plate.spacing = Gap.steps(1)
        plate.isLayoutMarginsRelativeArrangement = true
        plate.layoutMargins = UIEdgeInsets(top: Gap.steps(2), left: Gap.steps(2), bottom: Gap.steps(2), right: Gap.steps(2))
        plate.backgroundColor = DesignTokens.surfaceUI
        plate.layer.cornerRadius = Curve.card
        Elevation.apply(to: plate)
        plate.addArrangedSubview(action("Export CSV", accent: true, action: #selector(exportCSV)))
        plate.addArrangedSubview(action("Contact", accent: false, action: #selector(openContact)))
        plate.addArrangedSubview(action("Show introduction", accent: false, action: #selector(rerunIntro)))
        plate.addArrangedSubview(action("Reset manifest", accent: false, action: #selector(confirmReset)))
        stack.addArrangedSubview(plate)
    }

    private func body(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = Face.body()
        label.textColor = DesignTokens.mutedUI
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func action(_ title: String, accent: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = accent ? DesignTokens.accentUI : DesignTokens.inkUI
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
        button.configurationUpdateHandler = { control in
            control.alpha = control.isHighlighted || !control.isEnabled ? 0.55 : 1
        }
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        if title == "Reset manifest" {
            button.role = .destructive
            button.accessibilityLabel = "Reset manifest"
        }
        return button
    }

    @objc private func retryLoad() {
        Task {
            await store.open()
            store.show(query: "")
            ManifestDesk.shared.noteChanged()
        }
    }

    @objc private func exportCSV() {
        let text = LedgerExport.csv(store.chart)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bondmark-manifest.csv")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = UIAlertController(
                title: "Export failed",
                message: "The ledger could not be written. Try again in a moment.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(sheet, animated: true)
    }

    @objc private func openContact() {
        guard let contactURL else { return }
        UIApplication.shared.open(contactURL)
    }

    @objc private func rerunIntro() {
        Task {
            await store.reopenOnboarding()
            let nav = navigationController
            nav?.popViewController(animated: false)
            let manifest = nav?.viewControllers.compactMap { $0 as? ManifestViewController }.first
            manifest?.replayOnboarding()
        }
    }

    @objc private func confirmReset() {
        let alert = UIAlertController(
            title: "Reset the manifest?",
            message: "Every crate, seat, and arm on this device is removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            Task { await self?.reset() }
        })
        present(alert, animated: true)
    }

    private func reset() async {
        guard !resetting else { return }
        resetting = true
        await store.resetAllData()
        resetting = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ManifestDesk.shared.noteChanged()
    }
}
