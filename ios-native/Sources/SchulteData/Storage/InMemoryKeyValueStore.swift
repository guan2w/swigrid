import Foundation

public actor InMemoryKeyValueStore: KeyValueStore {
    private var storage: [String: Data]

    public init(initialStorage: [String: Data] = [:]) {
        self.storage = initialStorage
    }

    public func data(forKey key: String) async throws -> Data? {
        storage[key]
    }

    public func setData(_ data: Data?, forKey key: String) async throws {
        if let data {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
    }
}
