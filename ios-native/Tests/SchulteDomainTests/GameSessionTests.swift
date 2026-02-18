import XCTest
@testable import SchulteDomain

final class GameSessionTests: XCTestCase {
    func testSessionFlowsReadyToFinished() throws {
        var session = try GameSession(maxNumber: 3)

        try session.start(at: 1_000)
        XCTAssertEqual(session.gameStatus, .ongoing)
        XCTAssertEqual(session.nextNumber, 1)

        XCTAssertEqual(session.proceed(tapped: 1, at: 1_001), .correct(nextNumber: 2))
        XCTAssertEqual(session.proceed(tapped: 2, at: 1_002), .correct(nextNumber: 3))
        XCTAssertEqual(session.proceed(tapped: 3, at: 1_003), .finished)

        XCTAssertEqual(session.gameStatus, .finished)
        XCTAssertNil(session.nextNumber)
        XCTAssertTrue(session.validate())
        XCTAssertEqual(session.timeScore, 3)
    }

    func testIncorrectTapDoesNotAdvanceState() throws {
        var session = try GameSession(maxNumber: 2)
        try session.start(at: 1_000)

        XCTAssertEqual(session.proceed(tapped: 2, at: 1_001), .incorrect(expected: 1, tapped: 2))
        XCTAssertEqual(session.nextNumber, 1)
        XCTAssertEqual(session.gameStatus, .ongoing)
    }

    func testValidationFailsWhenTimestampsAreNotStrictlyIncreasing() throws {
        var session = try GameSession(maxNumber: 3)
        try session.start(at: 1_000)

        _ = session.proceed(tapped: 1, at: 1_001)
        _ = session.proceed(tapped: 2, at: 1_001)
        _ = session.proceed(tapped: 3, at: 1_002)

        XCTAssertFalse(session.validate())
        XCTAssertThrowsError(try session.buildRecord(player: Player(name: "A"), gridConfig: GridConfig(scale: 3, dual: false)))
    }
}
