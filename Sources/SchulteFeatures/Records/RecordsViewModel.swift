import Combine
import Foundation
import SchulteDomain

@MainActor
public final class RecordsViewModel: ObservableObject {
    @Published public private(set) var state = RecordsState()

    private let scoreRecordRepository: any ScoreRecordRepository
    private let gameConfigRepository: any GameConfigRepository
    private var allRecords = ScoreRecords()

    public init(scoreRecordRepository: any ScoreRecordRepository, gameConfigRepository: any GameConfigRepository) {
        self.scoreRecordRepository = scoreRecordRepository
        self.gameConfigRepository = gameConfigRepository
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
        Task {
            try? await gameConfigRepository.saveConfig(
                GameConfig(gridConfig: config, mute: (try? await gameConfigRepository.loadConfig().mute) ?? false)
            )
        }
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
            state.records = (allRecords.records[state.selectedGridConfig.storageKey()] ?? []).sorted { lhs, rhs in
                if lhs.timeScore == rhs.timeScore {
                    return lhs.endTimestampMS < rhs.endTimestampMS
                }
                return lhs.timeScore < rhs.timeScore
            }
        case .global, .today:
            state.records = []
        }
    }
}
