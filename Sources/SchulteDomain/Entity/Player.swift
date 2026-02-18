import Foundation

public struct Player: Codable, Equatable, Sendable {
    public static let maxNameLength = 16

    public var name: String {
        didSet {
            name = Self.normalizedName(name)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name
    }

    public init(name: String = "") {
        self.name = Self.normalizedName(name)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawName = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.init(name: rawName)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    public var isNotEmpty: Bool {
        !name.isEmpty
    }

    public static func normalizedName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxNameLength else {
            return trimmed
        }
        return String(trimmed.prefix(maxNameLength))
    }
}
