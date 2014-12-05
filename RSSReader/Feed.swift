//
//  Feed.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit
import CoreData

let defaultImage = UIImage(named: "news.png")!

class Feed: NSManagedObject, Printable, ArticleCollection, NSXMLParserDelegate {
    
    // MARK:- Feed properties
    
    // URL
    //
    // urlString is persistent. URLs cannot be stored in Core Data.
    // Therefore, url is a computed URL value of the urlString.
    //
    
    @NSManaged var urlString: String
    
    var url: NSURL { return NSURL(string: urlString)! }
    
    
    // Articles
    //
    // managedArticles represents the ordered set
    // managed by Core Data.
    //
    // mutableArticles is the mutable ordered set.
    //
    // articles, however, is a pure-Swift array of
    // articles which is useful for iteration and such.
    //
    // articlesById is a computed property which makes
    // it easier to determine which articles exist already,
    // based on their URL string.
    //
    @NSManaged var managedArticles: NSOrderedSet
    
    var articles: [Article] {
        return self.managedArticles.array as [Article]
    }
    
    var articlesById: [String: Article] {
        var byId = [String: Article]()
        for article in articles {
            byId[article.identifier] = article
        }
        return byId
    }
    
    lazy var mutableArticles: NSMutableOrderedSet = {
        return self.mutableOrderedSetValueForKey("managedArticles")
    }()
    
    
    // Groups
    //
    // this property is not necessarily used, but it represents the
    // inverse of the FeedGroup.feeds relationship.
    //
    
    @NSManaged var managedGroups: NSSet
    
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
    
    @NSManaged var channelTitle: String?    // actual title from the feed
    @NSManaged var userSetTitle: String?    // nickname assigned by user
    
    var title: String { return userSetTitle ?? channelTitle ?? url.absoluteString! }


    // Images
    //
    // iconUrlString and logoUrlString are persistent and set by the feed itself.
    //
    // logoData and iconData are also persistent and are the stored data which
    // may have been downloaded after the feed was fetched a previous time.
    //
    // logo and icon are lazy variables which will be computed after the feed is
    // retrieved from Core Data, but they will also be re-set again later if the
    // images are downloaded and have been modified.
    //
    
    @NSManaged var iconUrlString: String?   // URL of icon representing of the feed
    @NSManaged var logoUrlString: String?   // URL of logo representing of the feed
    
    @NSManaged var logoData: NSData?        // data representing the logo
    @NSManaged var iconData: NSData?        // data representing the icon
    
    lazy var logo: UIImage = {
        if let data = self.logoData {
            return UIImage(data: data)!
        }
        return defaultImage
    }()
    
    lazy var icon: UIImage = {
        if let data = self.iconData {
            return UIImage(data: data)!
        }
        return defaultImage
    }()

    
    // MARK:- Non-persistent state properties
    
    var shouldFetchIcon = false     // whether it's necessary to fetch icon
    var shouldFetchLogo = false     // whether it's necessary to fetch logo
    
    var loading = false                     // is it being fetched now?
    weak var currentGroup: FeedGroup?       // current feed group in user interface
    
    // printable description
    override var description: String {
        return "Feed \(url.absoluteString!)"
    }
    
    
    // MARK:- Feed methods

    // add an article to the feed, remembering it by both index and identifier.
    func addArticle(article: Article) {

        // this one already exists; update it.
        NSLog("looking for ID \(article.identifier)")
        if articlesById[article.identifier] != nil {
            NSLog("exists")
            mutableArticles.removeObject(article)
        }
        
        // FIXME: I'm not sure that this even works.
        // add the article to the correct location by date.
        for (i, art) in enumerate(articles) {
            
            // the article being added is more recent.
            if art.publishDate.laterDate(article.publishDate) == article.publishDate {
                mutableArticles.insertObject(article, atIndex: i)
                return
            }
            
        }
        
        // may not have been added if it's the oldest one.
        mutableArticles.addObject(article)
        
    }
    
    // fetch the feed data.
    // TODO: use separate operation queue
    func fetchThen(then: (Void -> Void)?) {
    
        loading = true
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            
            self.loading = false
            NSLog("Fetching \(self.title)")
            
            // error.
            if error != nil {
                NSLog("There was an error in \(self.title): \(error)")
                return
            }
            
            // initiate XML parser in this same queue.
            //NSLog("Parsing the data")
            let parser = XMLParser(feed: self, data: data)
            parser.parse()

            // download logo/icon.
            self.downloadImages()
            
            // in the main queue, update UI and call callback.
            mainQueue {
                self.reloadCells()
                then?()
            }
            
            return
        }
    }
    
    func fetchImage(urlString: String!, _ doIt: Bool, handler: (NSData, UIImage) -> Void) {
        
        // no image URL specified.
        if urlString == nil || !doIt { return }
        
        // send the request from the feed queue.
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            
            // error.
            if error != nil {
                NSLog("There was an error loading the image: \(error)")
                return
            }
            
            // create UIImage, remove white background, if any, then
            // convert back to binary data for storage in Core Data.
            // apparently working with UIImage is threadsafe now.
            let image = UIImage(data: data)!.withoutWhiteBackground
            handler(image.pngRepresentation!, image)
            
            // reload the table in the main queue, if there is one visible.
            mainQueue {
                self.reloadCells()
                return
            }
            
        }
        
    }
    
    // download the image, then optionally reload a table view.
    func downloadImages() {
        fetchImage(logoUrlString, shouldFetchLogo) {
            data, image in
            self.logoData = data
            self.logo = image
        }
        fetchImage(iconUrlString, shouldFetchIcon) {
            data, image in
            self.iconData = data
            self.icon = image
        }
    }
    
    // reload the visible cells associated with the feed, if any.
    func reloadCells() {
        if let feedVC = rss.currentFeedVC {
            let path = NSIndexPath(forRow: find(feedVC.group.feeds, self)!, inSection: feedVC.secFeedList)
            NSLog("path: \(path)")
            feedVC.tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
        }
    }
    
    // convenience for fetching with no callback.
    func fetch() {
        fetchThen(nil)
    }
    
}