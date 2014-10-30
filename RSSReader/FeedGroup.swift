//
//  FeedGroup.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation
import CoreData

class FeedGroup: NSManagedObject, ArticleCollection, Printable {
    
    @NSManaged var managedTitle: String
    var title: String { return managedTitle }
    @NSManaged var managedFeeds: NSMutableOrderedSet
    
    var feeds: [Feed]   { return managedFeeds.array as [Feed] }
    var isDefault: Bool { return title == "Default" }
    
    override var description: String {
        return "Group \(title)"
    }
    
    func addFeed(feed: Feed) {
        managedFeeds.addObject(feed)
    }

    // MARK:- Article collection
    
    // all articles in the group.
    var articles: [Article] {
        var all = [Article]()
        for feed in feeds {
            all += feed.articles
        }
        return all
    }
    
    // feeds loading.
    var loading: Bool {
        
        // set all as loading.
        set {
            for feed in feeds {
                feed.loading = true
            }
        }
        
        // are any loading?
        get {
            return find(feeds.map { $0.loading }, true) != nil
        }
        
    }
    
    // fetch all feeds.
    func fetchThen(then: (Void -> Void)?) {
        for feed in feeds {
            feed.fetchThen(then)
        }
    }
    
}