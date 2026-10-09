import Foundation

/// The Home place every new crate is seated on until a SeatMark moves it.
enum HomeSeat {
    static let name = "Home"

    static func make(id: UUID = UUID()) -> Slot {
        Slot(id: id, name: name, plate: nil, isHome: true)
    }
}
