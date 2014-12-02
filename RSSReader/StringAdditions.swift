//
//  StringExtensions.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

extension String {
    
    var withoutHTMLTagsAndNewlines: String {
        var s = self as NSString
        var r: NSRange!
        do {
            r = s.rangeOfString("<[^>]+>", options: .RegularExpressionSearch)
            if r == nil || r.location == NSNotFound {
                return s.stringByReplacingOccurrencesOfString("\n", withString: "")
            }
            s = s.stringByReplacingCharactersInRange(r!, withString: "")
        } while true
    }
    
}