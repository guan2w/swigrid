import XCTest
@testable import SchulteDomain

final class ScoreRecordsTests: XCTestCase {
    func testSaveRecordSortsAscendingAndKeepsLimit() throws {
        var records = ScoreRecords()
        let config = GridConfig(scale: 3, dual: false)

        for i in 0 ..< 25 {
            let start: Int64 = 1_000
            let end = start + Int64(5_000 - i * 50)
            let record = try ScoreRecord(
                player: Player(name: "P\(i)"),
                gridConfig: config,
                startTimestampMS: start,
                endTimestampMS: end
            )
            records.saveRecord(record)
        }

        let list = records.records[config.storageKey()]
        XCTAssertEqual(list?.count, 20)

        let sorted = list?.map(\.timeScore) ?? []
        XCTAssertEqual(sorted, sorted.sorted())
    }

    func testLatestLevel5RecordUpdatedWhenSavingFiveStarScore() throws {
        var records = ScoreRecords()
        let config = GridConfig(scale: 3, dual: false)

        let normal = try ScoreRecord(player: Player(name: "A"), gridConfig: config, startTimestampMS: 1_000, endTimestampMS: 8_000)
        let fiveStar = try ScoreRecord(player: Player(name: "B"), gridConfig: config, startTimestampMS: 1_000, endTimestampMS: 2_500)

        records.saveRecord(normal)
        records.saveRecord(fiveStar)

        XCTAssertEqual(records.latestFiveStarRecord(config)?.player.name, "B")
        XCTAssertEqual(records.best(config)?.player.name, "B")
    }

    func testNormalizedSortsAndKeepsLatestLevel5FromLegacyPayload() throws {
        let config = GridConfig(scale: 3, dual: false)
        let key = config.storageKey()

        let slow = try ScoreRecord(player: Player(name: "Slow"), gridConfig: config, startTimestampMS: 1_000, endTimestampMS: 6_000)
        let fast = try ScoreRecord(player: Player(name: "Fast"), gridConfig: config, startTimestampMS: 1_000, endTimestampMS: 3_000)
        let latestFive = try ScoreRecord(player: Player(name: "Latest5"), gridConfig: config, startTimestampMS: 9_000, endTimestampMS: 10_500)

        let legacy = ScoreRecords(
            records: [key: [slow, fast]],
            latestFiveStarRecords: [key: latestFive]
        )

        let normalized = legacy.normalized()
        XCTAssertEqual(normalized.records[key]?.map(\.player.name), ["Fast", "Slow"])
        XCTAssertEqual(normalized.latestFiveStarRecords[key]?.player.name, "Latest5")
    }
}
