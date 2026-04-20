import SwiftUI
import Combine
import Supabase
import PostgREST
import Auth

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (LoggedExercise) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose a library")
                        .font(.headline)

                    NavigationLink {
                        LiftingExerciseLibraryView { exercise in
                            onSelect(exercise)
                            dismiss()
                        }
                    } label: {
                        ExerciseLibraryTile(
                            title: "Lifting",
                            subtitle: "Strength exercises, custom lifts, sets, reps, and load.",
                            systemImage: "dumbbell.fill",
                            tint: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        CardioExerciseLibraryView { exercise in
                            onSelect(exercise)
                            dismiss()
                        }
                    } label: {
                        ExerciseLibraryTile(
                            title: "Cardio",
                            subtitle: "Cardio exercise library coming soon.",
                            systemImage: "figure.run",
                            tint: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LiftingExerciseLibraryView: View {
    @StateObject private var store = UserExerciseLibraryStore()
    @State private var isShowingCreateExercise = false
    let onSelect: (LoggedExercise) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Text("Muscle Groups")
                    .font(.headline)

                ForEach(ExerciseLibrary.muscleGroups, id: \.self) { muscleGroup in
                    NavigationLink {
                        MuscleGroupExerciseListView(
                            muscleGroup: muscleGroup,
                            store: store,
                            onSelect: onSelect
                        )
                    } label: {
                        ExerciseLibraryTile(
                            title: muscleGroup,
                            subtitle: muscleGroupSubtitle(for: muscleGroup),
                            systemImage: muscleGroupIcon(for: muscleGroup),
                            tint: muscleGroupTint(for: muscleGroup)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lifting")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingCreateExercise = true
                } label: {
                    Label("Create Exercise", systemImage: "plus")
                }
            }
        }
        .overlay {
            if store.isLoading {
                ProgressView("Loading exercises...")
            }
        }
        .task {
            await store.loadExercises()
        }
        .sheet(isPresented: $isShowingCreateExercise) {
            CreateUserExerciseView { name, muscleGroups in
                await store.createExercise(name: name, muscleGroups: muscleGroups)
            }
        }
    }

    private func muscleGroupSubtitle(for muscleGroup: String) -> String {
        let builtInCount = ExerciseLibrary.exercises(forMuscleGroup: muscleGroup).count
        let userCount = store.exercises.filter {
            $0.muscleGroups.contains(muscleGroup)
        }.count
        let totalCount = builtInCount + userCount

        if userCount == 0 {
            return "\(totalCount) exercises"
        }

        return "\(totalCount) exercises · \(userCount) custom"
    }

    private func muscleGroupIcon(for muscleGroup: String) -> String {
        switch muscleGroup {
        case "Chest":
            return "figure.strengthtraining.traditional"
        case "Shoulders":
            return "figure.arms.open"
        case "Back":
            return "figure.pullup"
        case "Biceps":
            return "dumbbell.fill"
        case "Triceps":
            return "figure.strengthtraining.functional"
        case "Quads":
            return "figure.squat"
        case "Hamstrings":
            return "figure.walk"
        case "Glutes":
            return "figure.run"
        case "Calves":
            return "shoeprints.fill"
        case "Core":
            return "figure.core.training"
        default:
            return "dumbbell.fill"
        }
    }

    private func muscleGroupTint(for muscleGroup: String) -> Color {
        switch muscleGroup {
        case "Chest":
            return .red
        case "Shoulders":
            return .orange
        case "Back":
            return .blue
        case "Biceps":
            return .purple
        case "Triceps":
            return .pink
        case "Quads":
            return .green
        case "Hamstrings":
            return .mint
        case "Glutes":
            return .indigo
        case "Calves":
            return .teal
        case "Core":
            return .cyan
        default:
            return .accentColor
        }
    }
}

struct MuscleGroupExerciseListView: View {
    let muscleGroup: String
    @ObservedObject var store: UserExerciseLibraryStore
    let onSelect: (LoggedExercise) -> Void
    @State private var searchText = ""

    private var builtInExercises: [String] {
        ExerciseLibrary.exercises(forMuscleGroup: muscleGroup)
    }

    private var customExercises: [UserExercise] {
        store.exercises.filter {
            $0.muscleGroups.contains(muscleGroup)
        }
    }

    private var filteredBuiltInExercises: [String] {
        guard !trimmedSearch.isEmpty else {
            return builtInExercises
        }

        return builtInExercises.filter {
            $0.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    private var filteredCustomExercises: [UserExercise] {
        guard !trimmedSearch.isEmpty else {
            return customExercises
        }

        return customExercises.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch)
                || $0.muscleGroups.contains {
                    $0.localizedCaseInsensitiveContains(trimmedSearch)
                }
        }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        List {
            if !filteredCustomExercises.isEmpty {
                Section("My Exercises") {
                    ForEach(filteredCustomExercises) { exercise in
                        Button {
                            onSelect(.empty(named: exercise.name, kind: .lifting))
                        } label: {
                            ExerciseLibraryRow(
                                name: exercise.name,
                                muscleGroups: exercise.muscleGroups
                            )
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteExercise(exercise)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if !filteredBuiltInExercises.isEmpty {
                Section("Exercises") {
                    ForEach(filteredBuiltInExercises, id: \.self) { exercise in
                        Button {
                            onSelect(.empty(named: exercise, kind: .lifting))
                        } label: {
                            ExerciseLibraryRow(
                                name: exercise,
                                muscleGroups: ExerciseLibrary.muscles(for: exercise)
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search \(muscleGroup.lowercased()) exercises")
        .navigationTitle(muscleGroup)
        .overlay {
            if filteredBuiltInExercises.isEmpty && filteredCustomExercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search or create a custom exercise for this muscle.")
                )
            }
        }
    }

    private func deleteExercise(_ exercise: UserExercise) {
        Task {
            await store.deleteExercise(exercise)
        }
    }
}

struct CardioExerciseLibraryView: View {
    let onSelect: (LoggedExercise) -> Void
    @State private var searchText = ""

    private var filteredExercises: [String] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return CardioExerciseLibrary.exercises
        }

        return CardioExerciseLibrary.exercises.filter {
            $0.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        List {
            Section("Exercises") {
                ForEach(filteredExercises, id: \.self) { exercise in
                    Button {
                        onSelect(.empty(named: exercise, kind: .cardio))
                    } label: {
                        ExerciseLibraryRow(name: exercise, muscleGroups: [])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search cardio exercises")
        .navigationTitle("Cardio")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if filteredExercises.isEmpty {
                ContentUnavailableView(
                    "No Cardio Found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different cardio exercise.")
                )
            }
        }
    }
}

struct ExerciseLibraryTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.14))
                .foregroundStyle(tint)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ExerciseLibraryRow: View {
    let name: String
    let muscleGroups: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .foregroundStyle(.primary)

            if !muscleGroups.isEmpty {
                Text(muscleGroups.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CreateUserExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName = ""
    @State private var selectedMuscles: Set<String> = []
    @State private var isSaving = false
    let onCreate: (String, [String]) async -> Void

    private var canCreate: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedMuscles.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise Name", text: $exerciseName)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    ForEach(ExerciseLibrary.muscleGroups, id: \.self) { muscle in
                        Button {
                            toggle(muscle)
                        } label: {
                            HStack {
                                Text(muscle)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedMuscles.contains(muscle) {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Muscles")
                } footer: {
                    Text("Pick every muscle this exercise primarily trains.")
                }
            }
            .navigationTitle("Create Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canCreate || isSaving)
                }
            }
        }
    }

    private func toggle(_ muscle: String) {
        if selectedMuscles.contains(muscle) {
            selectedMuscles.remove(muscle)
        } else {
            selectedMuscles.insert(muscle)
        }
    }

    private func save() {
        let name = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let muscles = ExerciseLibrary.muscleGroups.filter { selectedMuscles.contains($0) }

        isSaving = true
        Task {
            await onCreate(name, muscles)
            isSaving = false
            dismiss()
        }
    }
}


final class UserExerciseLibraryStore: ObservableObject {
    @Published var exercises: [UserExercise] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

    func loadExercises() async {
        isLoading = true
        errorMessage = nil

        do {
            let userID = try await currentUserID()
            let records: [UserExerciseRecord] = try await client
                .from("user_exercises")
                .select()
                .eq("user_id", value: userID)
                .order("name", ascending: true)
                .execute()
                .value

            exercises = records.map {
                UserExercise(id: $0.id, name: $0.name, muscleGroups: $0.muscleGroups)
            }
        } catch {
            errorMessage = "Could not load custom exercises: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createExercise(name: String, muscleGroups: [String]) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let userID = try await currentUserID()
            let upsert = UserExerciseUpsert(
                id: UUID(),
                userID: userID,
                name: trimmedName,
                muscleGroups: muscleGroups
            )

            try await client
                .from("user_exercises")
                .insert(upsert, returning: .minimal)
                .execute()

            exercises.append(
                UserExercise(
                    id: upsert.id,
                    name: upsert.name,
                    muscleGroups: upsert.muscleGroups
                )
            )
            exercises.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            errorMessage = "Could not create exercise: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func deleteExercise(_ exercise: UserExercise) async {
        let previousExercises = exercises
        exercises.removeAll { $0.id == exercise.id }
        isSaving = true
        errorMessage = nil

        do {
            try await client
                .from("user_exercises")
                .delete(returning: .minimal)
                .eq("id", value: exercise.id)
                .execute()
        } catch {
            exercises = previousExercises
            errorMessage = "Could not delete exercise: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func muscles(for exerciseName: String) -> [String] {
        if let exercise = exercises.first(where: { $0.name == exerciseName }) {
            return exercise.muscleGroups
        }

        return ExerciseLibrary.muscles(for: exerciseName)
    }

    private func currentUserID() async throws -> UUID {
        try await client.auth.session.user.id
    }
}

struct UserExercise: Identifiable {
    let id: UUID
    let name: String
    let muscleGroups: [String]
}

struct UserExerciseRecord: Decodable {
    let id: UUID
    let userID: UUID
    let name: String
    let muscleGroups: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case muscleGroups = "muscle_groups"
    }
}

struct UserExerciseUpsert: Encodable {
    let id: UUID
    let userID: UUID
    let name: String
    let muscleGroups: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case muscleGroups = "muscle_groups"
    }
}

enum CardioExerciseLibrary {
    static let exercises = [
        "Run",
        "Walk",
        "Incline Treadmill Walk",
        "Bike",
        "Swim",
        "Row",
        "Elliptical",
        "Stair Climber",
        "Jump Rope",
        "Hike"
    ]
}

enum ExerciseLibrary {
    struct Category: Identifiable {
        let name: String
        let exercises: [String]

        var id: String {
            name
        }
    }

    static let categories = [
        Category(
            name: "Chest",
            exercises: [
                "Barbell Bench Press",
                "Incline Barbell Bench Press",
                "Decline Barbell Bench Press",
                "Flat Dumbbell Bench Press",
                "Incline Dumbbell Bench Press",
                "Decline Dumbbell Bench Press",
                "Machine Chest Press",
                "Incline Machine Chest Press",
                "Smith Machine Bench Press",
                "Pec Deck",
                "Cable Fly",
                "Low-to-High Cable Fly",
                "High-to-Low Cable Fly",
                "Push-Up",
                "Weighted Push-Up",
                "Dips",
                "Close-Grip Bench Press"
            ]
        ),
        Category(
            name: "Shoulders",
            exercises: [
                "Seated Dumbbell Shoulder Press",
                "Standing Dumbbell Shoulder Press",
                "Barbell Overhead Press",
                "Seated Barbell Overhead Press",
                "Machine Shoulder Press",
                "Arnold Press",
                "Lateral Raise",
                "Cable Lateral Raise",
                "Rear Delt Fly",
                "Reverse Pec Deck",
                "Front Raise",
                "Upright Row",
                "Face Pull"
            ]
        ),
        Category(
            name: "Back",
            exercises: [
                "Lat Pulldown",
                "Wide-Grip Lat Pulldown",
                "Close-Grip Lat Pulldown",
                "Neutral-Grip Lat Pulldown",
                "Pull-Up",
                "Assisted Pull-Up",
                "Weighted Pull-Up",
                "Chin-Up",
                "Assisted Chin-Up",
                "Weighted Chin-Up",
                "Barbell Row",
                "Pendlay Row",
                "T-Bar Row",
                "Chest-Supported Row",
                "Seated Cable Row",
                "Single-Arm Cable Row",
                "One-Arm Dumbbell Row",
                "Meadows Row",
                "Machine Row",
                "Straight-Arm Pulldown",
                "Dumbbell Pullover",
                "Shrug",
                "Barbell Shrug",
                "Dumbbell Shrug"
            ]
        ),
        Category(
            name: "Biceps",
            exercises: [
                "Barbell Curl",
                "EZ-Bar Curl",
                "Dumbbell Bicep Curl",
                "Alternating Dumbbell Curl",
                "Seated Dumbbell Bicep Curl",
                "Hammer Curl",
                "Cross-Body Hammer Curl",
                "Preacher Curl",
                "Cable Curl",
                "Incline Dumbbell Curl",
                "Concentration Curl",
                "Reverse Curl"
            ]
        ),
        Category(
            name: "Triceps",
            exercises: [
                "Triceps Pushdown",
                "Rope Triceps Pushdown",
                "Straight-Bar Triceps Pushdown",
                "Overhead Triceps Extension",
                "Cable Overhead Triceps Extension",
                "Dumbbell Overhead Triceps Extension",
                "Skull Crusher",
                "Close-Grip Push-Up",
                "Bench Dip",
                "Machine Dip"
            ]
        ),
        Category(
            name: "Quads",
            exercises: [
                "Barbell Back Squat",
                "High-Bar Squat",
                "Low-Bar Squat",
                "Front Squat",
                "Goblet Squat",
                "Hack Squat",
                "Smith Machine Squat",
                "Leg Press",
                "Single-Leg Press",
                "Leg Extension",
                "Walking Lunge",
                "Reverse Lunge",
                "Stationary Lunge",
                "Bulgarian Split Squat",
                "Step-Up",
                "Smith Machine Lunge",
                "Sissy Squat"
            ]
        ),
        Category(
            name: "Hamstrings and Glutes",
            exercises: [
                "Deadlift",
                "Conventional Deadlift",
                "Sumo Deadlift",
                "Romanian Deadlift",
                "Stiff-Leg Deadlift",
                "Trap Bar Deadlift",
                "Rack Pull",
                "Good Morning",
                "Barbell Hip Thrust",
                "Dumbbell Hip Thrust",
                "Glute Bridge",
                "Cable Pull-Through",
                "Hamstring Curl",
                "Seated Hamstring Curl",
                "Lying Hamstring Curl",
                "Nordic Hamstring Curl",
                "Glute Kickback",
                "Cable Glute Kickback",
                "Back Extension",
                "Reverse Hyperextension"
            ]
        ),
        Category(
            name: "Calves",
            exercises: [
                "Standing Calf Raise",
                "Seated Calf Raise",
                "Leg Press Calf Raise",
                "Donkey Calf Raise"
            ]
        ),
        Category(
            name: "Core",
            exercises: [
                "Ab Crunch",
                "Cable Crunch",
                "Machine Crunch",
                "Decline Sit-Up",
                "Sit-Up",
                "Crunch",
                "Reverse Crunch",
                "Hanging Knee Raise",
                "Hanging Leg Raise",
                "Roman Chair Leg Raise",
                "Ab Wheel Rollout",
                "Plank",
                "Side Plank",
                "Russian Twist",
                "Mountain Climber",
                "Toe Touch",
                "Dead Bug",
                "Bicycle Crunch",
                "Flutter Kick",
                "V-Up",
                "Wood Chop",
                "Cable Wood Chop",
                "Pallof Press"
            ]
        )
    ]

    static let muscleGroups = [
        "Chest",
        "Shoulders",
        "Back",
        "Biceps",
        "Triceps",
        "Quads",
        "Hamstrings",
        "Glutes",
        "Calves",
        "Core"
    ]

    static func muscles(for exerciseName: String) -> [String] {
        categories.first { $0.exercises.contains(exerciseName) }
            .map { muscles(forCategory: $0.name) } ?? []
    }

    static func exercises(forMuscleGroup muscleGroup: String) -> [String] {
        categories
            .filter { muscles(forCategory: $0.name).contains(muscleGroup) }
            .flatMap(\.exercises)
    }

    private static func muscles(forCategory category: String) -> [String] {
        switch category {
        case "Hamstrings and Glutes":
            return ["Hamstrings", "Glutes"]
        default:
            return [category]
        }
    }
}
