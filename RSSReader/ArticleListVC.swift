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
    var sortedArticles = [Article]()
    
    // load the cell nibs.
    private let nib1 = UINib(nibName: "ArticleListCell", bundle: nil)
    private let nib2 = UINib(nibName: "ArticleListSmallCell", bundle: nil)

    override func viewDidLoad() {
        
        // register the nibs for the cells in the table view.
        tableView.registerNib(nib1, forCellReuseIdentifier: "article")
        tableView.registerNib(nib2, forCellReuseIdentifier: "articleSmall")
        
        tableView.separatorColor  = UIColor.clearColor()
        tableView.backgroundColor = UIColor.whiteColor()
        refresh()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortedArticles.count//1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1//sortedArticles.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let article = sortedArticles[indexPath.section]
        return article.summary != nil ? 140 : 60
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let article = sortedArticles[indexPath.section]//.row]
        
        // it has a summary.
        if let summary = article.summary {

            let cell = tableView.dequeueReusableCellWithIdentifier("article", forIndexPath: indexPath) as ArticleListCell
            
            cell.label.text           = article.title
            cell.publisherView.image  = article.feed.logo.whiteImage
            
            cell.iconView.image        = defaultImage
            cell.descriptionView.text  = summary
            
            // determine the appropriate size for the image.
            let widthRatio  = cell.iconView.bounds.size.width  / cell.iconView.image!.size.width
            let heightRatio = cell.iconView.bounds.size.height / cell.iconView.image!.size.height
            let scale       = min(widthRatio, heightRatio)
            let imageWidth  = scale * cell.iconView.image!.size.width
            let imageHeight = scale * cell.iconView.image!.size.height
            cell.iconView.frame.size.width = imageWidth
            
            return cell
        }
            
        // it has no summary, so use a smaller cell.
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("articleSmall", forIndexPath: indexPath) as ArticleListSmallCell
            cell.label.text           = article.title
            cell.publisherView.image  = article.feed.logo.whiteImage
            return cell
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let article = sortedArticles[indexPath.section]
        
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
        if collection == nil { return }
        self.navigationItem.title = collection.title

        // sort the articles.
        sortedArticles = collection.articles.sorted {
            art1, art2 in
            art1.publishDate.laterDate(art2.publishDate) == art1.publishDate
        }

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