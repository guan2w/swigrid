#if os(iOS)
import UIKit

public final class OrientationLockedAppDelegate: NSObject, UIApplicationDelegate {
    public override init() {}

    public func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}
#endif
