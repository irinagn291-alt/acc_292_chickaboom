import Foundation

/// Pulls barcode candidates out of a camera, typed, or pasted payload.
enum CodeScan {
    /// Maximal digit runs of length 8...14. A 12-digit UPC-A also yields a 0-prefixed candidate.
    static func candidates(in payload: String) -> [String] {
        var results: [String] = []
        var run = ""
        func flush() {
            if (8...14).contains(run.count) {
                results.append(run)
                if run.count == 12 {
                    results.append("0" + run)
                }
            }
            run = ""
        }
        for character in payload {
            if character.isNumber {
                run.append(character)
            } else {
                flush()
            }
        }
        flush()
        return results
    }
}
