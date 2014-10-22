//
//  Feed.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

let defaultImage = UIImage(named: "news.png")!

//
// this class must inherit from NSObject because it complies with
// an Objective-C protocol (NSXMLParserDelegate)
//
class Feed: NSObject, Printable, ArticleCollection, NSXMLParserDelegate {
    
    // MARK:- Feed details
    //                                                                              Stored
    
    let url: NSURL;                         // the URL of the feed                     (S)
    var articles = [Article]()              // articles in the feed                    (S)
    var articlesById = [String: Article]()  // articles by identifier                  (S)
    var channelTitle: String?               // actual title from the feed              (S)
    var userSetTitle: String?               // nickname assigned by user               (S)
    
    // best title option available.
    var title: String {
        return userSetTitle ?? channelTitle ?? url.absoluteString!
    }
    
    // index in feed manager.
    var index: Int {
        return find(rss.manager.feeds, self)!
    }
    
    var loading = false                     // is it being fetched now?
    weak var currentGroup: FeedGroup?       // current feed group in user interface
    
    // icon and logo.                       // for atom:
    var logo = defaultImage                 // ideally 1:1 ratio (small size)          (S)
    var icon = defaultImage                 // ideally 2:1 ratio (a bit bigger)        (S)
                                            // for RSS: the two are equivalent, size any.
    var iconURLString: String?              // URL of image representing of the feed   (S)
    var logoURLString: String?              // URL of image representing of the feed   (S)
    private var shouldFetchIcon = false     // whether it's necessary to fetch icon
    private var shouldFetchLogo = false     // whether it's necessary to fetch logo
    
    // MARK:- Feed methods
    
    // printable description
    override var description: String {
        return "Feed \(url.absoluteString!)"
    }
    
    init(url feedUrl: NSURL) {
        url = feedUrl
    }
    
    convenience init(urlString: String) {
        let feedUrl = NSURL(string: urlString)!
        self.init(url: feedUrl)
    }
    
    convenience init(storage: NSDictionary) {
        self.init(urlString: storage["urlString"]! as String)
        
        // these are all optional strings.
        // I did this because I like inout.
        func setMaybe(inout target: String?, name: String) {
            target = storage[name] as? String
        }
        setMaybe(&userSetTitle,  "userSetTitle")
        setMaybe(&channelTitle,  "channelTitle")
        setMaybe(&iconURLString, "iconURLString")
        setMaybe(&logoURLString, "logoURLString")
        
        // images.
        if let iconData = storage["icon"] as? NSData {
            icon = UIImage(data: iconData)!
        }
        if let logoData = storage["logo"] as? NSData {
            logo = UIImage(data: logoData)!
        }
        
        // add articles.
        for articleDict in storage["articles"]! as [NSDictionary] {
            let article = Article(feed: self, storage: articleDict)
            addArticle(article)
        }
        
    }
    
    // add an article to the feed, remembering it by both index and identifier.
    func addArticle(article: Article) {
        
        // this one already exists; update it.
        if articlesById[article.identifier] != nil {
            articlesById[article.identifier] = article
            articles[ find(articles, article)! ] = article
        }
        
        // add it for the first time.
        else {
            articlesById[article.identifier] = article
            articles.append(article)
        }
        
    }
    
    // fetch the feed data.
    // TODO: use separate operation queue
    func fetchThen (then: (Void -> Void)?) {
    
        loading = true
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            
            self.loading = false
            println("Fetching \(self.title)")
            
            // error.
            if error != nil {
                println("There was an error in \(self.title): \(error)")
                return
            }
            
            // FIXME: is it possible for this to fail?
            let parser = NSXMLParser(data: data)!
            parser.delegate = self
            
            // initiate XML parser in this same queue.
            //println("Parsing the data")
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
    
    func fetchImage(urlString: String!, _ doIt: Bool, handler: (UIImage) -> Void) {
        
        // no image URL specified.
        if urlString == nil || !doIt { return }
        
        // send the request from the feed queue.
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) {
            res, data, error in
            
            // error.
            if error != nil {
                println("There was an error loading the image: \(error)")
                return
            }
            
            // apparently working with UIImage is threadsafe now.
            handler(UIImage(data: data)!)
            
            // reload the table in the main queue, if there is one visible.
            mainQueue {
                rss.currentFeedVC?.tableView.reloadData()
                return
            }
            
        }
        
    }
    
