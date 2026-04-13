//
//  BodyBuddyApp.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

@main
struct BodyBuddyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    await appState.loadSession()
                }
        }
    }
}
