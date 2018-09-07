//
//  DateAdditions.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

// as of October 23, 2014, class variables are not yet supported,
// so this will have to be declared here for now instead.
private var _internetDateFormatter: DateFormatter?

// Extension for RSS/Atom date string parsing.
extension Date {
    
    // hints for which to try first.
    enum InternetHint {
        case rfc822, rfc3339
    }
    
    // possible date formats.
    fileprivate struct Format {
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
    static var internetDateFormatter: DateFormatter {
        if _internetDateFormatter == nil {
            let locale = Locale(identifier: "en_US_POSIX")
            _internetDateFormatter = DateFormatter()
            _internetDateFormatter!.locale = locale
            _internetDateFormatter!.timeZone = TimeZone(secondsFromGMT: 0)
        }
        return _internetDateFormatter!
    }
    
    // from either, with an optional hint.
    static func fromInternetString(_ string: String, hint: InternetHint = .rfc822) -> Date? {
        if hint == .rfc822 {
            return fromRFC822String(string) ?? fromRFC3339String(string)
        }
        return fromRFC3339String(string) ?? fromRFC822String(string)
    }
    
    // from RFC822.
    static func fromRFC822String(_ string: String) -> Date? {
        var string = string
        string = string.uppercased()
        var date: Date?
        
        // try formats with commas.
        for format in Format.rfc8FormatsWithCommas {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.date(from: string)
            if date != nil { return date }
        }
        
        // try formats without commas.
        for format in Format.rfc8FormatsNoCommas {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.date(from: string)
            if date != nil { return date }
        }
        
        return date
    }
    
    // from RFC3339.
    static func fromRFC3339String(_ string: String) -> Date? {
        var date: Date?
        for format in Format.rfc3Formats {
            internetDateFormatter.dateFormat = format
            date = internetDateFormatter.date(from: string)
            if date != nil { return date }
        }
        return date
    }
    
}

