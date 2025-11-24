//
//  ProgressViewCharts.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI
import Charts
import CoreData

struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct ProgressViewCharts: View {
    @Environment(\.managedObjectContext) private var ctx
    @State private var points: [ProgressPoint] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Volume by Day")
                .font(.title3).bold()

            if points.isEmpty {
                ContentUnavailableView(
                    "No data yet",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Log a set in Quick Log or create a Session to see progress here.")
                )
                .frame(maxWidth: .infinity, maxHeight: 260)
            } else {
                Chart(points) { p in
                    LineMark(x: .value("Date", p.date),
                             y: .value("Volume", p.volume))
                    PointMark(x: .value("Date", p.date),
                              y: .value("Volume", p.volume))
                }
                .frame(height: 260)
            }
        }
        .padding()
        .task { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)) { _ in
            Task { await load() }
        }
    }

    @MainActor
    private func load() async {
        let request = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        guard let sessions = try? ctx.fetch(request) else {
            points = []
            return
        }

        var daily: [Date: Double] = [:]
        let cal = Calendar.current

        for s in sessions {
            let date = s.value(forKey: "date") as? Date ?? Date.distantPast
            let day = cal.startOfDay(for: date)

            // Safely unwrap the to-many relationship and compute volume = sum(reps * weight)
            let setSet = (s.value(forKey: "sets") as? Set<WorkoutSet>) ?? []
            let vol = setSet.reduce(0.0) { acc, set in
                let reps = Int(set.reps)            // Int16 -> Int
                let weight = set.weight             // Double
                return acc + Double(reps) * weight
            }

            daily[day, default: 0] += vol
        }

        points = daily
            .keys
            .sorted()
            .map { ProgressPoint(date: $0, volume: daily[$0] ?? 0) }
    }
}

#Preview {
    // Minimal preview using in-memory Core Data so it compiles even before you add real data
    let pc = PersistenceController.shared
    return ProgressViewCharts()
        .environment(\.managedObjectContext, pc.container.viewContext)
}
