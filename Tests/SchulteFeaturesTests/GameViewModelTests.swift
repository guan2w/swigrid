import XCTest
@testable import SchulteDomain
@testable import SchulteFeatures

@MainActor
final class GameViewModelTests: XCTestCase {
    func testGameFlowCountdownTapAndFinalizeRecord() throws {
        let clock = IncrementingClock(start: 1_000)
        let viewModel = GameViewModel(now: { clock.next() })
        let config = GridConfig(scale: 3, dual: false)

        try viewModel.configure(gridConfig: config)
        XCTAssertEqual(viewModel.state.status, .ready)
        XCTAssertEqual(viewModel.state.countdown, 3)

        viewModel.tickCountdown()
        viewModel.tickCountdown()
        viewModel.tickCountdown()
        XCTAssertEqual(viewModel.state.status, .ongoing)

        let wrong = viewModel.tap(number: 2)
        XCTAssertEqual(wrong, .incorrect(expected: 1, tapped: 2))

        for number in 1 ... config.numbersCount {
            _ = viewModel.tap(number: number)
        }

        XCTAssertEqual(viewModel.state.status, .finished)
        let record = try viewModel.finalizeRecord(player: Player(name: "P1"))
        XCTAssertEqual(record.player.name, "P1")
        XCTAssertEqual(record.gridConfig, config)
    }

    func testResetClearsSessionState() throws {
        let clock = IncrementingClock(start: 1_000)
        let viewModel = GameViewModel(now: { clock.next() })
        try viewModel.configure(gridConfig: GridConfig(scale: 3, dual: false))

        viewModel.reset()

        XCTAssertEqual(viewModel.state.status, .ready)
        XCTAssertEqual(viewModel.state.countdown, 3)
        XCTAssertNil(viewModel.state.nextNumber)
        XCTAssertTrue(viewModel.state.gridNumbers == nil)
    }
}
