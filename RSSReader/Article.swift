//
//  Article.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/29/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation
import CoreData

private let veryOldDate = NSDate(timeIntervalSince1970: 0)

class Article: NSManagedObject, Equatable {
    
    // these are implicitly unwrapped optionals
    // because an article object will ONLY be dealt with
    // without them set inside of the XML parsing stage.
    @NSManaged var title: String!
    @NSManaged var urlString: String!
    @NSManaged var publishDate: NSDate
    @NSManaged var feed: Feed!
    
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
            if countElements(newValue) > 0 {
                summary = newValue.withoutHTMLTagsAndNewlines
            }
            else {
                summary = nil
            }
        }
    }
    var summary: String?
    
    var _identifier: String?
    var identifier: String { return _identifier ?? urlString }
    
}

// articles are equatable by identifier.
func == (lhs: Article, rhs: Article) -> Bool {
    return lhs.identifier == rhs.identifier
}