import Foundation

/// Witness that a known, not Relinquished crate opened the eight-second slot window.
struct ArmMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var itemID: UUID
    var at: Date
}

/// Live arm. Cleared when the window elapses, when a SeatMark lands, or when that crate is Relinquished.
struct Arm: Codable, Sendable, Equatable {
    var itemID: UUID
    var openedAt: Date
    static let window: TimeInterval = 8

    func isLive(at date: Date) -> Bool {
        date.timeIntervalSince(openedAt) < Self.window && date.timeIntervalSince(openedAt) >= 0
    }
}
