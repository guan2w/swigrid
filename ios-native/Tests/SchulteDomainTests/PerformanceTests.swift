import XCTest
@testable import SchulteDomain

final class PerformanceTests: XCTestCase {
    func testScoringRulePerformance() {
        let config = GridConfig(scale: 6, dual: true)

        measure(metrics: [XCTClockMetric()]) {
            var sum = 0
            for i in 0 ..< 10_000 {
                sum += ScoringRule.evalLevel(scoreMS: Int64(1_000 + i), config: config)
            }
            XCTAssertGreaterThanOrEqual(sum, 0)
        }
    }

    func testFullSessionSimulationPerformance() {
        let config = GridConfig(scale: 6, dual: true)

        measure(metrics: [XCTClockMetric()]) {
            do {
                var session = try GameSession(maxNumber: config.numbersCount)
                try session.start(at: 1_000)

                for number in 1 ... config.numbersCount {
                    _ = session.proceed(tapped: number, at: Int64(1_000 + number))
                }

                XCTAssertTrue(session.validate())
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
