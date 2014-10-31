//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit
import CoreData

class FeedListVC: UITableViewController {
    private var _textField : UITextField?
    var group: FeedGroup!

    convenience init(group: FeedGroup) {
        self.init()
        self.group = group
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = group.title
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonTapped:")
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
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

    // all rows are editable.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
    
    // MARK:- Interface interaction
    
    // push to the article list view for a feed.
    func pushArticleViewToCollection(collection: ArticleCollection) {
        let artVC = ArticleListVC(style: .Grouped)
        artVC.collection = collection
        self.navigationController?.pushViewController(artVC, animated: true)
    }
    
    
    func addButtonTapped(sender: AnyObject) {
        let alert = UIAlertController(title: "Add feed", message: nil, preferredStyle: .Alert)
        
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
            if countElements(string) < 1 { return }
            
            // does the feed exist already? reload it.
            if let feed = rss.manager.feedFromURLString(string) {
                feed.fetch()
                self.tableView.reloadData()
                return
            }
            
            // create and add the feed.
            let newFeed = rss.manager.newFeedWithUrlString(string)
            self.group.addFeed(newFeed)
        
            // fetch feed, update the table, save to database.
            newFeed.fetch()
            self.tableView.reloadData()
            
            return
        }
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        // present it.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
        
}