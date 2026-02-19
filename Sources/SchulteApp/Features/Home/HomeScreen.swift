import SwiftUI
import SchulteDomain
import SchulteFeatures

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel

    private let onStart: () -> Void
    private let onRecords: () -> Void
    private let onAbout: () -> Void

    @State private var playerNameDraft = ""
    @State private var showsPlayerNameRequiredAlert = false

    init(
        dependency: AppDependency,
        onStart: @escaping () -> Void,
        onRecords: @escaping () -> Void,
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
                SplitGridBackgroundView()
                    .overlay(Color.white.opacity(0.25))

                VStack(spacing: 0) {
                    titleArea
                    middleArea(screenWidth: geo.size.width)
                    startButton
                        .padding(.horizontal, 36)
                        .padding(.bottom, 20)
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
            Color(red: 1.0, green: 0.93, blue: 0.82).opacity(0.6)
            Text("Schulte Grid")
                .font(.custom("Sanvito", size: 60))
                .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
        }
        .frame(height: 110)
    }

    private func middleArea(screenWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                muteButton
                GridConfiguratorView(scale: scaleBinding, dual: dualBinding)
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
            Spacer()
            HStack(spacing: 12) {
                playerTextField
                recordsButton
            }
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    private var muteButton: some View {
        Button {
            Task { await viewModel.setMute(!viewModel.state.mute) }
        } label: {
            Image(systemName: viewModel.state.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
                .frame(width: 44, height: 44)
        }
        .accessibilityIdentifier("home.audio.mute")
    }

    private var aboutButton: some View {
        Button { onAbout() } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
                .frame(width: 44, height: 44)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("home.player.textfield")
    }

    private var recordsButton: some View {
        Button { onRecords() } label: {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
                .frame(width: 44, height: 44)
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
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.55, blue: 0.78), Color(red: 0.05, green: 0.40, blue: 0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 30)
                )
        }
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
