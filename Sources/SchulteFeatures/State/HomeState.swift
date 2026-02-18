import Foundation
import SchulteDomain

public struct HomeState: Equatable {
    public var playerName: String
    public var gridConfig: GridConfig
    public var mute: Bool
    public var starCount: Int
    public var showColorfulStar: Bool

    public init(
        playerName: String = "",
        gridConfig: GridConfig = GridConfig(),
        mute: Bool = false,
        starCount: Int = 0,
        showColorfulStar: Bool = false
    ) {
        self.playerName = playerName
        self.gridConfig = gridConfig
        self.mute = mute
        self.starCount = starCount
        self.showColorfulStar = showColorfulStar
    }
}
