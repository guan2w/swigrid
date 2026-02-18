import XCTest
@testable import SchulteDomain

final class ScoreRecordTests: XCTestCase {
    func testFreshAtExactFinishTimestamp() throws {
        let config = GridConfig(scale: 3, dual: false)
        let record = try ScoreRecord(p1: Player(name: "A"), gc: config, t0: 1_000, t1: 2_000)
        XCTAssertTrue(record.isFresh(referenceTimestampMS: 2_000))
    }
}
