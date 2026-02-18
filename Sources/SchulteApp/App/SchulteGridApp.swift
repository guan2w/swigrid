import SwiftUI

public struct SchulteRootView: View {
    @StateObject private var dependency = AppDependency()
    @State private var path: [AppRoute] = []

    public init() {
        FontCatalog.registerAll()
    }

    public var body: some View {
        NavigationStack(path: $path) {
            HomeScreen(
                dependency: dependency,
                onStart: { path.append(.game) },
                onRecords: { path.append(.records) },
                onAbout: { path.append(.about) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .game:
                    GameScreen(dependency: dependency)
                case .records:
                    RecordsScreen(dependency: dependency)
                case .about:
                    AboutScreen()
                }
            }
        }
    }
}
