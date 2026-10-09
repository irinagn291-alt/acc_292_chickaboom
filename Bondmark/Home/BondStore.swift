import Foundation

/// In-memory seam. Views talk to this type. UserDefaults is only touched here.
@MainActor
final class BondStore {
    nonisolated static let storageKey = "bmk.chart.v1"
    nonisolated static let backupKey = "bmk.chart.v1.backup"
    nonisolated static let demoKey = "bmk.demo.v1"
    nonisolated static let debounceNanoseconds: UInt64 = 400_000_000
    nonisolated static let searchDebounceNanoseconds: UInt64 = 300_000_000

    private let suiteName: String?
    private var saveTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = 0

    private(set) var chart: BondChart
    private(set) var restoreNotice: String?
    private(set) var focused: [Item] = []

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
        self.chart = .blank()
    }

    /// Reads the chart off the main thread. A bad primary falls back to the backup, then a blank manifest.
    func open() async {
        let suiteName = self.suiteName
        let loaded = await Self.readChart(suiteName: suiteName)
        chart = loaded.chart
        restoreNotice = loaded.notice
        focused = chart.items
    }

    func receive(payload: String, at date: Date = Date()) -> ScanOutcome {
        let outcome = chart.receive(payload: payload, at: date)
        if case .invalid = outcome {
            return outcome
        }
        if case .refused = outcome {
            return outcome
        }
        scheduleSave()
        return outcome
    }

    /// Immediate filter. Cancels a debounced query so a scan is not overwritten.
    func show(query: String) {
        searchTask?.cancel()
        searchGeneration += 1
        focused = chart.items(matching: query)
    }

    func finishOnboarding() async {
        chart.onboardingComplete = true
        await flush()
    }

    /// Settings can show the introduction again. The next finish writes the flag.
    func reopenOnboarding() async {
        chart.onboardingComplete = false
        await flush()
    }

    func setAssignee(itemID: UUID, name: String?) async {
        guard let index = chart.items.firstIndex(where: { $0.id == itemID }) else { return }
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        chart.items[index].assignee = trimmed.isEmpty ? nil : trimmed
        await flush()
    }

    /// Flips In stock and Issued. Relinquished stays frozen.
    func flipAvailability(itemID: UUID, at date: Date = Date(), calendar: Calendar = .current) async -> Bool {
        guard let index = chart.items.firstIndex(where: { $0.id == itemID }) else { return false }
        switch chart.items[index].status {
        case .relinquished:
            return false
        case .issued:
            chart.items[index].status = .inStock
        case .inStock:
            chart.items[index].status = .issued
            chart.issuedSpans.append(
                IssuedSpan(
                    id: UUID(),
                    itemID: itemID,
                    dayKey: DayKey.make(date, calendar: calendar),
                    assignee: chart.items[index].assignee
                )
            )
        }
        await flush()
        return true
    }

    func relinquish(itemID: UUID) async -> Bool {
        let changed = chart.relinquish(itemID: itemID)
        guard changed else { return false }
        await flush()
        return true
    }

    /// Drops both storage keys, then writes a blank chart so a force-quit stays empty.
    func resetAllData() async {
        saveTask?.cancel()
        searchTask?.cancel()
        chart = .blank()
        focused = []
        restoreNotice = nil
        await Self.removeKeys(suiteName: suiteName)
        await flush()
    }

    func notePhase(_ phase: StorePhase) async {
        switch phase {
        case .active:
            break
        case .inactive, .background:
            await flush()
        }
    }

    /// Cancels the previous query. A stale pass does not replace `focused`.
    func focus(query: String) async {
        searchGeneration += 1
        let generation = searchGeneration
        searchTask?.cancel()
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.searchDebounceNanoseconds)
            guard !Task.isCancelled, generation == self.searchGeneration else { return }
            self.focused = self.chart.items(matching: query)
        }
        searchTask = task
        await task.value
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        let snapshot = chart
        let suiteName = self.suiteName
        await Self.write(snapshot, suiteName: suiteName)
    }

    /// Simulator only, once. Marks onboarding done and fills Home plus a bay plate.
    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async {
        #if targetEnvironment(simulator)
        let already = await Self.demoFlag(suiteName: suiteName)
        guard !already else { return }
        chart = Self.demoChart(now: now, calendar: calendar)
        focused = chart.items
        await flush()
        await Self.setDemoFlag(suiteName: suiteName)
        #else
        _ = now
        _ = calendar
        #endif
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = chart
        let suiteName = self.suiteName
        saveTask = Task {
            try? await Task.sleep(nanoseconds: Self.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await Self.write(snapshot, suiteName: suiteName)
        }
    }

    /// Detached so UserDefaults IO does not block the main actor. The suite is opened inside the task.
    private static func readChart(suiteName: String?) async -> (chart: BondChart, notice: String?) {
        await Task.detached {
            load(from: store(suiteName: suiteName))
        }.value
    }

    private static func write(_ chart: BondChart, suiteName: String?) async {
        await Task.detached {
            persist(chart, to: store(suiteName: suiteName))
        }.value
    }

    private static func removeKeys(suiteName: String?) async {
        await Task.detached {
            let defaults = store(suiteName: suiteName)
            defaults.removeObject(forKey: storageKey)
            defaults.removeObject(forKey: backupKey)
        }.value
    }

    nonisolated private static func store(suiteName: String?) -> UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) {
            return suite
        }
        return UserDefaults.standard
    }

