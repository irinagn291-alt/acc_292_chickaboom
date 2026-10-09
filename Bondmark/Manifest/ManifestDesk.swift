import Foundation

extension Notification.Name {
    /// Posted after a mark, a status change, or a reset so every screen redraws.
    static let manifestChanged = Notification.Name("bmk.manifest.changed")
    /// Inventory asks the manifest to open Scan after the modal dismisses.
    static let requestScan = Notification.Name("bmk.request.scan")
}

/// App-wide seam. Screens talk to the store through this desk, never to UserDefaults.
@MainActor
final class ManifestDesk {
    static let shared = ManifestDesk()
    let store = BondStore()
    private init() {}

    func noteChanged() {
        NotificationCenter.default.post(name: .manifestChanged, object: nil)
    }
}
