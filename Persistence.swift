import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "BodyBuddy")
        
        if let description = container.persistentStoreDescriptions.first {
            // Enable CloudKit sync (optional)
            //description.cloudKitContainerOptions =
             //   NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourname.BodyBuddy")

            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        self.container = container
    }
}
