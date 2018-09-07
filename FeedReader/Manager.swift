//
//  Manager.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/9/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class Manager {
    final var groups = [FeedGroup]()
    let saveQueue = DispatchQueue(label: "save", attributes: [])
    
    // MARK: Feed management
    
    // all feeds
    var feeds: [Feed] {
        var f = [Feed]()
        for group in groups {
            f += group.feeds
        }
        return f
    }
    
    // all articles
    var articles: [Article] {
        var a = [Article]()
        for group in groups {
            a += group.articles
        }
        return a
    }
    
    // IDs of articles which have been deleted
    final var deletedArticleIDs = [String]()
    
    // all feeds to refresh automatically
    fileprivate var refreshFeeds: [Feed] {
        var f = [Feed]()
        for group in groups {
            if !group.automaticRefresh {
                continue
            }
            f += group.feeds
        }
        return f
    }
    
    // fetch all the feeds asynchronously.
    func fetchAllFeeds() {
        fetchAllFeedsThen(nil)
    }
    
    // fetch all the feeds asynchronously, then do something.
    var lastFetchTime = Date()
    func fetchAllFeedsThen(_ then: ((Void) -> Void)?) {
        lastFetchTime = Date()
        for feed in refreshFeeds {
            feed.fetchThen(then)
        }
    }
    
    // find the default group
    var defaultGroup: FeedGroup? {
        for group in groups {
            if group.isDefault { return group }
        }
        return nil
    }
    
    // list of groups, excluding default
    var notDefaultGroups: [FeedGroup] {
        var otherGroups = groups
        otherGroups.remove(at: 0)
        return otherGroups
    }
    
    // find a feed by its URL.
    // consider: capitalization...
    func feedFromURLString(_ urlString: String) -> Feed? {
        for feed in feeds {
            if urlString == feed.url.absoluteString! {
                return feed
            }
        }
        return nil
    }

    // MARK: Persistence
    
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    lazy var plistPath: String = {
        return self.documents.appendingPathComponent("manager.plist")
    }()
    
    // load from plist
    func loadContext() {
        if let storage = NSDictionary(contentsOfFile: plistPath) {
            if let stored = storage["groups"] as? [NSDictionary] {
                for info in stored {
                    let group = FeedGroup(storage: info)
                    groups.append(group)
                }
            }
            if let ids = storage["deletedArticleIDs"] as? [String] {
                deletedArticleIDs = ids
            }
        }
    }
    
    // save to plist
    func saveContext() {
        
        // save the feed manager
        saveQueue.async {
            rss.log("Saving changes")
            let storage = self.forStorage()
            storage.write(toFile: self.plistPath, atomically: true)
        }
        
        // save the user defaults
        UserDefaults.standard.synchronize()
        
    }
    
    func forStorage() -> NSDictionary {
        let x = [
            "groups":            groups.map { $0.forStorage() },
            "deletedArticleIDs": deletedArticleIDs
        ] as [String : Any]
        rss.log("manager.forStorage: \(x)")
        return x as NSDictionary
    }
    
}
