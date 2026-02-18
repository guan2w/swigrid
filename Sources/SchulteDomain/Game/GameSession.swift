import Foundation

public struct GameSession: Equatable, Sendable {
    public enum SessionError: Error {
        case invalidMaxNumber
        case invalidTransition
        case invalidTimeline
        case missingTimeScore
        case mismatchedGridConfig
    }

    public enum TapResult: Equatable, Sendable {
        case ignored
        case incorrect(expected: Int, tapped: Int)
        case correct(nextNumber: Int)
        case finished
    }

    public let maxNumber: Int
    public private(set) var nextNumber: Int?
    public private(set) var timestamps: [Int64?]
    public private(set) var gameStatus: GameStatus

    public init(maxNumber: Int) throws {
        guard maxNumber > 0 else {
            throw SessionError.invalidMaxNumber
        }

        self.maxNumber = maxNumber
        self.nextNumber = 1
        self.timestamps = Array(repeating: nil, count: maxNumber + 1)
        self.gameStatus = .ready
    }

    public mutating func start(at timestampMS: Int64) throws {
        guard gameStatus == .ready else {
            throw SessionError.invalidTransition
        }

        gameStatus = .ongoing
        timestamps[0] = timestampMS
    }

    @discardableResult
    public mutating func proceed(tapped number: Int, at timestampMS: Int64) -> TapResult {
        guard gameStatus == .ongoing, let expected = nextNumber else {
            return .ignored
        }

        guard number == expected else {
            return .incorrect(expected: expected, tapped: number)
        }

        timestamps[expected] = timestampMS

        if expected == maxNumber {
            nextNumber = nil
            gameStatus = .finished
            return .finished
        }

        nextNumber = expected + 1
        return .correct(nextNumber: expected + 1)
    }

    public var timeScore: Int64? {
        guard let start = timestamps.first ?? nil,
              let end = timestamps.last ?? nil else {
            return nil
        }

        return end - start
    }

    public func validate() -> Bool {
        guard gameStatus == .finished else {
            return false
        }

        for index in 1 ..< timestamps.count {
            guard let previous = timestamps[index - 1],
                  let current = timestamps[index],
                  current >= previous + 1 else {
                return false
            }
        }

        return true
    }

    public func buildRecord(player: Player, gridConfig: GridConfig) throws -> ScoreRecord {
        guard gridConfig.numbersCount == maxNumber else {
            throw SessionError.mismatchedGridConfig
        }

        guard validate() else {
            throw SessionError.invalidTimeline
        }

        guard let start = timestamps.first ?? nil,
              let end = timestamps.last ?? nil else {
            throw SessionError.missingTimeScore
        }

        return try ScoreRecord(player: player, gridConfig: gridConfig, startTimestampMS: start, endTimestampMS: end)
    }
}
