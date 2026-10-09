import Foundation

/// One manifest document. Slots, Items, the live Arm, Issued spans, and the mark list.
struct BondChart: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var blank: Bool
    var onboardingComplete: Bool
    var slots: [Slot]
    var items: [Item]
    var arm: Arm?
    var issuedSpans: [IssuedSpan]
    var marks: [WitnessMark]

    static let currentSchema = 1

    static func blank() -> BondChart {
        BondChart(
            schemaVersion: currentSchema,
            blank: true,
            onboardingComplete: false,
            slots: [],
            items: [],
            arm: nil,
            issuedSpans: [],
            marks: []
        )
    }

    init(
        schemaVersion: Int,
        blank: Bool,
        onboardingComplete: Bool,
        slots: [Slot],
        items: [Item],
        arm: Arm?,
        issuedSpans: [IssuedSpan],
        marks: [WitnessMark]
    ) {
        self.schemaVersion = schemaVersion
        self.blank = blank
        self.onboardingComplete = onboardingComplete
        self.slots = slots
        self.items = items
        self.arm = arm
        self.issuedSpans = issuedSpans
        self.marks = marks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            schemaVersion = version
            blank = try container.decode(Bool.self, forKey: .blank)
            onboardingComplete = try container.decode(Bool.self, forKey: .onboardingComplete)
            slots = try container.decode([Slot].self, forKey: .slots)
            items = try container.decode([Item].self, forKey: .items)
            arm = try container.decodeIfPresent(Arm.self, forKey: .arm)
            issuedSpans = try container.decode([IssuedSpan].self, forKey: .issuedSpans)
            marks = try container.decode([WitnessMark].self, forKey: .marks)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported manifest schema \(version)."
            )
        }
    }
}

/// A day an Item became Issued. Overdue is computed from this day, not stored beside it.
struct IssuedSpan: Codable, Sendable, Identifiable, Equatable {
    var id: UUID
    var itemID: UUID
    var dayKey: Int
    var assignee: String?
}

enum WitnessMark: Codable, Sendable, Identifiable, Equatable {
    case arm(ArmMark)
    case seat(SeatMark)
    case skew(SkewMark)
    case drift(DriftMark)

    var id: UUID {
        switch self {
        case .arm(let mark): return mark.id
        case .seat(let mark): return mark.id
        case .skew(let mark): return mark.id
        case .drift(let mark): return mark.id
        }
    }

    private enum Kind: String, Codable {
        case arm, seat, skew, drift
    }

    private enum CodingKeys: String, CodingKey {
        case kind, arm, seat, skew, drift
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .arm:
            self = .arm(try container.decode(ArmMark.self, forKey: .arm))
        case .seat:
            self = .seat(try container.decode(SeatMark.self, forKey: .seat))
        case .skew:
            self = .skew(try container.decode(SkewMark.self, forKey: .skew))
        case .drift:
            self = .drift(try container.decode(DriftMark.self, forKey: .drift))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .arm(let mark):
            try container.encode(Kind.arm, forKey: .kind)
            try container.encode(mark, forKey: .arm)
        case .seat(let mark):
            try container.encode(Kind.seat, forKey: .kind)
            try container.encode(mark, forKey: .seat)
        case .skew(let mark):
            try container.encode(Kind.skew, forKey: .kind)
            try container.encode(mark, forKey: .skew)
        case .drift(let mark):
            try container.encode(Kind.drift, forKey: .kind)
            try container.encode(mark, forKey: .drift)
        }
    }
}

enum ScanOutcome: Sendable, Equatable {
    case drafted(Item)
    case armed(ArmMark)
    case seated(SeatMark)
    case skewed(SkewMark)
    case drifted(DriftMark)
    case refused(String)
    case invalid(String)
}

enum DayKey {
    /// YYYYMMDD from `Calendar.startOfDay`.
    static func make(_ date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func date(_ key: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        guard let day = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: day)
    }
}

extension BondChart {
    var homeSlot: Slot? { slots.first { $0.isHome } }

    var seatMarks: [SeatMark] {
        marks.compactMap { mark in
            if case .seat(let seat) = mark { return seat }
            return nil
        }
    }

