// Copyright © 2021 SpotHero, Inc. All rights reserved.

import CoreData
import Foundation

/// A helper class to assist with all CoreData operations.
@available(iOS 10.0, watchOS 3.0, *)
public class CoreDataOperator {
    // MARK: - Shared Instance
    
    /// The shared instance of `CoreDataOperator`.
    ///
    /// Users must call one of the static `initializeSharedContext` methods on this class before
    /// operations will work without requiring a passed-in context.
    public private(set) static var shared = CoreDataOperator()
    
    // MARK: - Properties
    
    /// The container in charge of the Core Data stack.
    private var persistentContainer: NSPersistentContainer?
    
    /// The default managed object context for all requests.
    public var defaultContext: NSManagedObjectContext? {
        return self.persistentContainer?.viewContext
    }
    
    /// The URLs for each persistent store in the current Core Data stack.
    public var persistentStoreFileURLs: [URL] {
        let stores = self.persistentContainer?.persistentStoreCoordinator.persistentStores
        return stores?.compactMap(\.url) ?? []
    }
    
    // MARK: - Methods
    
    // MARK: Initializers
    
    /// Initializes a new `CoreDataOperator` with no default managed object context.
    /// This is only used for the shared instance of this class, which requires
    /// one of the `initializeSharedContext` methods to be called before most operations will succeed.
    private init() {}
    
    /// Initializes a new `CoreDataOperator` using the view context from a given `NSPersistentContainer`.
    /// - Parameter persistentContainer: The persistent container that owns the view context to use for all operations.
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    // MARK: Shared Instance Initializers
    
    /// Initializes a new Core Data stack using the passed in arguments to create a `NSPersistentContainer`.
    ///
    /// Ensure `clearCoreData` is called before subsequent calls to this method.
    /// - Parameters:
    ///   - modelName: The name of the model (.momd) file to use.
    ///   - databaseURL: The URL where the database should be persisted. If no URL is given, all data will be stored in memory.
    ///   - bundle: The bundle used to lookup the Core Data model file. Defaults to `.main`.
    public func initializeCoreDataStack(modelName: String, databaseURL: URL?, bundle: Bundle = .main) {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Failed to find \(modelName).momd in bundle \(bundle).")
        }
        
