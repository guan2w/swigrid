import Foundation

public protocol PlayerRepository: Sendable {
    func loadPlayer() async throws -> Player
    func savePlayer(_ player: Player) async throws
}

public protocol GameConfigRepository: Sendable {
    func loadConfig() async throws -> GameConfig
    func saveConfig(_ config: GameConfig) async throws
}

public protocol ScoreRecordRepository: Sendable {
    func loadAll() async throws -> ScoreRecords
    func save(_ record: ScoreRecord) async throws
}
