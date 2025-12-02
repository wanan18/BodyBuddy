//
//  NutritionHomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI

struct NutritionHomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Nutrition coming soon")
                    .font(.headline)
                Text("Log meals, see macros, and weekly totals here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Nutrition")
        }
    }
}
