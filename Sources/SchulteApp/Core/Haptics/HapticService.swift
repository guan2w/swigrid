import Foundation

import UIKit

@MainActor
final class HapticService {
    func correctTap() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func incorrectTap() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func nextHintTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
