//
//  Feed.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

//
// this class must inherit from NSObject because it complies with
// an Objective-C protocol (NSXMLParserDelegate)
//
class Feed: NSObject, Printable, NSXMLParserDelegate {
    
    // MARK:- Feed details
    
    let url: NSURL;                     // the URL of the feed
    var articles = [Article]()          // articles in the feed
    var loading  = false                // is it being fetched now?
    var imageURL: String?               // URL of image representing of the feed
    weak var currentGroup: FeedGroup?   // current feed group in user interface
    
    // title will default to the URL if not present.
    private var _title : String?
    var title: String {
        return _title ?? url.absoluteString!
    }
    
    // index in feed manager.
    var index: Int {
        return find(rss.manager.feeds, self)!
    }
    
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
        _title = (storage["title"]! as String)
        
        // add articles.
        for articleDict in storage["articles"]! as [NSDictionary] {
            let article = Article(feed: self, storage: articleDict)
            addArticle(article)
        }
        
    }
    
    func addArticle(article: Article) {
        articles.append(article)
    }
    
    // fetch the feed data.
    // TODO: use separate operation queue
    func fetchThen (then: (Void -> Void)?) {
    
        loading = true
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: rss.feedQueue) { res, data, error in
            self.loading = false

            // error.
            if error != nil {
                println("There was an error: \(error)")
                return
            }
            
            // FIXME: is it possible for this to fail?
            let parser = NSXMLParser(data: data)!
            parser.delegate = self
            
            // initiate XML parser in this same queue.
            //println("Parsing the data")
            parser.parse()

            // in the main queue, reload the table, then call callback.
            NSOperationQueue.mainQueue().addOperationWithBlock {
                rss.currentFeedVC?.tableView.reloadData()
                then?()
            }
            
            return
        }
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
                                //
            case None           // No element (main scope)      n/a                 n/a
            case Unknown        // Unknown element type         n/a                 n/a
            
            case FeedTitle      // title of the feed            <title>             <title>
            case FeedImage      // image for feed               <image>             n/a
            case FeedImageURL   // feed image URL               <url>               <icon> or <logo>
            case Channel        // RSS feed channel             <channel>           <feed>
            case Link           // URL for feed                 <link>              <link>
            
            case Item           // an item or article           <item>              <entry>
            case ItemTitle      // title of an item             <title>             <title>
            
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
    var currentElement = Element()
    
    // open an element as a child of the current element.
    func setCurrentElement(type: Element.Kind) {
        let old = currentElement
        currentElement = Element(kind: type)
        currentElement.parent = old
    }
    
    // close the current element.
    func closeCurrentElement() {
        currentElement = currentElement.parent ?? Element()
    }
    
    // MARK:- XML parsing
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        let attributes = attributeDict as [String: String]
        //println("Starting element: \(elementName)")
        
        switch elementName {
            
            case "channel", "feed":
                setCurrentElement(.Channel)
            
            // if there's an article, this is its title.
            case "title" where currentElement.type == .Item && currentArticle != nil:
                currentArticle!.title = String()
                setCurrentElement(.ItemTitle)
            
            // otherwise, this is the feed title.
            case "title" where currentElement.type == .Channel:
                _title = String()
                setCurrentElement(.FeedTitle)
            
            // the start of an article.
            case "item", "entry":
                setCurrentElement(.Item)
                currentArticle = Article(feed: self)

            // link of an article.
            case "link" where currentElement.type == .Item && currentArticle != nil:
                setCurrentElement(.Link)
                currentArticle!.urlString = String()

                switch attributes["rel"] ?? "alternate" {
                    
                    // edit link.
                    case "edit":
                        println("Edit")
                    
                    // the main link.
                    case "alternate":
                        if let href = attributes["href"] {
                            currentArticle!.urlString! += href
                        }
                    
                    // some other.
                    default:
                        break
                    
                }
            
            // image of an article.
            case "image" where currentElement.type == .Channel:
                setCurrentElement(.FeedImage)
            
            // feed image URL.
            case "url" where currentElement.type == .FeedImage:
                setCurrentElement(.FeedImageURL)
                imageURL = String()
            
            // some other element that we do not handle.
            default:
                setCurrentElement(.Unknown)
                //println("Unkown element \(elementName)")
            
        }

    }
    
    // found some characters that are not part of an element.
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        switch currentElement.type {
            
            // the title of the feed.
            case .FeedTitle:
                _title? += string
            
            // the title of an article.
            case .ItemTitle:
                currentArticle?.title? += string
            
            // in RSS, the link is within <link> tags (handled here).
            // in Atom, the link is in the href attribute.
            case .Link:
                currentArticle?.urlString? += string

            // image for the feed.
            case .FeedImageURL:
                imageURL? += string
            
            // some other element...
            default:
                break
            
        }
    }

    //func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String, qualifiedName qName: String) {
    func parser(parser: NSXMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        switch elementName {
            
            case "item", "entry":
                addArticle(currentArticle!)
                currentArticle = nil
            
            default:
                break
            
        }
        closeCurrentElement()
    }

    // returns NSDictionary because it will be converted to such anyway.
    var forStorage: NSDictionary {
        // note: URLs can be stored in user defaults
        /// but apparently not inside of a collection
        return [
            "title":        title,
            "urlString":    url.absoluteString!,
            "articles":     articles.map { $0.forStorage }
        ]
    }
    
}