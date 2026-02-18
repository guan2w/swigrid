import Foundation

public struct ScoreRecord: Codable, Equatable, Sendable {
    public enum ValidationError: Error {
        case invalidStartTime
        case invalidEndTime
    }

    public let p1: Player
    public let gc: GridConfig
    public let t0: Int64
    public let t1: Int64

    public init(p1: Player, gc: GridConfig, t0: Int64, t1: Int64) throws {
        guard t0 > 0 else {
            throw ValidationError.invalidStartTime
        }

        guard t1 > t0 else {
            throw ValidationError.invalidEndTime
        }

        self.p1 = p1
        self.gc = gc
        self.t0 = t0
        self.t1 = t1
    }

    public var timeScore: Int64 {
        t1 - t0
    }

    public var timeScoreAsSeconds: Double {
        ScoringRule.scoreMS2S(timeScore)
    }

    public var level: Int {
        ScoringRule.evalLevel(scoreMS: timeScore, config: gc)
    }

    public func isFresh(referenceTimestampMS: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) -> Bool {
        referenceTimestampMS >= t1 && (referenceTimestampMS - t1) < 86_400_000
    }
}
