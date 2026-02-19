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
            Color.orange.opacity(0.04)
            Text("Schulte Grid")
                .font(.custom("Sanvito", size: 60))
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 0.059, green: 0.573, blue: 0.710))
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            .frame(height: screenWidth / 11)
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
                .foregroundStyle(Color(red: 0.059, green: 0.573, blue: 0.710))
                .frame(width: 44, height: 44)
        }
        .accessibilityIdentifier("home.audio.mute")
    }

    private var aboutButton: some View {
        Button { onAbout() } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.059, green: 0.573, blue: 0.710))
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
        Button { onRecords(viewModel.state.gridConfig) } label: {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.059, green: 0.573, blue: 0.710))
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
                .font(.system(size: 36))
                .italic()
                .foregroundStyle(Color(white: 0.26))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.62, green: 0.86, blue: 0.95), Color(red: 0.36, green: 0.76, blue: 0.91)],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
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
