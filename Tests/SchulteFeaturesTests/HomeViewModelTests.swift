import XCTest
@testable import SchulteDomain
@testable import SchulteFeatures

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadAndPersistMuteAndPlayerName() async throws {
        let gridConfig = GridConfig(scale: 4, dual: true)
        let playerRepository = MockPlayerRepository(player: Player(name: "WG"))
        let gameConfigRepository = MockGameConfigRepository(config: GameConfig(gridConfig: gridConfig, mute: false))

        var scoreRecords = ScoreRecords()
        let fiveStar = try ScoreRecord(
            player: Player(name: "WG"),
            gridConfig: gridConfig,
            startTimestampMS: 1_000,
            endTimestampMS: 3_000
        )
        scoreRecords.saveRecord(fiveStar)
        let scoreRepository = MockScoreRecordRepository(scoreRecords: scoreRecords)

        let viewModel = HomeViewModel(
            playerRepository: playerRepository,
            gameConfigRepository: gameConfigRepository,
            scoreRecordRepository: scoreRepository
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state.playerName, "WG")
        XCTAssertEqual(viewModel.state.gridConfig, gridConfig)
        XCTAssertEqual(viewModel.state.starCount, 5)

        await viewModel.setMute(true)
        let savedConfig = try await gameConfigRepository.loadConfig()
        XCTAssertTrue(savedConfig.mute)

        await viewModel.savePlayerName("Eric")
        let savedPlayer = try await playerRepository.loadPlayer()
        XCTAssertEqual(savedPlayer.name, "Eric")
    }
}
