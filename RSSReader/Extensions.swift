//
//  ImageExtension.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

extension UIImage {
    var pngRepresentation: NSData? {
        return UIImagePNGRepresentation(self)
    }
}


// as of October 23, 2014, class variables are not yet supported,
// so this will have to be declared here for now instead.
private var _internetDateFormatter: NSDateFormatter?

// Extension for RSS/Atom date string parsing.
extension NSDate {
    
    // hints for which to try first.
    enum InternetHint {
        case RFC822, RFC3339
    }
    
    // possible date formats.
    private struct Format {
        static let rfc8FormatsWithCommas = [
            "EEE, d MMM yyyy HH:mm:ss zzz",
            "EEE, d MMM yyyy HH:mm zzz",
            "EEE, d MMM yyyy HH:mm:ss",
            "EEE, d MMM yyyy HH:mm"
        ]
        
        static let rfc8FormatsNoCommas = [
            "d MMM yyyy HH:mm:ss zzz",
            "d MMM yyyy HH:mm zzz",
            "d MMM yyyy HH:mm:ss",
            "d MMM yyyy HH:mm"
        ]
        
        static let rfc3Formats = [
            "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ",
            "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
        ]
    }
    
    // use the same formatter over and over.
    class var internetDateFormatter: NSDateFormatter {
        if _internetDateFormatter == nil {
            let locale = NSLocale(localeIdentifier: "en_US_POSIX")
            _internetDateFormatter = NSDateFormatter()
            _internetDateFormatter!.locale = locale
            _internetDateFormatter!.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        }
        return _internetDateFormatter!
    }
    
    // from either, with an optional hint.
    class func fromInternetString(string: String, hint: InternetHint = .RFC822) -> NSDate? {
        if hint == .RFC822 {
            return fromRFC822String(string) ?? fromRFC3339String(string)
        }
        return fromRFC3339String(string) ?? fromRFC822String(string)
    }
    
    // from RFC822.
    class func fromRFC822String(var string: String) -> NSDate? {
        string = string.uppercaseString
        var date: NSDate?
        
        // try formats with commas.
        for format in Format.rfc8FormatsWithCommas {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.dateFromString(string)
            if date != nil { return date }
        }
        
        // try formats without commas.
        for format in Format.rfc8FormatsNoCommas {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.dateFromString(string)
            if date != nil { return date }
        }
        
        return date
    }
    
    // from RFC3339.
    class func fromRFC3339String(string: String) -> NSDate? {
        var date: NSDate?
        for format in Format.rfc3Formats {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.dateFromString(string)
            if date != nil { return date }
        }
        return date
    }
    
}

extension String {
    var withoutHTMLTags: String {
        var s = self as NSString
        var r: NSRange!
        do {
            r = s.rangeOfString("<[^>]+>", options: .RegularExpressionSearch)
            if r == nil || r.location == NSNotFound {
                return s
            }
            s = s.stringByReplacingCharactersInRange(r!, withString: "")
        } while true
    }
}