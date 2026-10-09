import XCTest
@testable import Bondmark

final class ReviewLaunchTests: XCTestCase {
    func testScreenParsesReviewArgument() {
        XCTAssertEqual(ReviewLaunch.argument, "-ReviewScreen")
        let sample = ["Bondmark", "-ReviewScreen", "log"]
        let index = sample.firstIndex(of: ReviewLaunch.argument)
        XCTAssertEqual(index, 1)
        XCTAssertEqual(sample[(index ?? 0) + 1], "log")
    }

    func testScreenReadsProcessArguments() {
        let screen = ReviewLaunch.screen
        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") {
            XCTAssertNotNil(screen)
        } else {
            XCTAssertNil(screen)
        }
    }
}

final class ManifestInvariantTests: XCTestCase {
    func testScanDraftsInStockAtHome() {
        var chart = BondChart.blank()
        let outcome = chart.receive(payload: "https://crate.example/id/5901234123457", at: Date())
        guard case .drafted(let item) = outcome else {
            XCTFail("Expected a draft")
            return
        }
        XCTAssertEqual(item.status, .inStock)
        XCTAssertEqual(item.code, "5901234123457")
        XCTAssertEqual(item.name, "Crate 3457")
        XCTAssertEqual(item.assignedSlot, chart.homeSlot?.id)
        XCTAssertFalse(chart.blank)
        XCTAssertEqual(item.labelQR, item.code)
    }

    func testTransferWritesSeatMarkAndIssued() {
        var chart = BondChart.blank()
        _ = chart.receive(payload: "4006381333931", at: Date())
        let bay = Slot(id: UUID(), name: "Bay A", plate: SlotPlate(code: "PLATE-BAY-A"), isHome: false)
        chart.slots.append(bay)
        let armed = chart.receive(payload: "4006381333931", at: Date())
        guard case .armed = armed else {
            XCTFail("Expected an arm")
            return
        }
        let seated = chart.receive(payload: "PLATE-BAY-A", at: Date())
        guard case .seated(let record) = seated else {
            XCTFail("Expected a transfer")
            return
        }
        let transfer = record as TransferRecord
        XCTAssertEqual(chart.seatMarks.count, 1)
        XCTAssertEqual(transfer.slotID, bay.id)
        let item = chart.items[0]
        XCTAssertEqual(item.status, .issued)
        XCTAssertEqual(item.assignedTo, bay.id)
        XCTAssertEqual(item.assignedSlot, bay.id)
        XCTAssertNil(chart.arm)
    }

    func testIssuedOlderThanThirtyDaysIsOverdue() {
        var chart = BondChart.blank()
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        _ = chart.receive(payload: "4006381333931", at: today)
        let bay = Slot(id: UUID(), name: "Bay A", plate: SlotPlate(code: "PLATE-BAY-A"), isHome: false)
        chart.slots.append(bay)
        _ = chart.receive(payload: "4006381333931", at: today)
        _ = chart.receive(payload: "PLATE-BAY-A", at: today, calendar: calendar)
        let old = calendar.date(byAdding: .day, value: -31, to: calendar.startOfDay(for: today)) ?? today
        chart.issuedSpans[0].dayKey = DayKey.make(old, calendar: calendar)
        XCTAssertEqual(chart.overdueItems(on: today, calendar: calendar).count, 1)
        chart.issuedSpans[0].dayKey = DayKey.make(today, calendar: calendar)
        XCTAssertTrue(chart.overdueItems(on: today, calendar: calendar).isEmpty)
    }

    func testLabelQRFallsBackToIdentifier() {
        let item = Item(
            id: UUID(),
            code: nil,
            name: "Crate",
            status: .inStock,
            assignedSlot: UUID(),
            assignee: nil
        )
        XCTAssertEqual(item.labelQR, item.id.uuidString)
    }

    func testEmptyAndInvalidScansDoNotWrite() {
        var chart = BondChart.blank()
        guard case .invalid = chart.receive(payload: "   ", at: Date()) else {
            XCTFail("Blank payload")
            return
        }
        guard case .invalid = chart.receive(payload: "not-a-code", at: Date()) else {
            XCTFail("Non numeric payload")
            return
        }
        XCTAssertTrue(chart.items.isEmpty)
        XCTAssertTrue(chart.blank)
        XCTAssertTrue(chart.marks.isEmpty)
    }