    // download the image, then optionally reload a table view.
    func downloadImages() {
        fetchImage(logoURLString, shouldFetchLogo) { self.logo = $0 }
        fetchImage(iconURLString, shouldFetchIcon) { self.icon = $0 }
    }
    
    // convenience for fetching with no callback.
    func fetch () {
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
            case ItemId         // identifier of aitem          <guid>              <id>
            
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
    var currentArticle : Article?
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
        set {
            adoptNewElement(newValue)
        }
        get {
            return element.type
        }
    }
    
    // MARK:- XML parsing
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        let attributes = attributeDict as [String: String]
        println("Starting element: \(elementName)")
        
        switch elementName {
            
            case "channel", "feed":
                elementType = .Channel
            
            // if there's an article, this is its title.
            case "title" where element.type == .Item && currentArticle != nil:
                elementType = .ItemTitle
            
            // otherwise, this is the feed title.
            case "title" where element.type == .Channel:
                elementType = .FeedTitle
            
            // the start of an article.
            case "item", "entry":
                currentArticle = Article(feed: self)
                elementType = .Item

            // link of an article.
            case "link" where element.type == .Item && currentArticle != nil:
                elementType = .Link

                switch attributes["rel"] ?? "alternate" {
                    
                    // edit link.
                    case "edit":
                        println("Edit")
                    
                    // the main link.
                    case "alternate" where attributes["href"] != nil:
                        currentArticle!.urlString = attributes["href"]
                    
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
            case "guid", "id" where element.type == .Item:
                elementType = .ItemId

            // some other element that we do not handle.
            default:
                //println("Unkown element \(elementName)")
                elementType = .Unknown
            
        }

    }
    
    // found some characters that are not part of an element.
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        switch element.type {
            
            // the title of the feed.
            case .FeedTitle:
                channelTitle = string
            
            // the title of an article.
            case .ItemTitle:
                currentArticle?.title = string
            
            // in RSS, the link is within <link> tags (handled here).
            // in Atom, the link is in the href attribute.
            case .Link:
                currentArticle?.urlString = string

            // icon for the feed.
            case .FeedIconURL:
                shouldFetchIcon = icon == defaultImage || string != iconURLString
                iconURLString = string
            
            // logo for the feed.
            case .FeedLogoURL:
                shouldFetchLogo = logo == defaultImage || string != logoURLString
                logoURLString = string
            
            // item identifier.
            case .ItemId:
                currentArticle?._identifier = string
            
            // some other element...
            default:
                break
            
        }
    }

    //func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String, qualifiedName qName: String) {
    func parser(parser: NSXMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        switch elementName {
            
            case "channel", "feed":
                iconURLString = iconURLString ?? logoURLString
            
            // add the current article to the feed.
            // addArticle() MUST be called after the identifier (if any) has been determined.
            case "item", "entry":
                addArticle(currentArticle!)
                currentArticle = nil
            
            default:
                break
            
        }
        closeElement()
    }
    
    // returns NSDictionary because it will be converted to such anyway.
    var forStorage: NSDictionary {
        
        // note: URLs can be stored in user defaults
        /// but apparently not inside of a collection
        
        // articles are stored as an array, but when they are added back to
        // the feed, they are stored in RAM by identifier as well.
        let dict: NSMutableDictionary = [
            "urlString":    url.absoluteString!,
            "articles":     articles.map { $0.forStorage }
        ]

        let logoData: NSData? = logo == defaultImage ? nil : UIImagePNGRepresentation(logo)
        let iconData: NSData? = icon == defaultImage ? nil : UIImagePNGRepresentation(icon)
        
        // these optionals should be left out if not present.
        let optionals: [String : AnyObject?] = [
            "channelTitle":     channelTitle,
            "userSetTitle":     userSetTitle,
            "iconURLString":    iconURLString,
            "logoURLString":    logoURLString,
            "logo":             logoData,
            "icon":             iconData
        ]
        for (key, value) in optionals {
            if value == nil { continue }
            dict[key] = value!
        }

        return dict
    }
    
}