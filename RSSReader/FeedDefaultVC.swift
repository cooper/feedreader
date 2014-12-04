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
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 0 = all articles button
        // 1 = group list
        // 2 = feeds in default group
        switch section {
            case 0:  return 1
            case 1:  return rss.manager.notDefaultGroups.count
            case 2:  return group.feeds.count
            default: return 0
        }
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
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        //FIXME: doesn't work.
        swap(&group.mutableFeeds[sourceIndexPath.row], &group.mutableFeeds[destinationIndexPath.row])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // 0 = all articles button
        // 1 = group list
        // 2 = feeds in default group
        switch indexPath.section {
            case 0:  return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            case 1:  return cellForGroupAtRow(indexPath.row)
            case 2:
                let path = NSIndexPath(forRow: indexPath.row, inSection: 1)
                return super.tableView(tableView, cellForRowAtIndexPath: path)
            default: return UITableViewCell()
        }
    }
    
    func cellForGroupAtRow(row: NSInteger) -> UITableViewCell {
        let group = rss.manager.notDefaultGroups[row]
        let cell = UITableViewCell()
        cell.textLabel.text = group.title
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