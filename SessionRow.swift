//
//  SessionRow.swift
//  BodyBuddy
//
//  Created by William Anan on 11/5/25.
//

import SwiftUI

struct SessionRow: View {
    let session: WorkoutModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.date.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if totalVolume > 0 {
                    Label("\(Int(totalVolume)) vol", systemImage: "chart.bar.fill")
                        .font(.caption)
                }
            }

            Text(overview)
                .lineLimit(1)

            HStack(spacing: 12) {
                Label("\(session.sets.count) sets", systemImage: "number")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var overview: String {
        let names = Array(Set(session.sets.map { $0.exercise.name }))
        let head = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? head + " …" : head
    }

    private var totalVolume: Double {
        session.sets.reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
}
