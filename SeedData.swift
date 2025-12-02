//
//  SeedData.swift
//  BodyBuddy
//
//  Created by William Anan on 10/22/25.
//

import CoreData

enum SeedData {
    static func ensureBasics(in context: NSManagedObjectContext) throws {
        // If we already have at least one Exercise, skip seeding
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Exercise")
        req.fetchLimit = 1
        if (try? context.count(for: req)) ?? 0 > 0 { return }

        // Add some starter movements
        let defaults: [(String, String, Bool)] = [
            ("Barbell Bench Press", "Chest", false),
            ("Back Squat", "Quads", false),
            ("Deadlift", "Posterior Chain", false),
            ("Pull-Up", "Back", true),
            ("Overhead Press", "Shoulders", false)
        ]

        for (name, group, isBW) in defaults {
            guard let desc = NSEntityDescription.entity(forEntityName: "Exercise", in: context) else { continue }
            let ex = NSManagedObject(entity: desc, insertInto: context)
            ex.setValue(UUID(), forKey: "id")
            ex.setValue(name, forKey: "name")
            ex.setValue(group, forKey: "muscleGroup")
            ex.setValue(isBW, forKey: "isBodyweight")
        }

        try context.save()
    }
}
