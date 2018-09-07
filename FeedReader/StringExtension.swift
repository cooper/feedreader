//
//  StringExtensions.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

extension String {
    
    // returns a string without HTML tags and newlines
    var withoutHTMLTagsAndNewlines: String {
        var s = self as NSString
        var r: NSRange!
        repeat {
            r = s.range(of: "<[^>]+>", options: .regularExpression)
            if r == nil || r.location == NSNotFound {
                return s.replacingOccurrences(of: "\n", with: "")
            }
            s = s.replacingCharacters(in: r!, with: "") as NSString
        } while true
    }
    
    // returns a string trimmed by the whitespace character set
    var trimmed: String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    // returns a string safe for use as a filename
    var fileNameSafe: String {
        let set = CharacterSet.alphanumerics.inverted
        return "-".join(self.components(separatedBy: set))
    }
    
}
