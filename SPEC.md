# Bondmark — Build Specification

> Portfolio app 152, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Scan crate tags and bay slot plates to record what sits where on a local manifest.

| Field | Value |
| --- | --- |
| Product name | Bondmark |
| Bundle identifier | `com.bondmark.manifest` |
| Domain | https://bondmark-manifest.pro |
| Contact URL | https://bondmark-manifest.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `bmk_` |
| User-Agent | `Bondmark/1.0 (iOS; +https://bondmark-manifest.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Bondmark -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A bonded-store attendant scans a tagged crate and then scans the slot plate so every move is witnessed on the manifest and nothing lands on the wrong bay.

### 2.1 User flow

1. On the manifest, tap Scan and read an unknown barcode to register a new Item seated at Home.
2. Scan a known Item to arm the eight-second slot window, then scan a bay slot plate QR to write the seat.
3. Tap a row to flip status between In stock and Issued and type who holds it.
4. Open Lifecycle from the manifest toolbar to review long Issued spans and Relinquish frozen items.
5. Search by name or code on the manifest rail to focus an Item without scanning.
6. From an Item card, share or print an on-device QR label derived from its code or id.

### 2.2 Essential behaviour

- AVCaptureMetadataOutput scan for EAN-8, EAN-13, UPC-E, Code 128, and QR with simulator chips plus manual entry fallback
- Arm-then-seat transfers that require Item scan then Slot plate scan within the arm window
- Status chips for In stock, Issued, and Relinquished with optional assignee name
- Lifecycle overdue rail ranking Items Issued longer than thirty days
- Local in-memory search filtered by tag name and code with no remote catalog
- On-device QR generation and share sheet for labels
- CSV export of Items and SeatMarks from Settings

---

## 3. Uniqueness assignment for Bondmark

| Axis | Assigned value |
| --- | --- |
| Architecture | **Arm-slot encoding (a new scan writes Item and seats it at Home; a scan of a known Item writes ArmMark and opens an eight-second Slot window; a scan of a Slot plate while armed writes SeatMark and assignedSlot; a scan of anything else while armed writes SkewMark; Seat without Arm writes DriftMark; Relinquished freezes Arm; Issued older than thirty days ranks overdue; empty manifest writes Blank)** |
| UI approach | **UIKit UIKit Dynamics · canvas-first** |
| Naming convention | **Bonded-store / slot-plate lexicon** |
| File organization | **By manifest role (Manifest, Item, Slot, ArmMark, SeatMark, SkewMark, DriftMark, Home)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **resend · ledger-rows · high-contrast** |
| Typography | **Menlo** |
| Navigation pattern | **Manifest-locked chrome (the bonded manifest never leaves; Inventory and Lifecycle are UIKit modal segues; Settings pushes from the gear; arm and seat fuse on Inventory; Scan is a full-screen cover)** |
| AI art style | **Bauhaus geometric · typographic** |
| Functional twist | **Arm-then-seat (scan Item arms an eight-second Slot window; scan Slot plate writes SeatMark; Skew on wrong second scan; Drift on Seat without Arm)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — barcode_inventory

**Core** — A bonded-store attendant scans a tagged crate and then scans the slot plate so every move is witnessed on the manifest and nothing lands on the wrong bay.

**Audience** — Small shops, touring crews, and prop rooms that label crates and bays with barcodes but do not run warehouse software.

**User flow**

1. On the manifest, tap Scan and read an unknown barcode to register a new Item seated at Home.
2. Scan a known Item to arm the eight-second slot window, then scan a bay slot plate QR to write the seat.
3. Tap a row to flip status between In stock and Issued and type who holds it.
4. Open Lifecycle from the manifest toolbar to review long Issued spans and Relinquish frozen items.
5. Search by name or code on the manifest rail to focus an Item without scanning.
6. From an Item card, share or print an on-device QR label derived from its code or id.

**Essential features**

- AVCaptureMetadataOutput scan for EAN-8, EAN-13, UPC-E, Code 128, and QR with simulator chips plus manual entry fallback
- Arm-then-seat transfers that require Item scan then Slot plate scan within the arm window
- Status chips for In stock, Issued, and Relinquished with optional assignee name
- Lifecycle overdue rail ranking Items Issued longer than thirty days
- Local in-memory search filtered by tag name and code with no remote catalog
- On-device QR generation and share sheet for labels
- CSV export of Items and SeatMarks from Settings

**Twist** — Arm-then-seat. Home is the bonded manifest. Scan of an unknown code writes an Item, copies a fused name, and seats it at Home. Scan of a known Item that is not Relinquished writes an ArmMark, opens an eight-second Slot window, and refuses a second Arm while armed. Scan of a Slot plate while armed writes a SeatMark, moves the Item to that Slot, and clears the arm; any other scan during the window writes a SkewMark and keeps the arm. Arm on Relinquished is refused. Seat without a preceding Arm in the same pulse writes a DriftMark and is refused. Relinquish freezes an Item; new scans still resolve it but cannot Arm. Issued older than thirty days ranks on Lifecycle. Seed already registers one Item at Home and leaves Scan live so the first tap can Arm and the second can Seat on a seeded bay plate. Home verb is arm-then-seat, not hop-the-tag. Local only.

**Why this is not a repeat** — Stallage already ships stall-segment hop-the-tag with TrailMarks between stalls. This product keeps barcode_inventory scan, status, and lifecycle but changes the home verb to a two-scan slot witness with an arm window, uses UIKit storyboard segues with a lite RealityKit bay grid instead of SwiftUI crib segments, and never touches food slots or Open Food Facts.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Search + scan bar, status chips, asset cards.
- Invariant: Scan finds or creates draft inStock. Transfer writes TransferRecord, assignedTo, status issued. issued>30d = overdue. QR = code ?? id.
- Never: Camera denied → Settings. No Sweep game feeding real KPIs.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.
- Scan: AVFoundation + Vision; symbologies include `.qr`; digit runs 8–14 from QR/URL; UPC-A pad; Simulator chips + manual; stop session. Pre-permission CTA is Continue or Next (Guideline 5.1.1 — never Allow/Enable camera).

### 3.1 Architecture contract

Arm-slot encoding stores one Manifest. A scan of an unknown code writes an Item, copies a fused name built on device from the stem Crate and the code tail, marks it In stock, and seats it at Home. A scan of a known Item that is not Relinquished writes an ArmMark, opens an eight-second Slot window, and refuses a second Arm while that window is live. A Slot plate scan inside the window writes a SeatMark and assignedSlot and clears the arm, and any other scan in the window writes a SkewMark and keeps the arm until the eight seconds elapse. A Slot plate scan with no Arm in the same pulse writes a DriftMark and leaves the Item unmoved, Relinquish freezes further Arms while scans still resolve the Item, and an Item whose Issued day is older than thirty calendar days ranks overdue. An empty Manifest writes Blank, and the on-device label QR encodes the Item code when one is stored, otherwise the Item id.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

UIKit storyboard, canvas-first. The manifest root is a custom bay canvas, BayCanvasView, and that is the only UIKit Dynamics surface: one UIDynamicAnimator, snap and collision, so the armed crate token travels on the canvas. Reduce Motion skips the travel and fades the token to its seat. Every other screen is stock UIKit. The scan cover may host AVCaptureVideoPreviewLayer because capture requires it, with no second animator. Under the canvas, a UITableView draws comfortable ledger rows, tabular figures, and a running total that updates when a SeatMark lands. One hero, then rows of uneven density. The live Scan control wears the accent and uses a filled bordered button. Relinquish uses a destructive button. Rows, chips, and buttons hit at least 44 points across the whole control. Status chips read In stock, Issued, and Relinquished in words. Grouped reveals step 40 to 60 milliseconds and finish within 360 milliseconds. Reduce Motion shows the group at once. Interface style is Light, and every colour comes from DesignTokens. Radii are 20 and 12 through one accessor, with one shadow elevation. Voice is warm and brief. Empty copy invites, errors say what happened and what to do next. No emoji, and UI copy uses periods or commas.

### 3.3 Naming contract

Convention: Bonded-store / slot-plate lexicon.

Examples to follow: `Item`, `SlotPlate`, `writeSeatMark(_:)`, `assignedSlot`

### 3.4 Dependency contract

None. Zero external dependencies: no Swift Package Manager entry, no CocoaPods, no vendored source, and project.yml has no packages key. The only linked system frameworks are UIKit for the storyboard, segues, and UIKit Dynamics, Core Graphics for the bay canvas and the on-device QR, AVFoundation for AVCaptureMetadataOutput, and URLSession as the permitted networking stack. Manifest search filters Item name and code in memory. No request is sent, the assigned cgi search.pl page 8 endpoint is not called, and Open Food Facts is not used. No WebView, no analytics, and no remote config.

### 3.5 Navigation contract

The storyboard root is a navigation controller whose root is the bonded manifest, and that ledger is never popped. Tapping a row expands Inventory inline on the rail for status, assignee, and the label. A modal segue also presents Inventory where arm and seat fuse over the ledger. Lifecycle is a modal segue from the manifest toolbar for the overdue rail and Relinquish. Settings pushes from the gear. Scan is a full-screen modal cover. There is no TabView. After onboarding, process arguments are read once: today leaves Manifest up, log presents Inventory, goals presents Lifecycle, settings pushes Settings, and scan presents the cover. If onboarding is still up, that hook does not run.

### 3.6 Screen composition contract

Storyboard root is the bonded manifest ledger; Inventory detail expands inline on the rail; Lifecycle is a modal segue for overdue and relinquish; Scan is a full-screen cover; Settings pushes from gear; no TabView. Onboarding is three or four pages, with Continue or Next full width at the bottom, and Skip still writes defaults. Manifest holds the bay canvas, the search rail, status chips, the running total, Item rows, and Scan. Inventory is the inline row plus the modal where the eight-second arm and the SeatMark fuse. Lifecycle is the overdue rail and Relinquish. Scan is the full-screen capture cover with simulator chips and a manual field. Settings pushes CSV export of Items and SeatMarks, the contact link https://bondmark-manifest.pro/contact-us, reset, and re-run onboarding. Share and print use the system share sheet and print interaction from the Item, not a separate screen. An empty Manifest is a full page: generated art, the headline Scan your first crate, one supporting line, and Scan at the bottom.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By manifest role (Manifest, Item, Slot, ArmMark, SeatMark, SkewMark, DriftMark, Home)**

```
Bondmark/
  Manifest/ManifestViewController.swift
  Manifest/BayCanvasView.swift
  Manifest/ScanCoverViewController.swift
  Manifest/LifecycleViewController.swift
  Manifest/SettingsViewController.swift
  Item/Item.swift
  Item/InventoryViewController.swift
  Slot/Slot.swift
  Slot/SlotPlate.swift
  ArmMark/ArmMark.swift
  SeatMark/SeatMark.swift
  SkewMark/SkewMark.swift
  DriftMark/DriftMark.swift
  Home/HomeSeat.swift
  Home/BondChart.swift
  Home/BondStore.swift
  DesignTokens.swift
  Base.lproj/Main.storyboard
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Inventory
A first-class screen for **Inventory**. Must render empty, populated and error states.

