import Combine
import Foundation
import SchulteDomain

@MainActor
public final class GameViewModel: ObservableObject {
    @Published public private(set) var state = GameState()

    private var session: GameSession?
    private var gridConfig: GridConfig?
    private let now: @Sendable () -> Int64

    public init(now: @escaping @Sendable () -> Int64 = { Int64(Date().timeIntervalSince1970 * 1000) }) {
        self.now = now
    }

    public func reset() {
        session = nil
        gridConfig = nil
        state = GameState(status: .ready, countdown: 3, nextNumber: nil, elapsedMS: 0, gridNumbers: nil, highlightedNumber: nil)
    }

    public func configure(gridConfig: GridConfig) throws {
        self.gridConfig = gridConfig
        self.session = try GameSession(maxNumber: gridConfig.numbersCount)
        state = GameState(
            status: .ready,
            countdown: 3,
            nextNumber: 1,
            elapsedMS: 0,
            gridNumbers: GridGenerator.generate(config: gridConfig),
            highlightedNumber: nil
        )
    }

    public func tickCountdown() {
        guard state.status == .ready else {
            return
        }

        if state.countdown > 1 {
            state.countdown -= 1
            return
        }

        do {
            try session?.start(at: now())
            state.countdown = 0
            state.status = .ongoing
            state.nextNumber = session?.nextNumber
        } catch {
            return
        }
    }

    @discardableResult
    public func tap(number: Int) -> GameSession.TapResult {
        guard var session else {
            return .ignored
        }

        let result = session.proceed(tapped: number, at: now())
        self.session = session

        switch result {
        case .ignored:
            break
        case .incorrect:
            break
        case let .correct(nextNumber):
            state.nextNumber = nextNumber
        case .finished:
            state.status = .finished
            state.nextNumber = nil
            state.elapsedMS = session.timeScore ?? state.elapsedMS
            state.highlightedNumber = nil
        }

        return result
    }

    public func tickTimer() {
        guard let session, session.gameStatus == .ongoing else {
            return
        }

        guard let start = session.timestamps.first ?? nil else {
            return
        }

        state.elapsedMS = now() - start
    }

    public func toggleNextHint() {
        guard state.status == .ongoing else {
            return
        }

        if state.highlightedNumber == state.nextNumber {
            state.highlightedNumber = nil
        } else {
            state.highlightedNumber = state.nextNumber
        }
    }

    public func finalizeRecord(player: Player) throws -> ScoreRecord {
        guard let session, let gridConfig else {
            throw GameSession.SessionError.invalidTransition
        }

        return try session.buildRecord(player: player, gridConfig: gridConfig)
    }
}
