//
//  SignUpView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        Form {
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()

            SecureField("Password", text: $viewModel.password)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)
            }

            Button("Sign Up") {
                Task {
                    _ = await viewModel.signUp()
                }
            }
            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
        }
        .navigationTitle("Sign Up")
    }
}
