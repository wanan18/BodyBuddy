//
//  WorkoutStore.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import Foundation

@MainActor
final class WorkoutStore: ObservableObject {
    @Published private(set) var exercises: [ExerciseModel] = []
    @Published private(set) var workouts: [WorkoutModel] = []

    init() { seedExercisesIfNeeded() }

    // Create a new empty session
    func addWorkout(_ workout: WorkoutModel) {
        workouts.append(workout)
    }

    // Update date for a session (used by DatePicker in detail)
    func updateSessionDate(sessionID: UUID, newDate: Date) {
        guard let i = workouts.firstIndex(where: { $0.id == sessionID }) else { return }
        workouts[i].date = newDate
    }

    // Update notes on a session
    func updateNotes(sessionID: UUID, notes: String) {
        guard let i = workouts.firstIndex(where: { $0.id == sessionID }) else { return }
        workouts[i].notes = notes
    }

    // Append a set to a given session for a chosen exercise
    func appendSet(
        sessionID: UUID,
        exercise: ExerciseModel,
        reps: Int,
        weight: Double,
        rpe: Double? = nil,
        isWarmup: Bool = false
    ) {
        guard let i = workouts.firstIndex(where: { $0.id == sessionID }) else { return }

        let lastIndexForExercise = workouts[i].sets
            .filter { $0.exercise.id == exercise.id }
            .map { $0.setIndex }
            .max() ?? 0

        let set = SetEntryModel(
            id: UUID(),
            exercise: exercise,
            setIndex: lastIndexForExercise + 1,
            reps: reps,
            weight: weight,
            rpe: rpe,
            isWarmup: isWarmup
        )
        workouts[i].sets.append(set)
    }

    // Seed a tiny exercise library
    private func seedExercisesIfNeeded() {
        guard exercises.isEmpty else { return }
        exercises = [
            ExerciseModel(id: UUID(), name: "Barbell Bench Press", primary: .chest, secondary: [.triceps, .deltsFront], equipment: "Barbell"),
            ExerciseModel(id: UUID(), name: "Back Squat",             primary: .quads, secondary: [.glutes, .hamstrings],   equipment: "Barbell"),
            ExerciseModel(id: UUID(), name: "Deadlift",               primary: .hamstrings, secondary: [.glutes, .lowerBack], equipment: "Barbell"),
            ExerciseModel(id: UUID(), name: "Overhead Press",         primary: .deltsFront, secondary: [.triceps],          equipment: "Barbell"),
            ExerciseModel(id: UUID(), name: "Pull-up",                 primary: .lats, secondary: [.biceps],                 equipment: "Bodyweight")
        ]
    }
}
