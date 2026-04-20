import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    @AppStorage("dashboardStepCount") private var steps = 0
    @AppStorage("dashboardDistance") private var distance = 0.0
    @AppStorage("dashboardCalories") private var calories = 0
    @AppStorage("dashboardWeightEntries") private var encodedWeightEntries = "[]"
    private let stepGoal = 10000
    private let recentWorkouts = WorkoutPreview.sampleData

    private var stepProgress: Double {
        min(Double(steps) / Double(stepGoal), 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    NavigationLink {
                        StepEntryView(
                            steps: $steps,
                            distance: $distance,
                            calories: $calories,
                            stepGoal: stepGoal
                        )
                    } label: {
                        stepSummary
                    }
                    .buttonStyle(.plain)
                    todayPlan
                    quickActions
                    recentWorkoutSection
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Keep today simple: move, train, recover.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepSummary: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: stepProgress)
                        .stroke(
                            Color.green,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(stepProgress * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)

                        Text("goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 110, height: 110)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps")
                        .font(.headline)

                    Text(steps.formatted())
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(stepGoalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack {
                MetricPill(title: "Distance", value: distanceText)
                MetricPill(title: "Goal", value: stepGoal.formatted())
                MetricPill(title: "Energy", value: "\(calories.formatted()) cal")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var stepGoalText: String {
        let stepsLeft = max(stepGoal - steps, 0)

        if stepsLeft == 0 {
            return "Goal reached today"
        }

        return "\(stepsLeft.formatted()) left today"
    }

    private var distanceText: String {
        "\(distance.formatted(.number.precision(.fractionLength(0...2)))) mi"
    }

    private var weightEntries: [WeightEntry] {
        WeightEntry.decodeList(from: encodedWeightEntries)
    }

    private var latestWeightEntry: WeightEntry? {
        weightEntries.sorted { $0.date > $1.date }.first
    }

    private var weightTileValue: String? {
        guard let latestWeightEntry else {
            return nil
        }

        return "\(latestWeightEntry.weight.formatted(.number.precision(.fractionLength(0...1)))) lb"
    }

    private var weightTileDetail: String? {
        latestWeightEntry?.date.formatted(date: .abbreviated, time: .omitted)
    }

    private var todayPlan: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Focus")
                .font(.headline)

            HStack(spacing: 14) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.14))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upper body strength")
                        .fontWeight(.semibold)

                    Text("45 minutes · moderate intensity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DashboardAction(title: "Workout", systemImage: "plus.circle.fill", tint: .blue)
                NavigationLink {
                    WeightLogView(encodedEntries: $encodedWeightEntries)
                } label: {
                    DashboardAction(
                        title: "Weight",
                        value: weightTileValue ?? "Log weight",
                        detail: weightTileDetail,
                        systemImage: "scalemass.fill",
                        tint: .purple
                    )
                }
                .buttonStyle(.plain)
                DashboardAction(title: "Meal", systemImage: "fork.knife", tint: .orange)
                DashboardAction(title: "Water", systemImage: "drop.fill", tint: .cyan)
            }
        }
    }

    private var recentWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)

                Spacer()

                Button("See All") {
                }
                .font(.subheadline)
            }

            VStack(spacing: 10) {
                ForEach(recentWorkouts) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
    }
}

struct StepEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var steps: Int
    @Binding var distance: Double
    @Binding var calories: Int
    let stepGoal: Int

    @State private var stepText = ""
    @State private var distanceText = ""
    @State private var calorieText = ""

    private var progress: Double {
        guard stepGoal > 0 else {
            return 0
        }

        return min(Double(parsedSteps) / Double(stepGoal), 1)
    }

    private var canSave: Bool {
        isValidNumber(stepText, as: Int.self)
            && isValidNumber(distanceText, as: Double.self)
            && isValidNumber(calorieText, as: Int.self)
            && parsedSteps >= 0
            && parsedDistance >= 0
            && parsedCalories >= 0
    }

    private var parsedSteps: Int {
        Int(stepText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var parsedDistance: Double {
        Double(distanceText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var parsedCalories: Int {
        Int(calorieText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Steps")
                                .font(.headline)

                            Text("\(Int(progress * 100))% of \(stepGoal.formatted())")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    ProgressView(value: progress)
                        .tint(.green)
                }
                .padding(.vertical, 4)
            }

            Section {
                TextField("Steps", text: $stepText)
                    .keyboardType(.numberPad)

                TextField("Distance (mi)", text: $distanceText)
                    .keyboardType(.decimalPad)

                TextField("Calories", text: $calorieText)
                    .keyboardType(.numberPad)
            } header: {
                Text("Today's Total")
            } footer: {
                Text("Enter the totals you want shown on the dashboard tile.")
            }
        }
        .navigationTitle("Step Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            stepText = steps == 0 ? "" : String(steps)
            distanceText = distance == 0 ? "" : distance.formatted(.number.precision(.fractionLength(0...2)))
            calorieText = calories == 0 ? "" : String(calories)
        }
    }

    private func save() {
        steps = parsedSteps
        distance = parsedDistance
        calories = parsedCalories
        dismiss()
    }

    private func isValidNumber<T: LosslessStringConvertible>(_ value: String, as type: T.Type) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty || T(trimmedValue) != nil
    }
}

