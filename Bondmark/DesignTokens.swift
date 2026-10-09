import SwiftUI
import UIKit

/// SPEC section 7. The only place these hex values live — reach colours
/// and the font family through here. Keep this file and its values.
enum DesignTokens {
    /// #FCFCFC
    static let bg = Color(red: 0.988235, green: 0.988235, blue: 0.988235)
    static let bgHex = "#FCFCFC"
    /// #F5F5F5
    static let surface = Color(red: 0.960784, green: 0.960784, blue: 0.960784)
    static let surfaceHex = "#F5F5F5"
    /// #121212
    static let ink = Color(red: 0.070588, green: 0.070588, blue: 0.070588)
    static let inkHex = "#121212"
    /// #2D9E54
    static let accent = Color(red: 0.176471, green: 0.619608, blue: 0.329412)
    static let accentHex = "#2D9E54"
    /// #575757
    static let muted = Color(red: 0.341176, green: 0.341176, blue: 0.341176)
    static let mutedHex = "#575757"
    static let fontFamily = "Menlo"

    static let bgUI = UIColor(red: 0.988235, green: 0.988235, blue: 0.988235, alpha: 1)
    static let surfaceUI = UIColor(red: 0.960784, green: 0.960784, blue: 0.960784, alpha: 1)
    static let inkUI = UIColor(red: 0.070588, green: 0.070588, blue: 0.070588, alpha: 1)
    static let accentUI = UIColor(red: 0.176471, green: 0.619608, blue: 0.329412, alpha: 1)
    static let mutedUI = UIColor(red: 0.341176, green: 0.341176, blue: 0.341176, alpha: 1)
}

/// One spacing unit. Every inset is a multiple of this.
enum Gap {
    static let unit: CGFloat = 8
    static func steps(_ count: CGFloat) -> CGFloat { unit * count }
}

/// Card radius and chip radius. The only two corners in the app.
enum Curve {
    static let card: CGFloat = 20
    static let chip: CGFloat = 12
}

/// Single drop shadow for any surface that sits above another.
enum Elevation {
    static func apply(to view: UIView) {
        view.layer.shadowColor = DesignTokens.inkUI.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowRadius = Gap.unit
        view.layer.shadowOffset = CGSize(width: 0, height: Gap.unit / 2)
        view.layer.masksToBounds = false
    }
}

/// Six type steps. Masthead is the only serif. Everything else is Menlo.
enum Face {
    static func display() -> UIFont {
        let base = UIFont.systemFont(ofSize: 28, weight: .regular)
        let serif = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        let sized = UIFont(descriptor: serif, size: 28)
        let scaled = UIFontMetrics(forTextStyle: .title1).scaledFont(for: sized)
        return scaled.withSize(min(34, max(12, scaled.pointSize)))
    }

    static func title() -> UIFont { menlo(size: 20, bold: true, style: .title2) }
    static func headline() -> UIFont { menlo(size: 17, bold: true, style: .headline) }
    static func body() -> UIFont { menlo(size: 17, bold: false, style: .body) }
    static func caption() -> UIFont { menlo(size: 14, bold: false, style: .footnote) }
    static func micro() -> UIFont { menlo(size: 12, bold: false, style: .caption2) }

    private static func menlo(size: CGFloat, bold: Bool, style: UIFont.TextStyle) -> UIFont {
        let name = bold ? "Menlo-Bold" : "Menlo"
        let base = UIFont(name: name, size: size) ?? UIFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
        let scaled = UIFontMetrics(forTextStyle: style).scaledFont(for: base)
        if scaled.pointSize < 12 {
            return base.withSize(12)
        }
        return scaled
    }
}

enum Figures {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func whole(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? String(value)
    }

    private static let calendarDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Calendar day a stranger can read. Never the raw YYYYMMDD integer.
    static func calendarDay(for key: Int) -> String? {
        guard let date = DayKey.date(key) else { return nil }
        return calendarDay.string(from: date)
    }
}
