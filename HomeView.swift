//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/17/25.
//

//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/17/25.
//

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

    // Sheet for weight history
    @State private var showingWeightHistory = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // HEADER
                Text("Home")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                // WEIGHT TILE — tap anywhere to open history
                WeightSummaryTile()
                    .onTapGesture {
                        showingWeightHistory = true
                    }

                // STEPS TILE
                StepsTile()

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showingWeightHistory) {
            WeightHistoryView()
                .environment(\.managedObjectContext, ctx)
        }
    }
}

// MARK: - Weight History Screen

struct WeightHistoryView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    // newest first
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        animation: .default
    )
    private var bodyweights: FetchedResults<BodyweightEntry>

    var body: some View {
        NavigationStack {
            List {
                ForEach(bodyweights) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatWeight(entry.weight))
                                .font(.headline)
                                .foregroundColor(.white)

                            if let date = entry.date {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.black)
                }
                .onDelete(perform: deleteEntries)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Weight History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    private func formatWeight(_ weight: Double) -> String {
        let rounded = (weight * 10).rounded() / 10
        if rounded == floor(rounded) {
            return "\(Int(rounded)) lb"
        } else {
            return "\(rounded) lb"
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = bodyweights[index]
            ctx.delete(entry)
        }
        try? ctx.save()
    }
}

// MARK: - Log Bodyweight Sheet (unchanged from your version)

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

// MARK: - Shared dark field style

private extension View {
    func darkField() -> some View {
        self
            .padding(10)
            .background(Color(red: 28/255, green: 28/255, blue: 28/255))
            .cornerRadius(10)
    }
}
