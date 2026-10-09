import Foundation

/// Witnessed transfer. Writes assignedSlot and moves the crate to Issued.
struct SeatMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var itemID: UUID
    var slotID: UUID
    var at: Date
    var assignee: String?
}

/// Family name for the seat witness.
typealias TransferRecord = SeatMark
