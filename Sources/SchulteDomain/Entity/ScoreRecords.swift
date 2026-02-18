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

    public func normalized(limit: Int = recordsLimitCount) -> ScoreRecords {
        let allKeys = Set(records.keys).union(latestLevel5Records.keys)
        var normalizedRecords: [String: [ScoreRecord]] = [:]
        var normalizedLatest: [String: ScoreRecord] = [:]

        for key in allKeys {
            let sortedRecords = (records[key] ?? []).sorted { lhs, rhs in
                if lhs.timeScore == rhs.timeScore {
                    return lhs.t1 < rhs.t1
                }
                return lhs.timeScore < rhs.timeScore
            }
            let limitedRecords = Array(sortedRecords.prefix(limit))

            if !limitedRecords.isEmpty {
                normalizedRecords[key] = limitedRecords
            }

            var level5Candidates = limitedRecords.filter { $0.level == 5 }
            if let latest = latestLevel5Records[key], latest.level == 5 {
                level5Candidates.append(latest)
            }
            if let latestLevel5 = level5Candidates.max(by: { $0.t1 < $1.t1 }) {
                normalizedLatest[key] = latestLevel5
            }
        }

        return ScoreRecords(records: normalizedRecords, latestLevel5Records: normalizedLatest)
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
