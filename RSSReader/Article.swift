//
//  Article.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/29/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class Article {
    
    // these are implicitly unwrapped optionals
    // because an article object will ONLY be dealt with
    // without them set inside of the XML parsing stage.
    var title: String!
    var urlString: String!
    weak var feed: Feed!
    
    var url: NSURL {
        return NSURL(string: urlString)!
    }
    
    init(feed: Feed) {
        self.feed = feed
    }
    
    convenience init(feed: Feed, storage: NSDictionary) {
        self.init(feed: feed)
        title = storage["title"]! as String
        urlString = storage["urlString"]! as String
    }
    
    // returns NSDictionary because it will be converted to such anyway.
    var forStorage: NSDictionary {
        return [
            "title":        title,
            "urlString":    urlString
        ]
    }
    
}