### 5.3 Lifecycle
A first-class screen for **Lifecycle**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


**Scan (camera families). Mechanics from the white book scanner — add `.qr`.**

Capture:
- AVFoundation session + Vision `VNDetectBarcodesRequest` (or `AVCaptureMetadataOutput` with the same set).
- Symbologies must include `.qr` plus `.ean13`, `.ean8`, `.upce` (Code 128/39/93 if the domain uses them). Linear-only misses QR packs and QR-encoded EANs.
- Permission: notDetermined → `requestAccess` (system alert is the first ask). A pre-screen is allowed only if the proceed button is **Continue** or **Next**.
- Guideline 5.1.1 reject: any CTA that directs the grant — `Allow camera`, `Enable camera`, `Grant camera`, `Allow camera access`, or a bare `Allow` / `Enable` / `Grant` on the button that calls `requestAccess`.
- Denied/restricted → copy + Open Settings (`UIApplication.openSettingsURLString`). Never a second Allow/Enable button.
- No capture device (Simulator): sample-code chips + mandatory manual field. Fully usable without a camera.
- Start the session on appear; `stopRunning` on disappear and on background.
- Cooldown 1.5–2.0 s after a decode. Skip frames (every 3rd is enough). Ignore the same payload while a lookup is in flight.
- Continuous autofocus / autoexposure when supported. `alwaysDiscardsLateVideoFrames`. Preview `resizeAspectFill`.

