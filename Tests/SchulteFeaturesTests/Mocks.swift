import Foundation
@testable import SchulteDomain

actor MockPlayerRepository: PlayerRepository {
    var player: Player

    init(player: Player = Player()) {
        self.player = player
    }

    func loadPlayer() async throws -> Player {
        player
    }

    func savePlayer(_ player: Player) async throws {
        self.player = player
    }
}

actor MockGameConfigRepository: GameConfigRepository {
    var config: GameConfig

    init(config: GameConfig = GameConfig()) {
        self.config = config
    }

    func loadConfig() async throws -> GameConfig {
        config
    }

    func saveConfig(_ config: GameConfig) async throws {
        self.config = config
    }
}

actor MockScoreRecordRepository: ScoreRecordRepository {
    var scoreRecords: ScoreRecords

    init(scoreRecords: ScoreRecords = ScoreRecords()) {
        self.scoreRecords = scoreRecords
    }

    func loadAll() async throws -> ScoreRecords {
        scoreRecords
    }

    func save(_ record: ScoreRecord) async throws {
        scoreRecords.saveRecord(record)
    }
}

final class IncrementingClock: @unchecked Sendable {
    private var value: Int64

    init(start: Int64) {
        self.value = start
    }

    func next() -> Int64 {
        defer { value += 1 }
        return value
    }
}
