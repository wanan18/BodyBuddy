//
//  SessionsListView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//


import SwiftUI

struct SessionsListView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showCalendar = false
    @State private var newlyCreatedSession: WorkoutModel? = nil   // for sheet presentation

    // Date formatter for section headers
    private static let headerDF: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    var body: some View {
        NavigationStack {
            VStack {
                // Toggle between List and Calendar
                Picker("", selection: $showCalendar) {
                    Text("List").tag(false)
                    Text("Calendar").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if showCalendar {
                    SessionsCalendarView()
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Create an empty session for today and open it
                        let s = WorkoutModel(id: UUID(), date: Date(), notes: nil, sets: [])
                        store.addWorkout(s)
                        newlyCreatedSession = s
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            // Present the new session in a sheet
            .sheet(item: $newlyCreatedSession) { session in
                NavigationStack {
                    InMemorySessionDetailView(session: session)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        List {
            ForEach(sessionsByDay, id: \.day) { group in
                Section(Self.headerDF.string(from: group.day)) {
                    ForEach(group.items) { session in
                        NavigationLink(
                            destination: InMemorySessionDetailView(session: session),
                            label: { SessionRow(session: session) }
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouped Sessions by Day

    private var sessionsByDay: [(day: Date, items: [WorkoutModel])] {
        // Group sessions by start-of-day
        let grouped = Dictionary(grouping: store.workouts) {
            Calendar.current.startOfDay(for: $0.date)
        }

        // Sort days (newest first)
        let sortedDays = grouped.keys.sorted(by: >)

        // Return day + sorted sessions for that day
        return sortedDays.map { day in
            let items = (grouped[day] ?? []).sorted { $0.date > $1.date }
            return (day: day, items: items)
        }
    }
}
