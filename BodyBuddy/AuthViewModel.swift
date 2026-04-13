//
//  AuthViewModel.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    @Published var isLoading = false

    func signUp() async -> Bool {
        isLoading = true
        errorMessage = ""

        do {
            try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func signIn() async -> Bool {
        isLoading = true
        errorMessage = ""

        do {
            _ = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
