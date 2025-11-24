//
//  ProfileView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Goals") {
                    Text("Set targets & preferences here.")
                        .foregroundStyle(.secondary)
                }
                Section("Data & Sync") {
                    Text("CloudKit, export, privacy.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
