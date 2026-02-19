import SwiftUI
import SchulteDomain
import SchulteFeatures

struct RecordsScreen: View {
    @StateObject private var viewModel: RecordsViewModel

    private let initialGridConfig: GridConfig

    init(dependency: AppDependency, initialGridConfig: GridConfig) {
        _viewModel = StateObject(
            wrappedValue: RecordsViewModel(
                scoreRecordRepository: dependency.scoreRecordRepository,
                gameConfigRepository: dependency.gameConfigRepository
            )
        )
        self.initialGridConfig = initialGridConfig
    }

    var body: some View {
        GeometryReader { geo in
        VStack(spacing: 12) {
            Picker("Category", selection: Binding(
                get: { viewModel.state.selectedType },
                set: { viewModel.selectType($0) }
            )) {
                Text("My Records").tag(RecordsType.mine)
                Text("Global").tag(RecordsType.global)
                Text("Today").tag(RecordsType.today)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("records.type")

            GridConfiguratorView(
                scale: Binding(
                    get: { viewModel.state.selectedGridConfig.scale },
                    set: { newScale in
                        var config = viewModel.state.selectedGridConfig
                        config.scale = newScale
                        viewModel.updateGridConfig(config)
                    }
                ),
                dual: Binding(
                    get: { viewModel.state.selectedGridConfig.dual },
                    set: { newDual in
                        var config = viewModel.state.selectedGridConfig
                        config.dual = newDual
                        viewModel.updateGridConfig(config)
                    }
                ),
                width: geo.size.width * 0.45
            )
            .accessibilityIdentifier("records.grid.scale")

            let contentFontSize = geo.size.width / 24
            if viewModel.state.records.isEmpty {
                Text(emptyText)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.state.records.enumerated()), id: \.offset) { offset, record in
                        HStack {
                            Text("#\(offset + 1)")
                                .font(.system(size: contentFontSize))
                                .foregroundStyle(Color(red: 0.271, green: 0.353, blue: 0.392))
                                .frame(width: 42, alignment: .center)

                            Text(String(format: "%.2f", record.timeScoreAsSeconds))
                                .font(.custom("digital-7", size: contentFontSize * 1.3))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.976, green: 0.659, blue: 0.145))
                                .frame(width: 78, alignment: .leading)

                            StarRowView(
                                count: record.level,
                                dual: record.gridConfig.dual,
                                showColorful: record.isFresh(),
                                size: contentFontSize * 1.5
                            )
                            .frame(width: 88, alignment: .leading)

                            Text(record.player.name)
                                .font(.system(size: contentFontSize))
                                .foregroundStyle(Color(red: 0.271, green: 0.353, blue: 0.392))
                                .lineLimit(1)
                        }
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("records.list")
            }
        }
        }
        .frame(maxWidth: 720)
        .padding(16)
        .navigationTitle("Records")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reload") {
                    Task { await viewModel.refresh() }
                }
                .accessibilityIdentifier("records.refresh")
            }
        }
        .task {
            await viewModel.load(initialGridConfig: initialGridConfig)
        }
    }

    private var emptyText: String {
        switch viewModel.state.selectedType {
        case .mine:
            "No records yet"
        case .global, .today:
            "Coming soon"
        }
    }
}
