//
//  Settings.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/14/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import Foundation

// MARK:- Settings

class FeedReaderSettings {
    let defaults: UserDefaults
    
    init(defaults: UserDefaults) {
        self.defaults = defaults
        registerDefaults()
    }
    
    // register default values
    func registerDefaults() {
        defaults.register(defaults: [
            "daysToKeepArticles":   10,
            "articleSortMethod":    SortOption.NewestFirst.rawValue,
            "markReadMethod":       UnreadOption.MarkWhenTapped.rawValue,
            "backgroundRefresh":    false,
            "backgroundFrequency":  3
        ])
    }
    
    // MARK: Sorting
    
    enum SortOption: String {
        case NewestFirst  = "SortSettingNewestFirst"
        case OldestFirst  = "SortSettingOldestFirst"
        case Alphabetical = "SortSettingAlphabetical"
    }
    
    // the selected sorting method
    var articleSortMethod: SortOption {
        set { defaults.set(newValue.rawValue, forKey: "articleSortMethod") }
        get { return SortOption(rawValue: defaults.object(forKey: "articleSortMethod") as! String) ?? .NewestFirst }
    }

    // a function to sort articles with the selected method
    var articleSorter: (Article, Article) -> Bool {
        switch articleSortMethod {
            case .NewestFirst:  return sortNewestFirst
            case .OldestFirst:  return sortOldestFirst
            case .Alphabetical: return sortAtoZ
            default:            return sortNewestFirst
        }
    }
    
    // MARK: Article storage
    
    // how many days to keep an article before deleting it
    var daysToKeepArticles: Int {
        set { defaults.set(newValue, forKey: "daysToKeepArticles") }
        get { return defaults.integer(forKey: "daysToKeepArticles") }
    }
    
    // returns true if the article should be disposed of.
    // this setting may be specific to the group or use the master setting
    func articleIsExpired(_ article: Article) -> Bool {        
        let calendar = Calendar(identifier: NSGregorianCalendar)!
        let daysSince = calendar.components(.CalendarUnitDay, fromDate: article.publishDate, toDate: Date(), options: nil)
        return daysSince.day >= article.feed.group.daysToKeepArticles
    }
    
    // MARK: Article unread marker
    
    enum UnreadOption: String {
        
        // only mark read if the user opens the article webpage
        case MarkWhenTapped = "UnreadOptionMarkWhenTapped"
        
        // mark read as soon as the user sees it in the list
        case MarkFromList = "UnreadOptionMarkFromList"
        
    }

    // selected method for marking read
    var markReadMethod: UnreadOption {
        set { defaults.set(newValue.rawValue, forKey: "markReadMethod") }
        get { return UnreadOption(rawValue: defaults.object(forKey: "markReadMethod") as! String) ?? .MarkWhenTapped }
    }
 
    // MARK: Background updates
    
    // enable or disable background updates
    var backgroundRefresh: Bool {
        set { defaults.set(newValue, forKey: "backgroundRefresh") }
        get { return defaults.bool(forKey: "backgroundRefresh") }
    }
    
    // how often to update in background in hours
    var backgroundFrequency: Int {
        set { defaults.set(newValue, forKey: "backgroundFrequency") }
        get { return defaults.integer(forKey: "backgroundFrequency") }
    }
    
}

// Sort settings

private let sortNewestFirst: (Article, Article) -> Bool = {
    
    // same, fallback to alphabetical
    if $0.publishDate == $1.publishDate {
        return sortAtoZ($0, $1)
    }
    
    return $0.publishDate.laterDate($1.publishDate as Date) == $0.publishDate
}

private let sortOldestFirst: (Article, Article) -> Bool = {
    
    // same, fallback to alphabetical
    if $0.publishDate == $1.publishDate {
        return sortAtoZ($0, $1)
    }
    
    return $0.publishDate.laterDate($1.publishDate as Date) == $1.publishDate
}

private let sortAtoZ: (Article, Article) -> Bool = {
    $0.titleForSorting < $1.titleForSorting
}

// Global instance

let settings = FeedReaderSettings(defaults: UserDefaults.standard)
