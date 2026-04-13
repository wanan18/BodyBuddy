//
//  HomeView.swift
//  BodyBuddy
//
//  Created by William Anan on 3/23/26.
//

import SwiftUI

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

    private let steps = 7428
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
                    stepSummary
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

                    Text("\((stepGoal - steps).formatted()) left today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack {
                MetricPill(title: "Distance", value: "3.4 mi")
                MetricPill(title: "Active", value: "46 min")
                MetricPill(title: "Energy", value: "410 cal")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                DashboardAction(title: "Weight", systemImage: "scalemass.fill", tint: .purple)
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

private struct ExerciseLogView: View {
    @State private var sessions = WorkoutSession.sampleData
    @State private var selectedMode: ExerciseLogMode = .list
    @State private var selectedCalendarDate = Date()
    @State private var navigationPath: [UUID] = []

    private var sortedSessions: [WorkoutSession] {
        sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    switch selectedMode {
                    case .list:
                        sessionList
                    case .calendar:
                        calendarView
                    }
                }
                .padding()
                .padding(.bottom, 108)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercise Log")
            .navigationDestination(for: UUID.self) { sessionID in
                if let index = sessions.firstIndex(where: { $0.id == sessionID }) {
                    SessionEditorView(session: $sessions[index])
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
                sessions.append(newSession)
                navigationPath.append(newSession.id)
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

    private var sessionList: some View {
        VStack(spacing: 10) {
            ForEach(sortedSessions) { session in
                NavigationLink(value: session.id) {
                    SessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            WorkoutCalendarView(
                sessions: sessions,
                selectedDate: $selectedCalendarDate
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Sessions")
                    .font(.headline)

                let sessionsForDay = sessions.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: selectedCalendarDate)
                }
                .sorted { $0.date > $1.date }

                if sessionsForDay.isEmpty {
                    Text("No sessions logged for this date.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ForEach(sessionsForDay) { session in
                        NavigationLink(value: session.id) {
                            SessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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

    var body: some View {
        Form {
            Section("Session") {
                TextField("Name", text: $session.title)
                DatePicker("Date", selection: $session.date, displayedComponents: [.date])
            }

            Section("Exercises") {
                ForEach($session.exercises) { $exercise in
                    NavigationLink {
                        ExerciseEditorView(exercise: $exercise)
                    } label: {
                        ExerciseSummaryRow(exercise: exercise)
                    }
                }
                .onDelete { offsets in
                    session.exercises.remove(atOffsets: offsets)
                }

                Button {
                    session.exercises.append(.empty)
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            }

            Section("Notes") {
                TextEditor(text: $session.notes)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle(session.title.isEmpty ? "Session" : session.title)
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

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                    Text("Set \(index + 1): \(set.previewText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ExerciseEditorView: View {
    @Binding var exercise: LoggedExercise

    var body: some View {
        Form {
            Section("Exercise") {
                TextField("Name", text: $exercise.name)
            }

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
                        return
                    }
                    exercise.sets.remove(atOffsets: offsets)
                }

                Button {
                    exercise.sets.append(.empty)
                } label: {
                    Label("Add Blank Set", systemImage: "plus.circle.fill")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Sets")
            } footer: {
                Text("Swipe a set to delete it. New sets start blank so you can log as you go.")
            }

            Section("Additional Info") {
                TextEditor(text: $exercise.notes)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle(exercise.name.isEmpty ? "Exercise" : exercise.name)
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

            CompactNumberField(placeholder: "0", value: $set.reps)
                .frame(width: 70)

            CompactDecimalField(placeholder: "-", value: $set.rpe, unit: nil)
                .frame(width: 64)
        }
        .padding(.vertical, 2)
    }
}

private struct CompactNumberField: View {
    let placeholder: String
    @Binding var value: Int?

    var body: some View {
        TextField(placeholder, text: textBinding)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
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
                    .frame(width: 14, alignment: .trailing)
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
    var sets: [LoggedSet]
    var notes: String

    var topWeight: Double {
        sets.compactMap(\.weight).max() ?? 0
    }

    var summary: String {
        if topWeight == 0 {
            return "\(sets.count) sets"
        }

        return "\(sets.count) sets · top \(topWeight.formatted()) lb"
    }

    init(id: UUID = UUID(), name: String, sets: [LoggedSet], notes: String) {
        self.id = id
        self.name = name
        self.sets = sets
        self.notes = notes
    }

    static var empty: LoggedExercise {
        LoggedExercise(name: "New Exercise", sets: [.empty], notes: "")
    }
}

private struct LoggedSet: Identifiable {
    let id: UUID
    var reps: Int?
    var weight: Double?
    var rpe: Double?

    var previewText: String {
        let weightText = weight.map { "\($0.formatted()) lb" } ?? "weight"
        let repsText = reps.map { "\($0) reps" } ?? "reps"

        if let rpe {
            return "\(weightText) × \(repsText) · RPE \(rpe.formatted(.number.precision(.fractionLength(0...1))))"
        }

        return "\(weightText) × \(repsText)"
    }

    init(id: UUID = UUID(), reps: Int? = nil, weight: Double? = nil, rpe: Double? = nil) {
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
    let systemImage: String
    let tint: Color

    var body: some View {
        Button {
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)

                Text(title)
                    .fontWeight(.medium)

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
