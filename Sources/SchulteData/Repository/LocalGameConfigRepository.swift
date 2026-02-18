import Foundation
import SchulteDomain

public actor LocalGameConfigRepository: GameConfigRepository {
    private let store: any KeyValueStore
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(store: any KeyValueStore, key: String = StorageKeys.gameConfig) {
        self.store = store
        self.key = key
    }

    public func loadConfig() async throws -> GameConfig {
        guard let data = try await store.data(forKey: key) else {
            return GameConfig()
        }

        return (try? decoder.decode(GameConfig.self, from: data)) ?? GameConfig()
    }

    public func saveConfig(_ config: GameConfig) async throws {
        let data = try encoder.encode(config)
        try await store.setData(data, forKey: key)
    }
}
