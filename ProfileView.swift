//
//  ProfileView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var ctx

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

                // TEMP: Legacy import section
                Section("Developer Tools") {
                    Button {
                        LegacyLiftsImporter.importIfNeeded(context: ctx)
                    } label: {
                        Text("Import legacy lifts from CSV")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
