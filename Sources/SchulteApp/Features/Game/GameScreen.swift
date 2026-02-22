import SwiftUI
import SchulteDomain
import SchulteFeatures

struct GameScreen: View {

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

    @State private var flashIndex: Int?
    @State private var showCountdown = false

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
            ZStack {
                // Randomised coloured tile background – re‑generated each time the
                // game screen appears, giving every session a fresh look.
                GameGridBackgroundView()
                    .overlay(Color(uiColor: .systemBackground).opacity(0.55))
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Next")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.primary.opacity(0.6))
                        Button {
                            if let next = viewModel.state.nextNumber,
                               let idx = displayedNumbers.firstIndex(of: next) {
                                triggerFlash(at: idx)
                            }
                            hapticService.nextHintTap()
                        } label: {
                            Text(viewModel.state.nextNumber.map(String.init) ?? "-")
                                .font(.custom("ErasITC-Demi", size: proxy.size.width / 9))
                                .foregroundStyle(Color.primary.opacity(0.85))
                                .shadow(color: Color.white.opacity(0.5), radius: 6, x: 0, y: 0)
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.state.status != .ongoing)
                        .accessibilityIdentifier("game.next")
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Time")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.primary.opacity(0.6))
                        Text(formatSeconds(viewModel.state.elapsedMilliseconds))
                            .font(.custom("Digital-7MonoItalic", size: proxy.size.width / 5.5))
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
                    gridView(side: gridSide, screenWidth: proxy.size.width)
                }
                .padding(.bottom, 48)
                // 倒计时期间的蒙版：status 变 .ongoing 时立刻消失
                .overlay {
                    if viewModel.state.status == .ready {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .systemBackground).opacity(0.35))
                            .allowsHitTesting(false)
                    }
                }
                // 灯组：延迟移除，让 burst 动画播完
                .overlay(alignment: .bottom) {
                    if showCountdown {
                        RacingLightsOverlayView(countdown: viewModel.state.countdown)
                    }
                }

                Button {
                    Task { await configureGame() }
                } label: {
                    Text("Restart Round")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 36)
                .disabled(!player.hasName)
                .accessibilityIdentifier("game.restart")

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(16)
            } // End ZStack
        }
        .navigationTitle("Challenge")
        .edgeOnlySwipeBack()
        .task {
            await configureGame()
        }
        .onReceive(countdownTimer) { _ in
            if player.hasName, viewModel.state.status == .ready, viewModel.state.countdown > 0 {
                // withAnimation is required to trigger the structural .burstOut transition
                // when countdown hits 0. The individual RacingLight uses .animation(value: isLit)
                // which overrides this context for isLit property changes.
                withAnimation(.easeOut(duration: 0.28)) {
                    viewModel.tickCountdown()
                }
            }
        }
        .onReceive(elapsedTimer) { _ in
            viewModel.tickTimer()
        }
        .onChange(of: viewModel.state.status) { _, newStatus in
            if newStatus == .ongoing {
                // countdown 刚结束 → 延迟移除 overlay，给 burst 动画留时间
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCountdown = false
                }
            }
            guard newStatus == .finished else {
                return
            }

            Task {
                await saveResultIfNeeded()
            }
        }
        .overlay {
            if showsResultAlert {
                ResultOverlayView(
                    seconds: resultSeconds,
                    level: resultLevel,
                    dual: activeGridConfig.dual,
                    onNewGame: {
                        showsResultAlert = false
                        Task { await configureGame() }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showsResultAlert)
            }
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

    private func gridView(side: CGFloat, screenWidth: CGFloat) -> some View {
        let spacing: CGFloat = 6
        let scale = max(activeGridConfig.scale, 1)
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: scale)
        let cellSize = max((side - CGFloat(scale - 1) * spacing) / CGFloat(scale), 44)
        let fontSize = floor((screenWidth - 30) / CGFloat(scale) / 2)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(displayedNumbers.indices, id: \.self) { index in
                let displayNumber = displayedNumbers[index]
                let isFlashing = (flashIndex == index)
                let isVisible = (displayNumber != nil)
                Button {
                    // Action handled by TouchDownButtonStyle for instant response
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isFlashing ? Color.teal.opacity(0.4) : .clear)
                            .background(isFlashing ? .regularMaterial : .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.5), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)

                        // For dynamic grids, animating scale/opacity of a persistent view
                        // is far more reliable than inserting/removing it via .transition.
                        Text(displayNumber.map(String.init) ?? "")
                            .font(.custom("ErasITC-Demi", size: fontSize))
                            .foregroundStyle(Color.primary.opacity(Double(scale + 9) / 20.0))
                            .shadow(color: Color.white.opacity(0.3), radius: 2, x: 0, y: 0)
                            .scaleEffect(isVisible ? 1.0 : 0.1)
                            .opacity(isVisible ? 1.0 : 0)
                            .animation(.easeOut(duration: 0.18), value: isVisible)
                    }
                    .frame(height: cellSize)
                    .animation(.easeInOut(duration: 0.15), value: isFlashing)
                }
                .buttonStyle(TouchDownButtonStyle {
                    handleCellTap(index: index)
                })
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
            showCountdown = true
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
            withAnimation(.easeOut(duration: 0.15)) {
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

    private func triggerFlash(at index: Int) {
        flashIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if flashIndex == index { flashIndex = nil }
        }
    }

    private func formatSeconds(_ milliseconds: Int64) -> String {
        String(format: "%.2f", ScoringRule.millisecondsToSeconds(milliseconds))
    }
}

