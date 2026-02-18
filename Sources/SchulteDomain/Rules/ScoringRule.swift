import Foundation

public enum ScoringRule {
    public static let levelBoundariesByScale: [Int: [Double]] = [
        6: [60, 50, 40, 32, 24, 0],
        5: [40, 32, 24, 20, 16, 0],
        4: [32, 24, 16, 12, 8, 0],
        3: [12, 10, 8, 6, 4, 0],
    ]

    public static func millisecondsToSeconds(_ milliseconds: Int64) -> Double {
        ((Double(milliseconds) / 10.0).rounded()) / 100.0
    }

    public static func evaluateLevel(scoreMilliseconds: Int64, config: GridConfig) -> Int {
        guard let boundaries = levelBoundariesByScale[config.scale] else {
            return 0
        }

        let elapsedSeconds = millisecondsToSeconds(scoreMilliseconds)
        for (index, baseBoundary) in boundaries.enumerated() {
            let boundary = config.dual ? baseBoundary : (baseBoundary / 2.0)
            if elapsedSeconds >= boundary {
                return index
            }
        }

        return 0
    }

    @available(*, deprecated, renamed: "levelBoundariesByScale")
    public static var dualScaleLevelBoundary: [Int: [Double]] {
        levelBoundariesByScale
    }

    @available(*, deprecated, renamed: "millisecondsToSeconds(_:)")
    public static func scoreMS2S(_ milliseconds: Int64) -> Double {
        millisecondsToSeconds(milliseconds)
    }

    @available(*, deprecated, renamed: "evaluateLevel(scoreMilliseconds:config:)")
    public static func evalLevel(scoreMS: Int64, config: GridConfig) -> Int {
        evaluateLevel(scoreMilliseconds: scoreMS, config: config)
    }
}
