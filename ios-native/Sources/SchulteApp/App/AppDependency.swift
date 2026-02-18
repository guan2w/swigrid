import Combine
import Foundation
import SchulteData

@MainActor
final class AppDependency: ObservableObject {
    let playerRepository: LocalPlayerRepository
    let gameConfigRepository: LocalGameConfigRepository
    let scoreRecordRepository: LocalScoreRecordRepository

    init() {
        let store = UserDefaultsKeyValueStore()
        self.playerRepository = LocalPlayerRepository(store: store)
        self.gameConfigRepository = LocalGameConfigRepository(store: store)
        self.scoreRecordRepository = LocalScoreRecordRepository(store: store)
    }
}
