//
//  FeedManager.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class FeedManager {
    var feeds: [Feed];
    
    convenience init () {
        self.init(feeds: [])
    }
    
    init(feeds theFeeds: [Feed]) {
        feeds = theFeeds;
    }
    
    func addFeed(feed: Feed) {
        feeds.append(feed)
    }
    
    
}