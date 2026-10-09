<!-- gf-brief source=b5da05267ea133e8e3ea4364d14418c95b38d6d2874f2fcf1ea276cd6b90d9e4 written=2026-10-09T13:25:22+03:00 -->
# Bondmark

## What it is

Bondmark is a local crate-and-bay manifest for people who already label crates and slot plates and do not run warehouse software. An attendant scans a labeled crate, then scans the bay slot plate, so each move is written on the manifest. It is for small shops, touring crews, and prop rooms that need a record of what sits where.

## Launch and onboarding

Cold launch shows the system launch screen (no on-screen wordmark), then either the introduction or Manifest.

If the introduction has not been finished, three full-screen pages appear. Each page has art, a title, a body, **Skip**, and a primary button.

1. Title: **Bond the bay**. Body: **Scan a labeled crate, then the slot plate, so the move is witnessed on the manifest.** Buttons: **Skip**, **Next**.
2. Title: **Arm, then seat**. Body: **A known crate opens an eight second window. Scan the bay plate before it closes.** Buttons: **Skip**, **Next**.
3. Title: **Keep the record**. Body: **Issued crates older than thirty days show on Lifecycle. Relinquish freezes a crate.** Buttons: **Skip**, **Continue**.

**Next** advances a page. **Continue** on the last page, or **Skip** on any page, finishes the introduction and shows Manifest.

On a physical device the first launch is this introduction, then an empty Manifest. On Simulator the first launch can skip the introduction and open Manifest already filled (see Starter content). Later launches go straight to Manifest if the introduction was finished.

There is no sign-in and no permission ask on launch. Camera is asked only after the person opens Scan.

## Screens

There is no tab bar. Manifest stays on screen. **Lifecycle** and **Inventory** open as sheets. **Settings** pushes on from the gear. **Scan** covers the screen.

### Manifest

Navigation title: **Manifest**.

Chrome:

- **Lifecycle** (left). Opens the Lifecycle sheet.
- **Inventory** (left). Opens the Inventory sheet. If a crate row is expanded, that crate is the one Inventory focuses.
- Gear (right), spoken as **Settings**. Pushes Settings.
- **Scan** (bottom). Opens the Scan cover. The control dims and will not open a second Scan while one is opening.

Masthead: **Seat the crate**. A decorative header band sits above it. A bay canvas under that shows each place by name. An empty place reads **Open bay**. A seated crate shows its name on that bay. While a crate is armed, a token on the canvas stands for that crate (spoken as the crate name, or **Armed crate** before a name is set).

Search field placeholder: **Name or code** (spoken as **Search crates**). Typing filters the list by crate name or code. The keyboard search key dismisses the keyboard.

Status chips: **All**, **In stock**, **Issued**, **Relinquished**. They filter the list. **All** is the starting filter.

Ledger plate:

- Seat total: **1 seat written**, or **N seats written** (N follows the device number format).
- Guidance: **Scan a known crate, then the slot plate.**
- While armed: **Arm is open for N seconds. Scan the slot plate.** The count drops each second until the window closes.
- If the saved manifest could not be read, that guidance line is replaced by the restore sentence (see Behaviours).

Empty Manifest (no crates at all) hides the canvas and the list and shows:

- **Scan your first crate**
- **A new code sits at Home. Scan it again, then scan the slot plate.**
- **Scan** stays at the bottom.

Crate rows (when the list is not empty):

- Name, for example **Crate 3457**. A new scan is named **Crate** plus the last four characters of the code.
- Status chip: **In stock**, **Issued**, or **Relinquished**.
- Meta line: `code, place`, for example **5901234123457, Home**. A crate with no stored code shows **unknown** in place of the code. The place is **Home** until a seat is written, then the bay name (**Bay A**, **Dock**, **Cage**, or a name taken from a new plate).

Tap a row to expand or collapse it. The first row uses a larger name. Expanded controls:

- **Who holds it** (spoken as **Assignee**). Type a name. It is kept when the field loses focus.
- **Mark issued** when the crate is In stock. Sets status to Issued and records the issued day. Does not move the crate to a bay.
- **Mark in stock** when the crate is Issued. Sets status to In stock. Does not move the crate.
- Both of those stay dimmed when the crate is Relinquished.
- **Share label**. Opens the system share sheet with the crate code and a QR picture of that code.
- **Print label**. Opens the system print sheet with that QR picture.

