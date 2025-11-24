//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/17/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var ctx

    // Fetch bodyweight entries, newest first
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        animation: .default
    )
    private var bodyweights: FetchedResults<BodyweightEntry>

    @State private var showingLogWeightSheet = false

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray   = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // HEADER
                Text("Home")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                // BODYWEIGHT CARD
                bodyweightCard

                // You can add more cards under here later (recent workouts, steps, etc.)
                // For now, we keep it minimal.

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingLogWeightSheet) {
            LogBodyweightSheet()
                .environment(\.managedObjectContext, ctx)
        }
    }

    // MARK: - Bodyweight Card

    // MARK: - Bodyweight Card

    private var bodyweightCard: some View {
        let latest = bodyweights.first

        let latestWeightText: String
        let latestDateText: String

        if let entry = latest {
            // weight is non-optional Double
            latestWeightText = formatWeight(entry.weight)

            if let date = entry.date {
                latestDateText = formatDate(date)
            } else {
                latestDateText = "Last logged: unknown date"
            }
        } else {
            latestWeightText = "--"
            latestDateText = "No entries yet"
        }

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bodyweight")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(latestWeightText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Self.accentGreen)

                    Text(latestDateText)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Button {
                    showingLogWeightSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Self.accentGreen)
                }
            }

            if bodyweights.count > 1 {
                Text("Recent trend")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
    }

    // MARK: - Formatting

    private func formatWeight(_ weight: Double) -> String {
        // Show no decimals if whole, one decimal otherwise
        let rounded = (weight * 10).rounded() / 10
        if rounded == floor(rounded) {
            return "\(Int(rounded)) lb"
        } else {
            return "\(rounded) lb"
        }
    }

    private func formatDate(_ date: Date) -> String {
        // "Today", "Yesterday", or formatted date
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Last logged: Today"
        } else if calendar.isDateInYesterday(date) {
            return "Last logged: Yesterday"
        } else {
            return "Last logged: " + date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Log Bodyweight Sheet

struct LogBodyweightSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var date: Date = Date()

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log Bodyweight")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField(
                        "",
                        text: $weightText,
                        prompt: Text("Weight (lb)").foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .darkField()

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .foregroundColor(.white)
                    .datePickerStyle(.compact)
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
            .navigationTitle("Log Weight")
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
        guard let value = Double(weightText), value > 0 else { return false }
        return true
    }

    private func save() {
        guard let value = Double(weightText), value > 0 else { return }

        let entry = BodyweightEntry(context: ctx)
        entry.id = UUID()
        entry.date = date
        entry.weight = value

        try? ctx.save()
        dismiss()
    }
}

// MARK: - Shared dark field style (reuse same style as other screens)

private extension View {
    func darkField() -> some View {
        self
            .padding(10)
            .background(Color(red: 28/255, green: 28/255, blue: 28/255))
            .cornerRadius(10)
    }
}
