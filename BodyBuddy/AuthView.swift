//
//  AuthView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

struct AuthView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink("Sign In") {
                    SignInView()
                }

                NavigationLink("Sign Up") {
                    SignUpView()
                }
            }
            .navigationTitle("BodyBuddy")
        }
    }
}
