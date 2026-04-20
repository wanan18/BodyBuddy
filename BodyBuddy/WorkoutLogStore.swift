import Foundation
import Combine
import Supabase

enum SaveStatus: Equatable {
    case idle
    case saving
    case saved
    case failed(String)
}

@MainActor
final class WorkoutLogStore: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var saveStatus: SaveStatus = .idle

    private let client = SupabaseManager.shared.client
    private var activeSaveCount = 0
    private var saveStatusResetTask: Task<Void, Never>?

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let userID = try await currentUserID()
            let sessionRows: [WorkoutSessionRecord] = try await client
                .from("workout_sessions")
                .select()
                .eq("user_id", value: userID)
                .order("session_date", ascending: false)
                .execute()
                .value

            guard !sessionRows.isEmpty else {
                sessions = []
                isLoading = false
                return
            }

            let sessionIDs = sessionRows.map(\.id)
            let exerciseRows = try await loadExercises(sessionIDs: sessionIDs)
            let exerciseIDs = exerciseRows.map(\.id)
            let setRows = try await loadSets(exerciseIDs: exerciseIDs)
            let lapRows = try await loadCardioLaps(exerciseIDs: exerciseIDs)

            sessions = sessionRows.map { sessionRow in
                let exercises = exerciseRows
                    .filter { $0.sessionID == sessionRow.id }
                    .sorted { $0.position < $1.position }
                    .map { exerciseRow in
                        let sets = setRows
                            .filter { $0.exerciseID == exerciseRow.id }
                            .sorted { $0.setNumber < $1.setNumber }
                            .map {
                                LoggedSet(
                                    id: $0.id,
                                    reps: $0.reps,
                                    weight: $0.weight,
                                    rpe: $0.rpe
                                )
                            }

                        let exerciseKind = ExerciseKind(rawValue: exerciseRow.exerciseType) ?? .lifting

                        return LoggedExercise(
                            id: exerciseRow.id,
                            name: exerciseRow.name,
                            kind: exerciseKind,
                            sets: exerciseKind == .lifting && sets.isEmpty ? [.empty] : sets,
                            notes: exerciseRow.notes ?? "",
                            cardio: CardioLog(
                                durationSeconds: exerciseRow.resolvedDurationSeconds,
                                distanceMeters: exerciseRow.resolvedDistanceMeters,
                                distanceUnit: DistanceUnit(rawValue: exerciseRow.distanceUnit ?? "") ?? .mile,
                                caloriesBurned: exerciseRow.caloriesBurned,
                                laps: lapRows
                                    .filter { $0.exerciseID == exerciseRow.id }
                                    .sorted { $0.lapNumber < $1.lapNumber }
                                    .map {
                                        CardioLap(
                                            id: $0.id,
                                            distanceMeters: $0.resolvedDistanceMeters,
                                            distanceUnit: DistanceUnit(rawValue: $0.distanceUnit ?? "") ?? .mile,
                                            timeSeconds: $0.resolvedTimeSeconds
                                        )
                                    }
                            )
                        )
                    }

                return WorkoutSession(
                    id: sessionRow.id,
                    title: sessionRow.title,
                    date: SupabaseDateCoding.decode(sessionRow.sessionDate),
                    exercises: exercises,
                    notes: sessionRow.notes ?? ""
                )
            }
        } catch {
            errorMessage = "Could not load workout sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func saveSession(_ session: WorkoutSession) async {
        beginSaving()

        do {
            try await upsertSessionDetails(session)
            try await upsertSessionContents(session)
            finishSaving()
        } catch {
            failSaving("Could not save session: \(error.localizedDescription)")
        }
    }

    func saveExercise(_ exercise: LoggedExercise, sessionID: UUID, position: Int) async {
        beginSaving()

        do {
            try await upsertExercise(exercise, sessionID: sessionID, position: position)
            finishSaving()
        } catch {
            failSaving("Could not save exercise: \(error.localizedDescription)")
        }
    }

    func deleteExercise(_ exercise: LoggedExercise) async {
        beginSaving()

        do {
            try await client
                .from("workout_exercises")
                .delete(returning: .minimal)
                .eq("id", value: exercise.id)
                .execute()
            finishSaving()
        } catch {
            failSaving("Could not delete exercise: \(error.localizedDescription)")
            await loadSessions()
        }
    }

    func saveSet(_ set: LoggedSet, exerciseID: UUID, setNumber: Int) async {
        beginSaving()

        do {
            try await upsertSet(set, exerciseID: exerciseID, setNumber: setNumber)
            finishSaving()
        } catch {
            failSaving("Could not save set: \(error.localizedDescription)")
        }
    }

    func deleteSet(_ set: LoggedSet) async {
        beginSaving()

        do {
            try await client
                .from("workout_sets")
                .delete(returning: .minimal)
                .eq("id", value: set.id)
                .execute()
            finishSaving()
        } catch {
            failSaving("Could not delete set: \(error.localizedDescription)")
            await loadSessions()
        }
    }

    func saveCardioLap(_ lap: CardioLap, exerciseID: UUID, lapNumber: Int) async {
        beginSaving()

        do {
            try await upsertCardioLap(lap, exerciseID: exerciseID, lapNumber: lapNumber)
            finishSaving()
        } catch {
            failSaving("Could not save lap: \(error.localizedDescription)")
        }
    }

    func deleteCardioLap(_ lap: CardioLap) async {
        beginSaving()

        do {
            try await client
                .from("workout_cardio_laps")
                .delete(returning: .minimal)
                .eq("id", value: lap.id)
                .execute()
            finishSaving()
        } catch {
            failSaving("Could not delete lap: \(error.localizedDescription)")
            await loadSessions()
        }
    }

    func saveSessionDetails(_ session: WorkoutSession) async {
        beginSaving()

        do {
            try await upsertSessionDetails(session)
            finishSaving()
        } catch {
            failSaving("Could not save session: \(error.localizedDescription)")
        }
    }

    func deleteSession(_ session: WorkoutSession) async {
        beginSaving()

        do {
            try await client
                .from("workout_sessions")
                .delete(returning: .minimal)
                .eq("id", value: session.id)
                .execute()
            finishSaving()
        } catch {
            failSaving("Could not delete session: \(error.localizedDescription)")
            await loadSessions()
        }
    }

    private func beginSaving() {
        activeSaveCount += 1
        saveStatusResetTask?.cancel()
        isSaving = true
        errorMessage = nil
        saveStatus = .saving
    }

    private func finishSaving() {
        activeSaveCount = max(activeSaveCount - 1, 0)

        guard activeSaveCount == 0 else {
            return
        }

        isSaving = false
        saveStatus = .saved
        scheduleSavedStatusReset()
    }

    private func failSaving(_ message: String) {
        activeSaveCount = max(activeSaveCount - 1, 0)
        isSaving = activeSaveCount > 0
        errorMessage = message
        saveStatus = .failed(message)
    }

    private func scheduleSavedStatusReset() {
        saveStatusResetTask?.cancel()
        saveStatusResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard self?.saveStatus == .saved else {
                    return
                }

                self?.saveStatus = .idle
            }
        }
    }

    private func upsertSessionDetails(_ session: WorkoutSession) async throws {
        let userID = try await currentUserID()

        let sessionUpsert = WorkoutSessionUpsert(
            id: session.id,
            userID: userID,
            title: session.title,
            sessionDate: SupabaseDateCoding.encode(session.date),
            notes: session.notes.nilIfBlank
        )

        try await client
            .from("workout_sessions")
            .upsert(sessionUpsert, onConflict: "id", returning: .minimal)
            .execute()
    }

    private func upsertSessionContents(_ session: WorkoutSession) async throws {
        for (exerciseIndex, exercise) in session.exercises.enumerated() {
            try await upsertExercise(exercise, sessionID: session.id, position: exerciseIndex)

            if exercise.kind == .lifting {
                for (setIndex, set) in exercise.sets.enumerated() {
                    try await upsertSet(set, exerciseID: exercise.id, setNumber: setIndex)
                }
            } else {
                for (lapIndex, lap) in exercise.cardio.laps.enumerated() {
                    try await upsertCardioLap(lap, exerciseID: exercise.id, lapNumber: lapIndex)
                }
            }
        }
    }

    private func upsertExercise(_ exercise: LoggedExercise, sessionID: UUID, position: Int) async throws {
        let exerciseUpsert = WorkoutExerciseUpsert(
            id: exercise.id,
            sessionID: sessionID,
            name: exercise.name,
            exerciseType: exercise.kind.rawValue,
            notes: exercise.notes.nilIfBlank,
            position: position,
            durationSeconds: exercise.cardio.durationSeconds,
            distanceMeters: exercise.cardio.distanceMeters,
            distanceUnit: exercise.cardio.distanceUnit.rawValue,
            caloriesBurned: exercise.cardio.caloriesBurned
        )

        try await client
            .from("workout_exercises")
            .upsert(exerciseUpsert, onConflict: "id", returning: .minimal)
            .execute()
    }

    private func upsertSet(_ set: LoggedSet, exerciseID: UUID, setNumber: Int) async throws {
        let setUpsert = WorkoutSetUpsert(
            id: set.id,
            exerciseID: exerciseID,
            setNumber: setNumber,
            reps: set.reps,
            weight: set.weight,
            rpe: set.rpe
        )

        try await client
            .from("workout_sets")
            .upsert(setUpsert, onConflict: "id", returning: .minimal)
            .execute()
    }

    private func upsertCardioLap(_ lap: CardioLap, exerciseID: UUID, lapNumber: Int) async throws {
        let lapUpsert = WorkoutCardioLapUpsert(
            id: lap.id,
            exerciseID: exerciseID,
            lapNumber: lapNumber,
            distanceMeters: lap.distanceMeters,
            distanceUnit: lap.distanceUnit.rawValue,
            timeSeconds: lap.timeSeconds
        )

        try await client
            .from("workout_cardio_laps")
            .upsert(lapUpsert, onConflict: "id", returning: .minimal)
            .execute()
    }

    private func loadExercises(sessionIDs: [UUID]) async throws -> [WorkoutExerciseRecord] {
        guard !sessionIDs.isEmpty else {
            return []
        }

        return try await client
            .from("workout_exercises")
            .select()
            .in("session_id", values: filterValues(sessionIDs))
            .order("position", ascending: true)
            .execute()
            .value
    }

    private func loadSets(exerciseIDs: [UUID]) async throws -> [WorkoutSetRecord] {
        guard !exerciseIDs.isEmpty else {
            return []
        }

        return try await client
            .from("workout_sets")
            .select()
            .in("exercise_id", values: filterValues(exerciseIDs))
            .order("set_number", ascending: true)
            .execute()
            .value
    }

    private func loadCardioLaps(exerciseIDs: [UUID]) async throws -> [WorkoutCardioLapRecord] {
        guard !exerciseIDs.isEmpty else {
            return []
        }

        return try await client
            .from("workout_cardio_laps")
            .select()
            .in("exercise_id", values: filterValues(exerciseIDs))
            .order("lap_number", ascending: true)
            .execute()
            .value
    }

    private func currentUserID() async throws -> UUID {
        try await client.auth.session.user.id
    }

    private func filterValues(_ ids: [UUID]) -> [any PostgrestFilterValue] {
        ids.map { $0 as any PostgrestFilterValue }
    }
}

