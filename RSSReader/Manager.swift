//
//  Manager.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/9/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation
import CoreData

class Manager {
    var feeds   = [Feed]()
    var groups  = [FeedGroup]()
    
    // fetch all the feeds asynchronously.
    func fetchAllFeeds() {
        fetchAllFeedsThen(nil)
    }
    
    // fetch all the feeds asynchronously, then do something.
    func fetchAllFeedsThen(then: (Void -> Void)?) {
        for feed in feeds {
            feed.fetchThen(then)
        }
    }
    
    // add a feed.
    func addFeed(feed: Feed) {
        feeds.append(feed)
    }
    
    // add a group.
    func addGroup(group: FeedGroup) {
        groups.append(group)
    }
    
    var defaultGroup: FeedGroup? {
        for group in groups {
            if group.isDefault { return group }
        }
        return nil
    }
    
    // remove a feed.
    // I don't really like this because it's not very efficient.
    // an alternate solution is to cast to NSArray and then removeObject:.
    func removeFeed(feed: Feed) {
        feeds.removeAtIndex(find(feeds, feed)!)
        context.deleteObject(feed)
    }
    
    // find a feed by its URL.
    // consider: capitalization...
    func feedFromURLString(urlString: String) -> Feed? {
        for feed in feeds {
            if urlString == feed.url.absoluteString! {
                return feed
            }
        }
        return nil
    }

    func newFeedWithUrlString(urlString: String) -> Feed {
        let feed = NSEntityDescription.insertNewObjectForEntityForName("Feed", inManagedObjectContext: context) as Feed
        feed.urlString = urlString
        feed.managedArticles = NSMutableOrderedSet()
        return feed
    }
    
    func newArticleForFeed(feed: Feed) -> Article {
        let article = NSEntityDescription.insertNewObjectForEntityForName("Article", inManagedObjectContext: context) as Article
        article.feed = feed
        return article
    }
    
    func newGroupTitled(title: String) -> FeedGroup {
        let group = NSEntityDescription.insertNewObjectForEntityForName("FeedGroup", inManagedObjectContext: context) as FeedGroup
        group.managedTitle = title
        return group
    }
    
    // MARK:- Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.rlygd.RSSReader" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("RSSReader", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("RSSReader.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var context: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()

    // MARK:- Core Data Saving support

    func saveContext() {
        NSLog("saving changes")
        var error: NSError? = nil
        if context.hasChanges && !context.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }
    
    func loadFromCoreData() {
        loadFeedsFromCoreData()
        loadGroupsFromCoreData()
    }
    
    func loadFeedsFromCoreData() {
        let request = NSFetchRequest(entityName: "Feed")
        request.sortDescriptors = [ NSSortDescriptor(key: "index", ascending: true) ]
        var anyError: NSError?
        let fetched = context.executeFetchRequest(request, error: &anyError) as? [Feed]
        NSLog("fetched: \(fetched?.map{ $0.title })")
        
        if fetched == nil {
            NSLog("Error fetching: \(anyError)")
            fatalError("Core Data: Fetching feeds failed.")
            return
        }
        
        feeds = fetched!
    }
    
    func loadGroupsFromCoreData() {
        let request = NSFetchRequest(entityName: "FeedGroup")
        var anyError: NSError?
        let fetched = context.executeFetchRequest(request, error: &anyError) as? [FeedGroup]
        
        if fetched == nil {
            NSLog("Error fetching: \(anyError)")
            fatalError("Core Data: Fetching groups failed.")
            return
        }
        
        groups = fetched!
    }
    
}