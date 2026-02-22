import SwiftUI
import SchulteDomain
import SchulteFeatures

struct RecordsScreen: View {
    @StateObject private var viewModel: RecordsViewModel

    private let initialGridConfig: GridConfig

    @State private var gridDragOffset: CGFloat = 0

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

            // 整行作为滑动感应区，与 HomeScreen 的手势逻辑保持一致
            Color.clear
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .overlay(
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
                    .offset(x: gridDragOffset)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.65), value: gridDragOffset)
                )
                .contentShape(Rectangle())
                .simultaneousGesture(gridSwipeGesture(scales: GridConfig.allowedScales))
                .accessibilityIdentifier("records.grid.scale")

            let contentFontSize = geo.size.width / 24
            if viewModel.state.records.isEmpty {
                Text(emptyText)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.state.records.enumerated()), id: \.offset) { offset, record in
                        HStack(spacing: 8) {
                            Text("#\(offset + 1)")
                                .font(.system(size: contentFontSize))
                                .foregroundStyle(.secondary)
                                .frame(width: contentFontSize * 2.5, alignment: .center)

                            Text(String(format: "%.2f", record.timeScoreAsSeconds))
                                .font(.custom("Digital-7MonoItalic", size: contentFontSize * 1.3))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 0.976, green: 0.659, blue: 0.145))
                                .frame(width: contentFontSize * 4.5, alignment: .leading)

                            StarRowView(
                                count: record.level,
                                dual: record.gridConfig.dual,
                                showColorful: record.isFresh(),
                                size: contentFontSize * 1.5
                            )
                            .frame(width: contentFontSize * 11.5, alignment: .leading)

                            Text(record.player.name)
                                .font(.system(size: contentFontSize))
                                .foregroundStyle(Color(red: 0.271, green: 0.353, blue: 0.392))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
        .edgeOnlySwipeBack()
    }

    // MARK: - Grid swipe gesture (full-row, mirrors HomeScreen logic)

    private func gridSwipeGesture(scales: [Int]) -> some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { value in
                gridDragOffset = value.translation.width * 0.2
            }
            .onEnded { value in
                let threshold: CGFloat = 40
                let current = viewModel.state.selectedGridConfig.scale
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                    if value.translation.width < -threshold,
                       let idx = scales.firstIndex(of: current),
                       idx + 1 < scales.count {
                        var config = viewModel.state.selectedGridConfig
                        config.scale = scales[idx + 1]
                        viewModel.updateGridConfig(config)
                    } else if value.translation.width > threshold,
                              let idx = scales.firstIndex(of: current),
                              idx - 1 >= 0 {
                        var config = viewModel.state.selectedGridConfig
                        config.scale = scales[idx - 1]
                        viewModel.updateGridConfig(config)
                    }
                    gridDragOffset = 0
                }
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
