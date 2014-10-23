//
//  ArticleListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/7/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class ArticleListVC: UITableViewController, UITableViewDataSource {
    var collection: ArticleCollection!

    override func viewDidLoad() {
        refresh()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.articles.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 140
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // first, try to dequeue a cell.
        var cell: ArticleListCell
        if let cellMaybe = tableView.dequeueReusableCellWithIdentifier("article") as? ArticleListCell {
            cell = cellMaybe
        }
            
        // create a new cell.
        else {
            let items = NSBundle.mainBundle().loadNibNamed("ArticleListCell", owner: self, options: nil)
            cell = items[0] as ArticleListCell
        }
        
        let article         = collection.articles[indexPath.row]
        cell.label.text     = article.title
        cell.iconView.image = defaultImage
        cell.descriptionView.text = article.summary
        cell.iconView.sizeToFit()
        cell.iconView.backgroundColor = UIColor.yellowColor()
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let article = collection.articles[indexPath.row]
        
        // create a view controller with a webview.
        let vc = UIViewController(nibName: nil, bundle: nil)
        let webView = UIWebView()
        webView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        vc.view = webView
        vc.navigationItem.title = article.title
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "presentAction:")
        
        // navigate it to it, then load the URL.
        rss.navigationController.pushViewController(vc, animated: true)
        webView.loadRequest(NSURLRequest(URL: article.url))
        
    }
    
    func refreshButtonTapped(sender: AnyObject) {
        collection.loading = true
        refresh()
        collection.fetchThen(refresh)
    }
    
    func presentAction(sender: AnyObject) {
        
        // TODO: this uses a delegate to tell it what to do for each activity type.
        let activities = [
            UIActivityTypePostToFacebook,
            UIActivityTypePostToTwitter,
            UIActivityTypePostToWeibo,
            UIActivityTypePostToTencentWeibo,
            UIActivityTypeMessage,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypeAddToReadingList
        ]
        
        // it would be a lot more fluid to create the activity view controller before the share
        // button is actually tapped, but of course that might require more memory than necessary
        // if the user would not tap the button at all.
        let activityVC = UIActivityViewController(activityItems: activities, applicationActivities: nil)
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    func refresh() {
        self.navigationItem.title = collection.title

        // feed is loading; show an indicator.
        if collection.loading {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            indicator.startAnimating()
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
        }
            
        // the feed is not loading; place the refresh button.
        else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refreshButtonTapped:")
        }

    }
    
}