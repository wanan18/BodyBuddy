//
//  InMemorySessionDetailView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI

struct InMemorySessionDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    let session: WorkoutModel

    // Quick-add controls
    @State private var selectedExercise: ExerciseModel?
    @State private var weightText: String = ""   // ← weight first
    @State private var repsText: String = ""
    @State private var notesText: String = ""

    // Editable session date
    @State private var sessionDate: Date = Date()

    var body: some View {
        List {
            // Session header: date + volume + notes
            Section {
                HStack {
                    Label("Session", systemImage: "calendar")
                    Spacer()
                    Text("Volume \(Int(totalVolume))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Date picker to backfill/adjust session date
                DatePicker("Date",
                           selection: $sessionDate,
                           displayedComponents: .date)
                    .onChange(of: sessionDate) { _, new in
                        store.updateSessionDate(sessionID: current.id, newDate: new)
                    }

                TextField("Session notes (optional)", text: $notesText, axis: .vertical)
                    .onSubmit { store.updateNotes(sessionID: current.id, notes: notesText) }
                    .onAppear {
                        notesText = current.notes ?? ""
                        sessionDate = current.date
                    }
                    .submitLabel(.done)
            }

            // Quick Add Set
            Section("Add Set") {
                Picker("Exercise", selection: $selectedExercise) {
                    Text("Select Exercise").tag(Optional<ExerciseModel>.none)
                    ForEach(store.exercises) { ex in
                        Text(ex.name).tag(Optional(ex))
                    }
                }

                // Input order: Weight → Reps
                HStack {
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                    TextField("Reps", text: $repsText)
                        .keyboardType(.numberPad)
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    addSet()
                } label: {
                    Label("Add Set", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdd)
            }

            // Exercises & sets in this session
            ForEach(groupedByExercise, id: \.0.id) { (exercise, sets) in
                Section(exercise.name) {
                    ForEach(sets) { s in
                        HStack {
                            Text("Set \(s.setIndex)")
                            Spacer()
                            Text("\(String(format: "%.1f", s.weight)) x \(s.reps)")
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Session")
    }

    // MARK: - Derived data

    private var current: WorkoutModel {
        store.workouts.first(where: { $0.id == session.id }) ?? session
    }

    private var totalVolume: Double {
        current.sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }

    private var groupedByExercise: [(ExerciseModel, [SetEntryModel])] {
        let dict = Dictionary(grouping: current.sets, by: { $0.exercise })
        return dict
            .map { ($0.key, $0.value.sorted { $0.setIndex < $1.setIndex }) }
            .sorted { $0.0.name < $1.0.name }
    }

    private var canAdd: Bool {
        if selectedExercise == nil { return false }
        guard let w = Double(weightText), w >= 0 else { return false }
        guard let r = Int(repsText), r > 0 else { return false }
        return true
    }

    // MARK: - Actions

    private func addSet() {
        guard let ex = selectedExercise,
              let weight = Double(weightText),
              let reps = Int(repsText)
        else { return }

        store.appendSet(sessionID: current.id, exercise: ex, reps: reps, weight: weight)
        // reset inputs (keep exercise selected)
        weightText = ""
        repsText = ""
    }
}
