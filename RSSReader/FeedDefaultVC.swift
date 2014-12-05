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
    private var _textField : UITextField?

    override var secAllArticles: Int { return 0 }
             var secGroupList:   Int { return 1 }
    override var secFeedList:    Int { return 2 }
    
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
            case secAllArticles: return 1
            case secGroupList:   return rss.manager.notDefaultGroups.count
            case secFeedList:    return group.feeds.count
            default: return 0
        }
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
            
            // group list edit.
            case secGroupList:
                return
            
            // default group feed list edit.
            case secFeedList:
                switch editingStyle {
                    
                    case .Delete:
                        
                        let feed = group.managedFeeds[indexPath.row] as Feed
                        group.mutableFeeds.removeObject(feed)
                        rss.manager.removeFeed(feed)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                    // case .Insert:
                    // case .None:
                    
                    default: break
                }
            
            default: break
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != secAllArticles
    }
    
    // the "all articles" button cannot be moved.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != secAllArticles
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
            case secAllArticles:  return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
            case secGroupList:    return cellForGroupAtRow(indexPath.row)
            case secFeedList:
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
        
        // show all articles in all groups.
        if indexPath.section == secAllArticles {
            pushArticleViewToCollection(group)
            return
        }
        
        // show feeds in group.
        if indexPath.section == secGroupList {
            let group = rss.manager.notDefaultGroups[indexPath.row]
            return pushFeedViewForGroup(group)
        }
        
        // show articles in feed.
        let feed = group.feeds[indexPath.row]
        
        // no articles; fetch them
        if feed.articles.count == 0 {
            feed.fetch()
        }
    
        pushArticleViewToCollection(feed)
    }
    
    
    func addButtonTappedTwo(sender: AnyObject) {
        let alert = UIAlertController(title: "Create new...", message: nil, preferredStyle: .ActionSheet)

        // feed button.
        let action1 = UIAlertAction(title: "Feed", style: .Default) { _ in
            return self.presentFeedCreator(sender)
        }
        alert.addAction(action1)
        
        // group button.
        let action2 = UIAlertAction(title: "Group", style: .Default) { _ in
            return self.presentGroupCreator(sender)
        }
        alert.addAction(action2)
        
        // cancel button.
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // present it.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func presentGroupCreator(sender: AnyObject) {
        let alert = UIAlertController(title: "Create group", message: nil, preferredStyle: .Alert)
        
        // text field.
        alert.addTextFieldWithConfigurationHandler { textField in
            self._textField = textField
            textField.placeholder = "URL"
        }
        
        // OK button.
        let action = UIAlertAction(title: "OK", style: .Default) { _ in
            
            // empty string?
            let string = self._textField!.text!
            self._textField = nil
            if string.isEmpty { return }

            // create the group.
            let group = rss.manager.newGroupTitled(string)
            rss.manager.addGroup(group)
            let path = NSIndexPath(forRow: rss.manager.notDefaultGroups.count - 1, inSection: self.secGroupList)
            self.tableView.insertRowsAtIndexPaths([path], withRowAnimation: .Automatic)
            
            return
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // present it.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
}