#if targetEnvironment(simulator)
    private static func demoFlag(suiteName: String?) async -> Bool {
        await Task.detached {
            store(suiteName: suiteName).bool(forKey: demoKey)
        }.value
    }

    private static func setDemoFlag(suiteName: String?) async {
        await Task.detached {
            store(suiteName: suiteName).set(true, forKey: demoKey)
        }.value
    }
#endif

    nonisolated private static func load(from defaults: UserDefaults) -> (chart: BondChart, notice: String?) {
        if let data = defaults.data(forKey: storageKey), let chart = decode(data) {
            return (chart, nil)
        }
        if defaults.data(forKey: storageKey) != nil {
            if let backup = defaults.data(forKey: backupKey), let chart = decode(backup) {
                return (chart, "The manifest could not be read. The last saved copy is back.")
            }
            return (.blank(), "The manifest could not be read. Started a blank manifest.")
        }
        return (.blank(), nil)
    }

    nonisolated private static func persist(_ chart: BondChart, to defaults: UserDefaults) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(chart) else { return }
        if let current = defaults.data(forKey: storageKey), decode(current) != nil {
            defaults.set(current, forKey: backupKey)
        }
        defaults.set(data, forKey: storageKey)
    }

    nonisolated private static func decode(_ data: Data) -> BondChart? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try? decoder.decode(BondChart.self, from: data)
    }

#if targetEnvironment(simulator)
    nonisolated private static func demoChart(now: Date, calendar: Calendar) -> BondChart {
        let home = HomeSeat.make()
        let bay = Slot(id: UUID(), name: "Bay A", plate: SlotPlate(code: "PLATE-BAY-A"), isHome: false)
        let dock = Slot(id: UUID(), name: "Dock", plate: SlotPlate(code: "PLATE-DOCK"), isHome: false)
        let cage = Slot(id: UUID(), name: "Cage", plate: SlotPlate(code: "PLATE-CAGE"), isHome: false)
        let ready = Item(
            id: UUID(),
            code: "5901234123457",
            name: Item.fusedName(code: "5901234123457"),
            status: .inStock,
            assignedSlot: home.id,
            assignee: nil
        )
        let recent = Item(
            id: UUID(),
            code: "4006381333931",
            name: Item.fusedName(code: "4006381333931"),
            status: .issued,
            assignedSlot: dock.id,
            assignee: "Lane"
        )
        let oldDay = calendar.date(byAdding: .day, value: -45, to: calendar.startOfDay(for: now)) ?? now
        let stale = Item(
            id: UUID(),
            code: "012345678905",
            name: Item.fusedName(code: "012345678905"),
            status: .issued,
            assignedSlot: cage.id,
            assignee: "North"
        )
        let held = Item(
            id: UUID(),
            code: "036000291452",
            name: Item.fusedName(code: "036000291452"),
            status: .inStock,
            assignedSlot: bay.id,
            assignee: nil
        )
        let recentSpan = IssuedSpan(
            id: UUID(),
            itemID: recent.id,
            dayKey: DayKey.make(now, calendar: calendar),
            assignee: recent.assignee
        )
        let staleSpan = IssuedSpan(
            id: UUID(),
            itemID: stale.id,
            dayKey: DayKey.make(oldDay, calendar: calendar),
            assignee: stale.assignee
        )
        let seat = SeatMark(
            id: UUID(),
            itemID: recent.id,
            slotID: dock.id,
            at: now,
            assignee: recent.assignee
        )
        return BondChart(
            schemaVersion: BondChart.currentSchema,
            blank: false,
            onboardingComplete: true,
            slots: [home, bay, dock, cage],
            items: [ready, recent, stale, held],
            arm: nil,
            issuedSpans: [recentSpan, staleSpan],
            marks: [.seat(seat)]
        )
    }
#endif
}

enum StorePhase: Sendable {
    case active
    case inactive
    case background
}
