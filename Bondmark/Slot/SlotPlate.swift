import Foundation

/// QR identity of a bay slot plate. Matched against the raw scan before digit runs.
struct SlotPlate: Codable, Sendable, Equatable, Hashable {
    var code: String

    /// Bay plates are lettered codes, not crate barcodes. `PLATE-BAY-A` is one.
    static func matches(_ payload: String) -> Bool {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^PLATE-[A-Za-z0-9]+(-[A-Za-z0-9]+)*$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    static func bayName(for code: String) -> String {
        let stem = code.split(separator: "-", maxSplits: 1).dropFirst().joined()
        let words = stem.split(separator: "-").map { String($0).lowercased().capitalized }
        let name = words.joined(separator: " ")
        return name.isEmpty ? "Bay" : name
    }
}
