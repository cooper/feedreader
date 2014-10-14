//
//  ArticleCollection.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/9/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

/*
    An article collection represents a set of articles
    to be displayed with an ArticleListVC. A feed complies
    with this protocol.
*/

protocol ArticleCollection {
    
    // a list of articles in a specific order.
    var articles: [Article] { get }
    
    // this will be set to true by the interface as the
    // refresh button is tapped.
    //
    // a single feed will set it back to false when the
    // request finishes.
    //
    // a collection of feeds should set this as soon as
    // ALL feeds' requests have finished.
    //
    var loading: Bool { get set }
    
    // the title of the collection.
    // for a feed, it's the feed title.
    // it could also be "All feeds," etc.
    var title: String { get }
    
    // if more than one operation occurs, the callback will
    // be called after the completion of each one. this is
    // because fetchThen is usually used to refresh
    // something in the interface.
    func fetchThen (then: (Void -> Void)?)
    
}