import Combine
import Foundation
import SchulteDomain

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var state = HomeState()

    private let playerRepository: any PlayerRepository
    private let gameConfigRepository: any GameConfigRepository
    private let scoreRecordRepository: any ScoreRecordRepository

    public init(
        playerRepository: any PlayerRepository,
        gameConfigRepository: any GameConfigRepository,
        scoreRecordRepository: any ScoreRecordRepository
    ) {
        self.playerRepository = playerRepository
        self.gameConfigRepository = gameConfigRepository
        self.scoreRecordRepository = scoreRecordRepository
    }

    public func load() async {
        do {
            async let player = playerRepository.loadPlayer()
            async let config = gameConfigRepository.loadConfig()
            async let scoreRecords = scoreRecordRepository.loadAll()

            let loadedPlayer = try await player
            let loadedConfig = try await config
            let loadedRecords = try await scoreRecords

            state.playerName = loadedPlayer.name
            state.gridConfig = loadedConfig.gridConfig
            state.mute = loadedConfig.mute
            updateStars(with: loadedRecords)
        } catch {
            state = HomeState()
        }
    }

    public func savePlayerName(_ name: String) async {
        state.playerName = name
        do {
            try await playerRepository.savePlayer(Player(name: name))
        } catch {
            return
        }
    }

    public func setMute(_ mute: Bool) async {
        state.mute = mute
        await persistGameConfig()
    }

    public func setGridConfig(_ config: GridConfig) async {
        state.gridConfig = config
        await persistGameConfig()
        await reloadStars()
    }

    public func toggleDual() async {
        state.gridConfig.dual.toggle()
        await persistGameConfig()
        await reloadStars()
    }

    private func persistGameConfig() async {
        do {
            try await gameConfigRepository.saveConfig(
                GameConfig(gridConfig: state.gridConfig, mute: state.mute)
            )
        } catch {
            return
        }
    }

    private func reloadStars() async {
        do {
            let scoreRecords = try await scoreRecordRepository.loadAll()
            updateStars(with: scoreRecords)
        } catch {
            state.starCount = 0
            state.showColorfulStar = false
        }
    }

    private func updateStars(with records: ScoreRecords) {
        let best = records.best(state.gridConfig)?.level
        let latestFiveStar = records.latestLevel5Record(state.gridConfig)
        state.starCount = latestFiveStar?.level ?? best ?? 0
        state.showColorfulStar = latestFiveStar?.isFresh() ?? false
    }
}
