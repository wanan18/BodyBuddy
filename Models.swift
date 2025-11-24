//
//  Models.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import Foundation

// Muscles you'll use for the heatmap later
enum Muscle: String, CaseIterable, Codable {
    case chest, lats, deltsFront, deltsSide, biceps, triceps, traps, lowerBack
    case quads, hamstrings, glutes, calves, abs, forearms
}

// Basic exercise definition
struct ExerciseModel: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var primary: Muscle
    var secondary: [Muscle]
    var equipment: String
}

// A single set in a workout
struct SetEntryModel: Identifiable, Hashable {
    let id: UUID
    var exercise: ExerciseModel
    var setIndex: Int = 1         // used by SessionDetailView; increment as you add sets
    var reps: Int
    var weight: Double
    var rpe: Double?
    var isWarmup: Bool
}

// A workout session (the thing listed in Sessions)
struct WorkoutModel: Identifiable {
    let id: UUID
    var date: Date
    var notes: String?
    var sets: [SetEntryModel]
}
