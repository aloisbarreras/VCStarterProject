//
//  PersistenceController.swift
//  EpicEats-iOS
//
//  Created by Alois Barreras on 9/29/15.
//  Copyright © 2015 Vicino. All rights reserved.
//

import UIKit
import CoreData

typealias CompletionBlock = () -> Void
typealias JSON = [String : AnyObject]

public protocol DataViewControllerProtocol: class {
    weak var dataController: DataController! { get set }
}

public class DataController: NSObject {
    private var privateContext: NSManagedObjectContext! // this will do the actual writing to disk
    private var initCallback: (Bool -> Void)?
    private(set) var mainMOC: NSManagedObjectContext! // this will be our single source of truth
    private var networkQueue = NSOperationQueue()
    
    public init(callback: (Bool -> Void)?) {
        self.initCallback = callback
        networkQueue.maxConcurrentOperationCount = 5
        super.init()
        self.initializeCoreDataStack()
    }
    
    private func addOperation(operation: NSOperation, completionBlock: CompletionBlock?) {
        let blockOperation = NSBlockOperation() { [weak self] in
            dispatch_sync(dispatch_get_main_queue()) {
                completionBlock?()
            }
            self?.save()
        }
        // add dependency to make sure it runs after the request completes
        blockOperation.addDependency(operation)
        networkQueue.addOperation(blockOperation)
        networkQueue.addOperation(operation)
    }
    
    func fetchJSONData(completionBlock: CompletionBlock? = nil) {
        let operation = GetJSONDataOperation(parentMOC: mainMOC)
        addOperation(operation, completionBlock: completionBlock)
    }
}

// MARK: - Creating Fetched Results Controllers
extension DataController {
    func jsonDataResultsController(delegate delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: FakeData.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "identifier", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainMOC, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = delegate
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription, __FILE__, __FUNCTION__, __LINE__)
        }
        
        return fetchedResultsController
    }
}

// MARK: - Initialization
extension DataController {
    private func initializeCoreDataStack() {
        if let _ = mainMOC {
            return
        }
        
        guard let modelURL = NSBundle.mainBundle().URLForResource("DataModel", withExtension: "momd"), let managedObjectModel = NSManagedObjectModel.init(contentsOfURL: modelURL) else {
            // if we cannot get the managed object model, then something is seriously wrong
            // and there is nothing we can do to fix it
            fatalError("Could not initialize the managed object model")
        }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // now we create the managed object contexts
        privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        mainMOC = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainMOC.parentContext = privateContext
        mainMOC.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // The creation of the reference to the store can take time – an unknown amount of time. It can be nearly instantaneous (as is the case most of the time) or it can take multiple seconds if there is a migration or other issue. If it is going to take time, we do not want to block the main thread and therefore the User Interface.
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) { [unowned self] in
            var options = [String : AnyObject]()
            options[NSMigratePersistentStoresAutomaticallyOption] = true
            options[NSInferMappingModelAutomaticallyOption] = true
            options[NSSQLitePragmasOption] = ["journal_mode": "DELETE"]
            
            let fileManager = NSFileManager.defaultManager()
            let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last
            let storeURL = documentsURL?.URLByAppendingPathComponent("DataModel.sqlite")
            debugPrint(storeURL)
            do {
                try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
            } catch {
                // TODO: - log the error here in some way, something serious went wrong if we can't initialize the core data stack
                self.initCallback?(false)
            }
            
            guard let initCallback = self.initCallback else {
                return
            }
            
            dispatch_sync(dispatch_get_main_queue()) {
                initCallback(true)
            }
        }
    }
    
    public func save() {
        // make sure there are changes that need to be saved so we don't waste CPU cycles
        guard self.privateContext.hasChanges || self.mainMOC.hasChanges else {
            return
        }
        
        mainMOC.performBlockAndWait { [weak self] () -> Void in
            do {
                try self?.mainMOC.save()
            } catch let error {
                print(error)
            }
            
            self?.privateContext.performBlock {
                do {
                    try self?.privateContext.save()
                } catch let error {
                    print(error)
                }
            }
        }
    }
}
