import SwiftUI

struct ExerciseLogView: View {
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
                        saveStatus: store.saveStatus,
                        onSaveDetails: { session in
                            await store.saveSessionDetails(session)
                        },
                        onSaveExercise: { session, exercise, position in
                            await store.saveExercise(exercise, sessionID: session.id, position: position)
                        },
                        onDeleteExercise: { exercise in
                            await store.deleteExercise(exercise)
                        },
                        onSaveSet: { set, exerciseID, setNumber in
                            await store.saveSet(set, exerciseID: exerciseID, setNumber: setNumber)
                        },
                        onDeleteSet: { set in
                            await store.deleteSet(set)
                        },
                        onSaveCardioLap: { lap, exerciseID, lapNumber in
                            await store.saveCardioLap(lap, exerciseID: exerciseID, lapNumber: lapNumber)
                        },
                        onDeleteCardioLap: { lap in
                            await store.deleteCardioLap(lap)
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
                    await store.saveSessionDetails(newSession)
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

struct SaveStatusIndicator: View {
    let status: SaveStatus

    var body: some View {
        switch status {
        case .idle:
            EmptyView()
        case .saving:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.mini)

                Text("Saving")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .saved:
            Label("Saved", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .failed:
            Label("Could not save", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }
}

enum ExerciseLogMode: String, CaseIterable, Identifiable {
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

struct SessionRow: View {
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

struct WorkoutCalendarView: View {
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

struct CalendarDayCell: View {
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
