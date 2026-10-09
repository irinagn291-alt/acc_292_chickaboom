import UIKit

/// Inventory. One next tap: mark the chosen crate, or scan the slot plate while the arm is open.
@MainActor
final class InventoryViewController: UIViewController {
    var focusedID: UUID?
    private let store = ManifestDesk.shared.store
    private let stack = UIStackView()
    private let primary = UIButton(type: .system)
    private var armWatch: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        navigationItem.title = "Inventory"
        stack.axis = .vertical
        stack.spacing = Gap.steps(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        primary.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .onDrag
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        view.addSubview(primary)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: guide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: primary.topAnchor, constant: -Gap.steps(1)),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: Gap.steps(2)),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -Gap.steps(2)),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: Gap.steps(2)),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -Gap.steps(2)),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -Gap.steps(4)),
            primary.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Gap.steps(2)),
            primary.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Gap.steps(2)),
            primary.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Gap.steps(1)),
            primary.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        var config = UIButton.Configuration.filled()
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
        primary.configuration = config
        primary.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted || !button.isEnabled ? 0.55 : 1
        }
        primary.addAction(UIAction { [weak self] _ in
            self?.primaryTapped()
        }, for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(redraw), name: .manifestChanged, object: nil)
        render()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        armWatch?.cancel()
    }

    @objc private func redraw() { render() }

    private var focused: Item? {
        store.chart.items.first { $0.id == focusedID } ?? store.chart.items.first
    }

    private var armIsLive: Bool {
        store.chart.arm?.isLive(at: Date()) == true
    }

    private func render() {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if let message = store.restoreNotice {
            let notice = UILabel()
            notice.font = Face.body()
            notice.textColor = DesignTokens.inkUI
            notice.numberOfLines = 0
            notice.text = message
            stack.addArrangedSubview(notice)
            let title = label("Inventory could not refresh", font: Face.title(), color: DesignTokens.inkUI)
            let body = label("The last saved manifest is what you can edit. Try the row again.", font: Face.body(), color: DesignTokens.mutedUI)
            stack.addArrangedSubview(title)
            stack.addArrangedSubview(body)
            primary.isHidden = true
            return
        }
        primary.isHidden = false
        let items = store.chart.items
        if items.isEmpty {
            let art = UIImageView(image: UIImage(named: "bmk_EmptyList"))
            art.contentMode = .scaleAspectFit
            art.heightAnchor.constraint(equalToConstant: Gap.steps(20)).isActive = true
            stack.addArrangedSubview(art)
            stack.addArrangedSubview(label("No crates yet", font: Face.title(), color: DesignTokens.inkUI))
            stack.addArrangedSubview(label("Scan a code on the manifest. It will sit here as In stock at Home.", font: Face.body(), color: DesignTokens.mutedUI))
            primary.isEnabled = false
            var config = primary.configuration ?? .filled()
            config.title = "Mark issued"
            primary.configuration = config
            return
        }
        if focusedID == nil {
            focusedID = items.first?.id
        }
        let chosen = focused
        let heading = label(headline(for: chosen), font: Face.display(), color: DesignTokens.inkUI)
        stack.addArrangedSubview(heading)
        stack.addArrangedSubview(label(supportLine(for: chosen), font: Face.body(), color: DesignTokens.inkUI))

        if armIsLive, let arm = store.chart.arm, let armed = items.first(where: { $0.id == arm.itemID }) {
            let left = max(0, Int(ceil(Arm.window - Date().timeIntervalSince(arm.openedAt))))
            let plate = label(
                "Arm window open on \(armed.name). \(Figures.whole(left)) seconds left. Scan the slot plate.",
                font: Face.headline(),
                color: DesignTokens.inkUI
            )
            plate.backgroundColor = DesignTokens.surfaceUI
            plate.layer.cornerRadius = Curve.card
            stack.addArrangedSubview(plate)
            watchArm()
        }

        for item in items {
            stack.addArrangedSubview(row(for: item, selected: item.id == focusedID))
        }
        paintPrimary(for: chosen)
    }

    private func headline(for item: Item?) -> String {
        guard let item else { return "Choose a crate" }
        if armIsLive { return "Scan the slot plate" }
        if item.status == .issued { return "Mark \(item.name) in stock" }
        if item.status == .relinquished { return "\(item.name) is frozen" }
        return "Mark \(item.name) issued"
    }

    private func supportLine(for item: Item?) -> String {
        guard let item else { return "Pick a crate, then use the button below." }
        let slot = store.chart.slots.first { $0.id == item.assignedSlot }?.name ?? "Home"
        return "\(item.name) is \(item.status.title) at \(slot). \(issuedLine(item))"
    }

    private func issuedLine(_ item: Item) -> String {
        guard item.status == .issued else {
            return "It has not been issued."
        }
        let key = store.chart.issuedSpans.last { $0.itemID == item.id }?.dayKey
        if let key, let day = Figures.calendarDay(for: key) {
            return "Issued \(day)."
        }
        return "Issued on a day that could not be read."
    }

    private func paintPrimary(for item: Item?) {
        var config = primary.configuration ?? .filled()
        if armIsLive {
            config.title = "Scan the slot plate"
            primary.isEnabled = true
        } else if let item, item.status != .relinquished {
            config.title = item.status == .issued ? "Mark in stock" : "Mark issued"
            primary.isEnabled = true
        } else {
            config.title = "Choose another crate"
            primary.isEnabled = false
        }
        primary.configuration = config
        primary.accessibilityLabel = config.title
    }

    private func primaryTapped() {
        if armIsLive {
            dismiss(animated: true) {
                NotificationCenter.default.post(name: .requestScan, object: nil)
            }
            return
        }
        guard let id = focused?.id else { return }
        Task { await flip(id) }
    }

    private func row(for item: Item, selected: Bool) -> UIView {
        var chooseConfig = UIButton.Configuration.plain()
        chooseConfig.title = "\(item.name)\n\(rowDetail(item))"
        chooseConfig.titleAlignment = .leading
        chooseConfig.baseForegroundColor = DesignTokens.inkUI
        chooseConfig.background.backgroundColor = selected ? DesignTokens.surfaceUI : DesignTokens.bgUI
        chooseConfig.background.cornerRadius = Curve.card
        chooseConfig.contentInsets = NSDirectionalEdgeInsets(
            top: Gap.steps(2),
            leading: Gap.steps(2),
            bottom: Gap.steps(2),
            trailing: Gap.steps(2)
        )
        chooseConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        let choose = UIButton(configuration: chooseConfig)
        choose.contentHorizontalAlignment = .leading
        choose.titleLabel?.numberOfLines = 0
        choose.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        choose.accessibilityLabel = selected ? "Chosen \(item.name)" : "Choose \(item.name)"
        choose.addAction(UIAction { [weak self] _ in
            self?.focusedID = item.id
            self?.render()
        }, for: .touchUpInside)
        if selected, item.status != .relinquished {
            let field = UITextField()
            field.text = item.assignee
            field.placeholder = "Who holds it"
            field.font = Face.body()
            field.textColor = DesignTokens.inkUI
            field.backgroundColor = DesignTokens.bgUI
            field.layer.cornerRadius = Curve.chip
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            field.accessibilityLabel = "Assignee"
            field.addAction(UIAction { [weak self] action in
                let text = (action.sender as? UITextField)?.text
                Task { await self?.saveAssignee(item.id, text) }
            }, for: .editingDidEnd)
            let wrap = UIStackView(arrangedSubviews: [choose, field])
            wrap.axis = .vertical
            wrap.spacing = Gap.steps(1)
            wrap.isLayoutMarginsRelativeArrangement = true
            wrap.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            wrap.backgroundColor = DesignTokens.surfaceUI
            wrap.layer.cornerRadius = Curve.card
            Elevation.apply(to: wrap)
            return wrap
        }
        return choose
    }

    private func rowDetail(_ item: Item) -> String {
        let slot = store.chart.slots.first { $0.id == item.assignedSlot }?.name ?? "Home"
        if item.status == .issued {
            let key = store.chart.issuedSpans.last { $0.itemID == item.id }?.dayKey
            if let key, let day = Figures.calendarDay(for: key) {
                return "\(item.status.title) at \(slot). Issued \(day)."
            }
        }
        return "\(item.status.title) at \(slot)."
    }

    private func label(_ text: String, font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func watchArm() {
        armWatch?.cancel()
        armWatch = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                render()
                if !armIsLive { return }
            }
        }
    }

    private func flip(_ id: UUID) async {
        _ = await store.flipAvailability(itemID: id)
        store.show(query: "")
        ManifestDesk.shared.noteChanged()
    }

    private func saveAssignee(_ id: UUID, _ text: String?) async {
        await store.setAssignee(itemID: id, name: text)
        ManifestDesk.shared.noteChanged()
    }
}