Payload (camera, typed, pasted URL):
- Keep digit runs of length 8–14. A QR/URL may be text — extract those runs; do not require the whole payload to be digits.
- 12-digit UPC-A → prefix `0`.
- Try every candidate before miss. EAN-8/13, UPC-A/E, QR carrying any of those.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Asset** — named per this app's convention.
- **Transfer** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **resend · ledger-rows · high-contrast**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#FCFCFC` | Screen background |
| `surface` | `#F5F5F5` | Cards, rows, sheets |
| `ink` | `#121212` | Primary text and icons |
| `accent` | `#2D9E54` | Primary action, key figure, progress fill |
| `muted` | `#575757` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Bondmark/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Menlo**

The assigned move is one serif display and Menlo as the UI face, with a dark, short, wide headline feel. New York appears once, on the manifest masthead only, at most two lines and never above 34 points. Every other string is Menlo: Menlo-Bold for row titles, Menlo-Regular for body near 17 points, Menlo for captions, codes, and the running total. Six steps sit behind one UIFont accessor: display, title, headline, body, caption, micro. UIFontMetrics scales each step with Dynamic Type. Nothing goes below 12 points, and there is no fixed size that ignores the content size category. Counts, the arm seconds, and day keys go through NumberFormatter. At the largest accessibility size the masthead stays inside four lines and row titles stay readable. Day edges use Calendar.current.startOfDay, then an Int in YYYYMMDD form.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **20pt** for cards, sheets and primary surfaces; **12pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **UIKit UIKit Dynamics · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **UIKit UIKit Dynamics · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **dark** (Dark-tech: void surfaces, one glow or jewel, sparse chrome.)

