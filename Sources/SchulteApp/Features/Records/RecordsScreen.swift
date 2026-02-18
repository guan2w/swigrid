import SwiftUI
import SchulteDomain
import SchulteFeatures

struct RecordsScreen: View {
    @StateObject private var viewModel: RecordsViewModel
    private let gameConfigRepository: any GameConfigRepository

    init(dependency: AppDependency) {
        _viewModel = StateObject(
            wrappedValue: RecordsViewModel(scoreRecordRepository: dependency.scoreRecordRepository)
        )
        self.gameConfigRepository = dependency.gameConfigRepository
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Type", selection: Binding(
                get: { viewModel.state.selectedType },
                set: { viewModel.selectType($0) }
            )) {
                Text("Mine").tag(RecordsType.mine)
                Text("Global").tag(RecordsType.global)
                Text("Today").tag(RecordsType.today)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("records.type")

            HStack {
                Picker("Grid", selection: Binding(
                    get: { viewModel.state.selectedGridConfig.scale },
                    set: { newScale in
                        var config = viewModel.state.selectedGridConfig
                        config.scale = newScale
                        viewModel.updateGridConfig(config)
                    }
                )) {
                    ForEach(GridConfig.allowedScales, id: \.self) { scale in
                        Text("\(scale)x\(scale)").tag(scale)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("records.grid.scale")

                Toggle("Dual", isOn: Binding(
                    get: { viewModel.state.selectedGridConfig.dual },
                    set: { newDual in
                        var config = viewModel.state.selectedGridConfig
                        config.dual = newDual
                        viewModel.updateGridConfig(config)
                    }
                ))
                .toggleStyle(.switch)
                .accessibilityIdentifier("records.grid.dual")
            }

            if viewModel.state.records.isEmpty {
                Text(emptyText)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.state.records.enumerated()), id: \.offset) { offset, record in
                        HStack {
                            Text("#\(offset + 1)")
                                .frame(width: 42, alignment: .leading)

                            Text(String(format: "%.2f", record.timeScoreAsSeconds))
                                .font(.custom("digital-7", size: 26))
                                .frame(width: 78, alignment: .leading)

                            StarRowView(
                                count: record.level,
                                dual: record.gc.dual,
                                showColorful: record.isFresh(),
                                size: 14
                            )
                            .frame(width: 88, alignment: .leading)

                            Text(record.p1.name)
                                .lineLimit(1)
                        }
                    }
                }
                .listStyle(.plain)
                .accessibilityIdentifier("records.list")
            }
        }
        .frame(maxWidth: 720)
        .padding(16)
        .navigationTitle("Records")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
                .accessibilityIdentifier("records.refresh")
            }
        }
        .task {
            await loadInitial()
        }
    }

    private var emptyText: String {
        switch viewModel.state.selectedType {
        case .mine:
            "No records"
        case .global, .today:
            "No data"
        }
    }

    private func loadInitial() async {
        do {
            let config = try await gameConfigRepository.loadConfig()
            await viewModel.load(initialGridConfig: config.gridConfig)
        } catch {
            await viewModel.load(initialGridConfig: GridConfig())
        }
    }
}
