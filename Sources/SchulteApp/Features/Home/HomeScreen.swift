import SwiftUI
import SchulteDomain
import SchulteFeatures

struct HomeScreen: View {
    @StateObject private var viewModel: HomeViewModel

    private let onStart: () -> Void
    private let onRecords: () -> Void
    private let onAbout: () -> Void

    @State private var playerNameInput = ""
    @State private var showRequirePlayerAlert = false

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
        ZStack {
            SplitGridBackgroundView()
                .overlay(Color.white.opacity(0.25))

            ScrollView {
                VStack(spacing: 18) {
                    Text("Schulte Grid")
                        .font(.custom("Sanvito", size: 52))
                        .foregroundStyle(Color(red: 0.05, green: 0.34, blue: 0.49))
                        .padding(.top, 12)

                    VStack(spacing: 14) {
                        playerSection
                        configSection
                        starsSection
                        actionsSection
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.65), lineWidth: 1)
                    )
                }
                .frame(maxWidth: 620)
                .padding(16)
            }
        }
        .task {
            await viewModel.load()
            playerNameInput = viewModel.state.playerName
        }
        .alert("Player name required", isPresented: $showRequirePlayerAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please input a player name before starting the game.")
        }
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player")
                .font(.headline)

            TextField("Input your name", text: $playerNameInput)
                .onChange(of: playerNameInput) { _, newValue in
                    if newValue.count > 16 {
                        playerNameInput = String(newValue.prefix(16))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("home.player.textfield")

            Button("Save Player") {
                Task {
                    await viewModel.savePlayerName(trimmedPlayerName)
                }
            }
            .buttonStyle(.bordered)
            .disabled(trimmedPlayerName.isEmpty)
            .accessibilityIdentifier("home.player.save")
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Game Config")
                .font(.headline)

            Picker("Grid", selection: Binding(
                get: { viewModel.state.gridConfig.scale },
                set: { newScale in
                    var config = viewModel.state.gridConfig
                    config.scale = newScale
                    Task { await viewModel.setGridConfig(config) }
                }
            )) {
                ForEach(GridConfig.allowedScales, id: \.self) { scale in
                    Text("\(scale)x\(scale)").tag(scale)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("home.grid.scale")

            HStack(spacing: 14) {
                Toggle("Dual Numbers", isOn: Binding(
                    get: { viewModel.state.gridConfig.dual },
                    set: { value in
                        var config = viewModel.state.gridConfig
                        config.dual = value
                        Task { await viewModel.setGridConfig(config) }
                    }
                ))
                .accessibilityIdentifier("home.grid.dual")

                Toggle("Mute", isOn: Binding(
                    get: { viewModel.state.mute },
                    set: { value in
                        Task { await viewModel.setMute(value) }
                    }
                ))
                .accessibilityIdentifier("home.audio.mute")
            }
            .toggleStyle(.switch)
            .font(.subheadline)
        }
    }

    private var starsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Feedback")
                .font(.headline)

            StarRowView(
                count: viewModel.state.starCount,
                dual: viewModel.state.gridConfig.dual,
                showColorful: viewModel.state.showColorfulStar,
                size: 22
            )

            if viewModel.state.showColorfulStar {
                Text("Fresh 5-star record within 24 hours")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                if trimmedPlayerName.isEmpty {
                    showRequirePlayerAlert = true
                } else {
                    Task {
                        if trimmedPlayerName != viewModel.state.playerName {
                            await viewModel.savePlayerName(trimmedPlayerName)
                        }
                        onStart()
                    }
                }
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.1, green: 0.55, blue: 0.78))
            .accessibilityIdentifier("home.start")

            HStack(spacing: 12) {
                Button("Records") { onRecords() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("home.records")

                Button("About") { onAbout() }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("home.about")
            }
        }
    }

    private var trimmedPlayerName: String {
        playerNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
