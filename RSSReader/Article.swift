//
//  Article.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/29/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

let veryOldDate =  NSDate(timeIntervalSince1970: 0)

class Article: Equatable {
    
    // these are implicitly unwrapped optionals
    // because an article object will ONLY be dealt with
    // without them set inside of the XML parsing stage.
    var title: String!
    var urlString: String!
    var publishDate = veryOldDate
    weak var feed: Feed!
    
    var url: NSURL {
        return NSURL(string: urlString)!
    }
    
    // summary. caches without HTML tags.
    private var _rawSummary = ""
    var rawSummary: String {
        get {
            return _rawSummary
        }
        set {
            _rawSummary = newValue
            summary = newValue.withoutHTMLTags
        }
    }
    var summary = ""
    
    var _identifier: String?
    var identifier: String { return _identifier ?? urlString }
    
    init(feed: Feed) {
        self.feed = feed
    }
    
    convenience init(feed: Feed, storage: NSDictionary) {
        self.init(feed: feed)
        title       = storage["title"]       as  String
        urlString   = storage["urlString"]   as  String
        _identifier = storage["_identifier"] as? String    // might not be present
        rawSummary  = storage["rawSummary"]  as? String ?? ""
        publishDate = storage["publishDate"] as? NSDate ?? veryOldDate
    }

    // returns NSDictionary because it will be converted to such anyway.
    var forStorage: NSDictionary {
        var dict = [
            "title":        title,
            "urlString":    urlString,
            "rawSummary":   rawSummary,
            "publishDate":  publishDate
        ]
        
        // if an identifier exists (not using the URL), remember it.
        if _identifier != nil {
            dict["_identifier"] = _identifier
        }
    
        return dict
    }
    
}

// articles are equatable by identifier.
func == (lhs: Article, rhs: Article) -> Bool {
    return lhs.identifier == rhs.identifier
}