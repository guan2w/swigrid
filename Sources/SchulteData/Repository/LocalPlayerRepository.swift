import Foundation
import SchulteDomain

public actor LocalPlayerRepository: PlayerRepository {
    private let store: any KeyValueStore
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(store: any KeyValueStore, key: String = StorageKeys.player) {
        self.store = store
        self.key = key
    }

    public func loadPlayer() async throws -> Player {
        guard let data = try await store.data(forKey: key) else {
            return Player()
        }

        return (try? decoder.decode(Player.self, from: data)) ?? Player()
    }

    public func savePlayer(_ player: Player) async throws {
        let data = try encoder.encode(player)
        try await store.setData(data, forKey: key)
    }
}
