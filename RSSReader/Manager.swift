//
//  Manager.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/9/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

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
    
    // add feeds from storage.
    func addFeedsFromStorage(feedDicts: [NSDictionary]) {
        for feedDict in feedDicts {
            let feed = Feed(storage: feedDict)
            addFeed(feed)
        }
    }
    
    // add groups from storage.
    func addGroupsFromStorage(groupDicts: [NSDictionary]) {
        for groupDict in groupDicts {
            let group = FeedGroup(storage: groupDict)
            group.isDefault = group.name == "Default"
            addGroup(group)
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
    
    // remove a feed.
    // I don't really like this because it's not very efficient.
    // an alternate solution is to cast to NSArry and then removeObject:.
    func removeFeed(feed: Feed) {
        feeds.removeAtIndex(feed.index)
    }
    
    // NSArray of NSDictionaries representing feeds.
    // these feeds are in the order by which they were added.
    var feedsForStorage: NSArray {
        return feeds.map { $0.forStorage }
    }
    
    // NSArray of NSDictionaries representing feed groups.
    // these groups are in order by which they are organized in the interface.
    var groupsForStorage: NSArray {
        return groups.map { $0.forStorage }
    }
    
}