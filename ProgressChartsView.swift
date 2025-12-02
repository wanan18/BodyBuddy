//
//  ProgressChartsView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI
import Charts

struct ProgressChartsView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedExerciseID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ---- Chart 1: Weekly Volume ----
                    GroupBox("Weekly Training Volume") {
                        if weeklyVolume.isEmpty {
                            Text("Log a few sessions to see weekly volume.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Chart(weeklyVolume) { point in
                                BarMark(
                                    x: .value("Week", point.weekStart, unit: .weekOfYear),
                                    y: .value("Volume", point.volume)
                                )
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                                    AxisGridLine()
                                    AxisTick()
                                }
                            }
                            .frame(height: 220)
                        }
                    }

                    // ---- Chart 2: Est. 1RM per Exercise ----
                    GroupBox("Estimated 1RM") {
                        if store.exercises.isEmpty {
                            Text("No exercises available yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            // Exercise picker
                            Picker("Exercise", selection: $selectedExerciseID) {
                                ForEach(store.exercises) { ex in
                                    Text(ex.name).tag(Optional(ex.id))
                                }
                            }
                            .pickerStyle(.menu)

                            if let exID = selectedExerciseID,
                               let series = oneRMSeries[exID],
                               !series.isEmpty {
                                Chart(series) { pt in
                                    LineMark(
                                        x: .value("Date", pt.date),
                                        y: .value("Est 1RM", pt.oneRM)
                                    )
                                    PointMark(
                                        x: .value("Date", pt.date),
                                        y: .value("Est 1RM", pt.oneRM)
                                    )
                                }
                                .frame(height: 240)
                            } else {
                                Text("Pick an exercise to see estimated 1RM over time.")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .onAppear {
                if selectedExerciseID == nil { selectedExerciseID = store.exercises.first?.id }
            }
        }
    }

    // MARK: - Weekly volume

    private struct VolumePoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
    }

    private var weeklyVolume: [VolumePoint] {
        // group all sets into ISO weeks; sum reps*weight
        let calendar = Calendar(identifier: .iso8601)
        let grouped = Dictionary(grouping: store.workouts.flatMap { $0.sets }) { set in
            let day = calendar.startOfDay(for: dateForSet(set))
            // compute the Monday (week start) for that day
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day)) ?? day
            return weekStart
        }
        let points = grouped.map { (weekStart, sets) -> VolumePoint in
            let vol = sets.reduce(0.0) { $0 + Double($1.reps) * $1.weight }
            return VolumePoint(weekStart: weekStart, volume: vol)
        }
        return points.sorted { $0.weekStart < $1.weekStart }
    }

    private func dateForSet(_ set: SetEntryModel) -> Date {
        // find the parent workout's date (cheap pass through all since in-memory)
        for wk in store.workouts where wk.sets.contains(where: { $0.id == set.id }) {
            return wk.date
        }
        return Date()
    }

    // MARK: - Estimated 1RM series per exercise

    private struct OneRMPoint: Identifiable {
        let id = UUID()
        let date: Date
        let oneRM: Double
    }

    private var oneRMSeries: [UUID: [OneRMPoint]] {
        // For each exercise, compute best estimated 1RM per session day
        var result: [UUID: [OneRMPoint]] = [:]
        for ex in store.exercises {
            var perDay: [Date: Double] = [:]
            for wk in store.workouts {
                let setsForEx = wk.sets.filter { $0.exercise.id == ex.id }
                guard !setsForEx.isEmpty else { continue }
                // best 1RM of that day for this exercise
                let best = setsForEx.map { epley1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
                let day = Calendar.current.startOfDay(for: wk.date)
                perDay[day] = max(perDay[day] ?? 0, best)
            }
            let series = perDay.keys.sorted().map { day in
                OneRMPoint(date: day, oneRM: perDay[day] ?? 0)
            }
            result[ex.id] = series
        }
        return result
    }

    private func epley1RM(weight: Double, reps: Int) -> Double {
        // 1RM ≈ weight * (1 + reps/30)
        weight * (1.0 + (Double(reps) / 30.0))
    }
}
