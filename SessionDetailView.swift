//
//  SessionDetailView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI
import CoreData

// Used for multiple set rows in the add sheets
private struct SetInput: Identifiable, Hashable {
    let id = UUID()
    var weight: String = ""
    var reps: String = ""
    var rpe: String = ""
}

struct SessionDetailView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var session: WorkoutSession

    @State private var showingAddExercise = false

    // Editing sets (sheet driven by which set is selected)
    @State private var editingSet: WorkoutSet?
    @State private var editingWeightText: String = ""
    @State private var editingRepsText: String = ""
    @State private var editingRpeText: String = ""

    // Add-set sheet: driven by a selected Exercise
    @State private var addSetTargetExercise: Exercise?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default
    )
    private var allExercises: FetchedResults<Exercise>

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray   = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if groupedByExercise.isEmpty {
                    Text("No exercises logged yet. Tap the + or Add Exercise to start logging this session.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(groupedByExercise, id: \.exerciseID) { group in
                            exerciseSection(for: group)
                        }
                    }
                }

                addExerciseButton

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
        // Edit-set sheet, driven by editingSet
        .sheet(item: $editingSet) { set in
            EditSetSheet(
                set: set,
                weightText: $editingWeightText,
                repsText: $editingRepsText,
                rpeText: $editingRpeText
            )
            .environment(\.managedObjectContext, ctx)
        }
        // Add-set sheet, driven by which exercise is selected
        .sheet(item: $addSetTargetExercise) { exercise in
            AddSetsForExerciseSheet(session: session, exercise: exercise)
                .environment(\.managedObjectContext, ctx)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.white)
                        .font(.headline)
                }

                Spacer()

                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Self.accentGreen)
                }
            }

            Text("Session")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            if let date = session.date {
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }

    // MARK: - Grouping

    private struct ExerciseGroup {
        let exercise: Exercise?
        let exerciseID: String
        let sets: [WorkoutSet]
    }

    private var groupedByExercise: [ExerciseGroup] {
        let rawSets = (session.sets as? Set<WorkoutSet>) ?? []

        let grouped = Dictionary(grouping: rawSets) { (set: WorkoutSet) -> Exercise? in
            set.exercise
        }

        return grouped.map { key, sets in
            let idString: String
            if let ex = key, let id = ex.id?.uuidString {
                idString = id
            } else {
                idString = "unknown-\(UUID().uuidString)"
            }

            // preserve insertion order via sortIndex
            let sortedSets = sets.sorted { $0.sortIndex < $1.sortIndex }

            return ExerciseGroup(
                exercise: key,
                exerciseID: idString,
                sets: sortedSets
            )
        }
        .sorted { lhs, rhs in
            let lName = lhs.exercise?.name ?? "Unknown"
            let rName = rhs.exercise?.name ?? "Unknown"
            return lName < rName
        }
    }

    // MARK: - Exercise cards

    private func exerciseSection(for group: ExerciseGroup) -> some View {
        let name = group.exercise?.name ?? "Unknown exercise"
        let muscle = group.exercise?.muscleGroup
        let note   = group.exercise?.notes

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let muscle, !muscle.isEmpty {
                        Text(muscle)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    if let note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()
            }

            VStack(spacing: 6) {
                ForEach(Array(group.sets.enumerated()), id: \.element.objectID) { index, set in
                    SetRowView(
                        set: set,
                        index: index + 1,
                        onEdit: { startEditing(set) },
                        onDelete: { deleteSet(set) }
                    )
                }

                if let ex = group.exercise {
                    HStack {
                        Button {
                            addSetTargetExercise = ex
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("Add set")
                            }
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.top, 4)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
        .contextMenu {
            Button(role: .destructive) {
                deleteExerciseFromSession(group)
            } label: {
                Label("Remove Exercise from Session", systemImage: "trash")
            }
        }
    }

    private func startEditing(_ set: WorkoutSet) {
        editingWeightText = set.weight == 0 ? "" : String(format: "%.0f", set.weight)
        editingRepsText = set.reps == 0 ? "" : formatReps(set.reps)
        editingRpeText = set.rpe == 0 ? "" : String(format: "%.1f", set.rpe)
        editingSet = set   // setting this triggers .sheet(item:)
    }

    private func deleteExerciseFromSession(_ group: ExerciseGroup) {
        for set in group.sets {
            ctx.delete(set)
        }
        try? ctx.save()
    }

    private func deleteSet(_ set: WorkoutSet) {
        ctx.delete(set)
        try? ctx.save()
    }

    // MARK: - Add Exercise button

    private var addExerciseButton: some View {
        Button {
            showingAddExercise = true
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text("Add Exercise")
            }
            .font(.headline)
            .foregroundStyle(Self.accentGreen)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Self.cardGray)
            .cornerRadius(20)
        }
        .padding(.top, 24)
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToSessionSheet(
                session: session,
                allExercises: Array(allExercises),
                defaultDate: session.date ?? Date()
            )
            .environment(\.managedObjectContext, ctx)
        }
    }
}

