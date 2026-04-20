import SwiftUI

struct ExerciseEditorView: View {
    @Binding var exercise: LoggedExercise
    let saveStatus: SaveStatus
    let position: Int
    let sessionID: UUID
    let onSaveExercise: (LoggedExercise, Int) async -> Void
    let onSaveSet: (LoggedSet, UUID, Int) async -> Void
    let onDeleteSet: (LoggedSet) async -> Void
    let onSaveCardioLap: (CardioLap, UUID, Int) async -> Void
    let onDeleteCardioLap: (CardioLap) async -> Void
    @State private var isShowingExercisePicker = false
    @State private var exerciseSaveTask: Task<Void, Never>?
    @State private var setSaveTasks: [UUID: Task<Void, Never>] = [:]
    @State private var lapSaveTasks: [UUID: Task<Void, Never>] = [:]
    @State private var lastSets: [LoggedSet] = []
    @State private var lastLaps: [CardioLap] = []

    var body: some View {
        Form {
            Section("Exercise") {
                TextField("Name", text: $exercise.name)

                Button {
                    isShowingExercisePicker = true
                } label: {
                    Label("Choose From Library", systemImage: "magnifyingglass")
                }
            }

            if exercise.kind == .cardio {
                Section {
                    DurationField(title: "Duration", totalSeconds: $exercise.cardio.durationSeconds)

                    DistanceUnitField(
                        title: "Distance",
                        meters: $exercise.cardio.distanceMeters,
                        unit: $exercise.cardio.distanceUnit
                    )

                    CardioMetricField(title: "Calories Burned", value: $exercise.cardio.caloriesBurned, unit: "cal")
                } header: {
                    Text("Cardio")
                } footer: {
                    Text("Log the totals for this cardio exercise.")
                }

                Section {
                    ForEach(exercise.cardio.laps.indices, id: \.self) { index in
                        CardioLapEditorRow(
                            lap: $exercise.cardio.laps[index],
                            lapNumber: index + 1
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete { offsets in
                        let deletedLaps = offsets.map { exercise.cardio.laps[$0] }
                        exercise.cardio.laps.remove(atOffsets: offsets)
                        lastLaps = exercise.cardio.laps

                        Task {
                            for lap in deletedLaps {
                                await onDeleteCardioLap(lap)
                            }

                            for (index, lap) in exercise.cardio.laps.enumerated() {
                                await onSaveCardioLap(lap, exercise.id, index)
                            }
                        }
                    }

                    Button {
                        let newLap = CardioLap.empty
                        exercise.cardio.laps.append(newLap)
                        lastLaps = exercise.cardio.laps

                        Task {
                            await onSaveCardioLap(newLap, exercise.id, exercise.cardio.laps.count - 1)
                        }
                    } label: {
                        Label("Add Lap", systemImage: "plus.circle.fill")
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Laps")
                } footer: {
                    Text("Swipe a lap to delete it.")
                }
            } else {
                Section {
                    HStack(spacing: 8) {
                        Text("Set")
                            .frame(width: 26, alignment: .leading)

                        Text("Weight")
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Reps")
                            .frame(width: 70, alignment: .leading)

                        Text("RPE")
                            .frame(width: 64, alignment: .leading)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))

                    ForEach(exercise.sets.indices, id: \.self) { index in
                        ExerciseSetEditorRow(
                            set: $exercise.sets[index],
                            setNumber: index + 1
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .onDelete { offsets in
                        let deletedSets = offsets.map { exercise.sets[$0] }

                        guard exercise.sets.count > offsets.count else {
                            exercise.sets = [.empty]
                            lastSets = exercise.sets

                            Task {
                                for set in deletedSets {
                                    await onDeleteSet(set)
                                }

                                if let firstSet = exercise.sets.first {
                                    await onSaveSet(firstSet, exercise.id, 0)
                                }
                            }
                            return
                        }

                        exercise.sets.remove(atOffsets: offsets)
                        lastSets = exercise.sets

                        Task {
                            for set in deletedSets {
                                await onDeleteSet(set)
                            }

                            for (index, set) in exercise.sets.enumerated() {
                                await onSaveSet(set, exercise.id, index)
                            }
                        }
                    }

                    Button {
                        let newSet = LoggedSet.empty
                        exercise.sets.append(newSet)
                        lastSets = exercise.sets

                        Task {
                            await onSaveSet(newSet, exercise.id, exercise.sets.count - 1)
                        }
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Sets")
                } footer: {
                    Text("Swipe a set to delete it. New sets start blank so you can log as you go.")
                }
            }

            Section("Additional Info") {
                TextEditor(text: $exercise.notes)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle(exercise.name.isEmpty ? "Exercise" : exercise.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SaveStatusIndicator(status: saveStatus)
            }
        }
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerView { selectedExercise in
                exercise.applyLibrarySelection(selectedExercise)
                lastSets = exercise.sets
                lastLaps = exercise.cardio.laps

                Task {
                    await saveCurrentExerciseTree()
                }
            }
        }
        .onAppear {
            lastSets = exercise.sets
            lastLaps = exercise.cardio.laps
        }
        .onChange(of: exercise.name) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.kind) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.notes) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.cardio.durationSeconds) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.cardio.distanceMeters) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.cardio.distanceUnit) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.cardio.caloriesBurned) {
            scheduleExerciseSave()
        }
        .onChange(of: exercise.sets) { _, newSets in
            scheduleChangedSetSaves(newSets)
            lastSets = newSets
        }
        .onChange(of: exercise.cardio.laps) { _, newLaps in
            scheduleChangedLapSaves(newLaps)
            lastLaps = newLaps
        }
        .onDisappear {
            cancelPendingSaves()

            Task {
                await saveCurrentExerciseTree()
            }
        }
    }

    private func scheduleExerciseSave() {
        let exerciseToSave = exercise
        let positionToSave = position

        exerciseSaveTask?.cancel()
        exerciseSaveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else {
                return
            }

            await onSaveExercise(exerciseToSave, positionToSave)
        }
    }

    private func scheduleChangedSetSaves(_ newSets: [LoggedSet]) {
        for (index, set) in newSets.enumerated() {
            guard lastSets.first(where: { $0.id == set.id }) != set else {
                continue
            }

            scheduleSetSave(set, setNumber: index)
        }
    }

    private func scheduleSetSave(_ set: LoggedSet, setNumber: Int) {
        let exerciseID = exercise.id
        setSaveTasks[set.id]?.cancel()
        setSaveTasks[set.id] = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else {
                return
            }

            await onSaveSet(set, exerciseID, setNumber)
        }
    }

    private func scheduleChangedLapSaves(_ newLaps: [CardioLap]) {
        for (index, lap) in newLaps.enumerated() {
            guard lastLaps.first(where: { $0.id == lap.id }) != lap else {
                continue
            }

            scheduleLapSave(lap, lapNumber: index)
        }
    }

    private func scheduleLapSave(_ lap: CardioLap, lapNumber: Int) {
        let exerciseID = exercise.id
        lapSaveTasks[lap.id]?.cancel()
        lapSaveTasks[lap.id] = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else {
                return
            }

            await onSaveCardioLap(lap, exerciseID, lapNumber)
        }
    }

    private func cancelPendingSaves() {
        exerciseSaveTask?.cancel()
        setSaveTasks.values.forEach { $0.cancel() }
        lapSaveTasks.values.forEach { $0.cancel() }
    }

    private func saveCurrentExerciseTree() async {
        await onSaveExercise(exercise, position)

        if exercise.kind == .lifting {
            for (index, set) in exercise.sets.enumerated() {
                await onSaveSet(set, exercise.id, index)
            }
        } else {
            for (index, lap) in exercise.cardio.laps.enumerated() {
                await onSaveCardioLap(lap, exercise.id, index)
            }
        }
    }
}


