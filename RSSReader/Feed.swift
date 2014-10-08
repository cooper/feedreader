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
    let url: NSURL;
    var articles  = [Article]()
    var loading = false
    weak var manager: FeedManager?
    
    enum ElementType {
        case None, FeedTitle, ItemTitle, Item, Link
    }
    
    // parser state.
    var currentArticle : Article?
    var currentElement = ElementType.None
    
    // title will default to the URL if not present.
    private var _title : String?
    var title: String {
        return _title ?? url.absoluteString!
    }
    
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
    
    convenience init(storage: [String: AnyObject]) {
        self.init(urlString: storage["urlString"]! as String)
        _title = (storage["title"]! as String)
    }
    
    // fetch the feed data.
    // TODO: use separate operation queue
    func fetchThen (then: (Void -> Void)?) {
    
        loading = true
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: self.manager!.feedQueue) {
            (res: NSURLResponse!, data: NSData!, error: NSError?) -> Void in
            self.loading = false
            
            // error.
            if error != nil {
                println("There was an error: \(error!)")
                return
            }
            
            // FIXME: is it possible for this to fail?
            let parser = NSXMLParser(data: data)!
            parser.delegate = self
            
            println("Parsing the data")
            parser.parse()
            
            // I don't know how to determine the index from here
            // because Swift does not have a method to find the
            // index of an item in an array.
            //
            //let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            //rss.feedVC.tableView.reloadRowsAtIndexPaths([ indexPath ], withRowAnimation: .Fade)
            //
            NSOperationQueue.mainQueue().addOperationWithBlock {
                rss.feedVC.tableView.reloadData()
            }
            
            then?()
            return
        }
        
    }
    
    func fetch () {
        fetchThen(nil)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        let attributes = attributeDict as [String: String]
        println("Starting element: \(elementName)")
        
        switch elementName {
            
            case "title":
            
                // if there's an article, this is its title.
                if let article = currentArticle {
                    article.title  = String()
                    currentElement = .ItemTitle
                }
                    
                // otherwise, this is the feed title.
                // just to be safe, check whether the feed title already exists.
                else if _title == nil {
                    _title = String()
                    currentElement = .FeedTitle
                    println("Now in feed title")
                }
            
            case "item", "entry":
                currentElement = .Item
                currentArticle = Article(feed: self)

            case "link":

                // if there's no article, ignore this.
                if currentArticle == nil {
                    break
                }
                
                currentElement = .Link
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
                    
                    // main link.
                    default:
                        break
                    
                }
            
            default:
                println("Unkown element \(elementName)")
            
            
        }

    }
    
    // found some characters that are not part of an element name.
    func parser(parser: NSXMLParser, foundCharacters string: String) {

        switch currentElement {
            
            // the title of the feed.
            case .FeedTitle:
                _title? += string
                println("Dealing with the title: \(title)")
            
            // the title of an article.
            case .ItemTitle:
                currentArticle?.title? += string
            
            // in RSS, the link is within <link> tags (handled here).
            // in Atom, the link is in the href attribute.
            case .Link:
                currentArticle?.urlString? += string
            
            // some other element...
            default:
                break
            
        }
        
    }
    
    //func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String, qualifiedName qName: String) {
    func parser(parser: NSXMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        
        switch elementName {
            
            case "item", "entry":
                articles.append(currentArticle!)
                currentArticle = nil
            
            default:
                break
            
        }
        
        currentElement = .None
    }

    
    func forStorage() -> NSDictionary {
        // note: URLs can be stored in user defaults
        /// but apparently not inside of a collection
        return [
            "title":        title,
            "urlString":    url.absoluteString!,
            "articles":     articles.map { $0.forStorage() }
        ]
    }
    
}