import Foundation

public protocol KeyValueStore: Sendable {
    func data(forKey key: String) async throws -> Data?
    func setData(_ data: Data?, forKey key: String) async throws
}
