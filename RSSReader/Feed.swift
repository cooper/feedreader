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
    //let feedQueue = NSOperationQueue()
    var articles  = [Article]()
    
    enum ElementType {
        case None, FeedTitle, ItemTitle, Item
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
    
    // fetch the feed data.
    func fetch () {
        
        // create a parser with the feed URL and parse.
        if let parser = NSXMLParser(contentsOfURL: url) {
            parser.delegate = self
            println("Parsing the data")
            parser.parse()
            
            let articleNames = articles.map({ $0.title ?? "Unknown title" })
            println("Here are the articles: \(articleNames) for the feed named \(title)")
            
        }
            
        // error occured.
        else {
            println("NSXMLParser initialization error")
        }
        
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
                currentArticle = Article()

            case "link":
                
                // if there's no article, ignore this.
                if currentArticle == nil {
                    break
                }
                
                switch attributes["rel"] ?? "" {
                    
                    // alternate link.
                    case "alternate":
                        println("Alternate")
                    
                    // edit link.
                    case "edit":
                        println("Edit")
                    
                    // no rel
                    case "":
                        currentArticle?.link = attributes["href"]
                    
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

}