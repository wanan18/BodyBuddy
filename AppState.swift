//
//  AppState.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI
import Combine
import Supabase

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var isLoading = true

    func loadSession() async {
        isLoading = true

        do {
            let currentSession = try await SupabaseManager.shared.client.auth.session
            session = currentSession
        } catch {
            session = nil
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await SupabaseManager.shared.client.auth.signOut()
            session = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
