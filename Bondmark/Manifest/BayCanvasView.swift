import UIKit

/// The only UIKit Dynamics surface. An armed crate token snaps toward a bay.
/// Reduce Motion fades the token to that seat instead of traveling.
final class BayCanvasView: UIView {
    private var animator: UIDynamicAnimator!
    private let token = UIView()
    private var slotColumns: [UIView] = []
    private let columns = UIStackView()
    private var chart = BondChart.blank()
    private var signature = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        common()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        common()
    }

    private func common() {
        backgroundColor = DesignTokens.surfaceUI
        layer.cornerRadius = Curve.card
        clipsToBounds = false
        Elevation.apply(to: self)
        columns.axis = .horizontal
        columns.distribution = .fillEqually
        columns.alignment = .fill
        columns.spacing = Gap.steps(1)
        columns.translatesAutoresizingMaskIntoConstraints = false
        addSubview(columns)
        NSLayoutConstraint.activate([
            columns.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Gap.steps(1)),
            columns.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Gap.steps(1)),
            columns.topAnchor.constraint(equalTo: topAnchor, constant: Gap.steps(1)),
            columns.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Gap.steps(1))
        ])
        animator = UIDynamicAnimator(referenceView: self)
        token.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        token.layer.cornerRadius = Curve.chip
        token.backgroundColor = DesignTokens.accentUI
        token.isHidden = true
        token.isAccessibilityElement = true
        token.accessibilityLabel = "Armed crate"
        addSubview(token)
    }

    func render(_ chart: BondChart) {
        self.chart = chart
        signature = ""
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 1 else { return }
        rebuildLabels()
        moveToken()
    }

    private func rebuildLabels() {
        let seated = chart.slots.map { slot in
            chart.items.filter { $0.assignedSlot == slot.id && $0.status != .relinquished }.map(\.name).joined(separator: ",")
        }.joined(separator: "|")
        let key = "\(seated)-\(Int(bounds.width))"
        guard key != signature || slotColumns.isEmpty else { return }
        signature = key
        slotColumns.forEach { view in
            columns.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        slotColumns = chart.slots.map { slot in
            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .fill
            column.spacing = Gap.steps(1)
            let occupants = chart.items.filter { $0.assignedSlot == slot.id && $0.status != .relinquished }
            if occupants.isEmpty {
                column.addArrangedSubview(plate(text: "Open bay", filled: false))
            } else {
                for item in occupants {
                    column.addArrangedSubview(plate(text: item.name, filled: true))
                }
            }
            let bay = UILabel()
            bay.font = Face.caption()
            bay.textColor = DesignTokens.inkUI
            bay.textAlignment = .center
            bay.numberOfLines = 2
            bay.adjustsFontForContentSizeCategory = true
            bay.text = slot.name
            column.addArrangedSubview(bay)
            columns.addArrangedSubview(column)
            return column
        }
        bringSubviewToFront(token)
    }

    private func plate(text: String, filled: Bool) -> UILabel {
        let label = UILabel()
        label.font = Face.caption()
        label.textColor = DesignTokens.inkUI
        label.backgroundColor = filled ? DesignTokens.accentUI.withAlphaComponent(0.22) : DesignTokens.bgUI
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontForContentSizeCategory = true
        label.layer.cornerRadius = Curve.chip
        label.clipsToBounds = true
        label.text = text
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return label
    }

    private func moveToken() {
        let live = chart.arm.flatMap { arm -> UUID? in
            arm.isLive(at: Date()) ? arm.itemID : nil
        }
        let next = "token-\(live?.uuidString ?? "none")-\(Int(bounds.width))-\(chart.slots.count)"
        guard token.accessibilityHint != next else { return }
        token.accessibilityHint = next
        animator.removeAllBehaviors()
        guard let itemID = live,
              let item = chart.items.first(where: { $0.id == itemID }) else {
            token.isHidden = true
            return
        }
        token.isHidden = false
        token.accessibilityLabel = item.name
        let origin = point(for: item.assignedSlot)
        let destinationID = chart.slots.first(where: { !$0.isHome })?.id ?? item.assignedSlot
        let destination = point(for: destinationID)
        token.center = origin
        if UIAccessibility.isReduceMotionEnabled {
            token.center = destination
            token.alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.token.alpha = 1
            }
            return
        }
        token.alpha = 1
        let snap = UISnapBehavior(item: token, snapTo: destination)
        snap.damping = 0.72
        let collision = UICollisionBehavior(items: [token])
        collision.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collision)
        animator.addBehavior(snap)
    }

    private func point(for slotID: UUID) -> CGPoint {
        let index = chart.slots.firstIndex(where: { $0.id == slotID }) ?? 0
        return slotPoint(index: index, count: max(chart.slots.count, 1))
    }

    private func slotPoint(index: Int, count: Int) -> CGPoint {
        let inset = Gap.steps(5)
        let span = max(0, bounds.width - inset * 2)
        let step = count <= 1 ? 0 : span / CGFloat(count - 1)
        return CGPoint(x: inset + step * CGFloat(index), y: bounds.midY - Gap.steps(1))
    }
}
