//
//  FeedGroup.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class FeedGroup: NSObject, ArticleCollection, CustomStringConvertible {
    var feeds = [Feed]()
    
    // is this the default group?
    var isDefault: Bool { return _userSetTitle == "Default" }
    
    // initialize from string
    init(title: String) {
        _userSetTitle = title
    }
    
    // initialize from storage dictionary
    convenience init(storage: NSDictionary) {
        self.init(title: storage["userSetTitle"] as! String)
        
        // add feeds
        if let stored = storage["feeds"] as? [NSDictionary] {
            for info in stored {
                if let feed = Feed(group: self, storage: info) {
                    feeds.append(feed)
                }
            }
        }
        
        // other settings
        daysToKeepArticles = storage["daysToKeepArticles"] as? Int ?? 0
        iconResource       = storage["iconResource"]       as? String
        iconStored         = storage["iconStored"]         as? String
        automaticRefresh   = storage["automaticRefresh"]   as? Bool ?? true

    }
    
    // MARK: Notifications
    
    struct Notifications {
        static let Fetched = "FeedGroupFetchedNotification"
        static let AppearanceChanged = "FeedGroupAppearanceChangedNotification"
    }
    
    // MARK: Icon
    
    var iconResource: String?   // icon name in resources
    var iconStored:   String?   // icon name as stored by user
    
    lazy var icon: UIImage? = {
        if let name = self.iconResource {
            let image = UIImage(named: "icons/group/\(name)")
            if image == nil { self.iconResource = nil }
            return image
        }
        if let name = self.iconStored {
            let path = (rss.manager.documents as String) + "/stored-icons/\(name)"
            return UIImage(contentsOfFile: path)
        }
        return nil
    }()
    
    override var description: String {
        return "Group \(title)"
    }
    
    // add a feed
    func addFeed(_ feed: Feed) {
        feeds.append(feed)
        rss.log("[\(title)] Added \(feed.title)")
    }
    
    // MARK: Group settings
    
    fileprivate var _daysToKeepArticles = 0
    var daysToKeepArticles: Int {
        get {
            return _daysToKeepArticles == 0 ?
                settings.daysToKeepArticles : _daysToKeepArticles
        }
        set { _daysToKeepArticles = newValue }
    }
    
    // user set title can be an empty string
    fileprivate var _userSetTitle: String
    var userSetTitle: String {
        get { return _userSetTitle }
        set {
            _userSetTitle = newValue
            rss.center.post(name: Notification.Name(rawValue: Notifications.AppearanceChanged), object: self)
        }
    }
    
    // same as user set title except empty string -> "Unnamed"
    var title: String {
        return userSetTitle.isEmpty ? "Unnamed" : userSetTitle
    }
    
    // used in search bar
    var shortTitle: String { return title }
    
    // whether to refresh feeds in this group automatically
    var automaticRefresh = true
    
    // MARK: Article collection
    // these members make FeedGroup compliant with the ArticleCollection protocol.

    // all articles in the group
    var articles: [Article] {
        var all = [Article]()
        for feed in feeds {
            all += feed.articles
        }
        return all
    }
    
    // unread articles in this group
    var unread: [Article] {
        return articles.filter { !$0.read }
    }
    
    // saved articles in this group
    var saved: [Article] {
        return articles.filter { $0.saved }
    }
    
    // feeds loading?
    var loading: Bool {
        
        // set all as loading.
        set {
            for feed in feeds {
                feed.loading = true
            }
        }
        
        // are any loading?
        get {
            return find(feeds.map { $0.loading }, true) != nil
        }
        
    }
    
    // fetch all feeds in this group
    func fetchThen(_ then: ((Void) -> Void)?) {
        for feed in feeds {
            feed.fetchThen(then)
        }
        rss.center.post(name: Notification.Name(rawValue: Notifications.Fetched), object: self)
    }
    
    // MARK: Persistence
    
    func forStorage() -> NSDictionary {
        let storage: NSMutableDictionary = [
            "userSetTitle":         _userSetTitle,
            "daysToKeepArticles":   _daysToKeepArticles,
            "automaticRefresh":     automaticRefresh,
            "feeds":                feeds.map { $0.forStorage() }
        ]
        let maybe = [
            "iconResource": iconResource,
            "iconStored":   iconStored
        ]
        for (key, val) in maybe {
            if val == nil { continue }
            storage[key] = val!
        }
        return storage
    }
    
}
