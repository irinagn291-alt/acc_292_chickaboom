# Bondmark

Bondmark is a bonded-store manifest for small shops, touring crews, and prop rooms. People already label crates and bays with barcodes. They do not run warehouse software. An attendant scans a crate, then scans the slot plate, and the move is witnessed on the device.

## Architecture

Arm-slot encoding keeps one manifest. A scan is not a row insert. It is a witness with a rule:

- An unknown code writes an Item, names it from the stem Crate plus the code tail, marks it In stock, and seats it at Home.
- A known Item that is not Relinquished writes an ArmMark and opens an eight second slot window. A second arm is refused while that window is live.
- A slot plate scan inside the window writes a SeatMark, sets assignedSlot, and clears the arm.
- Any other scan inside the window writes a SkewMark and leaves the arm up.
- A slot plate with no arm in the same pulse writes a DriftMark and does not move the crate.
- Relinquish freezes further arms. Scans still resolve the crate.
- An Issued day older than thirty calendar days ranks overdue.
- An empty manifest is Blank. The label QR is the code when one is stored, otherwise the item id.

This suits the product because the mistake that matters is seating a crate on the wrong bay. The data model is the two-scan witness, not a list of notes. UserDefaults holds one Codable chart under a single key, with a backup key and a debounced save after each mark. Screens talk only to BondStore.

## Unique feature

Arm-then-seat. Home is the bay canvas. Scan a known crate and the token travels toward a bay for eight seconds. Scan the plate to seat it. A wrong second scan skews. A plate with no arm drifts. The same fusion is on the Inventory sheet. Lifecycle ranks long Issued spans and can Relinquish.

## Look

Bauhaus geometric, typographic, high contrast, Menlo, ledger rows under one canvas. Generated art is filled in a later step. The prompts reserved for those images:

- `bmk_AppIcon`: A flat Bauhaus emblem of a solid square crate overlapping a solid circle plate, centered, filling an opaque canvas edge to edge, no text, no rounded mask, no alpha, subject inside the middle.
- `bmk_Splash`: A tall Bauhaus poster, one large square and one circle on a quiet middle band, geometric and typographic, filling the canvas, no text, no people.
- `bmk_Onboarding1`: A solid closed crate with a small rectangular tag, Bauhaus geometry, opaque subject centered, isolated for a cutout.
- `bmk_Onboarding2`: A solid crate token beside a solid slot plate, a short bar between them, the two-scan gesture as one object, opaque and centered.
- `bmk_Onboarding3`: A solid stack of geometric crates seated on a row of slot plates, Bauhaus, opaque, centered, the record after several moves.
- `bmk_EmptyHome`: One solid closed crate in wood or painted board, fully opaque, calm, centered, waiting to be scanned.
- `bmk_EmptyList`: One solid upright slot plate, thick and opaque, Bauhaus rectangle with a circle punch, centered, not a wire rack.
- `bmk_CardBackdrop`: A quiet Bauhaus field of large flat shapes and one thick rule, low detail, filling the wide canvas so type can sit on it, no text.
- `bmk_ControlFace`: A solid round scan stamp set in a square housing, metal or ceramic, Bauhaus, opaque, centered, the face of the scan control.
- `bmk_TwistHero`: A solid crate token and a solid slot plate joined by a thick bar, the arm-then-seat emblem, opaque, centered, not an outline.
- `bmk_SuccessMark`: A solid filled geometric seal, ceramic or metal, occupying the middle, opaque, not a thin ring and not a hollow frame.
- `bmk_HeaderDecor`: A wide horizontal Bauhaus band of repeating triangles and one thick rule, filling the strip, no letters.

## How this differs

Stallage hops a tag between stall segments. Bondmark keeps barcode inventory, status, and lifecycle, and changes the home verb to a two-scan slot witness with an arm window. Navigation is a storyboard: the manifest stays, Inventory and Lifecycle are modal, Settings pushes, Scan is a cover. There is no food catalog.

## Build

```
xcodegen generate
xcodebuild build-for-testing -scheme Bondmark -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