enum SupabaseDateCoding {
    private static let formatterWithFractions: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func encode(_ date: Date) -> String {
        formatterWithFractions.string(from: date)
    }

    static func decode(_ value: String) -> Date {
        formatterWithFractions.date(from: value) ?? formatter.date(from: value) ?? Date()
    }
}

struct WorkoutSessionRecord: Decodable {
    let id: UUID
    let userID: UUID
    let title: String
    let sessionDate: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case sessionDate = "session_date"
        case notes
    }
}

struct WorkoutSessionUpsert: Encodable {
    let id: UUID
    let userID: UUID
    let title: String
    let sessionDate: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case sessionDate = "session_date"
        case notes
    }
}

struct WorkoutExerciseRecord: Decodable {
    let id: UUID
    let sessionID: UUID
    let name: String
    let exerciseType: String
    let notes: String?
    let position: Int
    let durationMinutes: Double?
    let distance: Double?
    let durationSeconds: Int?
    let distanceMeters: Double?
    let distanceUnit: String?
    let caloriesBurned: Double?

    var resolvedDurationSeconds: Int? {
        durationSeconds ?? durationMinutes.map { Int(($0 * 60).rounded()) }
    }

    var resolvedDistanceMeters: Double? {
        distanceMeters ?? distance.map { DistanceUnit.mile.meters(from: $0) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case name
        case exerciseType = "exercise_type"
        case notes
        case position
        case durationMinutes = "duration_minutes"
        case distance
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case distanceUnit = "distance_unit"
        case caloriesBurned = "calories_burned"
    }
}

struct WorkoutExerciseUpsert: Encodable {
    let id: UUID
    let sessionID: UUID
    let name: String
    let exerciseType: String
    let notes: String?
    let position: Int
    let durationSeconds: Int?
    let distanceMeters: Double?
    let distanceUnit: String
    let caloriesBurned: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionID = "session_id"
        case name
        case exerciseType = "exercise_type"
        case notes
        case position
        case durationSeconds = "duration_seconds"
        case distanceMeters = "distance_meters"
        case distanceUnit = "distance_unit"
        case caloriesBurned = "calories_burned"
    }
}