    func testSkewKeepsArmAndDriftRefusesSeat() {
        var chart = BondChart.blank()
        let start = Date()
        _ = chart.receive(payload: "4006381333931", at: start)
        let bay = Slot(id: UUID(), name: "Bay A", plate: SlotPlate(code: "PLATE-BAY-A"), isHome: false)
        chart.slots.append(bay)
        _ = chart.receive(payload: "4006381333931", at: start)
        let home = chart.items[0].assignedSlot
        let skew = chart.receive(payload: "036000291452", at: start.addingTimeInterval(1))
        guard case .skewed = skew else {
            XCTFail("Expected skew")
            return
        }
        XCTAssertEqual(chart.marks.filter { if case .arm = $0 { return true }; return false }.count, 1)
        XCTAssertNotNil(chart.arm)
        XCTAssertEqual(chart.items[0].assignedSlot, home)

        var bare = BondChart.blank()
        bare.slots.append(bay)
        let drift = bare.receive(payload: "PLATE-BAY-A", at: start)
        guard case .drifted = drift else {
            XCTFail("Expected drift")
            return
        }
        XCTAssertTrue(bare.items.isEmpty)
    }

    func testArmedUnknownPlateWritesSeatMark() {
        var chart = BondChart.blank()
        let start = Date()
        _ = chart.receive(payload: "4006381333931", at: start)
        _ = chart.receive(payload: "4006381333931", at: start)
        XCTAssertTrue(chart.slots.allSatisfy { $0.plate == nil })
        let seated = chart.receive(payload: "PLATE-BAY-A", at: start)
        guard case .seated(let record) = seated else {
            XCTFail("Expected a seat on a new plate")
            return
        }
        let plate = chart.slots.first { $0.plate?.code == "PLATE-BAY-A" }
        XCTAssertEqual(plate?.name, "Bay A")
        XCTAssertEqual(record.slotID, plate?.id)
        XCTAssertEqual(chart.items[0].assignedSlot, plate?.id)
        XCTAssertNil(chart.arm)
    }

    func testRelinquishedItemCannotArm() {
        var chart = BondChart.blank()
        let drafted = chart.receive(payload: "4006381333931", at: Date())
        guard case .drafted(let item) = drafted else {
            XCTFail("Draft")
            return
        }
        XCTAssertTrue(chart.relinquish(itemID: item.id))
        let again = chart.receive(payload: "4006381333931", at: Date())
        guard case .refused = again else {
            XCTFail("Arm should be refused")
            return
        }
        XCTAssertNil(chart.arm)
        XCTAssertEqual(chart.items[0].id, item.id)
    }

    func testArmExpiresWithoutASecondMark() {
        var chart = BondChart.blank()
        let start = Date()
        _ = chart.receive(payload: "4006381333931", at: start)
        _ = chart.receive(payload: "4006381333931", at: start)
        let later = chart.receive(payload: "4006381333931", at: start.addingTimeInterval(8))
        guard case .armed = later else {
            XCTFail("Window should have closed")
            return
        }
        XCTAssertEqual(chart.marks.filter { if case .arm = $0 { return true }; return false }.count, 2)
    }

    func testUPCAGainsALeadingZero() {
        let codes = CodeScan.candidates(in: "crate 036000291452 extra")
        XCTAssertTrue(codes.contains("036000291452"))
        XCTAssertTrue(codes.contains("0036000291452"))
    }

    func testBlankManifestIsTheEmptyArchitecture() {
        let chart = BondChart.blank()
        XCTAssertEqual(chart.schemaVersion, 1)
        XCTAssertTrue(chart.blank)
        XCTAssertNil(chart.arm)
        XCTAssertTrue(chart.issuedSpans.isEmpty)
    }
}

@MainActor
final class BondStoreTests: XCTestCase {
    private func makeSuite() -> (name: String, defaults: UserDefaults) {
        let name = "com.bondmark.manifest.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? UserDefaults()
        defaults.removePersistentDomain(forName: name)
        return (name, defaults)
    }

    func testRoundTripReload() async {
        let suite = makeSuite()
        let store = BondStore(suiteName: suite.name)
        await store.open()
        let outcome = store.receive(payload: "5901234123457")
        guard case .drafted(let item) = outcome else {
            XCTFail("Draft")
            return
        }
        await store.flush()
        let reloaded = BondStore(suiteName: suite.name)
        await reloaded.open()
        XCTAssertEqual(reloaded.chart.items.map(\.id), [item.id])
        XCTAssertEqual(reloaded.chart.items.first?.status, .inStock)
        XCTAssertNil(reloaded.restoreNotice)
    }

