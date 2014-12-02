//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit
import CoreData

class FeedDefaultVC: FeedListVC {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Feeds"
        self.navigationItem.rightBarButtonItem?.action = "addButtonTappedTwo:"
    }
    
    // MARK:- Table view source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : group.feeds.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
            
            case .Delete:
                
                let feed = group.managedFeeds[indexPath.row] as Feed
                group.mutableFeeds.removeObject(feed)
                rss.manager.removeFeed(feed)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

            // case .Insert:
            // case .None:
            
            default:
                break
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        //FIXME: doesn't work.
        swap(&group.mutableFeeds[sourceIndexPath.row], &group.mutableFeeds[destinationIndexPath.row])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // this is the top cell.
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
            cell.textLabel.text = "All articles"
            cell.accessoryType = .DisclosureIndicator
            return cell
        }
        
        // first, try to dequeue a cell.
        var cell: FeedListCell
        if let cellMaybe = tableView.dequeueReusableCellWithIdentifier("feed") as? FeedListCell {
            cell = cellMaybe
        }
        
        // create a new cell.
        else {
            let items = NSBundle.mainBundle().loadNibNamed("FeedListCell", owner: self, options: nil)
            cell = items[0] as FeedListCell
            cell.accessoryType = .DisclosureIndicator
        }
        
        let feed            = group.feeds[indexPath.row]
        cell.label.text     = feed.loading ? "Loading..." : feed.title
        cell.iconView.image = feed.logo
        cell.iconView.sizeToFit()
        
        return cell
    }
    
    // user selected a feed.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // group.
        if indexPath.section == 0 {
            pushArticleViewToCollection(group)
            return
        }
        
        // feed.
        let feed = group.feeds[indexPath.row]
        
        // no articles; fetch them
        if feed.articles.count == 0 {
            feed.fetch()
        }
    
        pushArticleViewToCollection(feed)
    }
    
    
    func addButtonTappedTwo(sender: AnyObject) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // feed button.
        let action1 = UIAlertAction(title: "Feed", style: .Default) { _ in
            return self.addButtonTapped(sender)
        }
        alert.addAction(action1)
        
        // group button.
        let action2 = UIAlertAction(title: "Group", style: .Default) { _ in
            
            return
        }
        alert.addAction(action2)
        
        // cancel button.
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // present it.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
}