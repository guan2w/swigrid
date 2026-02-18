import Foundation

public struct ScoreRecords: Codable, Equatable, Sendable {
    public static let maxRecordsPerConfig = 20

    public var records: [String: [ScoreRecord]]
    public var latestFiveStarRecords: [String: ScoreRecord]

    private enum CodingKeys: String, CodingKey {
        case records
        case latestFiveStarRecords = "latestLevel5Records"
    }

    public init(
        records: [String: [ScoreRecord]] = [:],
        latestFiveStarRecords: [String: ScoreRecord] = [:]
    ) {
        self.records = records
        self.latestFiveStarRecords = latestFiveStarRecords
    }

    @available(*, deprecated, renamed: "maxRecordsPerConfig")
    public static var recordsLimitCount: Int {
        maxRecordsPerConfig
    }

    @available(*, deprecated, renamed: "latestFiveStarRecords")
    public var latestLevel5Records: [String: ScoreRecord] {
        get { latestFiveStarRecords }
        set { latestFiveStarRecords = newValue }
    }

    public func best(_ gridConfig: GridConfig) -> ScoreRecord? {
        records[gridConfig.storageKey()]?.first
    }

    public func latestFiveStarRecord(_ gridConfig: GridConfig) -> ScoreRecord? {
        latestFiveStarRecords[gridConfig.storageKey()]
    }

    @available(*, deprecated, renamed: "latestFiveStarRecord(_:)")
    public func latestLevel5Record(_ gridConfig: GridConfig) -> ScoreRecord? {
        latestFiveStarRecord(gridConfig)
    }

    public func normalized(limit: Int = maxRecordsPerConfig) -> ScoreRecords {
        let allKeys = Set(records.keys).union(latestFiveStarRecords.keys)
        var normalizedRecords: [String: [ScoreRecord]] = [:]
        var normalizedLatest: [String: ScoreRecord] = [:]

        for key in allKeys {
            let sortedRecords = (records[key] ?? []).sorted { lhs, rhs in
                if lhs.timeScore == rhs.timeScore {
                    return lhs.endTimestampMS < rhs.endTimestampMS
                }
                return lhs.timeScore < rhs.timeScore
            }
            let limitedRecords = Array(sortedRecords.prefix(limit))

            if !limitedRecords.isEmpty {
                normalizedRecords[key] = limitedRecords
            }

            var fiveStarCandidates = limitedRecords.filter { $0.level == 5 }
            if let latest = latestFiveStarRecords[key], latest.level == 5 {
                fiveStarCandidates.append(latest)
            }
            if let latestFiveStar = fiveStarCandidates.max(by: { $0.endTimestampMS < $1.endTimestampMS }) {
                normalizedLatest[key] = latestFiveStar
            }
        }

        return ScoreRecords(records: normalizedRecords, latestFiveStarRecords: normalizedLatest)
    }

    public mutating func saveRecord(_ record: ScoreRecord, limit: Int = maxRecordsPerConfig) {
        let key = record.gridConfig.storageKey()
        var list = records[key] ?? []

        let insertIndex = list.firstIndex { $0.timeScore > record.timeScore } ?? list.count
        list.insert(record, at: insertIndex)

        if list.count > limit {
            list = Array(list.prefix(limit))
        }

        records[key] = list

        if record.level == 5 {
            latestFiveStarRecords[key] = record
        }
    }
}
