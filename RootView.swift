//
//  RootView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView()
            } else if appState.session == nil {
                AuthView()
            } else {
                HomeView()
            }
        }
    }
}
