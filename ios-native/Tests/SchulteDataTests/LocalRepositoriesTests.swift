import XCTest
@testable import SchulteDomain
@testable import SchulteData

final class LocalRepositoriesTests: XCTestCase {
    func testPlayerRepositoryLoadsDefaultAndPersists() async throws {
        let store = InMemoryKeyValueStore()
        let repository = LocalPlayerRepository(store: store)

        let empty = try await repository.loadPlayer()
        XCTAssertEqual(empty, Player())

        try await repository.savePlayer(Player(name: "Eric"))
        let loaded = try await repository.loadPlayer()
        XCTAssertEqual(loaded.name, "Eric")
    }

    func testGameConfigRepositoryPersistsMuteAndGridConfig() async throws {
        let store = InMemoryKeyValueStore()
        let repository = LocalGameConfigRepository(store: store)

        let config = GameConfig(gridConfig: GridConfig(scale: 6, dual: true), mute: true)
        try await repository.saveConfig(config)

        let loaded = try await repository.loadConfig()
        XCTAssertEqual(loaded.mute, true)
        XCTAssertEqual(loaded.gridConfig.scale, 6)
        XCTAssertEqual(loaded.gridConfig.dual, true)
    }

    func testScoreRecordRepositorySortsRecordsByTime() async throws {
        let store = InMemoryKeyValueStore()
        let repository = LocalScoreRecordRepository(store: store)
        let config = GridConfig(scale: 3, dual: false)

        let slower = try ScoreRecord(p1: Player(name: "Slow"), gc: config, t0: 1_000, t1: 5_000)
        let faster = try ScoreRecord(p1: Player(name: "Fast"), gc: config, t0: 1_000, t1: 2_000)

        try await repository.save(slower)
        try await repository.save(faster)

        let all = try await repository.loadAll()
        let list = all.records[config.asKey()] ?? []

        XCTAssertEqual(list.map(\.p1.name), ["Fast", "Slow"])
        XCTAssertEqual(all.best(config)?.p1.name, "Fast")
    }

    func testMutePersistenceUsingUseCase() async throws {
        let store = InMemoryKeyValueStore()
        let repository = LocalGameConfigRepository(store: store)
        let loadUseCase = LoadGameConfigUseCase(repository: repository)
        let saveUseCase = SaveGameConfigUseCase(repository: repository)

        let initial = try await loadUseCase.execute()
        XCTAssertFalse(initial.mute)

        var updated = initial
        updated.mute = true
        try await saveUseCase.execute(updated)

        let reloaded = try await loadUseCase.execute()
        XCTAssertTrue(reloaded.mute)
    }
}