Reference system: **resend** — steal rhythm and restraint, not their colours or logos.

Mood: **Email API. Minimal dark theme, monospace accents.**.

Home rhythm (`ledger-rows`, comfortable): Dense rows, tabular figures, a running total that moves.

Dark-tech: void surfaces, one glow or jewel, sparse chrome. Layout `ledger-rows`, density comfortable. Kit 20/12, shadow, bordered prominent. Palette recipe `high-contrast`. Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Serif display once; body stays the UI face. Reference type feel: dark.

Motion (`stagger`): Grouped reveals step 40-60ms, cap 360ms total. Last item must not arrive late. Reduce Motion: the group appears at once.

Voice (`warm`): Human and brief. Empty states invite. Errors stay calm and useful.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

UserDefaults holds one Codable Chart root, BondChart, schemaVersion 1, JSON under the single key bmk.chart.v1. The Chart's five collections are this manifest: Slots for places, Items for the crates, the optional live Arm for the session, Issued spans for runs, and the ArmMark, SeatMark, SkewMark, and DriftMark list for the witnessed moves. BondStore is the in-memory seam. Views never touch UserDefaults. Each mark schedules a debounced save of about 400 milliseconds, and the store flushes when the scene resigns active or enters background and after Relinquish or reset. Day keys are Int values in YYYYMMDD form taken from Calendar.current.startOfDay. Overdue is derived from the Issued day and is not a second stored list. A failed decode restores the backup key bmk.chart.v1.backup, then a Blank manifest, and does not crash. resetAllData() removes both keys and is reachable from Settings. Tests use a private suite. Simulator seed runs once behind bmk.demo.v1, only under targetEnvironment(simulator): it marks onboarding complete, writes four Slots including Home and a bay plate, writes several Items in mixed In stock and Issued states with one Issued span older than thirty days, leaves one In stock Item at Home so Scan can Arm, and never seeds a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Bondmark/1.0 (iOS; +https://bondmark-manifest.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.productivity`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_NSCameraUsageDescription: Bondmark uses the camera to read barcodes on labeled crates and QR codes on bay slot plates so each move is recorded on the manifest.
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.productivity
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Arm-then-seat (scan Item arms an eight-second Slot window; scan Slot plate writes SeatMark; Skew on wrong second scan; Drift on Seat without Arm)

