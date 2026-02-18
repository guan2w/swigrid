import Foundation

public struct LoadPlayerUseCase: Sendable {
    private let repository: any PlayerRepository

    public init(repository: any PlayerRepository) {
        self.repository = repository
    }

    public func execute() async throws -> Player {
        try await repository.loadPlayer()
    }
}

public struct SavePlayerUseCase: Sendable {
    private let repository: any PlayerRepository

    public init(repository: any PlayerRepository) {
        self.repository = repository
    }

    public func execute(_ player: Player) async throws {
        try await repository.savePlayer(player)
    }
}

public struct LoadGameConfigUseCase: Sendable {
    private let repository: any GameConfigRepository

    public init(repository: any GameConfigRepository) {
        self.repository = repository
    }

    public func execute() async throws -> GameConfig {
        try await repository.loadConfig()
    }
}

public struct SaveGameConfigUseCase: Sendable {
    private let repository: any GameConfigRepository

    public init(repository: any GameConfigRepository) {
        self.repository = repository
    }

    public func execute(_ config: GameConfig) async throws {
        try await repository.saveConfig(config)
    }
}

public struct LoadScoreRecordsUseCase: Sendable {
    private let repository: any ScoreRecordRepository

    public init(repository: any ScoreRecordRepository) {
        self.repository = repository
    }

    public func execute() async throws -> ScoreRecords {
        try await repository.loadAll()
    }
}

public struct SaveScoreRecordUseCase: Sendable {
    private let repository: any ScoreRecordRepository

    public init(repository: any ScoreRecordRepository) {
        self.repository = repository
    }

    public func execute(_ record: ScoreRecord) async throws {
        try await repository.save(record)
    }
}
