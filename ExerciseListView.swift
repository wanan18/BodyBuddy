//
//  ExerciseListView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/17/25.
//

import SwiftUI
import CoreData

struct ExerciseListView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var exercises: FetchedResults<Exercise>

    @State private var showingForm = false
    @State private var exerciseToEdit: Exercise?

    var body: some View {
        List {
            ForEach(exercises) { ex in
                Button {
                    exerciseToEdit = ex
                    showingForm = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ex.name ?? "Unnamed exercise")
                            .font(.headline)

                        HStack(spacing: 8) {
                            Text(ex.muscleGroup ?? "Unknown")
                            if ex.isBodyweight {
                                Text("Bodyweight")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("Exercises")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    exerciseToEdit = nil
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            ExerciseFormView(exercise: exerciseToEdit)
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets
            .map { exercises[$0] }
            .forEach(ctx.delete)
        try? ctx.save()
    }
}
