import Foundation

public struct ScoreRecord: Codable, Equatable, Sendable {
    public enum ValidationError: Error {
        case invalidStartTime
        case invalidEndTime
    }

    public let player: Player
    public let gridConfig: GridConfig
    public let startTimestampMS: Int64
    public let endTimestampMS: Int64

    private enum CodingKeys: String, CodingKey {
        case player = "p1"
        case gridConfig = "gc"
        case startTimestampMS = "t0"
        case endTimestampMS = "t1"
    }

    public init(player: Player, gridConfig: GridConfig, startTimestampMS: Int64, endTimestampMS: Int64) throws {
        guard startTimestampMS > 0 else {
            throw ValidationError.invalidStartTime
        }

        guard endTimestampMS > startTimestampMS else {
            throw ValidationError.invalidEndTime
        }

        self.player = player
        self.gridConfig = gridConfig
        self.startTimestampMS = startTimestampMS
        self.endTimestampMS = endTimestampMS
    }

    @available(*, deprecated, renamed: "init(player:gridConfig:startTimestampMS:endTimestampMS:)")
    public init(p1: Player, gc: GridConfig, t0: Int64, t1: Int64) throws {
        try self.init(player: p1, gridConfig: gc, startTimestampMS: t0, endTimestampMS: t1)
    }

    public var timeScore: Int64 {
        endTimestampMS - startTimestampMS
    }

    public var timeScoreAsSeconds: Double {
        ScoringRule.millisecondsToSeconds(timeScore)
    }

    public var level: Int {
        ScoringRule.evaluateLevel(scoreMilliseconds: timeScore, config: gridConfig)
    }

    public func isFresh(referenceTimestampMS: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) -> Bool {
        referenceTimestampMS >= endTimestampMS && (referenceTimestampMS - endTimestampMS) < 86_400_000
    }

    @available(*, deprecated, renamed: "player")
    public var p1: Player {
        player
    }

    @available(*, deprecated, renamed: "gridConfig")
    public var gc: GridConfig {
        gridConfig
    }

    @available(*, deprecated, renamed: "startTimestampMS")
    public var t0: Int64 {
        startTimestampMS
    }

    @available(*, deprecated, renamed: "endTimestampMS")
    public var t1: Int64 {
        endTimestampMS
    }
}
