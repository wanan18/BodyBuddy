//
//  NewSessionView.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import SwiftUI
import CoreData

struct NewSessionView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()

    private static let accentGreen = Color(red: 92/255, green: 255/255, blue: 156/255)
    private static let cardGray = Color(red: 20/255, green: 20/255, blue: 20/255)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New Session")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.top, 24)

                    dateSection

                    Spacer(minLength: 40)

                    createButton
                }
                .padding(.horizontal, 16)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
                .foregroundStyle(.white)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .colorScheme(.dark)
        }
    }

    private var createButton: some View {
        Button(action: createSession) {
            Text("Create Session")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Self.accentGreen)
                .cornerRadius(18)
        }
        .padding(.bottom, 24)
    }

    private func createSession() {
        let s = WorkoutSession(context: ctx)
        s.id = UUID()
        s.date = date
        try? ctx.save()
        dismiss()
    }
}

#Preview {
    let pc = PersistenceController.shared
    return NewSessionView()
        .environment(\.managedObjectContext, pc.container.viewContext)
}