// MARK: - Set Row View (observes WorkoutSet directly)

private struct SetRowView: View {
    @ObservedObject var set: WorkoutSet
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let weightText = String(format: "%.0f", set.weight)
        let repsText = formatReps(set.reps)
        let isEmpty = (set.weight == 0 && set.reps == 0)

        return HStack {
            Text("Set \(index)")
                .font(.caption)
                .foregroundColor(.gray)

            Text("\(weightText) x \(repsText)")
                .foregroundColor(isEmpty ? .gray : .white)

            if set.rpe > 0 {
                Text("RPE \(String(format: "%.1f", set.rpe))")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .font(.subheadline)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Set", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Exercise sheet (multi-set + notes)

struct AddExerciseToSessionSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let allExercises: [Exercise]
    let defaultDate: Date

    @State private var exerciseName: String = ""
    @State private var setInputs: [SetInput] = [SetInput()]
    @State private var notesText: String = ""

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField(
                        "",
                        text: $exerciseName,
                        prompt: Text("Exercise name").foregroundColor(.gray)
                    )
                    .foregroundColor(.white)
                    .darkField()
                }

                // Sets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set details")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach($setInputs) { $set in
                        VStack(spacing: 6) {
                            HStack {
                                TextField(
                                    "",
                                    text: $set.weight,
                                    prompt: Text("Weight").foregroundColor(.gray)
                                )
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .darkField()

                                TextField(
                                    "",
                                    text: $set.reps,
                                    prompt: Text("Reps").foregroundColor(.gray)
                                )
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .darkField()
                            }

                            TextField(
                                "",
                                text: $set.rpe,
                                prompt: Text("RPE (optional)").foregroundColor(.gray)
                            )
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .darkField()
                        }
                    }

                    Button {
                        setInputs.append(SetInput())
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add another set")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                    }
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.white)

                    TextField(
                        "",
                        text: $notesText,
                        prompt: Text("Form cues, how it felt, etc.").foregroundColor(.gray)
                    )
                    .foregroundColor(.white)
                    .darkField()
                }

                Spacer()

                Button(action: save) {
                    Text("Add to Session")
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
            .navigationTitle("Add Exercise")
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
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        return setInputs.contains { input in
            !input.weight.isEmpty && !input.reps.isEmpty
        }
    }

    private func save() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Reuse existing exercise by name (case-insensitive), or create a new one
        let ex: Exercise
        if let existing = allExercises.first(where: {
            ($0.name ?? "").lowercased() == trimmedName.lowercased()
        }) {
            ex = existing
        } else {
            let newEx = Exercise(context: ctx)
            newEx.id = UUID()
            newEx.name = trimmedName
            ex = newEx
        }

        // Save notes
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            ex.notes = trimmedNotes
        }

        // Determine next sort index for this exercise in this session
        let existingSetsForExercise = (session.sets as? Set<WorkoutSet> ?? [])
            .filter { $0.exercise == ex }
        let maxIndex = existingSetsForExercise.map { $0.sortIndex }.max() ?? -1
        var nextIndex = Int(maxIndex) + 1

        for input in setInputs {
            guard !input.weight.isEmpty, !input.reps.isEmpty else { continue }

            let set = WorkoutSet(context: ctx)
            set.id = UUID()
            set.session = session
            set.exercise = ex
            set.weight = Double(input.weight) ?? 0
            set.reps = Double(input.reps) ?? 0
            set.rpe = Double(input.rpe) ?? 0
            set.sortIndex = Int16(nextIndex)
            nextIndex += 1
        }

        try? ctx.save()
        dismiss()
    }
}

