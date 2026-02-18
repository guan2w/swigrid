import Foundation

public struct GameConfig: Codable, Equatable, Sendable {
    public var gridConfig: GridConfig
    public var mute: Bool

    public init(gridConfig: GridConfig = GridConfig(), mute: Bool = false) {
        self.gridConfig = gridConfig
        self.mute = mute
    }
}