    func items(matching query: String) -> [Item] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(trimmed)
                || (item.code?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    func overdueItems(on date: Date, calendar: Calendar = .current) -> [Item] {
        let today = calendar.startOfDay(for: date)
        return items.filter { item in
            guard item.status == .issued else { return false }
            guard let span = issuedSpans.last(where: { $0.itemID == item.id }) else { return false }
            guard let issued = DayKey.date(span.dayKey, calendar: calendar) else { return false }
            let days = calendar.dateComponents([.day], from: issued, to: today).day ?? 0
            return days > 30
        }
    }

    /// Accepts a scan. Unknown codes draft an In stock crate at Home. A known crate arms for eight seconds.
    @discardableResult
    mutating func receive(payload: String, at date: Date, calendar: Calendar = .current) -> ScanOutcome {
        expireArm(at: date)
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid("Enter a code or scan a crate.")
        }
        if let slot = slots.first(where: { $0.plate?.code == trimmed }) {
            return receivePlate(slot, at: date, calendar: calendar)
        }
        if SlotPlate.matches(trimmed) {
            let slot = Slot(
                id: UUID(),
                name: SlotPlate.bayName(for: trimmed),
                plate: SlotPlate(code: trimmed),
                isHome: false
            )
            slots.append(slot)
            return receivePlate(slot, at: date, calendar: calendar)
        }
        let codes = CodeScan.candidates(in: trimmed)
        guard let primary = codes.first else {
            return .invalid("That scan has no crate code. Use 8 to 14 digits, or a bay plate.")
        }
        if let live = arm, live.isLive(at: date) {
            let skew = SkewMark(id: UUID(), itemID: live.itemID, payload: trimmed, at: date)
            marks.append(.skew(skew))
            return .skewed(skew)
        }
        if let index = items.firstIndex(where: { item in
            guard let code = item.code else { return false }
            return codes.contains(code)
        }) {
            if items[index].status == .relinquished {
                return .refused("This crate is relinquished. Scan a crate that is still in stock.")
            }
            let mark = ArmMark(id: UUID(), itemID: items[index].id, at: date)
            marks.append(.arm(mark))
            arm = Arm(itemID: items[index].id, openedAt: date)
            return .armed(mark)
        }
        return draft(code: primary)
    }

    mutating func relinquish(itemID: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return false }
        items[index].status = .relinquished
        if arm?.itemID == itemID {
            arm = nil
        }
        return true
    }

    private mutating func expireArm(at date: Date) {
        if let live = arm, !live.isLive(at: date) {
            arm = nil
        }
    }

    private mutating func receivePlate(_ slot: Slot, at date: Date, calendar: Calendar) -> ScanOutcome {
        guard let live = arm, live.isLive(at: date) else {
            let drift = DriftMark(id: UUID(), slotID: slot.id, at: date)
            marks.append(.drift(drift))
            return .drifted(drift)
        }
        guard let index = items.firstIndex(where: { $0.id == live.itemID }) else {
            let drift = DriftMark(id: UUID(), slotID: slot.id, at: date)
            marks.append(.drift(drift))
            arm = nil
            return .drifted(drift)
        }
        items[index].assignedSlot = slot.id
        items[index].status = .issued
        let span = IssuedSpan(
            id: UUID(),
            itemID: items[index].id,
            dayKey: DayKey.make(date, calendar: calendar),
            assignee: items[index].assignee
        )
        issuedSpans.append(span)
        let seat = SeatMark(
            id: UUID(),
            itemID: items[index].id,
            slotID: slot.id,
            at: date,
            assignee: items[index].assignee
        )
        marks.append(.seat(seat))
        arm = nil
        return .seated(seat)
    }

    private mutating func draft(code: String) -> ScanOutcome {
        let home = ensureHome()
        let item = Item(
            id: UUID(),
            code: code,
            name: Item.fusedName(code: code),
            status: .inStock,
            assignedSlot: home.id,
            assignee: nil
        )
        items.append(item)
        blank = false
        return .drafted(item)
    }

    private mutating func ensureHome() -> Slot {
        if let home = homeSlot { return home }
        let home = HomeSeat.make()
        slots.insert(home, at: 0)
        return home
    }
}
