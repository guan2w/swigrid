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
    @State private var activeGridConfig = GridConfig()
    @State private var isMuted = false
    @State private var displayedNumbers: [Int?] = []
    @State private var deferredSecondRoundNumbers: [Int]? = nil
    @State private var didSaveResult = false

    @State private var showsResultAlert = false
    @State private var resultSeconds = "0.00"
    @State private var resultLevel = 0
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
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 0.22, green: 0.29, blue: 0.31))
                        Button {
                            viewModel.toggleNextHint()
                            hapticService.nextHintTap()
                        } label: {
                            Text(viewModel.state.nextNumber.map(String.init) ?? "-")
                                .font(.custom("Eras-Demi-ITC", size: proxy.size.width / 9))
                                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.28).opacity(0.4))
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.state.status != .ongoing)
                        .accessibilityIdentifier("game.next")
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Time")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 0.22, green: 0.29, blue: 0.31))
                        Text(formatSeconds(viewModel.state.elapsedMilliseconds))
                            .font(.custom("digital-7", size: proxy.size.width / 5.5))
                            .foregroundStyle(Color(red: 0.976, green: 0.659, blue: 0.145))
                            .shadow(color: Color(red: 0.976, green: 0.659, blue: 0.145), radius: 1)
                            .accessibilityIdentifier("game.timer")
                    }
                }

                if !player.hasName {
                    Text("Set a player name on Home before starting.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ZStack {
                    gridView(side: gridSide)
                        .overlay(alignment: .center) {
                            if viewModel.state.status == .ready {
                                Text(viewModel.state.countdown > 0 ? "\(viewModel.state.countdown)" : "Go")
                                    .font(.custom("CrashNumbering", size: 150))
                                    .foregroundStyle(.green.opacity(0.7))
                                    .shadow(color: Color.black.opacity(0.13), radius: 4)
                            }
                        }
                }

                Button("Restart Round") {
                    Task { await configureGame() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!player.hasName)
                .accessibilityIdentifier("game.restart")

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(16)
        }
        .navigationTitle("Challenge")
        .task {
            await configureGame()
        }
        .onReceive(countdownTimer) { _ in
            if player.hasName, viewModel.state.status == .ready, viewModel.state.countdown > 0 {
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
                await saveResultIfNeeded()
            }
        }
        .alert("Round Complete", isPresented: $showsResultAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Time: \(resultSeconds)\nRating: \(resultLevel)/5")
        }
        .alert("Unable to Continue", isPresented: Binding(
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
        let scale = max(activeGridConfig.scale, 1)
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: scale)
        let cellSize = max((side - CGFloat(scale - 1) * spacing) / CGFloat(scale), 44)
        let fontSize = floor((side - 30) / CGFloat(scale) / 2)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(displayedNumbers.indices, id: \.self) { index in
                let displayNumber = displayedNumbers[index]
                let isHighlighted = (viewModel.state.highlightedNumber == displayNumber)

                Button {
                    handleCellTap(index: index)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(white: 0.933))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isHighlighted ? Color.teal.opacity(0.9) : Color.clear, lineWidth: 3)
                            )

                        Text(displayNumber.map(String.init) ?? "")
                            .font(.custom("Eras-Demi-ITC", size: fontSize))
                            .foregroundStyle(Color(red: 0.216, green: 0.278, blue: 0.310).opacity(Double(scale + 9) / 20.0))
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
            activeGridConfig = loadedConfig.gridConfig
            isMuted = loadedConfig.mute

            guard player.hasName else {
                viewModel.reset()
                displayedNumbers = []
                deferredSecondRoundNumbers = nil
                didSaveResult = true
                return
            }

            try viewModel.configure(gridConfig: activeGridConfig)
            if let gridNumbers = viewModel.state.gridNumbers {
                displayedNumbers = gridNumbers.firstRound.map { Optional($0) }
                deferredSecondRoundNumbers = gridNumbers.secondRound
            } else {
                displayedNumbers = []
                deferredSecondRoundNumbers = nil
            }

            didSaveResult = false
            showsResultAlert = false
        } catch {
            errorMessage = "Failed to load game setup: \(error.localizedDescription)"
        }
    }

    private func handleCellTap(index: Int) {
        guard let number = displayedNumbers[index] else {
            return
        }

        let result = viewModel.tap(number: number)

        switch result {
        case .ignored:
            break
        case .incorrect:
            audioService.play(.incorrect, muted: isMuted)
            hapticService.incorrectTap()
        case .correct, .finished:
            audioService.play(.correct, muted: isMuted)
            hapticService.correctTap()
            if let deferredSecondRoundNumbers {
                if displayedNumbers[index] == deferredSecondRoundNumbers[index] {
                    displayedNumbers[index] = nil
                } else {
                    displayedNumbers[index] = deferredSecondRoundNumbers[index]
                }
            } else {
                displayedNumbers[index] = nil
            }
        }
    }

    private func saveResultIfNeeded() async {
        guard !didSaveResult else {
            return
        }

        didSaveResult = true

        do {
            let record = try viewModel.finalizeRecord(player: player)
            try await scoreRecordRepository.save(record)
            resultSeconds = String(format: "%.2f", record.timeScoreAsSeconds)
            resultLevel = record.level
            showsResultAlert = true
        } catch {
            errorMessage = "Failed to save the result: \(error.localizedDescription)"
        }
    }

    private func formatSeconds(_ milliseconds: Int64) -> String {
        String(format: "%.2f", ScoringRule.millisecondsToSeconds(milliseconds))
    }
}
