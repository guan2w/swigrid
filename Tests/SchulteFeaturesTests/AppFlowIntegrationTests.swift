import XCTest
@testable import SchulteDomain
@testable import SchulteFeatures

@MainActor
final class AppFlowIntegrationTests: XCTestCase {
    func testHomeGameRecordsFlow() async throws {
        let playerRepository = MockPlayerRepository(player: Player())
        let gameConfigRepository = MockGameConfigRepository(config: GameConfig(gridConfig: GridConfig(scale: 3, dual: false), mute: false))
        let scoreRepository = MockScoreRecordRepository(scoreRecords: ScoreRecords())

        let homeViewModel = HomeViewModel(
            playerRepository: playerRepository,
            gameConfigRepository: gameConfigRepository,
            scoreRecordRepository: scoreRepository
        )

        await homeViewModel.load()
        await homeViewModel.savePlayerName("Tester")

        var newConfig = homeViewModel.state.gridConfig
        newConfig.scale = 4
        newConfig.dual = false
        await homeViewModel.setGridConfig(newConfig)

        let clock = IncrementingClock(start: 1_000)
        let gameViewModel = GameViewModel(now: { clock.next() })
        try gameViewModel.configure(gridConfig: newConfig)

        gameViewModel.tickCountdown()
        gameViewModel.tickCountdown()
        gameViewModel.tickCountdown()

        for number in 1 ... newConfig.numbersCount {
            _ = gameViewModel.tap(number: number)
        }

        let player = try await playerRepository.loadPlayer()
        let record = try gameViewModel.finalizeRecord(player: player)
        try await scoreRepository.save(record)

        let recordsViewModel = RecordsViewModel(scoreRecordRepository: scoreRepository)
        await recordsViewModel.load(initialGridConfig: newConfig)

        XCTAssertEqual(recordsViewModel.state.selectedType, .mine)
        XCTAssertEqual(recordsViewModel.state.records.count, 1)
        XCTAssertEqual(recordsViewModel.state.records.first?.player.name, "Tester")
    }
}