        self.initializeCoreDataStack(modelURL: modelURL, databaseURL: databaseURL)
    }
    
    /// Initializes a new Core Data stack using the passed in arguments to create a `NSPersistentContainer`. The container
    /// is setup so that migrations are automatic and use inferred mapping models.
    ///
    /// Ensure `clearCoreData` is called before subsequent calls to this method.
    /// - Parameters:
    ///   - modelURL: The URL path to the model (.momd) file to use.
    ///   - databaseURL: The URL where the database should be persisted. If no URL is given, all data will be stored in memory.
    public func initializeCoreDataStack(modelURL: URL, databaseURL: URL?) {
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to initialize managed object model with contents of url: \(modelURL)")
        }
        
        let container = NSPersistentContainer(name: "CoreData", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.url = databaseURL
        
        let storeType: NSPersistentContainer.StoreType = databaseURL != nil ? .sqlite : .memory
        description.type = storeType.rawValue
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { description, error in
            // Check if the data store matches
            precondition(description.type == storeType.rawValue)
            
            // Check if creating container wrong
            if let error = error {
                fatalError("Failed to create persistent container. \(error.localizedDescription)")
            }
        }
        self.persistentContainer = container
    }
    
    // MARK: Temporary Context
    
    /// Creates a new `NSManagedObjectContext` with a private queue concurreny type and whose parent is the `defaultContext`.
    /// A temporary context can be used to perform work off the main thread and later be merged back into the `defaultContext`.
    public func createTemporaryContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.defaultContext
        return context
    }
    
    // MARK: Clearing Core Data
    
    /// Removes all persistent stores from the coordinator and removes them from the file system.
    ///
    /// **Note that this method is useful for testing, but should not be used on events such as a user logout.** In those such events,
    /// you may want to remove all data from your persistent store, but should not remove the persistent store from the file system.
    ///
    /// After calling this method, `initializeSharedContext` must be called again prior to performing any other operations.
    public func clearCoreData() {
        guard let container = self.persistentContainer else {
            // Nothing to tear down, there is no persistent container.
            return
        }
        
        for store in container.persistentStoreCoordinator.persistentStores {
            if let storeURL = store.url {
                // Destroy the persistent store, then clean up all the generated SQLite files.
                // (i.e. the .sqlite, .sqlite-shm, and .sqlite-wal files)
                try? container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL,
                                                                                 ofType: store.type,
                                                                                 options: nil)
                try? store.deleteStoreFiles()
            } else {
                // If there's no URL for the store, just remove it from the coordinator.
                try? container.persistentStoreCoordinator.remove(store)
            }
        }
        
        self.persistentContainer = nil
    }
    
    // MARK: Count
    
    /// Returns the count of a given managed object. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameter type: The type of managed object to count.
    /// - Parameter predicate: The predicate to filter the request by.
    /// - Parameter context: The managed object context to perform the count operation in. If nil, uses the current default context.
    public func count<T: NSManagedObject>(of type: T.Type,
                                          with predicate: NSPredicate? = nil,
                                          in context: NSManagedObjectContext? = nil) throws -> Int {
        guard let context = context ?? self.defaultContext else {
            throw UBCoreDataError.managedObjectContextNotFound
        }
        
        var count: Int?
        var performError: Error?
        context.performAndWait {
            // Instead of using T.fetchRequest(), we build the FetchRequest so we don't need to cast the result
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
            fetchRequest.includesPropertyValues = false
            fetchRequest.includesSubentities = false
            fetchRequest.predicate = predicate
            
            do {
                count = try context.count(for: fetchRequest)
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        } else if let count = count {
            // If the fetched objects were not found, ensure that we return 0
            return (count != NSNotFound) ? count : 0
        } else {
            return 0
        }
    }
    
    // MARK: Create
    
    /// Creates a new instance of a managed object subclass. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameter type: The managed object subclass type to create.
    /// - Parameter context: The managed object context to create the object in. If nil, uses the current default context.
    public func newInstance<T: NSManagedObject>(of type: T.Type, in context: NSManagedObjectContext? = nil) throws -> T? {
        guard let context = context ?? self.defaultContext else {
            throw UBCoreDataError.managedObjectContextNotFound
        }
        
        var newInstance: T?
        context.performAndWait {
            newInstance = NSEntityDescription.insertNewObject(forEntityName: String(describing: type.self), into: context) as? T
        }
        
        return newInstance
    }
    
    // MARK: Delete
    
    /// Deletes a single managed object. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameter object: The object to delete.
    public func delete<T: NSManagedObject>(_ object: T) throws {
        guard let context = object.managedObjectContext else {
            throw UBCoreDataError.objectHasNoManagedObjectContext(object)
        }
        
        var performError: Error?
        context.performAndWait {
            context.delete(object)
            do {
                try context.save()
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        }
    }
    
    /// Deletes all objects of a given entity type. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameter type: The entity type to batch delete.
    /// - Parameter predicate: The predicate to filter the request by.
    /// - Parameter context: The managed object context to perform the delete operation in. If nil, uses the current default context.
    /// - Parameter batchDelete: Whether or not to use a batch delete, if supported. Defaults to false.
    ///
    /// Batch requests can only be used if the context's persistent store is an SQLite store.
    ///
    /// **Sources**
    /// - [Implementing Batch Deletes](https://developer.apple.com/library/archive/featuredarticles/CoreData_Batch_Guide/BatchDeletes/BatchDeletes.html)
    public func deleteAll<T: NSManagedObject>(of type: T.Type,
                                              with predicate: NSPredicate? = nil,
                                              in context: NSManagedObjectContext? = nil,
                                              batchDelete: Bool = false) throws {
        guard let context = context ?? self.defaultContext else {
            throw UBCoreDataError.managedObjectContextNotFound
        }
        
        var performError: Error?
        context.performAndWait {
            // Batch requests are only compatible on SQLite stores.
            let canBatchDelete = context.persistentStoreCoordinator?.persistentStores.first?.type == NSSQLiteStoreType
            let useBatchRequest = canBatchDelete && batchDelete
            
            do {
                if useBatchRequest {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: type.self))
                    fetchRequest.includesPropertyValues = false
                    fetchRequest.predicate = predicate
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    try context.executeAndMergeChanges(using: deleteRequest)
                } else {
                    let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
                    fetchRequest.includesPropertyValues = false
                    fetchRequest.predicate = predicate
                    
                    let results = try context.fetch(fetchRequest)
                    for object in results {
                        context.delete(object)
                    }
                }
                
                try context.save()
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        }
    }
    
    // MARK: Exists
    
    /// Checks whether a given type of entity exists. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameter type: The type of entity to check existence for.
    /// - Parameter predicate: The predicate to filter the request by.
    /// - Parameter context: The managed object context to use when checking for existence of a given object type.
    ///                      If nil, uses the current default context.
    public func exists<T: NSManagedObject>(_ type: T.Type,
                                           with predicate: NSPredicate? = nil,
                                           in context: NSManagedObjectContext? = nil) throws -> Bool {
        return try self.count(of: type, with: predicate, in: context) > 0
    }
    
    // MARK: Fetch
    
    /// Fetches a single managed object of a given type. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameters:
    ///   - type: The type of entity to fetch.
    ///   - predicate: The predicate to filter the request by.
    ///   - context: The managed object context to perform the fetch operation in. If nil, uses the current default context.
    public func fetch<T: NSManagedObject>(_ type: T.Type,
                                          with predicate: NSPredicate? = nil,
                                          in context: NSManagedObjectContext? = nil) throws -> T? {
        guard let context = context ?? self.defaultContext else {
            throw UBCoreDataError.managedObjectContextNotFound
        }
        
        guard try self.count(of: type, with: predicate, in: context) <= 1 else {
            assertionFailure("The fetch request returned more than 1 object.")
            return nil
        }
        
        var result: T?
        var performError: Error?
        context.performAndWait {
            // Instead of using T.fetchRequest(), we build the FetchRequest so we don't need to cast the result
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
            fetchRequest.predicate = predicate
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try context.fetch(fetchRequest)
                result = results.first
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        } else {
            return result
        }
    }
    
    /// Allows fetching multiple managed objects of a given type. Ensures thread safety and performs work synchronously on the managed object context.
    /// - Parameters:
    ///   - type: The type of entity to fetch all results for.
    ///   - predicate: The predicate to filter the request by.
    ///   - sortDescriptors: The descriptors used to sort results.
    ///   - fetchLimit: The limit of items to fetch. Defaults to nil, which results in no limit.
    ///   - fetchBatchSize: The limit to set on the batch size. Defaults to nil, which results in no limit.
    ///   - context: The managed object context to perform the fetch operation in. If nil, uses the current default context.
    public func fetchMultiple<T: NSManagedObject>(of type: T.Type,
                                                  with predicate: NSPredicate? = nil,
                                                  sortDescriptors: [NSSortDescriptor]? = nil,
                                                  fetchLimit: Int? = nil,
                                                  fetchBatchSize: Int? = nil,
                                                  in context: NSManagedObjectContext? = nil) throws -> [T] {
        guard let context = context ?? self.defaultContext else {
            throw UBCoreDataError.managedObjectContextNotFound
        }
        
        var results: [T]?
        var performError: Error?
        context.performAndWait {
            // Instead of using T.fetchRequest(), we build the FetchRequest so we don't need to cast the result
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: type.self))
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors
            
            if let fetchLimit = fetchLimit {
                fetchRequest.fetchLimit = fetchLimit
            }
            
            if let fetchBatchSize = fetchBatchSize {
                fetchRequest.fetchBatchSize = fetchBatchSize
            }
            
            do {
                results = try context.fetch(fetchRequest)
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        } else {
            return results ?? []
        }
    }
    
    // MARK: Save
    
    /// Saves the default managed object context. Ensures thread safety and performs work synchronously on the managed object context.
    public func saveDefaultContext() throws {
        guard let context = self.defaultContext, context.hasChanges else {
            return
        }
        
        var performError: Error?
        context.performAndWait {
            do {
                try context.save()
            } catch {
                performError = error
            }
        }
        
        if let performError = performError {
            throw performError
        }
    }
    
    /// Saves the passed in context if there are changes and merges the changes with the `defaultContext`.
    /// If the passed in context is not a child of the `defaultContext`, this method does nothing.
    /// Ensures thread safety and performs work synchronously on the managed object contexts.
    /// - Parameters:
    ///   - context: The context to save.
    public func saveAndMerge(context: NSManagedObjectContext) {
        guard let mainContext = self.defaultContext else {
            // The main context has not been setup.
            return
        }
        
        guard context !== mainContext else {
            // This is the main context, not a child. Just return.
            return
        }
        
        guard context.parent === mainContext else {
            // The given context is not a child of the main context, so we cannot merge changes up.
            return
        }
        
        guard context.hasChanges else {
            // There are no changes to save, just return.
            return
        }
        
        context.performAndWait {
            // Save the child context. This will push changes up to the parent.
            try? context.save()
            
            mainContext.performAndWait {
                // Save the parent context. This will push changes to the persistent store.
                try? mainContext.save()
            }
        }
    }
}
