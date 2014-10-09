//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class FeedListVC: UITableViewController, UITableViewDataSource {
    private var _textField : UITextField?
    
    override func viewDidLoad() {
        self.navigationItem.title = "Feeds"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addButtonTapped:")
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rss.manager.feeds.count
    }

    // all rows are editable.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
            
            case .Delete:
                rss.manager.feeds.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                rss.saveChanges()
            
            // case .Insert:
            // case .None:
            
            default:
                break
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        swap(&rss.manager.feeds[sourceIndexPath.row], &rss.manager.feeds[destinationIndexPath.row])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // first, try to dequeue a cell.
        var cell: UITableViewCell
        if let cellMaybe = tableView.dequeueReusableCellWithIdentifier("feed") as? UITableViewCell {
            cell = cellMaybe
        }
        
        // create a new cell.
        else {
            
            // this is failable, but I don't see how it could ever fail...?!
            cell = UITableViewCell(style: .Default, reuseIdentifier: "feed")!
            
        }
        
        let feed             = rss.manager.feeds[indexPath.row];
        cell.textLabel?.text = feed.loading ? "Loading..." : feed.title
        return cell
    }
    
    // user selected a feed.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let feed = rss.manager.feeds[indexPath.row]
        
        // no articles; fetch them
        if feed.articles.count == 0 {
            feed.fetchThen {
                self.pushArticleView(feed)
            }
        }
    
        // already fetched.
        else {
            pushArticleView(feed)
        }
        
        
    }
    
    // push to the article list view for a feed.
    func pushArticleView(feed: Feed) {
        
        // ensure this is done in the main queue.
        NSOperationQueue.mainQueue().addOperationWithBlock {
            let artVC = ArticleListVC(nibName: nil, bundle: nil)
            artVC.feed = feed
            self.navigationController?.pushViewController(artVC, animated: true)
        }

    }
    
    func addButtonTapped(sender: AnyObject) {
        let alert = UIAlertController(title: "Add feed", message: nil, preferredStyle: .Alert)
        
        // text field.
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            self._textField = textField
            textField.placeholder = "URL"
        }
        
        // OK button.
        let action = UIAlertAction(title: "OK", style: .Default) {
            (_: UIAlertAction!) -> Void in
            
            // empty string?
            let string = self._textField!.text!
            self._textField = nil
            if countElements(string) < 1 { return }
            
            // create and add the feed.
            let newFeed = Feed(urlString: string)
            rss.addNewFeed(newFeed)
            
            return
        }
        alert.addAction(action)

        // present it.
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
}