//
//  Article.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/29/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

private let veryOldDate = Date(timeIntervalSince1970: 0)

class Article: NSObject, Equatable, CustomStringConvertible {
    
    // MARK: Notifications
    
    struct Notifications {
        static let Read    = "ArticleReadNotification"
        static let Unread  = "ArticleUnreadNotification"
        static let Saved   = "ArticleSavedNotification"
        static let Unsaved = "ArticleUnsavedNotification"
        static let ThumbChanged = "ArticleThumbnailChangedNotification"
    }
    
    // initialize from feed
    init(feed: Feed) {
        self.feed = feed
    }
    
    // initialize from storage
    convenience init(feed: Feed, storage: NSDictionary) {
        self.init(feed: feed)
        
        if let title = storage["title"] as? String {
            self.title = title
        }
        
        if let string = storage["urlString"] as? String {
            urlString = string
        }
        
        if let date = storage["publishDate"] as? Date {
            publishDate = date
        }
        
        if let sum = storage["rawSummary"] as? String {
            rawSummary = sum
        }
        
        if let id = storage["identifier"] as? String {
            identifier = id
        }
        
        thumbImageFileName = storage["thumbImageFileName"] as? String
        read  = storage["read"]  as? Bool ?? false
        saved = storage["saved"] as? Bool ?? false
    }
    
    // MARK: Properties
    
    // the article must belong to a feed.
    // it's unowned because it should not hold a strong reference to it.
    unowned let feed: Feed
    
    // Article title, as defined in the feed
    var title = "Article"
    var attributedTitle: NSAttributedString {
        return NSAttributedString(string: title, attributes: attr)
    }
    
    // title with only alphanumeric characters, used for sorting
    lazy var titleForSorting: String = {
        let removeChars = CharacterSet.alphanumerics.inverted
        return "".join(self.title.components(separatedBy: removeChars))
    }()
    
    // article permalink
    var urlString: String!
    var url: URL {
        return URL(string: urlString)!
    }
    
    // date article was published
    // if not specified by feed, falls back to the date when first fetched
    var publishDate: Date!
    
    // when setting read, publish the notification
    fileprivate var _read = false
    var read: Bool {
        set {
            _read = newValue
            rss.center.post(name: Notification.Name(rawValue: newValue ? Notifications.Read : Notifications.Unread), object: self)
        }
        get { return _read }
    }
    
    // when setting saved, publish the notification
    fileprivate var _saved = false
    var saved: Bool {
        set {
            _saved = newValue
            rss.center.post(name: Notification.Name(rawValue: newValue ? Notifications.Saved : Notifications.Unsaved), object: self)
        }
        get { return _saved }
    }
    
    // true if the article is past expiration
    // this can be dependent on a feed group, falling back to the default setting
    var expired: Bool {
        return settings.articleIsExpired(self)
    }
    
    // summary. caches without HTML tags.
    var rawSummary = ""
        
    // intitially a lazy var, but set later when feed fetched.
    lazy var summary: String = {
        WSLHTMLEntities.convertHTMLtoString(self.rawSummary.withoutHTMLTagsAndNewlines)?.trimmed ?? ""
    }()

    var attributedSummary: NSAttributedString {
        return NSAttributedString(string: summary, attributes: attr)
    }
    
    // true if the summary is non-empty
    var hasSummary: Bool { return !summary.isEmpty }
    
    // Thumbnail image
    
    var shouldFetchThumb = false
    var thumbImageUrlString: String?
    var thumbImageFileName: String?
    var thumbImageData: Data?

    lazy var thumbImage: UIImage? = {
        if let data = self.thumbImageData {
            return UIImage(data: data)
        }
        if var file = self.thumbImageFileName {
            file = rss.manager.documents.appendingPathComponent(file)
            if let data = try? Data(contentsOf: URL(fileURLWithPath: file)) {
                self.thumbImageData = data
                return UIImage(data: data)
            }
        }
        return nil
    }()
    
    // best way to identify the article
    // this is often equivalent to article's permalink
    var identifier: String!
    
    // MARK: Methods
    
    // delete an article
    var deleted = false
    func disposeOf() {
        rss.log("Disposing of article \(title)")
        
        // remove from container
        if let i = find(feed.articles, self) {
            feed.articles.remove(at: i)
        }
        
        // add to deleted list
        rss.manager.deletedArticleIDs.append(identifier)
        deleted = true
        
    }
    
    // update an article with another one
    func updateWithArticle(_ otherArticle: Article) {
        title       = otherArticle.title
        urlString   = otherArticle.urlString
        publishDate = otherArticle.publishDate
        rawSummary  = otherArticle.rawSummary
    }
    
    // fetch the thumbnail image if possible
    func fetchThumb() {
        if thumbImageUrlString == nil || !shouldFetchThumb { return }
        
        // send the request from the feed queue.
        let request = URLRequest(url: URL(string: thumbImageUrlString!)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        rss.activityLevel += 1
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            rss.activityLevel--
            
            // error.
            if error != nil {
                rss.log("There was an error loading the image: \(error)")
                return
            }
            
            // create UIImage
            if let image = UIImage(data: data) {
                self.thumbImage = image
                self.thumbImageData = data

                // store in file
                
                let file = self.identifier.fileNameSafe + "-thumb.png"
                let path = rss.manager.documents.appendingPathComponent(file)
                rss.log("Writing thumbnail to \(path)")
                data.writeToFile(path, atomically: true)
                self.thumbImageFileName = file

            }
            
            // notification
            mainQueue {
                rss.center.post(name: Notification.Name(rawValue: Notifications.ThumbChanged), object: self)
                return
            }
            
        }
        
        shouldFetchThumb = false
    }
    
    // printable description
    override var description: String {
        return "Article \(title)"
    }
    
    // MARK: Persistence
    
    func forStorage() -> NSDictionary {
        var storage: [NSString: AnyObject] = [
            "title":        title as AnyObject,
            "urlString":    urlString as AnyObject,
            "publishDate":  publishDate as AnyObject,
            "rawSummary":   rawSummary as AnyObject,
            "identifier":   identifier as AnyObject,
            "read":         read as AnyObject,
            "saved":        saved as AnyObject
        ]
        if let file = thumbImageFileName {
            storage["thumbImageFileName"] = file as AnyObject
        }
        return storage as NSDictionary
    }
    
}

// articles are equatable by identifier.
func == (lhs: Article, rhs: Article) -> Bool {
    return lhs.identifier == rhs.identifier
}

// common attributes used in summaries and titles
private let attr = [
    NSFontAttributeName: UIFont.systemFont(ofSize: 16),
    NSForegroundColorAttributeName: UIColor.white
]
