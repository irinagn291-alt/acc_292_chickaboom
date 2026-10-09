import Foundation

/// Crate on the manifest. Scan of an unknown code writes one of these, seated at Home, In stock.
struct Item: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var code: String?
    var name: String
    /// In stock, Issued, or Relinquished. Overdue is derived from the Issued day, not stored here.
    var status: ItemStatus
    var assignedSlot: UUID
    var assignee: String?

    /// Family transfer target. Same value as `assignedSlot`.
    var assignedTo: UUID { assignedSlot }

    /// On-device label. Code when one is stored, otherwise the id.
    var labelQR: String { code ?? id.uuidString }

    static func fusedName(code: String) -> String {
        let tail = String(code.suffix(4))
        return "Crate \(tail)"
    }
}

enum ItemStatus: String, Codable, Sendable, Equatable {
    case inStock
    case issued
    case relinquished
}
