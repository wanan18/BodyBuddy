//
//  WeightSummaryTile.swift
//  BodyBuddy
//
//  Created by William Anan on 11/25/25.
//

import SwiftUI
import Charts
import CoreData

struct WeightSummaryTile: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: true)],
        animation: .default
    )
    private var weighIns: FetchedResults<BodyweightEntry>

    @State private var showingAddWeight = false

    private var recentWeight: Double? {
        weighIns.last?.weight
    }
    
    private var recentDate: Date? {
        weighIns.last?.date
    }

    private var chartData: [BodyweightEntry] {
        let count = weighIns.count
        return count > 14 ? Array(weighIns.suffix(14)) : Array(weighIns)
    }
    
    private var minWeight: Double {
        chartData.map { $0.weight }.min() ?? 0
    }

    private var maxWeight: Double {
        chartData.map { $0.weight }.max() ?? 1
    }

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray   = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weight")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button {
                    showingAddWeight = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(Self.accentGreen)
                }
            }

            if let weight = recentWeight {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(String(format: "%.1f", weight)) lb")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    if let date = recentDate {
                        Text("Last logged: \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Text("No entries yet")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }

            if chartData.count > 1 {
                Chart(chartData) { entry in
                    // Slim green line
                    LineMark(
                        x: .value("Date", entry.date ?? Date()),
                        y: .value("Weight", entry.weight)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(Self.accentGreen)

                    // Dots for each logged weight
                    PointMark(
                        x: .value("Date", entry.date ?? Date()),
                        y: .value("Weight", entry.weight)
                    )
                    .symbolSize(16)
                    .foregroundStyle(Self.accentGreen)
                }
                // Tighten Y scale around your actual weights so slope is more obvious
                .chartYScale(domain: (minWeight - 0.5)...(maxWeight + 0.5))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 40)
            }
        }
        .padding(16)
        .background(Self.cardGray)
        .cornerRadius(20)
        .sheet(isPresented: $showingAddWeight) {
            LogBodyweightSheet()
        }
    }
}