// MARK: - Add Sets for existing exercise

struct AddSetsForExerciseSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let exercise: Exercise

    @State private var setInputs: [SetInput] = [SetInput()]

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add sets")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(exercise.name ?? "Exercise")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Set details")
                        .font(.headline)
                        .foregroundStyle(.white)

                    ForEach($setInputs) { $set in
                        VStack(spacing: 6) {
                            HStack {
                                TextField(
                                    "",
                                    text: $set.weight,
                                    prompt: Text("Weight").foregroundColor(.gray)
                                )
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .darkField()

                                TextField(
                                    "",
                                    text: $set.reps,
                                    prompt: Text("Reps").foregroundColor(.gray)
                                )
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .darkField()
                            }

                            TextField(
                                "",
                                text: $set.rpe,
                                prompt: Text("RPE (optional)").foregroundColor(.gray)
                            )
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .darkField()
                        }
                    }

                    Button {
                        setInputs.append(SetInput())
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Add another set")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                    }
                }

                Spacer()

                Button(action: save) {
                    Text("Add sets")
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
            .navigationTitle("Add Sets")
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
        setInputs.contains { input in
            !input.weight.isEmpty && !input.reps.isEmpty
        }
    }

    private func save() {
        let existingSetsForExercise = (session.sets as? Set<WorkoutSet> ?? [])
            .filter { $0.exercise == exercise }
        let maxIndex = existingSetsForExercise.map { $0.sortIndex }.max() ?? -1
        var nextIndex = Int(maxIndex) + 1

        for input in setInputs {
            guard !input.weight.isEmpty, !input.reps.isEmpty else { continue }

            let set = WorkoutSet(context: ctx)
            set.id = UUID()
            set.session = session
            set.exercise = exercise
            set.weight = Double(input.weight) ?? 0
            set.reps = Double(input.reps) ?? 0
            set.rpe = Double(input.rpe) ?? 0
            set.sortIndex = Int16(nextIndex)
            nextIndex += 1
        }

        try? ctx.save()
        dismiss()
    }
}

// MARK: - Edit Set sheet

struct EditSetSheet: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    var set: WorkoutSet

    @Binding var weightText: String
    @Binding var repsText: String
    @Binding var rpeText: String

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Set")
                        .font(.headline)
                        .foregroundStyle(.white)

                    HStack {
                        TextField(
                            "",
                            text: $weightText,
                            prompt: Text("Weight").foregroundColor(.gray)
                        )
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .darkField()

                        TextField(
                            "",
                            text: $repsText,
                            prompt: Text("Reps").foregroundColor(.gray)
                        )
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .darkField()
                    }

                    TextField(
                        "",
                        text: $rpeText,
                        prompt: Text("RPE (optional)").foregroundColor(.gray)
                    )
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .darkField()
                }

                Spacer()

                Button(action: save) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Self.accentGreen)
                        .cornerRadius(16)
                }
                .padding(.bottom, 16)
            }
            .padding(16)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Edit Set")
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

    private func save() {
        set.weight = Double(weightText) ?? 0
        set.reps = Double(repsText) ?? 0
        set.rpe = Double(rpeText) ?? 0

        try? ctx.save()
        dismiss()
    }
}

// MARK: - Formatting helpers

private func formatReps(_ reps: Double) -> String {
    // Round to 1 decimal place (good for 4.5 style reps)
    let rounded = (reps * 10).rounded() / 10

    if rounded == floor(rounded) {
        // 4.0 -> "4"
        return String(Int(rounded))
    } else {
        // 4.5 -> "4.5"
        return String(rounded)
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
