//
//  AddWeightView.swift
//  BodyBuddy
//
//  Created by William Anan on 11/25/25.
//

import SwiftUI
import CoreData

struct AddWeightView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Log Bodyweight")) {
                    TextField("Weight (lbs)", text: $weightText)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(Double(weightText) == nil)
                }
            }
            .navigationTitle("Add Weight")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveWeight() {
        guard let value = Double(weightText) else { return }

        let entry = BodyweightEntry(context: ctx)
        entry.id = UUID()
        entry.date = Date()
        entry.weight = value

        do {
            try ctx.save()
            dismiss()
        } catch {
            print("Failed to save bodyweight: \(error)")
        }
    }
}
