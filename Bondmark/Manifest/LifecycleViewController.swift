import UIKit

/// Overdue rail and Relinquish. Issued longer than thirty days ranks here.
@MainActor
final class LifecycleViewController: UIViewController {
    private let store = ManifestDesk.shared.store
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        navigationItem.title = "Lifecycle"
        stack.axis = .vertical
        stack.spacing = Gap.steps(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
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
        heading.font = Face.display()
        heading.textColor = DesignTokens.inkUI
        heading.numberOfLines = 2
        heading.text = "Issued too long"
        stack.addArrangedSubview(heading)

        if let message = store.restoreNotice {
            let body = UILabel()
            body.font = Face.body()
            body.textColor = DesignTokens.mutedUI
            body.numberOfLines = 0
            body.text = message
            let next = UILabel()
            next.font = Face.body()
            next.textColor = DesignTokens.inkUI
            next.numberOfLines = 0
            next.text = "Relinquish still writes when an overdue crate is listed."
            stack.addArrangedSubview(body)
            stack.addArrangedSubview(next)
        }

        let overdue = store.chart.overdueItems(on: Date())
        if overdue.isEmpty && store.restoreNotice == nil {
            let art = UIImageView(image: UIImage(named: "bmk_EmptyList"))
            art.contentMode = .scaleAspectFit
            art.heightAnchor.constraint(equalToConstant: Gap.steps(20)).isActive = true
            let title = UILabel()
            title.font = Face.title()
            title.textColor = DesignTokens.inkUI
            title.numberOfLines = 2
            title.text = "Nothing is overdue"
            let body = UILabel()
            body.font = Face.body()
            body.textColor = DesignTokens.mutedUI
            body.numberOfLines = 0
            body.text = "A crate issued longer than thirty days will rank here. Tap Relinquish to freeze it."
            stack.addArrangedSubview(art)
            stack.addArrangedSubview(title)
            stack.addArrangedSubview(body)
        }

        if let hero = overdue.first {
            let lead = UILabel()
            lead.font = Face.body()
            lead.textColor = DesignTokens.inkUI
            lead.numberOfLines = 0
            lead.text = "\(hero.name) has been out since \(issuedDay(hero)). Tap Relinquish."
            stack.addArrangedSubview(lead)
        }

        for item in overdue {
            stack.addArrangedSubview(overdueCard(for: item))
        }

        let others = store.chart.items.filter { item in
            item.status == .issued && !overdue.contains(where: { $0.id == item.id })
        }
        if !others.isEmpty {
            let label = UILabel()
            label.font = Face.headline()
            label.textColor = DesignTokens.inkUI
            label.numberOfLines = 0
            label.text = "Still inside thirty days"
            stack.addArrangedSubview(label)
            for item in others {
                stack.addArrangedSubview(quietRow(for: item))
            }
        }
    }

    private func issuedDay(_ item: Item) -> String {
        let key = store.chart.issuedSpans.last { $0.itemID == item.id }?.dayKey
        if let key, let day = Figures.calendarDay(for: key) {
            return day
        }
        return "a day that could not be read"
    }

    private func overdueCard(for item: Item) -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = Gap.steps(1)
        column.isLayoutMarginsRelativeArrangement = true
        column.layoutMargins = UIEdgeInsets(top: Gap.steps(2), left: Gap.steps(2), bottom: Gap.steps(2), right: Gap.steps(2))
        column.backgroundColor = DesignTokens.surfaceUI
        column.layer.cornerRadius = Curve.card
        Elevation.apply(to: column)
        let name = UILabel()
        name.font = Face.title()
        name.textColor = DesignTokens.inkUI
        name.numberOfLines = 2
        name.text = item.name
        let meta = UILabel()
        meta.font = Face.body()
        meta.textColor = DesignTokens.inkUI
        meta.numberOfLines = 0
        meta.text = "Issued \(issuedDay(item))"
        column.addArrangedSubview(name)
        column.addArrangedSubview(meta)
        var config = UIButton.Configuration.filled()
        config.title = "Relinquish"
        config.baseBackgroundColor = DesignTokens.inkUI
        config.baseForegroundColor = DesignTokens.bgUI
        config.background.cornerRadius = Curve.chip
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        let button = UIButton(configuration: config)
        button.role = .destructive
        button.isEnabled = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addAction(UIAction { [weak self] _ in
            self?.confirm(item)
        }, for: .touchUpInside)
        column.addArrangedSubview(button)
        return column
    }

    private func quietRow(for item: Item) -> UIView {
        let column = UIStackView()
        column.axis = .vertical
        column.spacing = Gap.steps(1)
        column.isLayoutMarginsRelativeArrangement = true
        column.layoutMargins = UIEdgeInsets(top: Gap.steps(2), left: Gap.steps(2), bottom: Gap.steps(2), right: Gap.steps(2))
        column.backgroundColor = DesignTokens.surfaceUI
        column.layer.cornerRadius = Curve.card
        let name = UILabel()
        name.font = Face.headline()
        name.textColor = DesignTokens.inkUI
        name.numberOfLines = 2
        name.text = item.name
        let meta = UILabel()
        meta.font = Face.body()
        meta.textColor = DesignTokens.inkUI
        meta.numberOfLines = 0
        meta.text = "Issued \(issuedDay(item)). Still inside thirty days."
        column.addArrangedSubview(name)
        column.addArrangedSubview(meta)
        return column
    }

    private func confirm(_ item: Item) {
        let alert = UIAlertController(
            title: "Relinquish \(item.name)?",
            message: "The crate stays on the manifest and cannot be armed again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Relinquish", style: .destructive) { [weak self] _ in
            Task { await self?.relinquish(item.id) }
        })
        present(alert, animated: true)
    }

    private func relinquish(_ id: UUID) async {
        _ = await store.relinquish(itemID: id)
        store.show(query: "")
        ManifestDesk.shared.noteChanged()
    }
}
