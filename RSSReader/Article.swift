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
    
    func forStorage() -> NSDictionary {
        return [
            "title":        title,
            "urlString":    urlString
        ]
    }
    
}