//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI
import Combine
import Supabase

struct HomeView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            selectedContent

            FloatingNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .exerciseLog:
            ExerciseLogView()
        case .statistics:
            StatisticsView()
        case .account:
            AccountView()
        }
    }
}

private enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case exerciseLog
    case statistics
    case account

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .dashboard:
            "Home"
        case .exerciseLog:
            "Log"
        case .statistics:
            "Stats"
        case .account:
            "Account"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "house.fill"
        case .exerciseLog:
            "dumbbell.fill"
        case .statistics:
            "chart.xyaxis.line"
        case .account:
            "person.crop.circle.fill"
        }
    }
}

private struct FloatingNavigationBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(height: 22)

                        Text(tab.title)
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color(.separator).opacity(0.28), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 7)
    }
}

private struct DashboardView: View {
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

private struct StepEntryView: View {
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

private struct WeightLogView: View {
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

private struct ExerciseLogView: View {
    @StateObject private var store = WorkoutLogStore()
    @State private var selectedMode: ExerciseLogMode = .list
    @State private var selectedCalendarDate = Date()
    @State private var navigationPath: [UUID] = []

    private var sortedSessions: [WorkoutSession] {
        store.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                if store.isLoading {
                    ProgressView("Loading sessions...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    if store.sessions.isEmpty {
                        emptyState
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        switch selectedMode {
                        case .list:
                            sessionList
                        case .calendar:
                            calendarView
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaPadding(.bottom, 108)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercise Log")
            .navigationDestination(for: UUID.self) { sessionID in
                if let index = store.sessions.firstIndex(where: { $0.id == sessionID }) {
                    SessionEditorView(
                        session: $store.sessions[index],
                        onSaveDetails: { session in
                            await store.saveSessionDetails(session)
                        },
                        onSave: { session in
                            await store.saveSession(session)
                        }
                    )
                } else {
                    Text("Session not found")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("View", selection: $selectedMode) {
                        ForEach(ExerciseLogMode.allCases) { mode in
                            Image(systemName: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 112)
                }
            }
            .task {
                await store.loadSessions()
            }
            .refreshable {
                await store.loadSessions()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Build each workout from sessions, exercises, and performance notes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                let newSession = WorkoutSession.empty
                store.sessions.append(newSession)
                navigationPath.append(newSession.id)
                Task {
                    await store.saveSession(newSession)
                }
            } label: {
                Label("Create Session", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.title2)
                .foregroundStyle(.blue)

            Text("No sessions yet")
                .font(.headline)

            Text("Create your first session and your exercises, sets, reps, weight, and RPE will save to Supabase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var sessionList: some View {
        Section("Recent Sessions") {
            ForEach(sortedSessions) { session in
                Button {
                    navigationPath.append(session.id)
                } label: {
                    SessionRow(session: session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    deleteSessionButton(for: session)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
    }

    private var calendarView: some View {
        Section {
            WorkoutCalendarView(
                sessions: store.sessions,
                selectedDate: $selectedCalendarDate
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            let sessionsForDay = store.sessions.filter {
                Calendar.current.isDate($0.date, inSameDayAs: selectedCalendarDate)
            }
            .sorted { $0.date > $1.date }

            if sessionsForDay.isEmpty {
                Text("No sessions logged for this date.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(sessionsForDay) { session in
                    Button {
                        navigationPath.append(session.id)
                    } label: {
                        SessionRow(session: session)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        deleteSessionButton(for: session)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        } header: {
            Text("Sessions")
        }
    }

    private func deleteSessionButton(for session: WorkoutSession) -> some View {
        Button(role: .destructive) {
            deleteSession(session)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        store.sessions.removeAll { $0.id == session.id }

        Task {
            await store.deleteSession(session)
        }
    }
}

private enum ExerciseLogMode: String, CaseIterable, Identifiable {
    case list
    case calendar

    var id: String {
        rawValue
    }

    var systemImage: String {
        switch self {
        case .list:
            "list.bullet"
        case .calendar:
            "calendar"
        }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(session.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)

                Text(session.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, height: 52)
            .background(Color.blue.opacity(0.14))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(session.title)
                    .fontWeight(.semibold)

                Text("\(session.exercises.count) exercises · \(session.totalSets) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct WorkoutCalendarView: View {
    let sessions: [WorkoutSession]
    @Binding var selectedDate: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = Calendar.current.shortWeekdaySymbols

    private var visibleDates: [Date?] {
        let calendar = Calendar.current
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
            let dayRange = calendar.range(of: .day, in: .month, for: selectedDate)
        else {
            return []
        }

        let weekdayOffset = calendar.component(.weekday, from: monthInterval.start) - 1
        let padding = Array<Date?>(repeating: nil, count: weekdayOffset)
        let days = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start)
        }

        return padding + days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedDate.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)

                Spacer()

                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(visibleDates.enumerated()), id: \.offset) { _, date in
                    if let date {
                        Button {
                            selectedDate = date
                        } label: {
                            CalendarDayCell(
                                date: date,
                                isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                                hasSession: sessions.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasSession: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.day()))
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)

            Circle()
                .fill(hasSession ? Color.green : Color.clear)
                .frame(width: 5, height: 5)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(isSelected ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SessionEditorView: View {
    @Binding var session: WorkoutSession
    let onSaveDetails: (WorkoutSession) async -> Void
    let onSave: (WorkoutSession) async -> Void
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
                ForEach($session.exercises) { $exercise in
                    NavigationLink {
                        ExerciseEditorView(exercise: $exercise) {
                            await onSave(session)
                        }
                    } label: {
                        ExerciseSummaryRow(exercise: exercise)
                    }
                }
                .onDelete { offsets in
                    session.exercises.remove(atOffsets: offsets)
                    Task {
                        await onSave(session)
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
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerView { exercise in
                session.exercises.append(exercise)
                Task {
                    await onSave(session)
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

private struct ExerciseSummaryRow: View {
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
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ExerciseEditorView: View {
    @Binding var exercise: LoggedExercise
    let onSave: () async -> Void
    @State private var isShowingExercisePicker = false

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
                        exercise.cardio.laps.remove(atOffsets: offsets)
                        Task {
                            await onSave()
                        }
                    }

                    Button {
                        exercise.cardio.laps.append(.empty)
                        Task {
                            await onSave()
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
                        guard exercise.sets.count > offsets.count else {
                            exercise.sets = [.empty]
                            Task {
                                await onSave()
                            }
                            return
                        }
                        exercise.sets.remove(atOffsets: offsets)
                        Task {
                            await onSave()
                        }
                    }

                    Button {
                        exercise.sets.append(.empty)
                        Task {
                            await onSave()
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
        .sheet(isPresented: $isShowingExercisePicker) {
            ExercisePickerView { selectedExercise in
                exercise.applyLibrarySelection(selectedExercise)
                Task {
                    await onSave()
                }
            }
        }
        .onDisappear {
            Task {
                await onSave()
            }
        }
    }
}

private struct ExercisePickerView: View {
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

private struct LiftingExerciseLibraryView: View {
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

private struct MuscleGroupExerciseListView: View {
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

private struct CardioExerciseLibraryView: View {
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

private struct ExerciseLibraryTile: View {
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

private struct ExerciseLibraryRow: View {
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

private struct CreateUserExerciseView: View {
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

private struct ExerciseSetEditorRow: View {
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

private struct CardioMetricField: View {
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

private struct CardioLapEditorRow: View {
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

private struct DistanceUnitField: View {
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

private struct DurationField: View {
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

private enum DurationComponent {
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

private struct CompactDecimalField: View {
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

private struct CompactIntegerField: View {
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

@MainActor
private final class WorkoutLogStore: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

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
        isSaving = true
        errorMessage = nil

        do {
            try await upsertSessionDetails(session)
            try await replaceExercises(for: session)
        } catch {
            errorMessage = "Could not save session: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func saveSessionDetails(_ session: WorkoutSession) async {
        isSaving = true
        errorMessage = nil

        do {
            try await upsertSessionDetails(session)
        } catch {
            errorMessage = "Could not save session: \(error.localizedDescription)"
        }

        isSaving = false
    }

    func deleteSession(_ session: WorkoutSession) async {
        isSaving = true
        errorMessage = nil

        do {
            try await client
                .from("workout_sessions")
                .delete(returning: .minimal)
                .eq("id", value: session.id)
                .execute()
        } catch {
            errorMessage = "Could not delete session: \(error.localizedDescription)"
            await loadSessions()
        }

        isSaving = false
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

    private func replaceExercises(for session: WorkoutSession) async throws {
        let existingExercises = try await loadExercises(sessionIDs: [session.id])
        let existingExerciseIDs = existingExercises.map(\.id)

        if !existingExerciseIDs.isEmpty {
            try await client
                .from("workout_sets")
                .delete(returning: .minimal)
                .in("exercise_id", values: filterValues(existingExerciseIDs))
                .execute()

            try await client
                .from("workout_cardio_laps")
                .delete(returning: .minimal)
                .in("exercise_id", values: filterValues(existingExerciseIDs))
                .execute()
        }

        try await client
            .from("workout_exercises")
            .delete(returning: .minimal)
            .eq("session_id", value: session.id)
            .execute()

        let exerciseUpserts = session.exercises.enumerated().map { index, exercise in
            WorkoutExerciseUpsert(
                id: exercise.id,
                sessionID: session.id,
                name: exercise.name,
                exerciseType: exercise.kind.rawValue,
                notes: exercise.notes.nilIfBlank,
                position: index,
                durationSeconds: exercise.cardio.durationSeconds,
                distanceMeters: exercise.cardio.distanceMeters,
                distanceUnit: exercise.cardio.distanceUnit.rawValue,
                caloriesBurned: exercise.cardio.caloriesBurned
            )
        }

        guard !exerciseUpserts.isEmpty else {
            return
        }

        try await client
            .from("workout_exercises")
            .insert(exerciseUpserts, returning: .minimal)
            .execute()

        let setUpserts = session.exercises.filter { $0.kind == .lifting }.flatMap { exercise in
            exercise.sets.enumerated().map { index, set in
                WorkoutSetUpsert(
                    id: set.id,
                    exerciseID: exercise.id,
                    setNumber: index,
                    reps: set.reps,
                    weight: set.weight,
                    rpe: set.rpe
                )
            }
        }

        if !setUpserts.isEmpty {
            try await client
                .from("workout_sets")
                .insert(setUpserts, returning: .minimal)
                .execute()
        }

        let lapUpserts = session.exercises.filter { $0.kind == .cardio }.flatMap { exercise in
            exercise.cardio.laps.enumerated().map { index, lap in
                WorkoutCardioLapUpsert(
                    id: lap.id,
                    exerciseID: exercise.id,
                    lapNumber: index,
                    distanceMeters: lap.distanceMeters,
                    distanceUnit: lap.distanceUnit.rawValue,
                    timeSeconds: lap.timeSeconds
                )
            }
        }

        guard !lapUpserts.isEmpty else {
            return
        }

        try await client
            .from("workout_cardio_laps")
            .insert(lapUpserts, returning: .minimal)
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

private enum SupabaseDateCoding {
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

private struct WorkoutSessionRecord: Decodable {
    let id: UUID
    let userID: UUID
    let title: String
    let sessionDate: String
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case sessionDate = "session_date"
        case notes
    }
}

private struct WorkoutSessionUpsert: Encodable {
    let id: UUID
    let userID: UUID
    let title: String
    let sessionDate: String
    let notes: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case title
        case sessionDate = "session_date"
        case notes
    }
}

private struct WorkoutExerciseRecord: Decodable {
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

    private enum CodingKeys: String, CodingKey {
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

private struct WorkoutExerciseUpsert: Encodable {
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

    private enum CodingKeys: String, CodingKey {
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

private struct WorkoutSetRecord: Decodable {
    let id: UUID
    let exerciseID: UUID
    let setNumber: Int
    let reps: Double?
    let weight: Double?
    let rpe: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weight
        case rpe
    }
}

private struct WorkoutSetUpsert: Encodable {
    let id: UUID
    let exerciseID: UUID
    let setNumber: Int
    let reps: Double?
    let weight: Double?
    let rpe: Double?

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case setNumber = "set_number"
        case reps
        case weight
        case rpe
    }
}

private struct WorkoutCardioLapRecord: Decodable {
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

    private enum CodingKeys: String, CodingKey {
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

private struct WorkoutCardioLapUpsert: Encodable {
    let id: UUID
    let exerciseID: UUID
    let lapNumber: Int
    let distanceMeters: Double?
    let distanceUnit: String
    let timeSeconds: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case exerciseID = "exercise_id"
        case lapNumber = "lap_number"
        case distanceMeters = "distance_meters"
        case distanceUnit = "distance_unit"
        case timeSeconds = "time_seconds"
    }
}

@MainActor
private final class UserExerciseLibraryStore: ObservableObject {
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

private struct UserExercise: Identifiable {
    let id: UUID
    let name: String
    let muscleGroups: [String]
}

private struct UserExerciseRecord: Decodable {
    let id: UUID
    let userID: UUID
    let name: String
    let muscleGroups: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case muscleGroups = "muscle_groups"
    }
}

private struct UserExerciseUpsert: Encodable {
    let id: UUID
    let userID: UUID
    let name: String
    let muscleGroups: [String]

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case muscleGroups = "muscle_groups"
    }
}

private enum CardioExerciseLibrary {
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

private enum ExerciseLibrary {
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

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct WeightEntry: Codable, Identifiable {
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

private struct WorkoutSession: Identifiable {
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
            exercises: [.empty],
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

private struct LoggedExercise: Identifiable {
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

private enum ExerciseKind: String {
    case lifting
    case cardio
}

private enum DistanceUnit: String, CaseIterable, Identifiable {
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
}

private struct CardioLog {
    var durationSeconds: Int?
    var distanceMeters: Double?
    var distanceUnit: DistanceUnit
    var caloriesBurned: Double?
    var laps: [CardioLap]

    var summary: String {
        let durationText = durationSeconds.map { Self.formatDuration($0) }
        let distanceText = distanceMeters.map { "\(distanceUnit.value(fromMeters: $0).formatted(.number.precision(.fractionLength(0...2)))) \(distanceUnit.rawValue)" }
        let calorieText = caloriesBurned.map { "\($0.formatted(.number.precision(.fractionLength(0...0)))) cal" }
        let values = [durationText, distanceText, calorieText].compactMap { $0 }

        if values.isEmpty {
            return laps.isEmpty ? "Duration, distance, and calories" : "\(laps.count) laps"
        }

        if laps.isEmpty {
            return values.joined(separator: " · ")
        }

        return "\(values.joined(separator: " · ")) · \(laps.count) laps"
    }

    static let empty = CardioLog(durationSeconds: nil, distanceMeters: nil, distanceUnit: .mile, caloriesBurned: nil, laps: [])
    static let starter = CardioLog(durationSeconds: nil, distanceMeters: nil, distanceUnit: .mile, caloriesBurned: nil, laps: [.empty])

    private static func formatDuration(_ totalSeconds: Int) -> String {
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
}

private struct CardioLap: Identifiable {
    let id: UUID
    var distanceMeters: Double?
    var distanceUnit: DistanceUnit
    var timeSeconds: Int?

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

private struct LoggedSet: Identifiable {
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

private struct StatisticsView: View {
    private let metrics = [
        ("Workouts", "12"),
        ("Steps Avg", "8.1k"),
        ("Active Time", "5h 22m"),
        ("Calories", "3,420")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("This Week")
                        .font(.title2)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(metrics, id: \.0) { metric in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(metric.0)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(metric.1)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trends")
                            .font(.headline)

                        Text("Step, workout, weight, and consistency charts will live here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }
}

private struct AccountView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Manage goals, connected services, and account settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        AccountRow(title: "Health Access", systemImage: "heart.fill")
                        AccountRow(title: "Goals", systemImage: "target")
                        AccountRow(title: "Notifications", systemImage: "bell.fill")
                    }

                    Button(role: .destructive) {
                        Task {
                            await appState.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Account")
        }
    }
}

private struct AccountRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.14))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MetricPill: View {
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

private struct DashboardAction: View {
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

private struct WorkoutRow: View {
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

private struct WorkoutPreview: Identifiable {
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
