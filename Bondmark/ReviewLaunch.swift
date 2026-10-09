import Foundation

/// Reads `-ReviewScreen` after onboarding on the bonded manifest.
/// today stays on the ledger. log, goals, settings, and scan open other covers.
/// Those keys are launch arguments, not tabs.
enum ReviewLaunch {
    static let argument = "-ReviewScreen"

    /// The key after `-ReviewScreen`, or nil on a normal launch.
    static var screen: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: argument), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

    /// Manifest keys the live driver may open. Unknown keys stay on the ledger.
    static func opensLedgerOnly(_ key: String?) -> Bool {
        key == nil || key == "today"
    }
}