struct ExerciseSetEditorRow: View {
    @Binding var set: LoggedSet
    let setNumber: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .leading)

            CompactDecimalField(placeholder: "0", value: $set.weight, unit: "lb")
                .frame(maxWidth: .infinity)

            CompactDecimalField(placeholder: "0", value: $set.reps, unit: nil)
                .frame(width: 70)

            CompactDecimalField(placeholder: "-", value: $set.rpe, unit: nil)
                .frame(width: 64)
        }
        .padding(.vertical, 2)
    }
}

struct CardioMetricField: View {
    let title: String
    @Binding var value: Double?
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            CompactDecimalField(placeholder: "0", value: $value, unit: unit)
                .frame(width: 132)
        }
    }
}

struct CardioLapEditorRow: View {
    @Binding var lap: CardioLap
    let lapNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lap \(lapNumber)")
                .font(.subheadline)
                .fontWeight(.semibold)

            DistanceUnitField(
                title: "Distance",
                meters: $lap.distanceMeters,
                unit: $lap.distanceUnit
            )

            DurationField(title: "Time", totalSeconds: $lap.timeSeconds)
        }
        .padding(.vertical, 6)
    }
}

struct DistanceUnitField: View {
    let title: String
    @Binding var meters: Double?
    @Binding var unit: DistanceUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                CompactDecimalField(placeholder: "0", value: displayValueBinding, unit: nil)
                    .frame(maxWidth: .infinity)

