import Foundation

public struct GridConfig: Codable, Equatable, Hashable, Sendable {
    public static let allowedScales: [Int] = [3, 4, 5, 6]

    public var scale: Int {
        didSet {
            if !Self.allowedScales.contains(scale) {
                scale = 3
            }
        }
    }

    public var dual: Bool

    public init(scale: Int = 3, dual: Bool = false) {
        self.scale = Self.allowedScales.contains(scale) ? scale : 3
        self.dual = dual
    }

    public var squaredScale: Int {
        scale * scale
    }

    public var numbersCount: Int {
        squaredScale * (dual ? 2 : 1)
    }

    public func asKey() -> String {
        "\(scale):\(dual ? 2 : 1)"
    }
}
