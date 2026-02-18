import XCTest
@testable import SchulteDomain

final class ScoringRuleTests: XCTestCase {
    func testScoreRoundingMatchesFlutterRule() {
        XCTAssertEqual(ScoringRule.scoreMS2S(12_345), 12.35)
        XCTAssertEqual(ScoringRule.scoreMS2S(12_344), 12.34)
    }

    func testDualBoundaryUsesOriginalThreshold() {
        let config = GridConfig(scale: 3, dual: true)
        XCTAssertEqual(ScoringRule.evalLevel(scoreMS: 11_000, config: config), 1)
        XCTAssertEqual(ScoringRule.evalLevel(scoreMS: 3_500, config: config), 5)
    }

    func testNonDualBoundaryUsesHalfThreshold() {
        let config = GridConfig(scale: 4, dual: false)
        XCTAssertEqual(ScoringRule.evalLevel(scoreMS: 4_000, config: config), 4)
        XCTAssertEqual(ScoringRule.evalLevel(scoreMS: 3_500, config: config), 5)
    }
}
