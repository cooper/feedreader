//
//  XMLParser.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class XMLParser: NSObject, NSXMLParserDelegate {
    private var feed: Feed
    private var parser: NSXMLParser
    
    init(feed: Feed, data: NSData) {
        self.feed = feed
        parser = NSXMLParser(data: data)
        super.init()
        parser.delegate = self
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
                article = rss.manager.newArticleForFeed(feed)
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
                feed.channelTitle = string
            
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
                feed.shouldFetchIcon = feed.icon == defaultImage || string != feed.iconUrlString
                feed.iconUrlString   = string
            
            // logo for the feed.
            case .FeedLogoURL:
                feed.shouldFetchLogo = feed.logo == defaultImage || string != feed.logoUrlString
                feed.logoUrlString   = string
            
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
                feed.iconUrlString = feed.iconUrlString ?? feed.logoUrlString
            
            // add the current article to the feed.
            // addArticle() MUST be called after the identifier (if any) has been determined.
            case .Item:
                feed.addArticle(article!)
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
    
    func parse() -> Bool {
        return parser.parse()
    }

}