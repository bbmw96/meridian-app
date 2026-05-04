import CoreData
import CloudKit

final class PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentCloudKitContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MERIDIAN")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve persistent store description.")
            }
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.io.meridian.app"
            )
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Persistent store failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            ctx.rollback()
        }
    }

    func saveDomain(_ profile: DomainProfile) {
        let ctx = newBackgroundContext()
        ctx.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SavedDomain")
            request.predicate = NSPredicate(format: "url == %@", profile.url)
            let existing = (try? ctx.fetch(request))?.first ?? NSEntityDescription.insertNewObject(
                forEntityName: "SavedDomain", into: ctx
            )
            existing.setValue(profile.url, forKey: "url")
            existing.setValue(profile.name, forKey: "name")
            existing.setValue(profile.monthlyTraffic, forKey: "monthlyTraffic")
            existing.setValue(profile.estimatedRevenuePounds, forKey: "estimatedRevenuePounds")
            existing.setValue(profile.lastScanned, forKey: "lastScanned")
            existing.setValue(profile.id.uuidString, forKey: "id")
            self.save(context: ctx)
        }
    }

    func saveOpportunity(_ opportunity: Opportunity) {
        let ctx = newBackgroundContext()
        ctx.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "SavedOpportunity")
            request.predicate = NSPredicate(format: "id == %@", opportunity.id.uuidString)
            let existing = (try? ctx.fetch(request))?.first ?? NSEntityDescription.insertNewObject(
                forEntityName: "SavedOpportunity", into: ctx
            )
            existing.setValue(opportunity.id.uuidString, forKey: "id")
            existing.setValue(opportunity.title, forKey: "title")
            existing.setValue(opportunity.geography, forKey: "geography")
            existing.setValue(opportunity.opportunityScore, forKey: "opportunityScore")
            existing.setValue(opportunity.discoveredAt, forKey: "discoveredAt")
            existing.setValue(opportunity.isPinned, forKey: "isPinned")
            self.save(context: ctx)
        }
    }

    func saveRateAlert(_ alert: RateAlert) {
        let ctx = newBackgroundContext()
        ctx.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "RateAlertEntity")
            request.predicate = NSPredicate(format: "id == %@", alert.id.uuidString)
            let existing = (try? ctx.fetch(request))?.first ?? NSEntityDescription.insertNewObject(
                forEntityName: "RateAlertEntity", into: ctx
            )
            existing.setValue(alert.id.uuidString, forKey: "id")
            existing.setValue(alert.pair, forKey: "pair")
            existing.setValue(alert.threshold, forKey: "threshold")
            existing.setValue(alert.direction.rawValue, forKey: "direction")
            existing.setValue(alert.isActive, forKey: "isActive")
            self.save(context: ctx)
        }
    }
}
