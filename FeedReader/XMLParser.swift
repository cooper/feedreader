//
//  XMLParser.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class XMLParser: NSObject, XMLParserDelegate {
    fileprivate var feed: Feed
    fileprivate var parser: Foundation.XMLParser
    
    // initialize with a feed and some unparsed XML data
    init(feed: Feed, data: Data) {
        self.feed = feed
        parser = Foundation.XMLParser(data: data)
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

            case none           // No element (main scope)      n/a                 n/a
            case unknown        // Unknown element type         n/a                 n/a
            
            case feedTitle      // title of the feed            <title>             <title>
            case feedImage      // image for feed               <image>             n/a
            case feedIconURL    // feed image URL               <url>               <icon>
            case feedLogoURL    // feed image URL               <url>               <logo>
            case channel        // RSS feed channel             <channel>           <feed>
            case link           // URL for feed                 <link>              <link>
            
            case item           // an item or article           <item>              <entry>
            case itemTitle      // title of an item             <title>             <title>
            case itemId         // identifier of item           <guid>              <id>
            case itemDesc       // description of item          <description>       <summary>
            case itemThumb      // thumbnail URL of item        <image>/<media:>
            case itemPubDate    // date of item publish         <pubDate>           <published>
                                //                                                  or <updated>
            
        }
        
        // type of the element and its parent, if any.
        var type = Kind.none
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
    func adoptNewElement(_ type: Element.Kind) {
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
    
    // current variables not stored in article,
    // useful for properties that must be stored only when in full
    struct current {
        static var itemPublishedDate = ""
    }
    
    // MARK:- XML parsing
    
    func parser(_ parser: Foundation.XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [AnyHashable: Any]) {
        let attributes = attributeDict as! [String: String]
        
        switch elementName {
            
            // start a feed
            case "channel", "feed":
                elementType = .channel
                feed.channelTitle = ""
            
            // if there's an article, this is its title
            case "title" where element.type == .item && article != nil:
                elementType = .itemTitle
                article?.title = ""
            
            // otherwise, this is the feed title
            case "title" where element.type == .channel:
                elementType = .feedTitle
            
            // the start of an article
            case "item", "entry":
                article = Article(feed: feed)
                elementType = .item

            // link of an article
            case "link" where element.type == .item && article != nil:
                elementType = .link

                switch attributes["rel"] ?? "alternate" {
                    
                    // edit link
                    case "edit":
                        rss.log("Edit link found")
                    
                    // the main link
                    case "alternate" where attributes["href"] != nil:
                        article!.urlString = attributes["href"]!
                    
                    // some other link
                    default:
                        break
                    
                }
            
            // image of an feed (RSS)
            case "image" where element.type == .channel:
                elementType = .feedImage
            
            // feed logo URL (RSS = url, Atom = logo)
            case "url" where element.type == .feedImage,
                "logo" where element.type == .channel:
                
                elementType = .feedLogoURL
            
            // feed icon URL (Atom only)
            case "icon" where element.type == .channel:
                
                elementType = .feedIconURL
            
            // identifier for an article or item
            case "guid" where element.type == .item,
                 "id"   where element.type == .item:
                
                elementType = .itemId
            
            // item description
            case "description" where element.type == .item,
                 "summary"     where element.type == .item:
                
                elementType = .itemDesc
                article?.rawSummary = ""
            
            // item publish date
            case "pubDate"   where element.type == .item,
                 "published" where element.type == .item,
                 "updated"   where element.type == .item: // FIXME: updated vs published
                
                elementType = .itemPubDate
                current.itemPublishedDate = ""
            
            // item thumbnail
            case "media:thumbnail" where element.type == .item:
                
                elementType = .itemThumb
                if let urlString = attributes["url"] {
                    article!.shouldFetchThumb = urlString != article!.thumbImageUrlString || article!.thumbImage == nil
                    article!.thumbImageUrlString = urlString
                }
            
            // some other element that we do not handle
            default:
                elementType = .unknown
            
        }

    }
    
    // found some characters that are not part of an element.
    // note: it seems that this will be called several times with the data in pieces
    // if the any of the characters are encoded with entities like &gt; etc.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch element.type {
            
            // the title of the feed
            case .feedTitle:
                feed.channelTitle! += string
            
            // the title of an article
            case .itemTitle:
                article?.title += string
            
            // in RSS, the link is within <link> tags (handled here).
            // in Atom, the link is in the href attribute.
            case .link:
                article?.urlString = string

            // icon for the feed
            case .feedIconURL:
                feed.shouldFetchIcon = string != feed.iconUrlString
                feed.iconUrlString   = string
            
            // logo for the feed
            case .feedLogoURL:
                feed.shouldFetchLogo = string != feed.logoUrlString
                feed.logoUrlString   = string
            
            // item identifier
            case .itemId:
                article?.identifier = string
            
            // item description
            case .itemDesc:
                if article?.rawSummary == nil {
                    article?.rawSummary = string
                    break
                }
                article?.rawSummary += string
            
            case .itemPubDate:
                current.itemPublishedDate += string
            
            // some other element...
            default:
                break
            
        }
    }

    // an element ended
    func parser(_ parser: XMLParser, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        switch element.type {
            
            // channel ended,
            // replace missing images with counterparts if possible.
            case .channel:
                feed.iconUrlString = feed.iconUrlString ?? feed.logoUrlString
                feed.logoUrlString = feed.logoUrlString ?? feed.iconUrlString
            
            // add the current article to the feed.
            // addArticle() MUST be called after the identifier (if any) has been determined.
            case .item:
                
                // no date? use right now
                if article!.publishDate == nil {
                    article!.publishDate = Date()
                    rss.log("No publish date for article [\(feed.title)] \(article!.title)")
                }
                if article!.identifier == nil {
                    article!.identifier = article?.urlString
                }
                
                article!.title = article!.title.trimmed
                feed.addArticle(article!)
                article = nil
            
            // publish date
            case .itemPubDate:
                article!.publishDate =
                    Date.fromInternetString(current.itemPublishedDate) ??
                    article!.publishDate
                current.itemPublishedDate = ""
            
            // item title
            case .itemTitle:
                article!.title = WSLHTMLEntities.convertHTMLtoString(article!.title)
            
            // item summary
            case .itemDesc:
                article!.summary = WSLHTMLEntities.convertHTMLtoString(article!.rawSummary.withoutHTMLTagsAndNewlines)?.trimmed ?? ""

            default:
                break
            
        }
        
        // close the current
        closeElement()
        
    }
    
    // an error occurred.
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        
        // show on the current view controller, if any
        if let vc = rss.currentFeedVC {
            let alert = PSTAlertController(title: "Feed error", message: "An error occurred for \"\(feed.title)\": \(parseError.localizedDescription)", preferredStyle: .alert)
            alert?.addAction(PSTAlertAction(title: "OK", handler: nil))
            alert?.showWithSender(nil, controller: vc, animated: true, completion: nil)
        }
        
    }
    
    // initiate the parser
    func parse() -> Bool {
        return parser.parse()
    }

}
