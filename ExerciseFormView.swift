//
//  ExerciseFormView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/17/25.
//

import SwiftUI
import CoreData

struct ExerciseFormView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise?

    @State private var name: String
    @State private var muscleGroup: String
    @State private var isBodyweight: Bool
    @State private var notes: String

    init(exercise: Exercise? = nil) {
        self.exercise = exercise
        _name = State(initialValue: exercise?.name ?? "")
        _muscleGroup = State(initialValue: exercise?.muscleGroup ?? "")
        _isBodyweight = State(initialValue: exercise?.isBodyweight ?? false)
        _notes = State(initialValue: exercise?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                    TextField("Muscle group (e.g. Chest, Back)", text: $muscleGroup)
                    Toggle("Bodyweight", isOn: $isBodyweight)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let ex = exercise ?? Exercise(context: ctx)
        if exercise == nil {
            ex.id = UUID()
        }

        ex.name = name.trimmingCharacters(in: .whitespaces)
        ex.muscleGroup = muscleGroup.trimmingCharacters(in: .whitespaces)
        ex.isBodyweight = isBodyweight
        ex.notes = notes

        try? ctx.save()
        dismiss()
    }
}
