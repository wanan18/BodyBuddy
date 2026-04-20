import Foundation

struct WorkoutSession: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var exercises: [LoggedExercise]
    var notes: String

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    static var empty: WorkoutSession {
        WorkoutSession(
            id: UUID(),
            title: "New Session",
            date: Date(),
            exercises: [],
            notes: ""
        )
    }

    static let sampleData = [
        WorkoutSession(
            id: UUID(),
            title: "Push Day",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            exercises: [
                LoggedExercise(
                    name: "Bench Press",
                    sets: [
                        LoggedSet(reps: 8, weight: 145, rpe: 7),
                        LoggedSet(reps: 8, weight: 155, rpe: 8),
                        LoggedSet(reps: 7, weight: 155, rpe: 8.5),
                        LoggedSet(reps: 6, weight: 155, rpe: 9)
                    ],
                    notes: "Last set moved slower."
                ),
                LoggedExercise(
                    name: "Shoulder Press",
                    sets: [
                        LoggedSet(reps: 10, weight: 70, rpe: 7),
                        LoggedSet(reps: 10, weight: 75, rpe: 7.5),
                        LoggedSet(reps: 9, weight: 75, rpe: 8)
                    ],
                    notes: ""
                )
            ],
            notes: "Good upper body session."
        ),
        WorkoutSession(
            id: UUID(),
            title: "Leg Strength",
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            exercises: [
                LoggedExercise(
                    name: "Back Squat",
                    sets: [
                        LoggedSet(reps: 5, weight: 165, rpe: 7),
                        LoggedSet(reps: 5, weight: 175, rpe: 8),
                        LoggedSet(reps: 5, weight: 185, rpe: 8.5),
                        LoggedSet(reps: 5, weight: 185, rpe: 8.5),
                        LoggedSet(reps: 4, weight: 185, rpe: 9)
                    ],
                    notes: "Add five pounds next time."
                ),
                LoggedExercise(
                    name: "Romanian Deadlift",
                    sets: [
                        LoggedSet(reps: 8, weight: 135, rpe: 7),
                        LoggedSet(reps: 8, weight: 135, rpe: 7),
                        LoggedSet(reps: 8, weight: 145, rpe: 7.5)
                    ],
                    notes: ""
                )
            ],
            notes: "Keep squat depth consistent."
        )
    ]
}

struct LoggedExercise: Identifiable, Equatable {
    let id: UUID
    var name: String
    var kind: ExerciseKind
    var sets: [LoggedSet]
    var notes: String
    var cardio: CardioLog

    var topWeight: Double {
        sets.compactMap(\.weight).max() ?? 0
    }

    var summary: String {
        if kind == .cardio {
            return cardio.summary
        }

        if topWeight == 0 {
            return "\(sets.count) sets"
        }

        return "\(sets.count) sets · top \(topWeight.formatted()) lb"
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: ExerciseKind = .lifting,
        sets: [LoggedSet],
        notes: String,
        cardio: CardioLog = .empty
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.sets = sets
        self.notes = notes
        self.cardio = cardio
    }

    static var empty: LoggedExercise {
        LoggedExercise(name: "New Exercise", sets: [.empty], notes: "")
    }

    static func empty(named name: String, kind: ExerciseKind = .lifting) -> LoggedExercise {
        LoggedExercise(
            name: name,
            kind: kind,
            sets: kind == .lifting ? [.empty] : [],
            notes: "",
            cardio: kind == .cardio ? .starter : .empty
        )
    }

    mutating func applyLibrarySelection(_ selectedExercise: LoggedExercise) {
        name = selectedExercise.name
        kind = selectedExercise.kind
        sets = selectedExercise.kind == .lifting ? selectedExercise.sets : []
        cardio = selectedExercise.kind == .cardio ? selectedExercise.cardio : .empty
    }
}

enum ExerciseKind: String {
    case lifting
    case cardio
}

enum DistanceUnit: String, CaseIterable, Identifiable {
    case mile = "mi"
    case kilometer = "km"
    case meter = "m"

    var id: String {
        rawValue
    }

