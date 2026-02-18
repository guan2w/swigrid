//
//  swigridApp.swift
//  swigrid
//
//  Created by Eric on 2026-02-18.
//

import SwiftUI
import SchulteAppUI

@main
struct swigridApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(OrientationLockedAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            SchulteRootView()
        }
    }
}
