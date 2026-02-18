import Combine
import Foundation
import SchulteDomain

@MainActor
public final class RecordsViewModel: ObservableObject {
    @Published public private(set) var state = RecordsState()

    private let scoreRecordRepository: any ScoreRecordRepository
    private var allRecords = ScoreRecords()

    public init(scoreRecordRepository: any ScoreRecordRepository) {
        self.scoreRecordRepository = scoreRecordRepository
    }

    public func load(initialGridConfig: GridConfig) async {
        state.selectedGridConfig = initialGridConfig
        do {
            allRecords = try await scoreRecordRepository.loadAll()
            applyCurrentFilter()
        } catch {
            state.records = []
        }
    }

    public func selectType(_ type: RecordsType) {
        state.selectedType = type
        applyCurrentFilter()
    }

    public func updateGridConfig(_ config: GridConfig) {
        state.selectedGridConfig = config
        applyCurrentFilter()
    }

    public func refresh() async {
        do {
            allRecords = try await scoreRecordRepository.loadAll()
            applyCurrentFilter()
        } catch {
            state.records = []
        }
    }

    private func applyCurrentFilter() {
        switch state.selectedType {
        case .mine:
            state.records = (allRecords.records[state.selectedGridConfig.asKey()] ?? []).sorted { lhs, rhs in
                if lhs.timeScore == rhs.timeScore {
                    return lhs.t1 < rhs.t1
                }
                return lhs.timeScore < rhs.timeScore
            }
        case .global, .today:
            state.records = []
        }
    }
}
