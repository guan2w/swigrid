import XCTest
@testable import SchulteDomain

final class ScoringRuleTests: XCTestCase {
    func testScoreRoundingMatchesFlutterRule() {
        XCTAssertEqual(ScoringRule.millisecondsToSeconds(12_345), 12.35)
        XCTAssertEqual(ScoringRule.millisecondsToSeconds(12_344), 12.34)
    }

    func testDualBoundaryUsesOriginalThreshold() {
        let config = GridConfig(scale: 3, dual: true)
        XCTAssertEqual(ScoringRule.evaluateLevel(scoreMilliseconds: 11_000, config: config), 1)
        XCTAssertEqual(ScoringRule.evaluateLevel(scoreMilliseconds: 3_500, config: config), 5)
    }

    func testNonDualBoundaryUsesHalfThreshold() {
        let config = GridConfig(scale: 4, dual: false)
        XCTAssertEqual(ScoringRule.evaluateLevel(scoreMilliseconds: 4_000, config: config), 4)
        XCTAssertEqual(ScoringRule.evaluateLevel(scoreMilliseconds: 3_500, config: config), 5)
    }
}
