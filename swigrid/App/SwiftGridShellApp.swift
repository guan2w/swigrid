import SwiftUI
import SchulteAppUI

@main
struct SwiftGridShellApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(OrientationLockedAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            SchulteRootView()
        }
    }
}
