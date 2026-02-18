import Foundation
import SchulteDomain

public actor LocalScoreRecordRepository: ScoreRecordRepository {
    private let store: any KeyValueStore
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(store: any KeyValueStore, key: String = StorageKeys.localRecords) {
        self.store = store
        self.key = key
    }

    public func loadAll() async throws -> ScoreRecords {
        guard let data = try await store.data(forKey: key) else {
            return ScoreRecords()
        }

        return (try? decoder.decode(ScoreRecords.self, from: data)) ?? ScoreRecords()
    }

    public func save(_ record: ScoreRecord) async throws {
        var all = try await loadAll()
        all.saveRecord(record)
        let data = try encoder.encode(all)
        try await store.setData(data, forKey: key)
    }
}
