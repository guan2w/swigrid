import XCTest
@testable import SchulteDomain

final class ScoreRecordTests: XCTestCase {
    func testFreshAtExactFinishTimestamp() throws {
        let config = GridConfig(scale: 3, dual: false)
        let record = try ScoreRecord(player: Player(name: "A"), gridConfig: config, startTimestampMS: 1_000, endTimestampMS: 2_000)
        XCTAssertTrue(record.isFresh(referenceTimestampMS: 2_000))
    }
}