                Picker("Unit", selection: $unit) {
                    ForEach(DistanceUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 132)
            }
        }
    }

    private var displayValueBinding: Binding<Double?> {
        Binding(
            get: {
                guard let meters else {
                    return nil
                }

                return unit.value(fromMeters: meters)
            },
            set: { newValue in
                meters = newValue.map { unit.meters(from: $0) }
            }
        )
    }
}

struct DurationField: View {
    let title: String
    @Binding var totalSeconds: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                CompactIntegerField(placeholder: "0", value: hoursBinding, unit: "hr")
                CompactIntegerField(placeholder: "0", value: minutesBinding, unit: "min")
                CompactIntegerField(placeholder: "0", value: secondsBinding, unit: "sec")
            }
        }
    }

    private var hoursBinding: Binding<Int?> {
        durationComponentBinding(component: .hours)
    }

    private var minutesBinding: Binding<Int?> {
        durationComponentBinding(component: .minutes)
    }

    private var secondsBinding: Binding<Int?> {
        durationComponentBinding(component: .seconds)
    }

    private func durationComponentBinding(component: DurationComponent) -> Binding<Int?> {
        Binding(
            get: {
                component.value(from: totalSeconds ?? 0)
            },
            set: { newValue in
                setDurationComponent(component, to: newValue ?? 0)
            }
        )
    }

    private func setDurationComponent(_ component: DurationComponent, to value: Int) {
        let currentSeconds = max(totalSeconds ?? 0, 0)
        let hours = DurationComponent.hours.value(from: currentSeconds) ?? 0
        let minutes = DurationComponent.minutes.value(from: currentSeconds) ?? 0
        let seconds = DurationComponent.seconds.value(from: currentSeconds) ?? 0
        let boundedValue = max(value, 0)

        switch component {
        case .hours:
            totalSeconds = boundedValue * 3600 + minutes * 60 + seconds
        case .minutes:
            totalSeconds = hours * 3600 + min(boundedValue, 59) * 60 + seconds
        case .seconds:
            totalSeconds = hours * 3600 + minutes * 60 + min(boundedValue, 59)
        }

        if totalSeconds == 0 {
            totalSeconds = nil
        }
    }
}

enum DurationComponent {
    case hours
    case minutes
    case seconds

    func value(from totalSeconds: Int) -> Int? {
        let safeSeconds = max(totalSeconds, 0)
        let value: Int

        switch self {
        case .hours:
            value = safeSeconds / 3600
        case .minutes:
            value = (safeSeconds % 3600) / 60
        case .seconds:
            value = safeSeconds % 60
        }

        return value == 0 ? nil : value
    }
}

struct CompactDecimalField: View {
    let placeholder: String
    @Binding var value: Double?
    let unit: String?

    var body: some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: textBinding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)

            if let unit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: unit.count > 2 ? 24 : 16, alignment: .trailing)
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var textBinding: Binding<String> {
        Binding(
            get: {
                guard let value else {
                    return ""
                }

                return value.formatted(.number.precision(.fractionLength(0...2)))
            },
            set: { newValue in
                let trimmedValue = newValue.trimmingCharacters(in: .whitespaces)
                value = trimmedValue.isEmpty ? nil : Double(trimmedValue)
            }
        )
    }
}

struct CompactIntegerField: View {
    let placeholder: String
    @Binding var value: Int?
    let unit: String

    var body: some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: textBinding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 24, alignment: .trailing)
        }
        .frame(height: 36)
        .padding(.horizontal, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var textBinding: Binding<String> {
        Binding(
            get: {
                value.map(String.init) ?? ""
            },
            set: { newValue in
                let trimmedValue = newValue.trimmingCharacters(in: .whitespaces)
                value = trimmedValue.isEmpty ? nil : Int(trimmedValue)
            }
        )
    }
}
