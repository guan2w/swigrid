import Foundation

public struct Player: Codable, Equatable, Sendable {
    public var name: String

    public init(name: String = "") {
        self.name = name
    }

    public var isNotEmpty: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
