import SwiftUI
import SchulteDomain
import SchulteFeatures

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel

    private let onStart: () -> Void
    private let onRecords: (GridConfig) -> Void
    private let onAbout: () -> Void

    @State private var playerNameDraft = ""
    @State private var showsPlayerNameRequiredAlert = false
    @State private var starDragOffset: CGFloat = 0

    init(
        dependency: AppDependency,
        onStart: @escaping () -> Void,
        onRecords: @escaping (GridConfig) -> Void,
        onAbout: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                playerRepository: dependency.playerRepository,
                gameConfigRepository: dependency.gameConfigRepository,
                scoreRecordRepository: dependency.scoreRecordRepository
            )
        )
        self.onStart = onStart
        self.onRecords = onRecords
        self.onAbout = onAbout
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Let the animated background be crisp
                SplitGridBackgroundView()
                    .overlay(Color(uiColor: .systemBackground).opacity(0.4))
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    titleArea
                        .padding(.top, 40) // Pushes title down
                    middleArea(screenWidth: geo.size.width)
                    startButton
                        .padding(.horizontal, 36)
                        .padding(.bottom, 60) // Pushes start button up
                }
            }
        }
        .task {
            await viewModel.load()
            playerNameDraft = viewModel.state.playerName
        }
        .alert("Player Name Required", isPresented: $showsPlayerNameRequiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enter a player name before starting.")
        }
    }

    private var titleArea: some View {
        ZStack {
            Text("Schulte Grid")
                // Use a modern rounded system font instead of the custom one for a cleaner look
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.85))
                // Solid drop shadow to lift it off the patterned background
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                .shadow(color: Color.white.opacity(0.8), radius: 1, x: 0, y: -1)
        }
        .frame(height: 120)
    }

    private func middleArea(screenWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            HStack(spacing: 0) {
                muteButton
                Spacer()
                GridConfiguratorView(scale: scaleBinding, dual: dualBinding, width: screenWidth * 0.45)
                Spacer()
                aboutButton
            }
            .padding(.horizontal, 16)

            Spacer()

            StarRowView(
                count: viewModel.state.starCount,
                dual: viewModel.state.gridConfig.dual,
                showColorful: viewModel.state.showsFreshFiveStarBadge,
                size: screenWidth / 11
            )
            // 固定高度，并撑满宽度，确保星星为 0 时触控区域依然存在
            .frame(height: screenWidth / 11)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .offset(x: starDragOffset)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.65), value: starDragOffset)
            // 点击手势保留在星星行自身，以便与 VStack 层形成互补
            .onTapGesture { performToggleDual() }

            Spacer()

            HStack(spacing: 12) {
                playerTextField
                recordsButton
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        // ─── 以下三行是本次改动的全部内容，布局完全不变 ───
        // 让 VStack 整体（含 Spacer 空白区域）成为可命中区域
        .contentShape(Rectangle())
        // 点击 Spacer 空白区时触发（点击 Button/TextField 由子视图消费，不会冒泡到此）
        .onTapGesture { performToggleDual() }
        // 滑动在中间区域任意位置触发，simultaneousGesture 不阻断子视图手势
        .simultaneousGesture(swipeGesture)
    }

    private func performToggleDual() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dualBinding.wrappedValue.toggle()
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                // 橡皮筋反馈，系数 0.2 给轻微位移感
                starDragOffset = value.translation.width * 0.2
            }
            .onEnded { value in
                let threshold: CGFloat = 40
                let scales = GridConfig.allowedScales
                let current = scaleBinding.wrappedValue
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                    if value.translation.width < -threshold,
                       let idx = scales.firstIndex(of: current),
                       idx + 1 < scales.count {
                        scaleBinding.wrappedValue = scales[idx + 1]
                    } else if value.translation.width > threshold,
                              let idx = scales.firstIndex(of: current),
                              idx - 1 >= 0 {
                        scaleBinding.wrappedValue = scales[idx - 1]
                    }
                    starDragOffset = 0
                }
            }
    }

    private var muteButton: some View {
        Button {
            Task { await viewModel.setMute(!viewModel.state.mute) }
        } label: {
            Image(systemName: viewModel.state.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .accessibilityIdentifier("home.audio.mute")
    }

    private var aboutButton: some View {
        Button { onAbout() } label: {
            Image(systemName: "info")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .accessibilityIdentifier("home.about")
    }

    private var playerTextField: some View {
        TextField("Enter your name", text: $playerNameDraft)
            .onChange(of: playerNameDraft) { _, newValue in
                if newValue.count > Player.maxNameLength {
                    playerNameDraft = String(newValue.prefix(Player.maxNameLength))
                }
            }
            .font(.system(.body, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            // Visible glass border edge
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .accessibilityIdentifier("home.player.textfield")
    }

    private var recordsButton: some View {
        Button { onRecords(viewModel.state.gridConfig) } label: {
            Image(systemName: "list.bullet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.primary.opacity(0.7))
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .accessibilityIdentifier("home.records")
    }

    private var startButton: some View {
        Button {
            if normalizedPlayerName.isEmpty {
                showsPlayerNameRequiredAlert = true
            } else {
                Task {
                    if normalizedPlayerName != viewModel.state.playerName {
                        await viewModel.savePlayerName(normalizedPlayerName)
                    }
                    onStart()
                }
            }
        } label: {
            Text("Start")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        // Button press animation support
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("home.start")
    }

    private var scaleBinding: Binding<Int> {
        Binding(
            get: { viewModel.state.gridConfig.scale },
            set: { newScale in
                var config = viewModel.state.gridConfig
                config.scale = newScale
                Task { await viewModel.setGridConfig(config) }
            }
        )
    }

    private var dualBinding: Binding<Bool> {
        Binding(
            get: { viewModel.state.gridConfig.dual },
            set: { value in
                var config = viewModel.state.gridConfig
                config.dual = value
                Task { await viewModel.setGridConfig(config) }
            }
        )
    }

    private var normalizedPlayerName: String {
        playerNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
