//
//  Article.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/29/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation

class Article {
    
    // these are implicitly unwrapped optionals
    // because an article object will ONLY be dealt with
    // without them set inside of the XML parsing stage.
    var title: String!
    var link:  String!
    
    init() {
    }
}