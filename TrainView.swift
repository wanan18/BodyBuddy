//
//  TrainView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI
import CoreData

private enum TrainViewMode {
    case cards
    case calendar
}

struct TrainView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<WorkoutSession>

    @State private var mode: TrainViewMode = .cards
    @State private var showingNewSession = false

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    header

                    if mode == .cards {
                        cardsList
                    } else {
                        calendarPlaceholder
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewSession) {
            NewSessionView()
                .environment(\.managedObjectContext, ctx)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("Train")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Spacer()

            Button {
                showingNewSession = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Self.accentGreen)
            }

            modeToggle
        }
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            toggleButton(targetMode: .cards, systemImage: "list.bullet.rectangle")
            toggleButton(targetMode: .calendar, systemImage: "calendar")
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(Self.cardGray)
        .clipShape(Capsule())
    }

    private func toggleButton(targetMode: TrainViewMode, systemImage: String) -> some View {
        let isSelected = (mode == targetMode)
        return Button {
            mode = targetMode
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? Self.accentGreen : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black.opacity(0.7) : Color.clear)
                .clipShape(Capsule())
        }
    }

    // MARK: - Cards

    private var cardsList: some View {
        Group {
            if sessions.isEmpty {
                Text("No sessions yet. Use the + button or Add tab to record your workouts.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.top, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            workoutCard(for: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func workoutCard(for session: WorkoutSession) -> some View {
        let rawSets = (session.sets as? Set<WorkoutSet>) ?? []
        let exerciseNames = Array(Set(rawSets.compactMap { $0.exercise?.name }))

        let title: String
        if exerciseNames.isEmpty {
            title = "Workout"
        } else if exerciseNames.count == 1 {
            title = exerciseNames[0]
        } else {
            title = "\(exerciseNames[0]) + \(exerciseNames.count - 1) more"
        }

        let dateString = formattedDate(session.date)
        let volumeString = formattedVolume(for: session)

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                if let volumeString {
                    Text(volumeString)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Self.accentGreen)
                .frame(width: 3)
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteSession(session)
            } label: {
                Label("Delete Session", systemImage: "trash")
            }
        }
    }

    private func deleteSession(_ session: WorkoutSession) {
        ctx.delete(session)
        try? ctx.save()
    }

    // MARK: - Calendar placeholder

    private var calendarPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar view")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Calendar layout coming soon. You’ll be able to tap a day to see that day’s workouts.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top, 4)
        }
        .padding(.top, 24)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Unknown date" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func formattedVolume(for session: WorkoutSession) -> String? {
        guard let rawSets = session.sets as? Set<WorkoutSet>, !rawSets.isEmpty else {
            return nil
        }

        let sets = Array(rawSets)
        let totalVolume = sets.reduce(0.0) { partial, set in
            partial + (Double(set.reps) * set.weight)
        }
        return "Volume: \(Int(totalVolume)) • \(sets.count) sets"
    }
}
