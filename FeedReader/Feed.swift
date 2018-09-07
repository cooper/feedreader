//
//  Feed.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class Feed: NSObject, CustomStringConvertible, ArticleCollection, XMLParserDelegate {
    
    // failable if URL is invalid
    init?(group: FeedGroup, urlString string: String!) {
        var string = string
        
        // if the string is nil, it just won't work
        if string == nil {
            urlString = ""
            self.group = rss.defaultGroup
            super.init()
            return nil
        }
        
        // if feed:// replace with http://
        if let r = string.rangeOfString("feed://", options: nil, range: nil, locale: nil) {
            string.replaceRange(r, with: "http://")
        }
        
        // feed:http://
        if (string?.hasPrefix("feed:"))! {
            string.removeSubrange((string.startIndex ..< advance(string.startIndex, 5)))
        }
        
        self.group = group
        urlString = string!
        super.init()

        // check validity
        if url.scheme == nil || !contains(["http", "https"], url.scheme!) {
            return nil
        }
        
    }
    
    // failable if mandatory data is missing
    convenience init?(group: FeedGroup, storage: NSDictionary) {
        self.init(group: group, urlString: storage["urlString"] as? String)
        
        // optional values
        channelTitle  = storage["channelTitle"]  as? String
        userSetTitle  = storage["userSetTitle"]  as? String
        iconUrlString = storage["iconUrlString"] as? String
        logoUrlString = storage["logoUrlString"] as? String
        iconFileName  = storage["iconFileName"]  as? String
        logoFileName  = storage["logoFileName"]  as? String
        
        // add each article
        if let stored = storage["articles"] as? [NSDictionary] {
            for info in stored {
                let article = Article(feed: self, storage: info)
                
                // check if too old
                if article.expired && !article.saved {
                    continue
                }
                
                articles.append(article)
            }
        }
        
    }
    
    // MARK:- Notifications
    
    struct Notifications {
        static let Fetched = "FeedWasFetchedNotification"
        static let Error   = "FeedErrorOccurredNotification"
    }
    
    // MARK:- Properties
    
    // URL
    //
    // urlString is persistent. URLs cannot be stored in Core Data/plist.
    // Therefore, url is a computed URL value of the urlString.
    //
    
    var urlString: String
    var url: URL { return URL(string: urlString)! }
    var identifier: String { return urlString }
    
    // Group
    //
    // The group is set when loaded from storage
    // or when the feed is first added to the group
    //
    // it is unowned because the group will hold a strong
    // reference to the feed; therefore, the feed should
    // not hold a strong reference to the group
    //
    
    unowned var group: FeedGroup
    
    // Articles
    //
    // articles is the list of articles in no
    // particular order
    //
    // articlesById is a computed property which makes
    // it easier to determine which articles exist already,
    // based on their URL string.
    //
    
    var articles = [Article]()
    
    // feeds for article
    var feeds: [Feed] { return [self] }
    
    var articlesById: [String: Article] {
        var byId = [String: Article]()
        for article in articles {
            byId[article.identifier] = article
        }
        return byId
    }
    
    var unread: [Article] {
        return articles.filter { !$0.read }
    }
    
    var saved: [Article] {
        return articles.filter { $0.saved }
    }
    
    // Titles
    //
    // channelTitle represents the title assigned by the feed itself.
    // userSetTitle represents the title set by the user, or nickname.
    // Both properties are persistent.
    //
    // title chooses the best possible title available, the first that exists of:
    //      user set title,
    //      channel-set title,
    //      feed URL string
    //
    // the short title is a property of the article collection,
    // used for display in the search bar.
    //
    
    var channelTitle: String?    // actual title from the feed
    var userSetTitle: String?    // nickname assigned by user
    
    // best option
    var title: String {
        return userSetTitle ?? channelTitle ?? url.absoluteString
    }
    
    // used in search bar
    var shortTitle: String {
        let short = (userSetTitle ?? channelTitle)?.components(separatedBy: " ")[0]
        return short ?? url.absoluteString
    }

    // Images
    //
    // iconUrlString and logoUrlString are persistent and set by the feed itself.
    //
    // logoData and iconData are also persistent and are the stored data which
    // may have been downloaded after the feed was fetched a previous time.
    //
    // logo and icon are lazy variables which will be computed after the feed is
    // retrieved from Core Data/plist, but they will also be re-set again later if the
    // images are downloaded and have been modified.
    //
    
    var iconUrlString: String?   // URL of icon representing of the feed
    var logoUrlString: String?   // URL of logo representing of the feed
    
    var iconFileName: String?
    var logoFileName: String?
    
    var logoData: Data?        // data representing the logo
    var iconData: Data?        // data representing the icon
    
    lazy var logo: UIImage? = {
        if let data = self.logoData {
            return UIImage(data: data)
        }
        if var file = self.logoFileName {
            file = rss.manager.documents.appendingPathComponent(file)

            if let data = try? Data(contentsOf: URL(fileURLWithPath: file)) {
                self.logoData = data
                return UIImage(data: data)
            }
        }
        return nil
    }()
    
    lazy var icon: UIImage? = {
        if let data = self.iconData {
            return UIImage(data: data)
        }
        if var file = self.iconFileName {
            file = rss.manager.documents.appendingPathComponent(file)
            if let data = try? Data(contentsOf: URL(fileURLWithPath: file)) {
                self.iconData = data
                return UIImage(data: data)
            }
        }
        return nil
    }()

    // MARK: Non-persistent properties
    
    var shouldFetchIcon = false     // whether it's necessary to fetch icon
    var shouldFetchLogo = false     // whether it's necessary to fetch logo
    
    var loading = false                     // is it being fetched now?
    weak var currentGroup: FeedGroup?       // current feed group in user interface
    
    // printable description
    override var description: String {
        return "Feed \(title)"
    }
    
    // MARK:- Methods

    // add an article to the feed.
    func addArticle(_ article: Article) {

        // this article was deleted
        if contains(rss.manager.deletedArticleIDs, article.identifier) {
            rss.log("Ignoring deleted article \(article.title)")
            return
        }
        
        // already exists; update the old one.
        if let existing = articlesById[article.identifier] {
            existing.updateWithArticle(article)
            return
        }
        
        articles.append(article)
    }
    
    // fetch the feed data.
    func fetchThen(_ then: ((Void) -> Void)?) {
        rss.log("Fetching \(self.title)")
        
        loading = true
        rss.activityLevel += 1
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 3)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            
            rss.activityLevel--
            self.loading = false
            
            // error.
            if error != nil {
                rss.log("There was an error in \(self.title): \(error)")
                mainQueue {
                    
                    // show error on current view controller, if any
                    // remember that we've shown an error. it will be
                    // unset when the user taps OK button.
                    var canShowError = true
                    if let vc = rss.currentFeedVC {
                        if canShowError {
                            let alert = PSTAlertController(title: "Feed error", message: "An error occurred for \"\(self.title)\": \(error.localizedDescription)", preferredStyle: .Alert)
                            alert.addAction(PSTAlertAction(title: "OK") { _ in
                                canShowError = true
                                return
                            })
                            alert.showWithSender(nil, controller: vc, animated: true, completion: nil)
                            canShowError = false
                        }
                    }
                    
                    rss.center.post(name: Notification.Name(rawValue: Notifications.Error), object: self)
                    then?()
                }
                
                // retry after five seconds, but don't retain self.
                after(5) { [weak self] in
                    self?.fetchThen(then)
                    return
                }
                return
            }
            
            // initiate XML parser in this same queue.
            let parser = XMLParser(feed: self, data: data)
            parser.parse()

            // download logo/icon.
            self.downloadImages()
            
            // in the main queue, update UI and call callback.
            mainQueue {
                self.reloadCells()
                then?()
                rss.center.post(name: Notification.Name(rawValue: Notifications.Fetched), object: self)
            }
            
            return
        }
    }
    
    // fetch an image at the specific URL iff doIt is true, calling handler
    // with the NSData and UIImage if/when completed successfully
    func fetchImage(_ urlString: String!, _ doIt: Bool, handler: @escaping (Data, UIImage) -> Void) {
        
        // no image URL specified.
        if urlString == nil || !doIt { return }
        
        // send the request from the feed queue.
        let request = URLRequest(url: URL(string: urlString)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        rss.activityLevel += 1
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            rss.activityLevel--
            
            // error.
            if error != nil {
                rss.log("There was an error loading the image: \(error)")
                return
            }
            
            // create UIImage, remove white background, if any, then
            // convert back to binary data for storage in Core Data/documents.
            // working with UIImage is threadsafe now.
            if var image = UIImage(data: data) {
                image = image.withoutWhiteBackground
                handler(image.pngRepresentation!, image)
            }
            
            // reload the table in the main queue, if there is one visible.
            mainQueue {
                self.reloadCells()
                return
            }
            
        }
        
    }
    
    // download all images associated with the feed.
    func downloadImages() {
        
        // feed logo
        fetchImage(logoUrlString, shouldFetchLogo) {
            data, image in
            self.logoData = data
            self.logo = image
            let file = self.identifier.fileNameSafe + "-logo.png"
            let path = rss.manager.documents.appendingPathComponent(file)
            rss.log("Writing logo to \(path)")
            try? image.pngRepresentation!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            self.logoFileName = file
        }
        
        // feed icon
        fetchImage(iconUrlString, shouldFetchIcon) {
            data, image in
            self.iconData = data
            self.icon = image
            let file = self.identifier.fileNameSafe + "-icon.png"
            let path = rss.manager.documents.appendingPathComponent(file)
            rss.log("Writing icon to \(path)")
            try? image.pngRepresentation!.write(to: URL(fileURLWithPath: path), options: [.atomic])
            self.iconFileName = file
        }
        
        // article thumbnails
        for article in articles {
            article.fetchThumb()
        }
        
    }
    
    // reload the visible cells associated with the feed, if any.
    // this only applies to the topmost feed list, but that's okay because
    // any others will be updated when receiving viewWillAppear:.
    func reloadCells() {
        if let feedVC = rss.currentFeedVC {
            if let myRow = find(feedVC.group.feeds, self) {
                let path = IndexPath(row: myRow, section: feedVC.secFeedList)
                feedVC.tableView.reloadRows(at: [path], with: .automatic)
            }
        }
    }
    
    // convenience method for fetching with no callback.
    func fetch() {
        fetchThen(nil)
    }
    
    // MARK: Persistence
    
    func forStorage() -> NSDictionary {
        
        // these values always present
        var forStorage: [String: AnyObject] = [
            "articles":         articles.map { $0.forStorage() },
            "identifier":       identifier,
            "urlString":        urlString
        ]
        
        // add present values from these
        let maybe = [
            "channelTitle":     channelTitle,
            "userSetTitle":     userSetTitle,
            "iconUrlString":    iconUrlString,
            "logoUrlString":    logoUrlString,
            "iconFileName":     iconFileName,
            "logoFileName":     logoFileName
        ]
        
        for (key, val) in maybe {
            if val == nil { continue }
            forStorage[key] = val! as AnyObject
        }
        
        return forStorage as NSDictionary
    }
    
}
