import Foundation
import SchulteDomain

public struct RecordsState: Equatable {
    public var selectedType: RecordsType
    public var selectedGridConfig: GridConfig
    public var records: [ScoreRecord]

    public init(
        selectedType: RecordsType = .mine,
        selectedGridConfig: GridConfig = GridConfig(),
        records: [ScoreRecord] = []
    ) {
        self.selectedType = selectedType
        self.selectedGridConfig = selectedGridConfig
        self.records = records
    }
}
