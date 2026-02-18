import SwiftUI
import SchulteAppUI

@main
struct SchulteGridApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(OrientationLockedAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            SchulteRootView()
        }
    }
}