### Scan

Full-screen cover. Close is an X, spoken as **Close**. It dismisses Scan and returns to Manifest.

When a camera is present and allowed:

- **Point at a crate barcode or a slot plate.**
- Live camera preview.
- Field **Type a code** (spoken as **Manual code**).
- **Use code**. Submits the typed value.

When camera access is denied or restricted:

- **The camera is off. Open Settings to change it, or type the code below.**
- **Open Settings**. Opens the iOS Settings page for Bondmark.
- **Type a code** and **Use code** still work.

When the camera does not start:

- **The camera did not start. Type the code instead.**
- **Type a code** and **Use code** still work.

When the device has no camera (typical Simulator):

- **No camera on this device. Use a sample code or type one.**
- Sample buttons: **5901234123457**, **4006381333931**, **PLATE-BAY-A**, **PLATE-DOCK**, **012345678905**. Each button uses that code at once.
- **Type a code** and **Use code** still work.

A successful new crate, a successful arm, or a successful seat closes Scan and returns to Manifest. A paused scan leaves Scan open. The pause alert title is **Scan paused**, with **OK**, and one of these messages:

- **Enter a code or scan a crate.**
- **That scan has no crate code. Use 8 to 14 digits, or a bay plate.**
- **This crate is relinquished. Scan a crate that is still in stock.**
- **That scan was not a slot plate. The arm stays open.**
- **Scan a crate first. The plate did not move anything.**

The pause alert is shown on Manifest. If Scan is still up, Close Scan to read it, then continue.

What a scan does:

- An unknown crate code (8 to 14 digits, including a code found inside other text) adds a crate named **Crate** plus the last four characters, status **In stock**, place **Home**.
- A known crate that is not Relinquished opens the eight-second arm. Scan the slot plate before the count reaches 0.
- A plate code such as **PLATE-BAY-A** or **PLATE-DOCK**, while armed, seats that crate on that bay, sets status to **Issued**, records the issued day, and closes the arm. An unknown plate that matches the **PLATE-…** shape adds a new bay (for example **PLATE-BAY-A** becomes **Bay A**) and seats there.
- A plate with no live arm does not move anything.
- Another crate code while armed does not seat and does not start a second arm.
- A Relinquished crate will not arm.

**Use code** on an empty or blank field does nothing. Repeating the same code within about two seconds is ignored.

The first time Scan opens on a device with a camera and the person has not answered yet, iOS shows the system camera dialog. There is no in-app **Allow** or **Enable** button.

### Inventory

Opens as a sheet from **Inventory**. There is no Close or Done on the sheet. Swipe down to return to Manifest. The sheet does not show a navigation title. The headline on the page is the action for the chosen crate.

Empty (no crates):

- **No crates yet**
- **Scan a code on the manifest. It will sit here as In stock at Home.**
- Bottom button **Mark issued**, dimmed.

Restore failure:

- The restore sentence.
- **Inventory could not refresh**
- **The last saved manifest is what you can edit. Try the row again.**
- No bottom button on this state.

Populated:

- Headline is one of: **Choose a crate**; **Scan the slot plate** while armed; **Mark {name} issued**; **Mark {name} in stock**; **{name} is frozen**.
- Support line: **Pick a crate, then use the button below.** or **{name} is {status} at {place}. {issued line}**
  - Issued line when not issued: **It has not been issued.**
  - Issued line when the day is known: **Issued {medium date}.** The date follows the device region (for example 8 Oct 2026).
  - Issued line when the day cannot be read: **Issued on a day that could not be read.**
- While armed: **Arm window open on {name}. N seconds left. Scan the slot plate.**
- A row per crate. Chosen row is spoken **Chosen {name}**; others **Choose {name}**. The row shows the name and **{status} at {place}.** or **{status} at {place}. Issued {date}.**
- On the chosen crate that is not Relinquished: **Who holds it**.

Bottom button:

- **Scan the slot plate** while armed. Dismisses Inventory and opens Scan.
- **Mark issued** or **Mark in stock** for a crate that is not Relinquished. Flips status the same way as the Manifest row.
- **Choose another crate**, dimmed, when the chosen crate is Relinquished.

