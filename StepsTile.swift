//
//  StepsTile.swift
//  BodyBuddy
//
//  Created by William Anan on 11/25/25.
//

import SwiftUI

struct StepsTile: View {

    // TODO: Replace this with real HealthKit / Core Data later
    @State private var stepsToday: Int = 5421
    @State private var showingAddSteps = false

    private let dailyGoal: Int = 10_000

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray   = Color(red: 20/255, green: 20/255, blue: 20/255)

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(stepsToday) / Double(dailyGoal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // HEADER ROW: "Steps" + goal + plus button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Goal: \(dailyGoal.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button {
                    showingAddSteps = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(Self.accentGreen)
                }
            }

            // MAIN ROW: text + progress on left, walking icon on right
            HStack(alignment: .center, spacing: 12) {

                VStack(alignment: .leading, spacing: 4) {

                    // Big steps number
                    Text("\(stepsToday.formatted())")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 30/255, green: 30/255, blue: 30/255))

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Self.accentGreen)
                                .frame(width: geo.size.width * CGFloat(progress))
                        }
                    }
                    .frame(height: 8)
                    .padding(.top, 4)

                    // Percent of goal
                    Text("\(Int(progress * 100))% of daily goal")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }

                Spacer()

                // Green walking icon on the right
                Image(systemName: "figure.walk")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Self.accentGreen)
            }
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
        .sheet(isPresented: $showingAddSteps) {
            LogStepsSheet(stepsToday: $stepsToday, dailyGoal: dailyGoal)
        }
    }
}

// MARK: - Log Steps Sheet

struct LogStepsSheet: View {
    @Binding var stepsToday: Int
    let dailyGoal: Int

    @Environment(\.dismiss) private var dismiss

    @State private var stepsText: String = ""

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Steps")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField(
                        "",
                        text: $stepsText,
                        prompt: Text("Steps for today").foregroundColor(.gray)
                    )
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(red: 28/255, green: 28/255, blue: 28/255))
                    .cornerRadius(10)

                    Text("Daily goal: \(dailyGoal.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: save) {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Self.accentGreen)
                        .cornerRadius(16)
                }
                .padding(.bottom, 16)
                .disabled(!canSave)
            }
            .padding(16)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Log Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var canSave: Bool {
        guard let value = Int(stepsText), value > 0 else { return false }
        return true
    }

    private func save() {
        guard let value = Int(stepsText), value > 0 else { return }
        stepsToday = value
        dismiss()
    }
}