    private var metersPerUnit: Double {
        switch self {
        case .mile:
            return 1609.344
        case .kilometer:
            return 1000
        case .meter:
            return 1
        }
    }

    func meters(from value: Double) -> Double {
        value * metersPerUnit
    }

    func value(fromMeters meters: Double) -> Double {
        meters / metersPerUnit
    }

    func formattedDistance(fromMeters meters: Double) -> String {
        let value = value(fromMeters: meters)

        switch self {
        case .meter:
            return "\(value.formatted(.number.precision(.fractionLength(0...0)))) \(rawValue)"
        case .mile, .kilometer:
            return "\(value.formatted(.number.precision(.fractionLength(0...2)))) \(rawValue)"
        }
    }
}

struct CardioLog: Equatable {
    var durationSeconds: Int?
    var distanceMeters: Double?
    var distanceUnit: DistanceUnit
    var caloriesBurned: Double?
    var laps: [CardioLap]

    var loggedLaps: [CardioLap] {
        laps.filter(\.hasLoggedInfo)
    }

    var summary: String {
        let durationText = durationSeconds.map { Self.formatDuration($0) }
        let distanceText = distanceMeters.map { distanceUnit.formattedDistance(fromMeters: $0) }
        let calorieText = caloriesBurned.map { "\($0.formatted(.number.precision(.fractionLength(0...0)))) cal" }
        let values = [durationText, distanceText, calorieText].compactMap { $0 }
        let loggedLapCount = loggedLaps.count

        if values.isEmpty {
            return loggedLapCount == 0 ? "Duration, distance, and calories" : "\(loggedLapCount) laps"
        }

        if loggedLapCount == 0 {
            return values.joined(separator: " · ")
        }

        return "\(values.joined(separator: " · ")) · \(loggedLapCount) laps"
    }

    static let empty = CardioLog(durationSeconds: nil, distanceMeters: nil, distanceUnit: .mile, caloriesBurned: nil, laps: [])
    static let starter = CardioLog(durationSeconds: nil, distanceMeters: nil, distanceUnit: .mile, caloriesBurned: nil, laps: [.empty])

    static func formatDuration(_ totalSeconds: Int) -> String {
        let safeSeconds = max(totalSeconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        }

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
    }

    static func formatClockDuration(_ totalSeconds: Int) -> String {
        let safeSeconds = max(totalSeconds, 0)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }

        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct CardioLap: Identifiable, Equatable {
    let id: UUID
    var distanceMeters: Double?
    var distanceUnit: DistanceUnit
    var timeSeconds: Int?

    var hasLoggedInfo: Bool {
        distanceMeters != nil || timeSeconds != nil
    }

    var previewText: String {
        let distanceText = distanceMeters.map { distanceUnit.formattedDistance(fromMeters: $0) } ?? "distance"
        let timeText = timeSeconds.map { CardioLog.formatDuration($0) } ?? "time"

        return "\(distanceText) - \(timeText)"
    }

    static var empty: CardioLap {
        CardioLap(id: UUID(), distanceMeters: nil, distanceUnit: .mile, timeSeconds: nil)
    }

    init(
        id: UUID = UUID(),
        distanceMeters: Double? = nil,
        distanceUnit: DistanceUnit = .mile,
        timeSeconds: Int? = nil
    ) {
        self.id = id
        self.distanceMeters = distanceMeters
        self.distanceUnit = distanceUnit
        self.timeSeconds = timeSeconds
    }
}

struct LoggedSet: Identifiable, Equatable {
    let id: UUID
    var reps: Double?
    var weight: Double?
    var rpe: Double?

    var previewText: String {
        let weightText = weight.map { "\($0.formatted()) lb" } ?? "weight"
        let repsText = reps.map { "\($0.formatted(.number.precision(.fractionLength(0...2)))) reps" } ?? "reps"

        if let rpe {
            return "\(weightText) × \(repsText) · RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))"
        }

        return "\(weightText) × \(repsText)"
    }

    init(id: UUID = UUID(), reps: Double? = nil, weight: Double? = nil, rpe: Double? = nil) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
    }

    static var empty: LoggedSet {
        LoggedSet()
    }
}
