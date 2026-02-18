import Foundation

public struct ScoreRecords: Codable, Equatable, Sendable {
    public static let recordsLimitCount = 20

    public var records: [String: [ScoreRecord]]
    public var latestLevel5Records: [String: ScoreRecord]

    public init(
        records: [String: [ScoreRecord]] = [:],
        latestLevel5Records: [String: ScoreRecord] = [:]
    ) {
        self.records = records
        self.latestLevel5Records = latestLevel5Records
    }

    public func best(_ gridConfig: GridConfig) -> ScoreRecord? {
        records[gridConfig.asKey()]?.first
    }

    public func latestLevel5Record(_ gridConfig: GridConfig) -> ScoreRecord? {
        latestLevel5Records[gridConfig.asKey()]
    }

    public mutating func saveRecord(_ record: ScoreRecord, limit: Int = recordsLimitCount) {
        let key = record.gc.asKey()
        var list = records[key] ?? []

        let insertIndex = list.firstIndex { $0.timeScore > record.timeScore } ?? list.count
        list.insert(record, at: insertIndex)

        if list.count > limit {
            list = Array(list.prefix(limit))
        }

        records[key] = list

        if record.level == 5 {
            latestLevel5Records[key] = record
        }
    }
}