// MARK: - Result Overlay

fileprivate struct ResultOverlayView: View {
    @Environment(\.dismiss) private var dismiss

    let seconds: String
    let level: Int
    let dual: Bool
    let onNewGame: () -> Void


    private let gold = Color(red: 0.976, green: 0.73, blue: 0.10)
    private let orange = Color(red: 0.95, green: 0.45, blue: 0.1)

    var body: some View {
        ZStack {
            // 明亮半透明蒙层：浅色而不是纯黑
            Color.white.opacity(0.18)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // ── Title ──────────────────────────────────────
                    Text("Round Complete")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(white: 0.12))

                    // ── Stars ──────────────────────────────────────
                    // 入场动画由 StarRowView 内部 onAppear stagger 驱动
                    StarRowView(
                        count: level,
                        dual: dual,
                        showColorful: level == 5,
                        size: 36,
                        animated: true
                    )

                    // ── Time ───────────────────────────────────────
                    VStack(spacing: 2) {
                        Text("Time")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(white: 0.35))
                            .tracking(1.5)
                            .textCase(.uppercase)
                        Text(seconds)
                            .font(.custom("Digital-7MonoItalic", size: 52))
                            .foregroundStyle(gold)
                            .shadow(color: gold.opacity(0.5), radius: 6)
                    }

                    // ── Buttons ────────────────────────────────────
                    HStack(spacing: 14) {
                        // Return Home
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "house")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Home")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color(white: 0.2))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.72), in: Capsule())
                            .overlay(Capsule().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // New Game
                        Button(action: onNewGame) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("New Game")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [gold, orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .shadow(color: gold.opacity(0.55), radius: 12, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 36)
                // 卡片：白色半透明底 + thinMaterial，明亮干净
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.78))
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white, lineWidth: 1.5)
                )
                .shadow(color: gold.opacity(0.18), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.08), radius: 40, x: 0, y: 16)
                .padding(.horizontal, 24)

                Spacer()
            }
        }

    }
}


fileprivate struct TouchDownButtonStyle: ButtonStyle {
    let action: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    // Dispatch to next run loop to decouple from the gesture state update
                    // This allows `withAnimation` inside the action to properly trigger `.transition`
                    DispatchQueue.main.async {
                        action()
                    }
                }
            }
    }
}

// MARK: - Racing Lights Countdown

/// F1 发车红灯倒计时覆盖层。
/// burstProgress 由 onChange 驱动，确保 withAnimation 上下文明确可靠。
fileprivate struct RacingLightsOverlayView: View {
    let countdown: Int

    @State private var burstProgress: CGFloat = 0

    private var litCount: Int {
        switch countdown {
        case 3: return 1
        case 2: return 2
        case 1: return 3
        default: return 0
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    RacingLight(isLit: i < litCount, burstProgress: burstProgress, index: i)
                }
            }
            if burstProgress > 0.4 {
                Text("GO!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .onChange(of: countdown) { _, newVal in
            if newVal == 0 {
                withAnimation(.easeOut(duration: 0.3)) {
                    burstProgress = 1
                }
            } else {
                burstProgress = 0
            }
        }
    }
}

/// 单盏灯：接收 burstProgress 并直接应用非均匀变换
fileprivate struct RacingLight: View {
    let isLit: Bool
    let burstProgress: CGFloat  // 0 = 正常, 1 = 完全 burst 消失
    let index: Int

    private let redGlow = Color(red: 1.0, green: 0.1, blue: 0.1)

    // 每盏灯的 burst 方向与形变比例各异，制造不规则炸裂感
    private var bScaleX: CGFloat { [3.4, 1.4, 3.0][min(index, 2)] }
    private var bScaleY: CGFloat { [1.3, 3.6, 1.5][min(index, 2)] }
    private var bDX:     CGFloat { [-28, 0, 26][min(index, 2)] }
    private var bDY:     CGFloat { [-8, -26, -10][min(index, 2)] }

    var body: some View {
        let notBursting = burstProgress == 0
        Circle()
            .fill(isLit && notBursting ? redGlow.opacity(0.35) : Color.clear)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle().stroke(
                    isLit && notBursting
                        ? redGlow.opacity(0.55)
                        : Color.white.opacity(max(0, 0.45 * (1 - burstProgress))),
                    lineWidth: 1.5
                )
            )
            .frame(width: 28, height: 28)
            .shadow(color: isLit && notBursting ? redGlow.opacity(0.25) : .clear, radius: 6)
            // 非均匀 burst 变换：由父级 withAnimation 驱动 burstProgress 插值
            .scaleEffect(x: 1 + (bScaleX - 1) * burstProgress,
                         y: 1 + (bScaleY - 1) * burstProgress)
            .offset(x: bDX * burstProgress, y: bDY * burstProgress)
            .opacity(Double(max(0, 1 - burstProgress)))
            .blur(radius: 4 * burstProgress)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isLit)
    }
}
