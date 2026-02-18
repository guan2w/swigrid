import Foundation
import SchulteDomain

public struct GameState: Equatable {
    public var status: GameStatus
    public var countdown: Int
    public var nextNumber: Int?
    public var elapsedMS: Int64
    public var gridNumbers: GridNumbers?
    public var highlightedNumber: Int?

    public init(
        status: GameStatus = .ready,
        countdown: Int = 3,
        nextNumber: Int? = 1,
        elapsedMS: Int64 = 0,
        gridNumbers: GridNumbers? = nil,
        highlightedNumber: Int? = nil
    ) {
        self.status = status
        self.countdown = countdown
        self.nextNumber = nextNumber
        self.elapsedMS = elapsedMS
        self.gridNumbers = gridNumbers
        self.highlightedNumber = highlightedNumber
    }
}
