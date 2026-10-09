import UIKit

/// Bonded manifest. The ledger never pops. Scan, search, and the bay canvas live here.
@MainActor
final class ManifestNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        navigationBar.tintColor = DesignTokens.inkUI
        view.backgroundColor = DesignTokens.bgUI
    }
}

@MainActor
final class ManifestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    private let store = ManifestDesk.shared.store
    private let canvas = BayCanvasView()
    private let table = UITableView(frame: .zero, style: .plain)
    private let search = UITextField()
    private let total = UILabel()
    private let armLine = UILabel()
    private let emptyArt = UIImageView()
    private let emptyTitle = UILabel()
    private let emptyBody = UILabel()
    private let emptyStack = UIStackView()
    private let scanButton = UIButton(type: .system)
    private var filter: ItemStatus?
    private var expanded: UUID?
    private var query = ""
    private var reviewRead = false
    private var staggered = Set<Int>()
    private var chipButtons: [UIButton] = []
    private var bootStarted = false
    private var armWatch: Task<Void, Never>?
    private var committing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.bgUI
        overrideUserInterfaceStyle = .light
        navigationItem.title = "Manifest"
        let lifecycle = UIBarButtonItem(
            title: "Lifecycle",
            style: .plain,
            target: self,
            action: #selector(openLifecycle)
        )
        let inventory = UIBarButtonItem(
            title: "Inventory",
            style: .plain,
            target: self,
            action: #selector(openInventoryFromChrome)
        )
        navigationItem.leftBarButtonItems = [lifecycle, inventory]
        let gear = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        gear.accessibilityLabel = "Settings"
        navigationItem.rightBarButtonItem = gear
        layoutChrome()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chartChanged),
            name: .manifestChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(enterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scanRequested),
            name: .requestScan,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        committing = false
        scanButton.isEnabled = true
        guard !bootStarted else { return }
        bootStarted = true
        Task { await boot() }
    }

    private func boot() async {
        await store.open()
        await store.seedDemoIfNeeded()
        store.show(query: query)
        render()
        if store.chart.onboardingComplete {
            consumeReview()
        } else {
            presentOnboarding()
        }
    }

    private func layoutChrome() {
        canvas.translatesAutoresizingMaskIntoConstraints = false
        table.translatesAutoresizingMaskIntoConstraints = false
        search.translatesAutoresizingMaskIntoConstraints = false
        total.translatesAutoresizingMaskIntoConstraints = false
        armLine.translatesAutoresizingMaskIntoConstraints = false
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        scanButton.translatesAutoresizingMaskIntoConstraints = false

        search.placeholder = "Name or code"
        search.font = Face.body()
        search.textColor = DesignTokens.inkUI
        search.backgroundColor = DesignTokens.surfaceUI
        search.layer.cornerRadius = Curve.chip
        search.autocorrectionType = .no
        search.autocapitalizationType = .none
        search.returnKeyType = .search
        search.delegate = self
        search.addTarget(self, action: #selector(queryEdited), for: .editingChanged)
        search.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Gap.steps(2), height: 44))
        search.leftViewMode = .always
        search.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        search.accessibilityLabel = "Search crates"

        total.font = Face.headline()
        total.textColor = DesignTokens.inkUI
        armLine.font = Face.caption()
        armLine.textColor = DesignTokens.mutedUI
        armLine.numberOfLines = 2

        canvas.heightAnchor.constraint(equalToConstant: Gap.steps(22)).isActive = true

        table.dataSource = self
        table.delegate = self
        table.backgroundColor = DesignTokens.bgUI
        table.separatorColor = DesignTokens.mutedUI.withAlphaComponent(0.35)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.register(LedgerRowCell.self, forCellReuseIdentifier: LedgerRowCell.reuse)
        table.keyboardDismissMode = .onDrag

        var scanConfig = UIButton.Configuration.filled()
        scanConfig.title = "Scan"
        scanConfig.baseBackgroundColor = DesignTokens.accentUI
        scanConfig.baseForegroundColor = DesignTokens.bgUI
        scanConfig.background.cornerRadius = Curve.chip
        scanConfig.background.strokeColor = DesignTokens.inkUI
        scanConfig.background.strokeWidth = 1
        scanConfig.contentInsets = NSDirectionalEdgeInsets(
            top: Gap.steps(2),
            leading: Gap.steps(2),
            bottom: Gap.steps(2),
            trailing: Gap.steps(2)
        )
        scanConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        scanButton.configuration = scanConfig
        scanButton.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted || !button.isEnabled ? 0.55 : 1
        }
        scanButton.addTarget(self, action: #selector(openScan), for: .touchUpInside)
        scanButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        scanButton.accessibilityLabel = "Scan"

        let header = UIStackView(arrangedSubviews: [headerBand(), masthead(), canvas, search, chipRow(), ledgerPlate()])
        header.axis = .vertical
        header.spacing = Gap.steps(2)
        header.isLayoutMarginsRelativeArrangement = true
        header.layoutMargins = UIEdgeInsets(top: Gap.steps(2), left: Gap.steps(2), bottom: Gap.steps(2), right: Gap.steps(2))
        header.translatesAutoresizingMaskIntoConstraints = false
        let headerWrap = UIView()
        headerWrap.addSubview(header)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: headerWrap.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: headerWrap.trailingAnchor),
            header.topAnchor.constraint(equalTo: headerWrap.topAnchor),
            header.bottomAnchor.constraint(equalTo: headerWrap.bottomAnchor)
        ])
        table.tableHeaderView = headerWrap

        emptyArt.contentMode = .scaleAspectFit
        emptyArt.image = UIImage(named: "bmk_EmptyHome")
        emptyArt.heightAnchor.constraint(equalToConstant: Gap.steps(20)).isActive = true
        emptyTitle.font = Face.title()
        emptyTitle.textColor = DesignTokens.inkUI
        emptyTitle.numberOfLines = 2
        emptyTitle.text = "Scan your first crate"
        emptyBody.font = Face.body()
        emptyBody.textColor = DesignTokens.mutedUI
        emptyBody.numberOfLines = 0
        emptyBody.text = "A new code sits at Home. Scan it again, then scan the slot plate."
        emptyStack.axis = .vertical
        emptyStack.spacing = Gap.steps(2)
        emptyStack.addArrangedSubview(emptyArt)
        emptyStack.addArrangedSubview(emptyTitle)
        emptyStack.addArrangedSubview(emptyBody)
        emptyStack.isHidden = true

        view.addSubview(table)
        view.addSubview(emptyStack)
        view.addSubview(scanButton)
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: guide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: scanButton.topAnchor, constant: -Gap.steps(1)),
            scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Gap.steps(2)),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Gap.steps(2)),
            scanButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Gap.steps(1)),
            emptyStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Gap.steps(3)),
            emptyStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Gap.steps(3)),
            emptyStack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Gap.steps(4))
        ])
    }

    private func headerBand() -> UIImageView {
        let image = UIImageView(image: UIImage(named: "bmk_HeaderDecor"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = Curve.chip
        image.backgroundColor = DesignTokens.surfaceUI
        image.isAccessibilityElement = false
        image.heightAnchor.constraint(equalToConstant: Gap.steps(6)).isActive = true
        return image
    }

    private func ledgerPlate() -> UIView {
        let plate = UIView()
        plate.backgroundColor = DesignTokens.surfaceUI
        plate.layer.cornerRadius = Curve.card
        Elevation.apply(to: plate)
        let backdrop = UIImageView(image: UIImage(named: "bmk_CardBackdrop"))
        backdrop.contentMode = .scaleAspectFill
        backdrop.clipsToBounds = true
        backdrop.layer.cornerRadius = Curve.card
        backdrop.isAccessibilityElement = false
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        plate.addSubview(backdrop)
        let column = UIStackView(arrangedSubviews: [total, armLine])
        column.axis = .vertical
        column.spacing = Gap.steps(1)
        column.translatesAutoresizingMaskIntoConstraints = false
        plate.addSubview(column)
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: plate.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: plate.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: plate.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: plate.bottomAnchor),
            column.leadingAnchor.constraint(equalTo: plate.leadingAnchor, constant: Gap.steps(2)),
            column.trailingAnchor.constraint(equalTo: plate.trailingAnchor, constant: -Gap.steps(2)),
            column.topAnchor.constraint(equalTo: plate.topAnchor, constant: Gap.steps(2)),
            column.bottomAnchor.constraint(equalTo: plate.bottomAnchor, constant: -Gap.steps(2))
        ])
        return plate
    }

    private func masthead() -> UILabel {
        let label = UILabel()
        label.text = "Seat the crate"
        label.font = Face.display()
        label.textColor = DesignTokens.inkUI
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func chipRow() -> UIStackView {
        let titles: [(String, ItemStatus?)] = [
            ("All", nil),
            ("In stock", .inStock),
            ("Issued", .issued),
            ("Relinquished", .relinquished)
        ]
        chipButtons = titles.map { title, status in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = Face.caption()
            button.titleLabel?.numberOfLines = 1
            button.titleLabel?.lineBreakMode = .byClipping
            button.titleLabel?.adjustsFontSizeToFitWidth = false
            button.setTitleColor(DesignTokens.inkUI, for: .normal)
            button.backgroundColor = DesignTokens.surfaceUI
            button.layer.cornerRadius = Curve.chip
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.tag = status == nil ? 0 : (status == .inStock ? 1 : status == .issued ? 2 : 3)
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            button.accessibilityLabel = title
            return button
        }
        let lead = UIStackView(arrangedSubviews: Array(chipButtons.prefix(3)))
        lead.axis = .horizontal
        lead.spacing = Gap.steps(1)
        lead.distribution = .fillEqually
        let tail = UIStackView(arrangedSubviews: Array(chipButtons.suffix(1)))
        tail.axis = .horizontal
        tail.distribution = .fill
        let column = UIStackView(arrangedSubviews: [lead, tail])
        column.axis = .vertical
        column.spacing = Gap.steps(1)
        return column
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = table.tableHeaderView else { return }
        let width = table.bounds.width
        let height = header.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        if header.frame.width != width || abs(header.frame.height - height) > 1 {
            header.frame = CGRect(x: 0, y: 0, width: width, height: height)
            table.tableHeaderView = header
        }
    }

    @objc private func chipTapped(_ sender: UIButton) {
        switch sender.tag {
        case 1: filter = .inStock
        case 2: filter = .issued
        case 3: filter = .relinquished
        default: filter = nil
        }
        paintChips()
        table.reloadData()
    }

    private func paintChips() {
        for button in chipButtons {
            let selected: Bool
            switch button.tag {
            case 1: selected = filter == .inStock
            case 2: selected = filter == .issued
            case 3: selected = filter == .relinquished
            default: selected = filter == nil
            }
            button.backgroundColor = selected ? DesignTokens.accentUI : DesignTokens.surfaceUI
            button.setTitleColor(selected ? DesignTokens.bgUI : DesignTokens.inkUI, for: .normal)
        }
    }

    @objc private func queryEdited() {
        query = search.text ?? ""
        Task {
            await store.focus(query: query)
            renderRows()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func chartChanged() {
        render()
    }

    @objc private func enterBackground() {
        Task { await store.notePhase(.background) }
    }

    @objc private func resignActive() {
        Task { await store.notePhase(.inactive) }
    }

    private func render() {
        canvas.render(store.chart)
        let seats = store.chart.seatMarks.count
        total.text = seats == 1 ? "1 seat written" : "\(Figures.whole(seats)) seats written"
        paintArm()
        watchArm()
        let blank = store.chart.items.isEmpty
        emptyStack.isHidden = !blank
        table.isHidden = blank
        canvas.isHidden = blank
        if let notice = store.restoreNotice, !notice.isEmpty {
            armLine.text = notice
        }
        paintChips()
        staggered.removeAll()
        renderRows()
        viewDidLayoutSubviews()
    }

    private func renderRows() {
        table.reloadData()
    }

    private func paintArm() {
        armLine.isHidden = false
        if let notice = store.restoreNotice, !notice.isEmpty {
            armLine.text = notice
            return
        }
        if let arm = store.chart.arm, arm.isLive(at: Date()) {
            let left = max(0, Int(ceil(Arm.window - Date().timeIntervalSince(arm.openedAt))))
            armLine.text = "Arm is open for \(Figures.whole(left)) seconds. Scan the slot plate."
            return
        }
        armLine.text = "Scan a known crate, then the slot plate."
    }

    private func watchArm() {
        armWatch?.cancel()
        guard store.chart.arm?.isLive(at: Date()) == true else { return }
        armWatch = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                let live = store.chart.arm?.isLive(at: Date()) == true
                paintArm()
                if !live {
                    canvas.render(store.chart)
                    return
                }
            }
        }
    }

    private var visibleItems: [Item] {
        store.focused.filter { item in
            guard let filter else { return true }
            return item.status == filter
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LedgerRowCell.reuse, for: indexPath) as! LedgerRowCell
        let item = visibleItems[indexPath.row]
        let slot = store.chart.slots.first { $0.id == item.assignedSlot }?.name ?? "Home"
        cell.fill(
            item: item,
            slot: slot,
            lead: indexPath.row == 0,
            expanded: expanded == item.id
        )
        cell.onFlip = { [weak self] in
            Task { await self?.flip(item.id) }
        }
        cell.onAssignee = { [weak self] name in
            Task { await self?.assign(item.id, name: name) }
        }
        cell.onShare = { [weak self] in self?.share(item) }
        cell.onPrint = { [weak self] in self?.printLabel(item) }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !staggered.contains(indexPath.row) else { return }
        staggered.insert(indexPath.row)
        if UIAccessibility.isReduceMotionEnabled {
            cell.alpha = 1
            return
        }
        cell.alpha = 0
        let delay = min(0.05 * Double(indexPath.row), 0.16)
        UIView.animate(withDuration: 0.2, delay: delay, options: [.curveEaseOut]) {
            cell.alpha = 1
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = visibleItems[indexPath.row]
        expanded = expanded == item.id ? nil : item.id
        table.reloadRows(at: [indexPath], with: .automatic)
    }

    private func flip(_ id: UUID) async {
        guard !committing else { return }
        committing = true
        defer { committing = false }
        let changed = await store.flipAvailability(itemID: id)
        guard changed else { return }
        store.show(query: query)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ManifestDesk.shared.noteChanged()
    }

    private func assign(_ id: UUID, name: String) async {
        await store.setAssignee(itemID: id, name: name)
        store.show(query: query)
        ManifestDesk.shared.noteChanged()
    }

    private func share(_ item: Item) {
        let image = LabelPlate.image(for: item.labelQR, side: 240)
        var items: [Any] = [item.labelQR]
        if let image { items.append(image) }
        let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(sheet, animated: true)
    }

    private func printLabel(_ item: Item) {
        guard let image = LabelPlate.image(for: item.labelQR, side: 240) else { return }
        let job = UIPrintInteractionController.shared
        job.printingItem = image
        job.present(animated: true)
    }

    @objc private func openLifecycle() {
        performSegue(withIdentifier: "showLifecycle", sender: nil)
    }

    @objc private func openInventoryFromChrome() {
        openInventory(itemID: expanded)
    }

    @objc private func openSettings() {
        performSegue(withIdentifier: "showSettings", sender: nil)
    }

    @objc private func scanRequested() {
        openScan()
    }

    @objc private func openScan() {
        guard !committing else { return }
        committing = true
        scanButton.isEnabled = false
        performSegue(withIdentifier: "showScan", sender: nil)
    }

    func replayOnboarding() {
        presentOnboarding()
    }

    func openInventory(itemID: UUID?) {
        performSegue(withIdentifier: "showInventory", sender: itemID)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let inventory = segue.destination as? InventoryViewController {
            inventory.focusedID = sender as? UUID ?? expanded
        }
    }

    private func presentOnboarding() {
        let board = OnboardingViewController()
        board.modalPresentationStyle = .fullScreen
        board.onDone = { [weak self] in
            self?.dismiss(animated: true) {
                self?.render()
                self?.consumeReview()
            }
        }
        present(board, animated: false)
    }

    private func consumeReview() {
        guard store.chart.onboardingComplete, !reviewRead else { return }
        reviewRead = true
        let key = ReviewLaunch.screen
        guard !ReviewLaunch.opensLedgerOnly(key) else { return }
        switch key {
        case "log":
            performSegue(withIdentifier: "showInventory", sender: nil)
        case "goals":
            performSegue(withIdentifier: "showLifecycle", sender: nil)
        case "settings":
            performSegue(withIdentifier: "showSettings", sender: nil)
        case "scan":
            performSegue(withIdentifier: "showScan", sender: nil)
        default:
            break
        }
    }

    func applyOutcome(_ outcome: ScanOutcome) {
        store.show(query: query)
        switch outcome {
        case .drafted, .armed, .seated:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .skewed:
            explain("That scan was not a slot plate. The arm stays open.")
        case .drifted:
            explain("Scan a crate first. The plate did not move anything.")
        case .refused(let message), .invalid(let message):
            explain(message)
        }
        ManifestDesk.shared.noteChanged()
    }

    private func explain(_ message: String) {
        let alert = UIAlertController(title: "Scan paused", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

/// Ledger row. The first row is taller so the list is not a stack of equals.
@MainActor
final class LedgerRowCell: UITableViewCell {
    static let reuse = "LedgerRowCell"
    var onFlip: (() -> Void)?
    var onAssignee: ((String) -> Void)?
    var onShare: (() -> Void)?
    var onPrint: (() -> Void)?

    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private let statusLabel = UILabel()
    private let detail = UIStackView()
    private let assignee = UITextField()
    private let flipButton = UIButton(type: .system)
    private var itemID: UUID?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = DesignTokens.bgUI
        selectionStyle = .none
        nameLabel.textColor = DesignTokens.inkUI
        nameLabel.numberOfLines = 2
        metaLabel.font = Face.caption()
        metaLabel.textColor = DesignTokens.mutedUI
        metaLabel.numberOfLines = 2
        statusLabel.font = Face.caption()
        statusLabel.textColor = DesignTokens.inkUI
        statusLabel.backgroundColor = DesignTokens.surfaceUI
        statusLabel.layer.cornerRadius = Curve.chip
        statusLabel.clipsToBounds = true
        statusLabel.textAlignment = .center

        assignee.font = Face.body()
        assignee.placeholder = "Who holds it"
        assignee.borderStyle = .none
        assignee.backgroundColor = DesignTokens.surfaceUI
        assignee.layer.cornerRadius = Curve.chip
        assignee.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        assignee.addTarget(self, action: #selector(commitAssignee), for: .editingDidEnd)
        assignee.accessibilityLabel = "Assignee"

        var flipConfig = UIButton.Configuration.filled()
        flipConfig.baseBackgroundColor = DesignTokens.inkUI
        flipConfig.baseForegroundColor = DesignTokens.bgUI
        flipConfig.background.cornerRadius = Curve.chip
        flipConfig.title = "Update status"
        flipButton.configuration = flipConfig
        flipButton.addTarget(self, action: #selector(flip), for: .touchUpInside)
        flipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        let share = symbolButton("Share label", symbol: "square.and.arrow.up", action: #selector(shareTapped))
        let print = symbolButton("Print label", symbol: "printer", action: #selector(printTapped))
        let actions = UIStackView(arrangedSubviews: [flipButton, share, print])
        actions.axis = .vertical
        actions.spacing = Gap.steps(1)

        detail.axis = .vertical
        detail.spacing = Gap.steps(1)
        detail.addArrangedSubview(assignee)
        detail.addArrangedSubview(actions)
        detail.isHidden = true

        let top = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = Gap.steps(1)
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byClipping
        statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        let column = UIStackView(arrangedSubviews: [top, metaLabel, detail])
        column.axis = .vertical
        column.spacing = Gap.steps(1)
        column.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(column)
        NSLayoutConstraint.activate([
            column.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Gap.steps(2)),
            column.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Gap.steps(2)),
            column.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Gap.steps(2)),
            column.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Gap.steps(2))
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Ledger rows are built in code")
    }

    func fill(item: Item, slot: String, lead: Bool, expanded: Bool) {
        itemID = item.id
        nameLabel.font = lead ? Face.title() : Face.headline()
        nameLabel.text = item.name
        let code = item.code ?? "unknown"
        metaLabel.text = "\(code), \(slot)"
        statusLabel.text = "  \(item.status.title)  "
        assignee.text = item.assignee
        detail.isHidden = !expanded
        let next = item.status == .issued ? "Mark in stock" : "Mark issued"
        var config = flipButton.configuration ?? .filled()
        config.title = next
        flipButton.configuration = config
        flipButton.isEnabled = item.status != .relinquished
        contentView.layoutMargins = UIEdgeInsets(
            top: lead ? Gap.steps(2) : Gap.steps(1),
            left: 0,
            bottom: lead ? Gap.steps(2) : Gap.steps(1),
            right: 0
        )
    }

    private func symbolButton(_ title: String, symbol: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .leading
        config.imagePadding = Gap.steps(1)
        config.baseForegroundColor = DesignTokens.inkUI
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = Face.headline()
            return next
        }
        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = title
        return button
    }

    @objc private func flip() { onFlip?() }
    @objc private func shareTapped() { onShare?() }
    @objc private func printTapped() { onPrint?() }
    @objc private func commitAssignee() { onAssignee?(assignee.text ?? "") }
}
