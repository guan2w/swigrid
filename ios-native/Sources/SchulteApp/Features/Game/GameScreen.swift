import SwiftUI
import SchulteDomain
import SchulteFeatures

struct GameScreen: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: GameViewModel

    private let playerRepository: any PlayerRepository
    private let gameConfigRepository: any GameConfigRepository
    private let scoreRecordRepository: any ScoreRecordRepository

    @State private var player = Player()
    @State private var currentConfig = GridConfig()
    @State private var muted = false
    @State private var cellNumbers: [Int?] = []
    @State private var secondRoundNumbers: [Int]? = nil
    @State private var didPersistResult = false

    @State private var showResult = false
    @State private var resultSeconds = "0.00"
    @State private var resultStars = 0
    @State private var errorMessage: String? = nil

    @State private var audioService = AudioService()
    @State private var hapticService = HapticService()

    private let countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let elapsedTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    init(dependency: AppDependency) {
        _viewModel = StateObject(wrappedValue: GameViewModel())
        self.playerRepository = dependency.playerRepository
        self.gameConfigRepository = dependency.gameConfigRepository
        self.scoreRecordRepository = dependency.scoreRecordRepository
    }

    var body: some View {
        GeometryReader { proxy in
            let gridSide = max(220, min(proxy.size.width - 32, proxy.size.height * 0.72))
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Next")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            viewModel.toggleNextHint()
                            hapticService.nextHintTap()
                        } label: {
                            Text(viewModel.state.nextNumber.map(String.init) ?? "-")
                                .font(.custom("Eras-Demi-ITC", size: 44))
                                .foregroundStyle(Color(red: 0.37, green: 0.24, blue: 0.14))
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.state.status != .ongoing)
                        .accessibilityIdentifier("game.next")
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatSeconds(viewModel.state.elapsedMS))
                            .font(.custom("digital-7", size: 44))
                            .foregroundStyle(.yellow.opacity(0.9))
                            .accessibilityIdentifier("game.timer")
                    }
                }

                if !player.isNotEmpty {
                    Text("Please set player name in Home first")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    gridView(side: gridSide)
                        .overlay(alignment: .center) {
                            if viewModel.state.status == .ready {
                                Text(viewModel.state.countdown > 0 ? "\(viewModel.state.countdown)" : "Start")
                                    .font(.custom("CrashNumbering", size: min(gridSide * 0.34, 110)))
                                    .foregroundStyle(.green.opacity(0.75))
                            }
                        }
                }

                Button("Restart") {
                    Task { await configureGame() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!player.isNotEmpty)
                .accessibilityIdentifier("game.restart")

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(16)
        }
        .navigationTitle("Game")
        .task {
            await configureGame()
        }
        .onReceive(countdownTimer) { _ in
            if player.isNotEmpty, viewModel.state.status == .ready, viewModel.state.countdown > 0 {
                viewModel.tickCountdown()
            }
        }
        .onReceive(elapsedTimer) { _ in
            viewModel.tickTimer()
        }
        .onChange(of: viewModel.state.status) { _, newStatus in
            guard newStatus == .finished else {
                return
            }

            Task {
                await persistResultIfNeeded()
            }
        }
        .alert("Result", isPresented: $showResult) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Time: \(resultSeconds)\nStars: \(resultStars)/5")
        }
        .alert("Game Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func gridView(side: CGFloat) -> some View {
        let spacing: CGFloat = 6
        let scale = max(currentConfig.scale, 1)
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: scale)
        let cellSize = max((side - CGFloat(scale - 1) * spacing) / CGFloat(scale), 44)
        let fontSize = min(cellSize * 0.48, 30)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(cellNumbers.indices, id: \.self) { index in
                let displayNumber = cellNumbers[index]
                let isHighlighted = (viewModel.state.highlightedNumber == displayNumber)

                Button {
                    handleCellTap(index: index)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isHighlighted ? Color.teal.opacity(0.9) : Color.clear, lineWidth: 3)
                            )

                        Text(displayNumber.map(String.init) ?? "")
                            .font(.custom("Eras-Demi-ITC", size: fontSize))
                            .foregroundStyle(Color(red: 0.26, green: 0.35, blue: 0.39))
                    }
                    .frame(height: cellSize)
                    .scaleEffect(isHighlighted ? 1.04 : 1.0)
                    .shadow(color: isHighlighted ? Color.teal.opacity(0.35) : .clear, radius: 8, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.25), value: isHighlighted)
                }
                .buttonStyle(.plain)
                .disabled(displayNumber == nil || viewModel.state.status != .ongoing)
                .accessibilityIdentifier("game.cell.\(index)")
            }
        }
        .frame(width: side)
    }

    private func configureGame() async {
        do {
            let loadedPlayer = try await playerRepository.loadPlayer()
            let loadedConfig = try await gameConfigRepository.loadConfig()
            player = loadedPlayer
            currentConfig = loadedConfig.gridConfig
            muted = loadedConfig.mute

            guard player.isNotEmpty else {
                viewModel.reset()
                cellNumbers = []
                secondRoundNumbers = nil
                didPersistResult = true
                return
            }

            try viewModel.configure(gridConfig: currentConfig)
            if let gridNumbers = viewModel.state.gridNumbers {
                cellNumbers = gridNumbers.firstRound.map { Optional($0) }
                secondRoundNumbers = gridNumbers.secondRound
            } else {
                cellNumbers = []
                secondRoundNumbers = nil
            }

            didPersistResult = false
            showResult = false
        } catch {
            errorMessage = "Failed to configure game: \(error.localizedDescription)"
        }
    }

    private func handleCellTap(index: Int) {
        guard let number = cellNumbers[index] else {
            return
        }

        let result = viewModel.tap(number: number)

        switch result {
        case .ignored:
            break
        case .incorrect:
            audioService.play(.incorrect, muted: muted)
            hapticService.incorrectTap()
        case .correct, .finished:
            audioService.play(.correct, muted: muted)
            hapticService.correctTap()
            if let secondRoundNumbers {
                if cellNumbers[index] == secondRoundNumbers[index] {
                    cellNumbers[index] = nil
                } else {
                    cellNumbers[index] = secondRoundNumbers[index]
                }
            } else {
                cellNumbers[index] = nil
            }
        }
    }

    private func persistResultIfNeeded() async {
        guard !didPersistResult else {
            return
        }

        didPersistResult = true

        do {
            let record = try viewModel.finalizeRecord(player: player)
            try await scoreRecordRepository.save(record)
            resultSeconds = String(format: "%.2f", record.timeScoreAsSeconds)
            resultStars = record.level
            showResult = true
        } catch {
            errorMessage = "Failed to finish game: \(error.localizedDescription)"
        }
    }

    private func formatSeconds(_ milliseconds: Int64) -> String {
        String(format: "%.2f", ScoringRule.scoreMS2S(milliseconds))
    }
}
