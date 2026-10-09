import Foundation

/// A slot plate scan with no arm in the same pulse. The crate does not move.
struct DriftMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var slotID: UUID
    var at: Date
}
