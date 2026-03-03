//
//  ProgressChartsView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI
import CoreData

struct ProgressChartsView: View {
    @Environment(\.managedObjectContext) private var ctx

    // Fetch sessions oldest → newest
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
        animation: .default
    )
    private var sessions: FetchedResults<WorkoutSession>

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray   = Color(red: 20/255, green: 20/255, blue: 20/255)

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if sessions.isEmpty {
                    Text("No training data yet. Log some workouts to see your progress here.")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 8)
                } else {
                    volumeCard
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Track how your training volume changes over time.")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - Volume Card

    private var volumeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Volume")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if let latest = weeklyVolume.last {
                        Text("Last week: \(Int(latest.volume)) lbs")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()
            }

            if weeklyVolume.count > 1 {
                WeeklyVolumeChart(points: weeklyVolume)
                    .frame(height: 180)
            } else {
                Text("Not enough data yet for a weekly chart.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
    }

    // MARK: - Weekly Volume Calculation

    struct VolumePoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
    }

    /// Sum reps * weight for all sets, grouped by ISO week (Monday).
    private var weeklyVolume: [VolumePoint] {
        let calendar = Calendar(identifier: .iso8601)

        // Flatten all sets from all sessions
        let allSets: [WorkoutSet] = sessions.flatMap { session in
            (session.sets as? Set<WorkoutSet>)?.map { $0 } ?? []
        }

        // Group by week start date
        let grouped = Dictionary(grouping: allSets) { set -> Date in
            let day = calendar.startOfDay(for: set.session?.date ?? Date())

            let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day)
            ) ?? day

            return weekStart
        }

        let points = grouped.map { (weekStart, sets) -> VolumePoint in
            let vol = sets.reduce(0.0) { total, set in
                total + Double(set.reps) * set.weight
            }
            return VolumePoint(weekStart: weekStart, volume: vol)
        }

        return points.sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - Weekly Volume Chart (nested so it can see VolumePoint)

    private struct WeeklyVolumeChart: View {
        let points: [VolumePoint]

        private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)

        var body: some View {
            GeometryReader { geo in
                let maxVolume = max(points.map { $0.volume }.max() ?? 0, 1)
                let barWidth  = max(10, geo.size.width / CGFloat(max(points.count, 4)) * 0.6)

                HStack(alignment: .bottom, spacing: barWidth * 0.4) {
                    ForEach(points) { point in
                        VStack {
                            // Bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Self.accentGreen)
                                .frame(
                                    width: barWidth,
                                    height: CGFloat(point.volume / maxVolume) * (geo.size.height - 20)
                                )

                            // Week label
                            Text(weekLabel(for: point.weekStart))
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }

        private func weekLabel(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}
