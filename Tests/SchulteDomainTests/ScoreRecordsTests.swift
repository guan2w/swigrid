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
                p1: Player(name: "P\(i)"),
                gc: config,
                t0: start,
                t1: end
            )
            records.saveRecord(record)
        }

        let list = records.records[config.asKey()]
        XCTAssertEqual(list?.count, 20)

        let sorted = list?.map(\.timeScore) ?? []
        XCTAssertEqual(sorted, sorted.sorted())
    }

    func testLatestLevel5RecordUpdatedWhenSavingFiveStarScore() throws {
        var records = ScoreRecords()
        let config = GridConfig(scale: 3, dual: false)

        let normal = try ScoreRecord(p1: Player(name: "A"), gc: config, t0: 1_000, t1: 8_000)
        let fiveStar = try ScoreRecord(p1: Player(name: "B"), gc: config, t0: 1_000, t1: 2_500)

        records.saveRecord(normal)
        records.saveRecord(fiveStar)

        XCTAssertEqual(records.latestLevel5Record(config)?.p1.name, "B")
        XCTAssertEqual(records.best(config)?.p1.name, "B")
    }

    func testNormalizedSortsAndKeepsLatestLevel5FromLegacyPayload() throws {
        let config = GridConfig(scale: 3, dual: false)
        let key = config.asKey()

        let slow = try ScoreRecord(p1: Player(name: "Slow"), gc: config, t0: 1_000, t1: 6_000)
        let fast = try ScoreRecord(p1: Player(name: "Fast"), gc: config, t0: 1_000, t1: 3_000)
        let latestFive = try ScoreRecord(p1: Player(name: "Latest5"), gc: config, t0: 9_000, t1: 10_500)

        let legacy = ScoreRecords(
            records: [key: [slow, fast]],
            latestLevel5Records: [key: latestFive]
        )

        let normalized = legacy.normalized()
        XCTAssertEqual(normalized.records[key]?.map(\.p1.name), ["Fast", "Slow"])
        XCTAssertEqual(normalized.latestLevel5Records[key]?.p1.name, "Latest5")
    }
}
