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

    convenience init(feeds: [Feed]) {
        self.init()
        self.feeds = feeds
    }
    
    func addFeedsFromStorage(storage: [String: AnyObject]) {
        let feedsStored = storage["feeds"] as AnyObject! as [[String: AnyObject]]
        println("feeds: \(feedsStored)")
        
        for feedInfo in feedsStored {
            let feed = Feed(storage: feedInfo)
            addFeed(feed)
        }
        
    }
    
    func addFeed(feed: Feed) {
        feeds.append(feed)
    }
    
    func fetchAllFeeds() {
        fetchAllFeedsThen(nil)
    }
    
    func fetchAllFeedsThen(then: (Void -> Void)?) {
        for feed in feeds {
            feed.fetchThen(then)
        }
    }
    
    // returns NSDictionary because it will be converted to such anyway.
    func forStorage() -> NSDictionary {
        return [ "feeds": feeds.map { $0.forStorage() } ]
    }
    
}