struct WorkoutSetRecord: Decodable {
    let id: UUID
    let exerciseID: UUID
    let setNumber: Int
    let reps: Double?
    let weight: Double?
    let rpe: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weight
        case rpe
    }
}

struct WorkoutSetUpsert: Encodable {
    let id: UUID
    let exerciseID: UUID
    let setNumber: Int
    let reps: Double?
    let weight: Double?
    let rpe: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weight
        case rpe
    }
}

struct WorkoutCardioLapRecord: Decodable {
    let id: UUID
    let exerciseID: UUID
    let lapNumber: Int
    let distance: Double?
    let timeMinutes: Double?
    let distanceMeters: Double?
    let distanceUnit: String?
    let timeSeconds: Int?

    var resolvedDistanceMeters: Double? {
        distanceMeters ?? distance.map { DistanceUnit.mile.meters(from: $0) }
    }

    var resolvedTimeSeconds: Int? {
        timeSeconds ?? timeMinutes.map { Int(($0 * 60).rounded()) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case lapNumber = "lap_number"
        case distance
        case timeMinutes = "time_minutes"
        case distanceMeters = "distance_meters"
        case distanceUnit = "distance_unit"
        case timeSeconds = "time_seconds"
    }
}

struct WorkoutCardioLapUpsert: Encodable {
    let id: UUID
    let exerciseID: UUID
    let lapNumber: Int
    let distanceMeters: Double?
    let distanceUnit: String
    let timeSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case lapNumber = "lap_number"
        case distanceMeters = "distance_meters"
        case distanceUnit = "distance_unit"
        case timeSeconds = "time_seconds"
    }
}

@MainActor

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
