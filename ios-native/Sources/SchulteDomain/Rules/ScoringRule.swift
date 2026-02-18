import Foundation

public enum ScoringRule {
    public static let dualScaleLevelBoundary: [Int: [Double]] = [
        6: [60, 50, 40, 32, 24, 0],
        5: [40, 32, 24, 20, 16, 0],
        4: [32, 24, 16, 12, 8, 0],
        3: [12, 10, 8, 6, 4, 0],
    ]

    public static func scoreMS2S(_ milliseconds: Int64) -> Double {
        ((Double(milliseconds) / 10.0).rounded()) / 100.0
    }

    public static func evalLevel(scoreMS: Int64, config: GridConfig) -> Int {
        guard let boundaries = dualScaleLevelBoundary[config.scale] else {
            return 0
        }

        let scoreAsSeconds = scoreMS2S(scoreMS)
        for (index, baseBoundary) in boundaries.enumerated() {
            let boundary = config.dual ? baseBoundary : (baseBoundary / 2.0)
            if scoreAsSeconds >= boundary {
                return index
            }
        }

        return 0
    }
}
