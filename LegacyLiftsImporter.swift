//
//  LegacyLiftsImporter.swift
//  BodyBuddy
//
//  Created by William Anan on 11/29/25.
//

import Foundation
import CoreData

private struct LiftRow {
    let date: Date
    let exerciseName: String
    let weight: Double
    let reps: Double
    let rpe: Double?
    let notes: String?
}

enum LegacyLiftsImporter {

    // Call this once to import from lifts.csv
    static func importIfNeeded(context ctx: NSManagedObjectContext) {
        // Safety: if there are already sessions, don't import again
        let request: NSFetchRequest<WorkoutSession> = WorkoutSession.fetchRequest()
        request.fetchLimit = 1
        let existing = (try? ctx.fetch(request)) ?? []
        guard existing.isEmpty else {
            print("Legacy import skipped: sessions already exist.")
            return
        }

        guard let url = Bundle.main.url(forResource: "lifts", withExtension: "csv") else {
            print("Could not find lifts.csv in app bundle")
            return
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("Unable to read lifts.csv")
            return
        }

        let rows = parseCSV(content: content)
        guard !rows.isEmpty else {
            print("No valid rows parsed from lifts.csv")
            return
        }

        // Map from date (startOfDay) -> WorkoutSession
        var sessionByDate: [Date: WorkoutSession] = [:]

        let calendar = Calendar.current

        for row in rows {
            let day = calendar.startOfDay(for: row.date)

            // Get or create session for this day
            let session: WorkoutSession
            if let existingSession = sessionByDate[day] {
                session = existingSession
            } else {
                let newSession = WorkoutSession(context: ctx)
                newSession.id = UUID()
                newSession.date = day
                sessionByDate[day] = newSession
                session = newSession
            }

            // Reuse or create Exercise
            let exercise = fetchOrCreateExercise(
                named: row.exerciseName,
                notes: row.notes,
                in: ctx
            )

            // Determine next global sortIndex for this session
            let allSetsInSession = (session.sets as? Set<WorkoutSet> ?? [])
            let maxIndex = allSetsInSession.map { $0.sortIndex }.max() ?? -1
            let nextIndex = Int16(maxIndex + 1)

            // Create set
            let set = WorkoutSet(context: ctx)
            set.id = UUID()
            set.session = session
            set.exercise = exercise
            set.weight = row.weight
            set.reps = row.reps
            if let rpe = row.rpe {
                set.rpe = rpe
            } else {
                set.rpe = 0
            }
            set.sortIndex = nextIndex
        }

        do {
            try ctx.save()
            print("Imported \(sessionByDate.count) sessions from lifts.csv")
        } catch {
            print("Failed to save imported lifts: \(error)")
        }
    }

    // MARK: - Helpers

    private static func fetchOrCreateExercise(
        named name: String,
        notes: String?,
        in ctx: NSManagedObjectContext
    ) -> Exercise {

        let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "name =[c] %@", name)
        request.fetchLimit = 1

        if let existing = (try? ctx.fetch(request))?.first {
            // Optionally fill in notes if they were empty
            if (existing.notes ?? "").isEmpty,
               let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                existing.notes = notes
            }
            return existing
        }

        let ex = Exercise(context: ctx)
        ex.id = UUID()
        ex.name = name
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ex.notes = notes
        }
        return ex
    }

    private static func parseCSV(content: String) -> [LiftRow] {
        var result: [LiftRow] = []

        let lines = content.split(whereSeparator: \.isNewline)
        guard !lines.isEmpty else { return [] }

        // Expected header: date,exerciseName,weight,reps,rpe,notes
        // Skip header
        let dataLines = lines.dropFirst()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for line in dataLines {
            // Keep empty fields so we still get 6 columns
            let parts = line.split(separator: ",", omittingEmptySubsequences: false)
            guard parts.count >= 4 else { continue }

            let dateString = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let exerciseName = String(parts[1]).trimmingCharacters(in: .whitespaces)

            let weight = Double(parts[2].trimmingCharacters(in: .whitespaces)) ?? 0
            let reps = Double(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0

            let rpe: Double?
            if parts.count > 4, !parts[4].trimmingCharacters(in: .whitespaces).isEmpty {
                rpe = Double(parts[4].trimmingCharacters(in: .whitespaces))
            } else {
                rpe = nil
            }

            let notes: String?
            if parts.count > 5 {
                let raw = String(parts[5]).trimmingCharacters(in: .whitespaces)
                notes = raw.isEmpty ? nil : raw
            } else {
                notes = nil
            }

            guard let date = dateFormatter.date(from: dateString) else {
                print("Skipping row with invalid date: \(dateString)")
                continue
            }

            result.append(LiftRow(
                date: date,
                exerciseName: exerciseName,
                weight: weight,
                reps: reps,
                rpe: rpe,
                notes: notes
            ))
        }

        return result
    }
}
