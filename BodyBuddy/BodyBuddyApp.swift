import SwiftUI

@main
struct BodyBuddyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
