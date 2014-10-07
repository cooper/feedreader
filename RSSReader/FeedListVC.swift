//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import Foundation
import UIKit

class FeedListVC: UITableViewController, UITableViewDataSource {
    
    var colors = [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor()]
    
    override func viewDidLoad() {
        println("view did load")
        println("table view: \(tableView)")
        println("view: \(view)")
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rss.feedManager.feeds.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = rss.feedManager.feeds[indexPath.row].url.absoluteString
        cell.backgroundColor = colors.removeAtIndex(0)
        colors.append(cell.backgroundColor!)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let feed = rss.feedManager.feeds[indexPath.row]
        feed.fetch()
    }
}