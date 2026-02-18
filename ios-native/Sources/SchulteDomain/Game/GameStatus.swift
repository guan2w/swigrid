import Foundation

public enum GameStatus: String, Codable, Equatable, Sendable {
    case ready
    case ongoing
    case finished
}
