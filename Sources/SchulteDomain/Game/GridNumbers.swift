import Foundation

public struct GridNumbers: Equatable, Sendable {
    public let firstRound: [Int]
    public let secondRound: [Int]?

    public init(firstRound: [Int], secondRound: [Int]?) {
        self.firstRound = firstRound
        self.secondRound = secondRound
    }
}

public enum GridGenerator {
    public static func generate(config: GridConfig) -> GridNumbers {
        var rng = SystemRandomNumberGenerator()
        return generate(config: config, using: &rng)
    }

    public static func generate<R: RandomNumberGenerator>(config: GridConfig, using rng: inout R) -> GridNumbers {
        let squared = config.squaredScale

        var firstRound = Array(1 ... squared)
        firstRound.shuffle(using: &rng)

        var secondRound: [Int]? = nil
        if config.dual {
            var values = Array((squared + 1) ... (squared * 2))
            values.shuffle(using: &rng)
            secondRound = values
        }

        return GridNumbers(firstRound: firstRound, secondRound: secondRound)
    }
}