The home verb is arm-then-seat on the bonded manifest, shown as Scan and the live eight-second window, and unit tests lock that verb. Scanning a known Item that is not Relinquished writes an ArmMark and starts the Slot window. Scanning the bay Slot plate inside that window writes a SeatMark, sets assignedSlot, and clears the arm. A second scan that is not a Slot plate writes a SkewMark and keeps the same arm until the window ends without writing another ArmMark. A Slot plate with no Arm in the same pulse writes a DriftMark and is refused, and Arm on a Relinquished Item is refused even though the scan still finds that Item. An Issued span older than thirty days ranks on Lifecycle, the SeatMark is the witnessed transfer and Issued stores the optional assignee, the label QR is the code or else the id, and the Simulator seed seats one Item at Home with Scan live so the first decode can Arm and the second can Seat on a seeded bay plate.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Bauhaus geometric · typographic**


Base prompt, reused and extended for every asset:

```
Bauhaus geometric print, flat and typographic. Solid circles, squares, and triangles arranged as a closed crate and a slot plate, with thick rules and a heavy central emblem. Even print-shop light, hard edges, one clear subject, no letters, no clay, no glass, no photograph.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `bmk_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `bmk_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `bmk_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `bmk_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `bmk_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `bmk_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `bmk_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `bmk_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `bmk_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `bmk_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `bmk_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Arm-then-seat (scan Item arms an eight-second Slot window; scan Slot plate writes SeatMark; Skew on wrong second scan; Drift on Seat without Arm)' feature screen. |
| 11 | `bmk_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `bmk_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`bmk_AppIcon`** — 1024x1024

```
A flat Bauhaus emblem of a solid square crate overlapping a solid circle plate, centered, filling an opaque canvas edge to edge, no text, no rounded mask, no alpha, subject inside the middle.
```

**`bmk_Splash`** — 1290x2796

```
A tall Bauhaus poster, one large square and one circle on a quiet middle band, geometric and typographic, filling the canvas, no text, no people.
```

**`bmk_Onboarding1`** — 1024x1536

```
A solid closed crate with a small rectangular tag, Bauhaus geometry, opaque subject centered, isolated for a cutout.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_Onboarding2`** — 1024x1536

```
A solid crate token beside a solid slot plate, a short bar between them, the two-scan gesture as one object, opaque and centered.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_Onboarding3`** — 1024x1536

```
A solid stack of geometric crates seated on a row of slot plates, Bauhaus, opaque, centered, the record after several moves.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_EmptyHome`** — 1024x1024

```
One solid closed crate in wood or painted board, fully opaque, calm, centered, waiting to be scanned.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_EmptyList`** — 1024x1024

```
One solid upright slot plate, thick and opaque, Bauhaus rectangle with a circle punch, centered, not a wire rack.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_CardBackdrop`** — 1200x800

```
A quiet Bauhaus field of large flat shapes and one thick rule, low detail, filling the wide canvas so type can sit on it, no text.
```

**`bmk_ControlFace`** — 512x512

```
A solid round scan stamp set in a square housing, metal or ceramic, Bauhaus, opaque, centered, the face of the scan control.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_TwistHero`** — 1024x1024

```
A solid crate token and a solid slot plate joined by a thick bar, the arm-then-seat emblem, opaque, centered, not an outline.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_SuccessMark`** — 512x512

```
A solid filled geometric seal, ceramic or metal, occupying the middle, opaque, not a thin ring and not a hollow frame.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bmk_HeaderDecor`** — 1200x600

```
A wide horizontal Bauhaus band of repeating triangles and one thick rule, filling the strip, no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`bmk.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `BondmarkTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Bondmark/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Bondmark -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Arm-slot encoding (a new scan writes Item and seats it at Home; a scan of a known Item writes ArmMark and opens an eight-second Slot window; a scan of a Slot plate while armed writes SeatMark and assignedSlot; a scan of anything else while armed writes SkewMark; Seat without Arm writes DriftMark; Relinquished freezes Arm; Issued older than thirty days ranks overdue; empty manifest writes Blank)** with no leakage across layers.
- [ ] UI approach matches **UIKit UIKit Dynamics · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Manifest-locked chrome (the bonded manifest never leaves; Inventory and Lifecycle are UIKit modal segues; Settings pushes from the gear; arm and seat fuse on Inventory; Scan is a full-screen cover)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Menlo** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Bondmark
xcodegen generate
xcodebuild build-for-testing -scheme Bondmark -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.bondmark.manifest/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Bondmark -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.bondmark.manifest/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Bondmark -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.bondmark.manifest/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