struct WeightLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var encodedEntries: String
    @State private var weightText = ""
    @State private var selectedDate = Date()

    private var entries: [WeightEntry] {
        WeightEntry.decodeList(from: encodedEntries).sorted { $0.date > $1.date }
    }

    private var parsedWeight: Double? {
        let trimmedValue = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        return Double(trimmedValue)
    }

    private var canSave: Bool {
        guard let parsedWeight else {
            return false
        }

        return parsedWeight > 0
    }

    var body: some View {
        Form {
            Section {
                TextField("Weight (lb)", text: $weightText)
                    .keyboardType(.decimalPad)

                DatePicker("Date", selection: $selectedDate, displayedComponents: [.date])
            } header: {
                Text("Log Weight")
            } footer: {
                Text("Save your current body weight for the selected date.")
            }

            if !entries.isEmpty {
                Section("History") {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))

                            Spacer()

                            Text("\(entry.weight.formatted(.number.precision(.fractionLength(0...1)))) lb")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear {
            if let latestEntry = entries.first {
                selectedDate = Date()
                weightText = latestEntry.weight.formatted(.number.precision(.fractionLength(0...1)))
            }
        }
    }

    private func save() {
        guard let parsedWeight else {
            return
        }

        var updatedEntries = WeightEntry.decodeList(from: encodedEntries)
        let calendar = Calendar.current

        updatedEntries.removeAll {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }

        updatedEntries.append(WeightEntry(date: selectedDate, weight: parsedWeight))
        updatedEntries.sort { $0.date > $1.date }
        encodedEntries = WeightEntry.encodeList(updatedEntries)
        dismiss()
    }
}


struct WeightEntry: Codable, Identifiable {
    var id: Date {
        date
    }

    let date: Date
    let weight: Double

    static func decodeList(from encodedEntries: String) -> [WeightEntry] {
        guard let data = encodedEntries.data(using: .utf8) else {
            return []
        }

        return (try? JSONDecoder().decode([WeightEntry].self, from: data)) ?? []
    }

    static func encodeList(_ entries: [WeightEntry]) -> String {
        guard let data = try? JSONEncoder().encode(entries),
              let encodedEntries = String(data: data, encoding: .utf8) else {
            return "[]"
        }

        return encodedEntries
    }
}


struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DashboardAction: View {
    let title: String
    var value: String?
    var detail: String?
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)

                if let value {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkoutRow: View {
    let workout: WorkoutPreview

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: workout.systemImage)
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(workout.tint.opacity(0.14))
                .foregroundStyle(workout.tint)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .fontWeight(.semibold)

                Text(workout.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(workout.completedAt)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkoutPreview: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let completedAt: String
    let systemImage: String
    let tint: Color

    static let sampleData = [
        WorkoutPreview(
            name: "Push Day",
            detail: "Chest, shoulders, triceps · 52 min",
            completedAt: "Yesterday",
            systemImage: "dumbbell.fill",
            tint: .blue
        ),
        WorkoutPreview(
            name: "Zone 2 Run",
            detail: "3.1 miles · 31 min",
            completedAt: "Sat",
            systemImage: "figure.run",
            tint: .green
        ),
        WorkoutPreview(
            name: "Leg Strength",
            detail: "Squat focus · 48 min",
            completedAt: "Thu",
            systemImage: "figure.strengthtraining.traditional",
            tint: .orange
        )
    ]
}
