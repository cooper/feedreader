//
//  ArticleCollection.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/9/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

/*
    an article collection represents a set of articles
    to be displayed with an ArticleListVC.

    complying with this protocol are:

    Feed
        An actual feed.

    FeedGroup
        A category of feeds.

    GenericArticleCollection
        A generic collection with a list of articles.
        Used for total, unread, saved, etc.

*/

protocol ArticleCollection {
    
    // a list of articles in a specific order.
    var articles: [Article] { get }
    
    // all feeds involved in the articles
    var feeds: [Feed] { get }

    // a single feed will set it to false when the
    // request finishes.
    //
    // a collection of feeds should set this as soon as
    // ALL feeds' requests have finished.
    //
    var loading: Bool { get }
    
    // the title of the collection.
    // for a feed, it's the feed title.
    // it could also be "All feeds," etc.
    var title: String { get }
    var shortTitle: String { get }
    
    // if more than one operation occurs, the callback will
    // be called after the completion of each one. this is
    // because fetchThen is usually used to refresh
    // something in the interface.
    mutating func fetchThen(_ then: ((Void) -> Void)?)
    
    // returns the lists of unread and saved articles
    var unread: [Article] { get }
    var saved:  [Article] { get }
    
}


// the generic article collection consists of a title
// and a list of articles.

struct GenericArticleCollection: ArticleCollection {
    var articles: [Article]
    var title = "Articles"
    var shortTitle: String { return title }
    
    // feeds
    var feeds: [Feed] {
        var f = [Feed: Bool]()
        for feed in (articles.map { $0.feed }) {
            f[feed] = true
        }
        return f.keys.array
    }
    
    // unread articles
    var unread: [Article] {
        return articles.filter { !$0.read }
    }
    
    // saved articles
    var saved: [Article] {
        return articles.filter { $0.saved }
    }
    
    // initialize with title and articles
    init(title: String, articles: [Article]) {
        self.articles = articles
        self.title = title
    }

    // loading updated by fetchThen()
    var loading: Bool {
        return feeds.filter { $0.loading }.first != nil
    }
    
    // fetch all feeds involved
    mutating func fetchThen (_ then: ((Void) -> Void)?) {
        for feed in feeds {
            feed.fetchThen(then)
        }
    }
    
}
