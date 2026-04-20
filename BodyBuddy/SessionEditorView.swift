import SwiftUI

struct SessionEditorView: View {
    @Binding var session: WorkoutSession
    let saveStatus: SaveStatus
    let onSaveDetails: (WorkoutSession) async -> Void
    let onSaveExercise: (WorkoutSession, LoggedExercise, Int) async -> Void
    let onDeleteExercise: (LoggedExercise) async -> Void
    let onSaveSet: (LoggedSet, UUID, Int) async -> Void
    let onDeleteSet: (LoggedSet) async -> Void
    let onSaveCardioLap: (CardioLap, UUID, Int) async -> Void
    let onDeleteCardioLap: (CardioLap) async -> Void
    @State private var isShowingExercisePicker = false
    @State private var detailsSaveTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section("Session") {
                TextField("Name", text: sessionTitleBinding)
                    .onSubmit {
                        saveCurrentSession()
                    }
                DatePicker("Date", selection: sessionDateBinding, displayedComponents: [.date])
            }

            Section("Exercises") {
                if session.exercises.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No exercises yet")
                            .font(.headline)

                        Text("Add lifting or cardio from your library.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                ForEach(session.exercises.indices, id: \.self) { index in
                    NavigationLink {
                        ExerciseEditorView(
                            exercise: $session.exercises[index],
                            saveStatus: saveStatus,
                            position: index,
                            sessionID: session.id,
                            onSaveExercise: { exercise, position in
                                await onSaveExercise(session, exercise, position)
                            },
                            onSaveSet: onSaveSet,
                            onDeleteSet: onDeleteSet,
                            onSaveCardioLap: onSaveCardioLap,
                            onDeleteCardioLap: onDeleteCardioLap
                        )
                    } label: {
                        ExerciseSummaryRow(exercise: session.exercises[index])
                    }
                }
                .onDelete { offsets in
                    let deletedExercises = offsets.map { session.exercises[$0] }
                    session.exercises.remove(atOffsets: offsets)

                    Task {
                        for exercise in deletedExercises {
                            await onDeleteExercise(exercise)
                        }

                        for (index, exercise) in session.exercises.enumerated() {
                            await onSaveExercise(session, exercise, index)
                        }
                    }
                }

                Button {
                    isShowingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }

            Section("Notes") {
                TextEditor(text: sessionNotesBinding)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle(session.title.isEmpty ? "Session" : session.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SaveStatusIndicator(status: saveStatus)
            }
        }
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerView { exercise in
                session.exercises.append(exercise)
                let position = session.exercises.count - 1

                Task {
                    await onSaveDetails(session)
                    await onSaveExercise(session, exercise, position)
                }
            }
        }
        .onDisappear {
            detailsSaveTask?.cancel()
            saveCurrentSession()
        }
    }

    private var sessionTitleBinding: Binding<String> {
        Binding(
            get: {
                session.title
            },
            set: { newValue in
                session.title = newValue
                scheduleDetailsSave(for: session)
            }
        )
    }

    private var sessionDateBinding: Binding<Date> {
        Binding(
            get: {
                session.date
            },
            set: { newValue in
                session.date = newValue
                scheduleDetailsSave(for: session)
            }
        )
    }

    private var sessionNotesBinding: Binding<String> {
        Binding(
            get: {
                session.notes
            },
            set: { newValue in
                session.notes = newValue
                scheduleDetailsSave(for: session)
            }
        )
    }

    private func scheduleDetailsSave(for sessionToSave: WorkoutSession) {
        detailsSaveTask?.cancel()
        detailsSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else {
                return
            }

            await onSaveDetails(sessionToSave)
        }
    }

    private func saveCurrentSession() {
        let sessionToSave = session

        Task {
            await onSaveDetails(sessionToSave)
        }
    }
}

struct ExerciseSummaryRow: View {
    let exercise: LoggedExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .fontWeight(.semibold)

            Text(exercise.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if exercise.kind == .lifting {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        Text("Set \(index + 1): \(set.previewText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(exercise.cardio.loggedLaps.enumerated()), id: \.element.id) { index, lap in
                        Text("Lap \(index + 1): \(lap.previewText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
