import SwiftUI

extension View {
    /// Disables the iOS 18+ full-screen swipe-to-pop gesture while keeping
    /// the standard left-edge `interactivePopGestureRecognizer`.
    func edgeOnlySwipeBack() -> some View {
        onAppear {
            #if canImport(UIKit)
            guard #available(iOS 18, *) else { return }
            DispatchQueue.main.async {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .compactMap { $0.rootViewController }
                    .compactMap { findNavController(in: $0) }
                    .first?
                    .interactiveContentPopGestureRecognizer?.isEnabled = false
            }
            #endif
        }
    }
}

#if canImport(UIKit)
private func findNavController(in vc: UIViewController) -> UINavigationController? {
    if let nav = vc as? UINavigationController { return nav }
    for child in vc.children {
        if let found = findNavController(in: child) { return found }
    }
    if let presented = vc.presentedViewController {
        return findNavController(in: presented)
    }
    return nil
}
#endif
