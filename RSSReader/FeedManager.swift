//
//  FeedManager.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class FeedManager {
    var feeds = [Feed]()
    let feedQueue = NSOperationQueue()

    convenience init(feeds: [Feed]) {
        self.init()
        for feed in feeds {
            self.addFeed(feed)
        }
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
        feed.manager = self
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
    
    func forStorage() -> NSDictionary {
        return [ "feeds": feeds.map { $0.forStorage() } ]
    }
    
}