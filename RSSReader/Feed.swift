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

//
// this class must inherit from NSObject because it complies with
// an Objective-C protocol (NSXMLParserDelegate)
//
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
    
    lazy var mutableArticles: NSMutableOrderedSet = {
        return self.mutableOrderedSetValueForKey("managedArticles")
    }()
    
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
    
    // Groups
    //
    // this property is not necessarily used, but only represents the
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
    
    private var shouldFetchIcon = false     // whether it's necessary to fetch icon
    private var shouldFetchLogo = false     // whether it's necessary to fetch logo
    
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
        if articlesById[article.identifier] != nil {
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
            
            // FIXME: is it possible for this to fail?
            let parser = NSXMLParser(data: data)
            parser.delegate = self
            
            // initiate XML parser in this same queue.
            //NSLog("Parsing the data")
            parser.parse()
            rss.currentFeedVC?.tableView.reloadData()

            // download logo/icon.
            self.downloadImages()
            
            // in the main queue, reload the table, then call callback.
            mainQueue {
                rss.currentFeedVC?.tableView.reloadData()
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
                rss.currentFeedVC?.tableView.reloadData()
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
    
    // convenience for fetching with no callback.
    func fetch() {
        fetchThen(nil)
    }

    // MARK:- XML parser state
    
    // this class represents a single specific XML element.
    // its purpose is to create a hierarchy of elements.
    class Element {
        
        // these are the element types recognized by this RSS/Atom parser.
        enum Kind {
            
                                // Description                  RSS                 Atom
                                // --------------               ------              -------

            case None           // No element (main scope)      n/a                 n/a
            case Unknown        // Unknown element type         n/a                 n/a
            
            case FeedTitle      // title of the feed            <title>             <title>
            case FeedImage      // image for feed               <image>             n/a
            case FeedIconURL    // feed image URL               <url>               <icon>
            case FeedLogoURL    // feed image URL               <url>               <logo>
            case Channel        // RSS feed channel             <channel>           <feed>
            case Link           // URL for feed                 <link>              <link>
            
            case Item           // an item or article           <item>              <entry>
            case ItemTitle      // title of an item             <title>             <title>
            case ItemId         // identifier of item           <guid>              <id>
            case ItemDesc       // description of item          <description>       <summary>
            case ItemPubDate    // date of item publish         <pubDate>           <published>
            
        }
        
        // type of the element and its parent, if any.
        var type = Kind.None
        var parent: Element?
        
        // initialize with a type.
        convenience init(kind: Kind) {
            self.init()
            type = kind
        }
        
    }
    
    // current article and element while parsing.
    var article : Article?
    var element = Element()
    
    // open an element as a child of the current element.
    func adoptNewElement(type: Element.Kind) {
        let old = element
        element = Element(kind: type)
        element.parent = old
    }
    
    // close the current element.
    func closeElement() {
        element = element.parent ?? Element()
    }
    
    // convenience for assigning/fetching.
    var elementType: Element.Kind {
        set { adoptNewElement(newValue) }
        get { return element.type       }
    }
    
    struct current {
        static var itemPublishedDate = ""
    }
    
    // MARK:- XML parsing
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        let attributes = attributeDict as [String: String]
        //NSLog("Starting element: \(elementName)")
        
        switch elementName {
            
            case "channel", "feed":
                elementType = .Channel
            
            // if there's an article, this is its title.
            case "title" where element.type == .Item && article != nil:
                elementType = .ItemTitle
                article?.title = ""
            
            // otherwise, this is the feed title.
            case "title" where element.type == .Channel:
                elementType = .FeedTitle
            
            // the start of an article.
            case "item", "entry":
                article = rss.manager.newArticleForFeed(self)
                elementType = .Item

            // link of an article.
            case "link" where element.type == .Item && article != nil:
                elementType = .Link

                switch attributes["rel"] ?? "alternate" {
                    
                    // edit link.
                    case "edit":
                        NSLog("Edit")
                    
                    // the main link.
                    case "alternate" where attributes["href"] != nil:
                        article!.urlString = attributes["href"]!
                    
                    // some other.
                    default:
                        break
                    
                }
            
            // image of an article (RSS).
            case "image" where element.type == .Channel:
                elementType = .FeedImage
            
            // feed logo URL (RSS = url, Atom = logo).
            case "url" where element.type == .FeedImage,
                "logo" where element.type == .Channel:
                
                elementType = .FeedLogoURL
            
            // feed icon URL (Atom only).
            case "icon" where element.type == .Channel:
                
                elementType = .FeedIconURL
            
            // identifier for an article or item.
            case "guid" where element.type == .Item,
                 "id"   where element.type == .Item:
                
                elementType = .ItemId
            
            // item description.
            case "description" where element.type == .Item,
                 "summary"     where element.type == .Item:
                
                elementType = .ItemDesc
                article?.rawSummary = ""
            
            // item publish date.
            case "pubDate"   where element.type == .Item,
                 "published" where element.type == .Item:
                
                elementType = .ItemPubDate
                current.itemPublishedDate = ""
            
            // some other element that we do not handle.
            default:
                //NSLog("Unkown element \(elementName)")
                elementType = .Unknown
            
        }

    }
    
    // found some characters that are not part of an element.
    // note: it seems that this will be called several times with the data in pieces
    // if the any of the characters are encoded with entities like &gt; etc.
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        switch element.type {
            
            // the title of the feed.
            case .FeedTitle:
                channelTitle = string
            
            // the title of an article.
            case .ItemTitle:
                article?.title += string
                //NSLog("adding to title: \(string)")
            
            // in RSS, the link is within <link> tags (handled here).
            // in Atom, the link is in the href attribute.
            case .Link:
                article?.urlString = string

            // icon for the feed.
            case .FeedIconURL:
                shouldFetchIcon = icon == defaultImage || string != iconUrlString
                iconUrlString   = string
            
            // logo for the feed.
            case .FeedLogoURL:
                shouldFetchLogo = logo == defaultImage || string != logoUrlString
                logoUrlString   = string
            
            // item identifier.
            case .ItemId:
                article?._identifier = string
            
            // item description.
            case .ItemDesc:

                if article?.rawSummary == nil {
                    article?.rawSummary = string
                }
                else {
                    article?.rawSummary! += string
                }
            
            case .ItemPubDate:
                current.itemPublishedDate += string
            
            // some other element...
            default:
                
                break
            
        }
    }

    //func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String, qualifiedName qName: String) {
    func parser(parser: NSXMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        switch element.type {
            
            case .Channel:
                iconUrlString = iconUrlString ?? logoUrlString
            
            // add the current article to the feed.
            // addArticle() MUST be called after the identifier (if any) has been determined.
            case .Item:
                addArticle(article!)
                article = nil
            
            case .ItemPubDate:
                article!.publishDate =
                    NSDate.fromInternetString(current.itemPublishedDate) ??
                    article!.publishDate
            
            case .ItemDesc:
                article!.summary = article!.rawSummary?.withoutHTMLTagsAndNewlines
            
            default:
                break
            
        }
        closeElement()
    }
    
}