Tap a crate row to choose it.

### Lifecycle

Opens as a sheet from **Lifecycle**. No Close or Done. Swipe down to return to Manifest. Navigation title **Lifecycle** is set but the sheet has no navigation bar. On-screen heading: **Issued too long**.

Empty (nothing issued longer than thirty days, and no restore sentence):

- **Nothing is overdue**
- **A crate issued longer than thirty days will rank here. Tap Relinquish to freeze it.**

Restore failure (shown above the list when present):

- The restore sentence.
- **Relinquish still writes when an overdue crate is listed.**

When an overdue crate exists:

- Lead line: **{name} has been out since {date}. Tap Relinquish.** If the day cannot be read: **{name} has been out since a day that could not be read. Tap Relinquish.**
- Each overdue card: crate name, **Issued {date}**, and **Relinquish**.

**Relinquish** asks:

- Title: **Relinquish {name}?**
- Body: **The crate stays on the manifest and cannot be armed again.**
- **Cancel** or **Relinquish**.

Confirming sets status to **Relinquished**. The crate remains on Manifest. It cannot be armed again. **Mark issued** and **Mark in stock** stay dimmed.

Issued crates that are still inside thirty days appear under **Still inside thirty days**, each as **Issued {date}. Still inside thirty days.** Those rows have no **Relinquish** control.

In-stock crates do not appear here.

### Settings

Pushed from the gear. Navigation title: **Settings**. Back returns to **Manifest**.

Heading: **The record**.

When the ledger has crates: **N crates on the ledger. N seats witnessed.**

When the ledger is empty and there is no restore sentence:

- **Nothing to export yet**
- **Scan a crate on the manifest. The ledger can be exported after that.**

When a restore sentence is present, it is shown, plus **Try again**, which reloads the saved manifest.

Always present:

- **Export CSV**. Builds a spreadsheet of crates and seats and opens the system share sheet. The shared file is named **bondmark-manifest.csv**. If the file cannot be written: title **Export failed**, body **The ledger could not be written. Try again in a moment.**, button **OK**.
- **Contact**. Opens the Bondmark support page.
- **Show introduction**. Returns to Manifest and plays the three introduction pages again. **Skip** or **Continue** finishes them as on first launch.
- **Reset manifest**. Asks **Reset the manifest?** / **Every crate, seat, and arm on this device is removed.** Buttons: **Cancel**, **Reset**. **Reset** clears the ledger on this device.

## Features

- Manifest of crates and bay seats on this device.
- Scan a crate barcode, then a bay slot plate, so the move is witnessed.
- Type a code when the camera is off or missing.
- Sample codes on a device with no camera.
- A new code sits **In stock** at **Home**.
- **Arm, then seat**: a known crate opens an eight-second window; the slot plate must be scanned before it closes.
- Statuses **In stock**, **Issued**, and **Relinquished**.
- **Who holds it** on a crate.
- Search by **Name or code**.
- Filter **All**, **In stock**, **Issued**, **Relinquished**.
- Bay canvas of places and seated crates.
- **Mark issued** and **Mark in stock** without scanning.
- **Share label** and **Print label** (QR of the crate code).
- **Lifecycle** for crates issued longer than thirty days.
- **Relinquish** to freeze a crate on the manifest.
- **Export CSV**.
- **Contact**.
- **Show introduction**.
- **Reset manifest**.

## Behaviours that can look like bugs

