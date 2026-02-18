import Foundation

public actor UserDefaultsKeyValueStore: KeyValueStore {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func data(forKey key: String) async throws -> Data? {
        userDefaults.data(forKey: key)
    }

    public func setData(_ data: Data?, forKey key: String) async throws {
        if let data {
            userDefaults.set(data, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
