//
//  MuscleMapView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI


struct MuscleMapView: View {
var body: some View {
VStack(spacing: 12) {
Text("Muscle Frequency (Placeholder)").font(.title3).bold()
Text("Tap a muscle group to filter sessions. SVG/SceneKit overlay coming next.")
.foregroundStyle(.secondary)
Image(systemName: "figure.stand")
.font(.system(size: 80))
.padding()
}
}
}