- Empty Manifest shows **Scan your first crate** and hides the bay canvas. Tap **Scan** and use a crate code. The first code only adds the crate at **Home**. Scan that crate again, then the plate.
- **Mark issued** changes status only. It does not seat a bay. Seating needs **Scan**, a known crate, then a plate while **Arm is open for N seconds. Scan the slot plate.**
- The arm lasts eight seconds. If the plate is scanned after that, **Scan paused** / **Scan a crate first. The plate did not move anything.** Arm the crate again, then scan the plate at once.
- Scanning a plate first, or after the window closes, is the same pause. Scan a crate first.
- Scanning another crate while armed: **That scan was not a slot plate. The arm stays open.** Scan a **PLATE-…** code, not a second crate, or wait for the window to close.
- A Relinquished crate: **This crate is relinquished. Scan a crate that is still in stock.** Use a crate that is still In stock or Issued.
- A code that is not 8 to 14 digits and not a **PLATE-…** plate: **That scan has no crate code. Use 8 to 14 digits, or a bay plate.**
- **Use code** with an empty **Type a code** field does nothing. Type a code first.
- Repeating a scan within about two seconds does nothing. Wait, then scan again.
- **Scan** on Manifest goes dim while Scan is opening. Wait for the cover, or Close and tap **Scan** again.
- A paused scan leaves the camera up. The **Scan paused** alert sits on Manifest. Tap **Close**, read **OK**, then continue.
- Camera off: **The camera is off. Open Settings to change it, or type the code below.** Tap **Open Settings**, or type the code. There is no second Allow button in the app.
- Filter or search can hide every row while crates still exist. The full-page empty art appears only when there are no crates at all. Tap **All** and clear **Name or code**.
- **Nothing is overdue** until a crate has been **Issued** longer than thirty days. On a clean device that can take more than thirty days. **Relinquish** is only on those overdue cards, not under **Still inside thirty days**.
- Relinquished crates keep **Mark issued**, **Mark in stock**, and Inventory **Choose another crate** dimmed. That is intended. They stay on the list.
- Inventory and Lifecycle have no **Done**. Swipe the sheet down.
- After **Reset**, Manifest is empty in the same session and the introduction does not return until the next launch, or until **Show introduction**.
- If the saved manifest cannot be read: **The manifest could not be read. The last saved copy is back.** or **The manifest could not be read. Started a blank manifest.** On Settings, tap **Try again**. On Inventory the bottom button is hidden until that is resolved.

## Starter content and resume

On a physical device: none. First launch is the introduction, then **Scan your first crate**.

On Simulator, the first launch can skip the introduction and fill Manifest with:

- Places: **Home**, **Bay A**, **Dock**, **Cage**.
- **Crate 3457** (5901234123457), **In stock** at **Home**.
- **Crate 3931** (4006381333931), **Issued** at **Dock**, **Who holds it** is **Lane**.
- **Crate 8905** (012345678905), **Issued** at **Cage**, holder **North**, issued about forty-five days earlier so it ranks on Lifecycle.
- **Crate 1452** (036000291452), **In stock** at **Bay A**.

That seed runs once. **Reset manifest** clears it.

Scan sample buttons (no camera only): **5901234123457**, **4006381333931**, **PLATE-BAY-A**, **PLATE-DOCK**, **012345678905**.

The manifest, statuses, holders, seats, and whether the introduction was finished come back after quit. An open arm does not last past eight seconds. Typed **Who holds it** is kept when the field is dismissed. **Show introduction** replays the three pages without wiping crates. **Reset manifest** wipes crates, seats, and arms on this device.

## Permissions

Camera, the first time the person opens **Scan** on a device that has a camera and has not answered yet. The system dialog is the first ask. Usage description: **Bondmark uses the camera to read barcodes on labeled crates and QR codes on bay slot plates so each move is recorded on the manifest.**

If already denied or restricted: **The camera is off. Open Settings to change it, or type the code below.** and **Open Settings**.

No microphone, photos, location, or tracking permission.

## Absent

Login or accounts, in-app purchase, ads, analytics, user-generated content (no public feed, no report or block), account deletion flow, and App Tracking Transparency prompt are all absent.

## Data and support

Crate records, seats, and holders stay on this device. Nothing is signed in. **Export CSV** only shares a file the person chooses to send. **Contact** on Settings opens the support page.

## Scanning and health

The app scans crate barcodes (8 to 14 digits, including a code found inside other text) and bay slot plates whose codes look like **PLATE-BAY-A** or **PLATE-DOCK**. It also accepts those values from **Type a code** or the sample buttons. It does not look up products, calories, or medical data.

None for health, medical, or product-health information. No citations.

## Platform

UI copy is English only. Dates and counts follow the device region and calendar. There is no country gate and no language picker.

Portrait only, including iPad. Light appearance. iPhone and iPad. Minimum iOS 17.0. iPad is full screen.

## Category

Productivity.
