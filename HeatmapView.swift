//
//  HeatmapView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI

struct HeatmapView: View {
    @EnvironmentObject var store: WorkoutStore   // will use this later for muscle volume

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Muscle Heatmap (placeholder)")
                    .font(.headline)
                Text("We’ll shade muscles by 28-day training volume.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Muscles")
        }
    }
}
