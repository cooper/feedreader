//
//  FeedGroup.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class FeedGroup {
    var feeds = [Feed]()
    var name  = "(Unnamed)"
    var isDefault = false

    convenience init(feeds: [Feed]) {
        self.init()
        self.feeds = feeds
    }
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
    
    convenience init(storage: NSDictionary) {
        self.init()
        addFeedsFromStorage(storage)
    }
    
    // add feeds from storage to the group.
    // this should be called after the feeds themselves have been loaded from storage.
    // this method only grabs the feeds from their indices and adds them to the group.
    func addFeedsFromStorage(storage: NSDictionary) {
        
        // group name.
        name = storage["name"] as String
        
        // add each feed from storage.
        let feedsStored = storage["feeds"] as [Int]
        for feedIndex in feedsStored {
            let feed = rss.manager.feeds[feedIndex]
            addFeed(feed)
        }
        
    }
    
    func addFeed(feed: Feed) {
        feeds.append(feed)
    }
    
    // NSDictionary representing the group.
    // feeds are represented as an array of indices in the manager.
    var forStorage: NSDictionary {
        
        // find the index of each feed in the manager.
        let feedIndices = feeds.map { $0.index }
        
        return [
            "name":     name,
            "feeds":    feedIndices
        ]
    }
    
}