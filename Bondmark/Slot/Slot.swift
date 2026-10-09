import Foundation

/// A place on the bay. Home is the seat a new crate gets. A bay plate is scannable.
struct Slot: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var plate: SlotPlate?
    var isHome: Bool
}
