import SchulteDomain

enum AppRoute: Hashable {
    case game
    case records(GridConfig)
    case about
}