    func testCorruptPrimaryRestoresBackupThenBlank() async {
        let suite = makeSuite()
        let defaults = suite.defaults
        let store = BondStore(suiteName: suite.name)
        await store.open()
        _ = store.receive(payload: "5901234123457")
        await store.flush()
        let backup = defaults.data(forKey: BondStore.storageKey)
        defaults.set(Data("not-json".utf8), forKey: BondStore.storageKey)
        defaults.set(backup, forKey: BondStore.backupKey)
        let restored = BondStore(suiteName: suite.name)
        await restored.open()
        XCTAssertEqual(restored.chart.items.count, 1)
        XCTAssertNotNil(restored.restoreNotice)

        defaults.set(Data("still-bad".utf8), forKey: BondStore.storageKey)
        defaults.set(Data("also-bad".utf8), forKey: BondStore.backupKey)
        let blank = BondStore(suiteName: suite.name)
        await blank.open()
        XCTAssertTrue(blank.chart.blank)
        XCTAssertTrue(blank.chart.items.isEmpty)
        XCTAssertNotNil(blank.restoreNotice)
    }

    func testResetRemovesBothKeysThenWritesBlank() async {
        let suite = makeSuite()
        let defaults = suite.defaults
        let store = BondStore(suiteName: suite.name)
        await store.open()
        _ = store.receive(payload: "5901234123457")
        await store.flush()
        await store.resetAllData()
        XCTAssertNil(defaults.data(forKey: BondStore.backupKey))
        XCTAssertTrue(store.chart.blank)
        let data = defaults.data(forKey: BondStore.storageKey)
        XCTAssertNotNil(data)
        if let data {
            let decoded = try? JSONDecoder().decode(BondChart.self, from: data)
            XCTAssertEqual(decoded?.blank, true)
            XCTAssertEqual(decoded?.items.count, 0)
        }
    }

    func testSearchIgnoresAStaleQuery() async {
        let suite = makeSuite()
        let store = BondStore(suiteName: suite.name)
        await store.open()
        _ = store.receive(payload: "5901234123457")
        _ = store.receive(payload: "4006381333931")
        await store.focus(query: "3457")
        XCTAssertEqual(store.focused.count, 1)
        XCTAssertEqual(store.focused.first?.code, "5901234123457")
    }

    func testRelinquishFlushes() async {
        let suite = makeSuite()
        let store = BondStore(suiteName: suite.name)
        await store.open()
        let outcome = store.receive(payload: "5901234123457")
        guard case .drafted(let item) = outcome else {
            XCTFail("Draft")
            return
        }
        let changed = await store.relinquish(itemID: item.id)
        XCTAssertTrue(changed)
        let reloaded = BondStore(suiteName: suite.name)
        await reloaded.open()
        XCTAssertEqual(reloaded.chart.items.first?.status, .relinquished)
    }

    func testUnsupportedSchemaDoesNotCrash() async {
        let suite = makeSuite()
        let payload = Data("{\"schemaVersion\":99}".utf8)
        suite.defaults.set(payload, forKey: BondStore.storageKey)
        let store = BondStore(suiteName: suite.name)
        await store.open()
        XCTAssertTrue(store.chart.blank)
        XCTAssertNotNil(store.restoreNotice)
    }

#if targetEnvironment(simulator)
    func testSimulatorSeedRunsOnce() async {
        let suite = makeSuite()
        let store = BondStore(suiteName: suite.name)
        await store.open()
        await store.seedDemoIfNeeded()
        XCTAssertTrue(store.chart.onboardingComplete)
        XCTAssertEqual(store.chart.slots.count, 4)
        XCTAssertTrue(store.chart.slots.contains { $0.isHome })
        XCTAssertTrue(store.chart.slots.contains { $0.plate != nil })
        XCTAssertGreaterThan(store.chart.items.count, 2)
        XCTAssertTrue(store.chart.items.contains { $0.status == .inStock && $0.assignedSlot == store.chart.homeSlot?.id })
        XCTAssertFalse(store.chart.overdueItems(on: Date()).isEmpty)
        let again = BondStore(suiteName: suite.name)
        await again.open()
        let before = again.chart
        await again.seedDemoIfNeeded()
        XCTAssertEqual(again.chart, before)
    }
#endif
}
