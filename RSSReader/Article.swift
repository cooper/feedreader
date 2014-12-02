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
    
    @NSManaged var title: String
    @NSManaged var urlString: String
    @NSManaged var publishDate: NSDate
    @NSManaged var feed: Feed
    
    var url: NSURL { return NSURL(string: urlString)! }
    
    // summary. caches without HTML tags.
    @NSManaged var rawSummary: String?
    
    // intitially a lazy var, but set later when feed fetched.
    lazy var summary: String? = { return self.rawSummary?.withoutHTMLTagsAndNewlines }()
    var hasSummary: Bool { return summary != nil && countElements(summary!) > 0 }
    
    var _identifier: String?
    var identifier: String { return _identifier ?? urlString }
    
}

// articles are equatable by identifier.
func == (lhs: Article, rhs: Article) -> Bool {
    return lhs.identifier == rhs.identifier
}