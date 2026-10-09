import Foundation

/// A second scan during the arm window that was not a slot plate. The same arm stays open.
struct SkewMark: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var itemID: UUID
    var payload: String
    var at: Date
}
