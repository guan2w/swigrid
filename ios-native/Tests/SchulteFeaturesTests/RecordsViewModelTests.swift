import XCTest
@testable import SchulteDomain
@testable import SchulteFeatures

@MainActor
final class RecordsViewModelTests: XCTestCase {
    func testMineFilterAndPlaceholderTypes() async throws {
        let configA = GridConfig(scale: 3, dual: false)
        let configB = GridConfig(scale: 4, dual: false)

        var scoreRecords = ScoreRecords()
        scoreRecords.saveRecord(try ScoreRecord(p1: Player(name: "A"), gc: configA, t0: 1_000, t1: 3_000))
        scoreRecords.saveRecord(try ScoreRecord(p1: Player(name: "B"), gc: configB, t0: 1_000, t1: 4_000))

        let repository = MockScoreRecordRepository(scoreRecords: scoreRecords)
        let viewModel = RecordsViewModel(scoreRecordRepository: repository)

        await viewModel.load(initialGridConfig: configA)
        XCTAssertEqual(viewModel.state.records.count, 1)
        XCTAssertEqual(viewModel.state.records.first?.p1.name, "A")

        viewModel.selectType(.global)
        XCTAssertTrue(viewModel.state.records.isEmpty)

        viewModel.selectType(.mine)
        viewModel.updateGridConfig(configB)
        XCTAssertEqual(viewModel.state.records.count, 1)
        XCTAssertEqual(viewModel.state.records.first?.p1.name, "B")
    }
}
