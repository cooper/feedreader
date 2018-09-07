//
//  InfoCell.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/1/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit


class InfoCell: UITableViewCell {
    @IBOutlet var unreadBox: UIView!
    @IBOutlet var totalBox:  UIView!
    @IBOutlet var savedBox:  UIView!
    fileprivate var inProgress = false
    
    // info for the buttons, as returned by delegate methods
    var totalCollection:  ArticleCollection?
    var unreadCollection: ArticleCollection?
    var savedCollection:  ArticleCollection?
    
    // upon setting the delegate, get the info we need
    fileprivate weak var _dataSource: InfoCellDataSource?
    var dataSource: InfoCellDataSource? {
        get {
            return _dataSource
        }
        set {
            _dataSource = newValue
            update()
        }
    }
    
    // overlay when tapped
    lazy var overlay: UIView = {
        let box  = self.unreadBox
        let view = UIView(frame: CGRect(x: 0, y: 0, width: (box?.frame.width)!, height: (box?.frame.height)!))
        view.backgroundColor = UIColor.black
        view.alpha = 0.5
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // add gesture recognizers
        for box in [unreadBox, totalBox, savedBox] {
            let tap = UITapGestureRecognizer(target: self, action: #selector(InfoCell.handleTap(_:)))
            box?.addGestureRecognizer(tap)
        }
        
        // watch for changes
        rss.center.addObserver(self, selector: "update", name: Feed.Notifications.Fetched, object: nil)
        rss.center.addObserver(self, selector: "updateUnreadMaybe:", name: Article.Notifications.Read, object: nil)
        rss.center.addObserver(self, selector: "updateUnreadMaybe:", name: Article.Notifications.Unread, object: nil)
        rss.center.addObserver(self, selector: "updateSavedMaybe:", name: Article.Notifications.Saved, object: nil)
        rss.center.addObserver(self, selector: "updateSavedMaybe:", name: Article.Notifications.Unsaved, object: nil)
        
    }
    
    // button box view map to button info
    var boxToCollectionMap: [UIView: ArticleCollection?] {
       return [
            unreadBox: unreadCollection,
            totalBox:  totalCollection,
            savedBox:  savedCollection
        ]
    }
    
    // callback for all gesture recognizers
    func handleTap(_ sender: UITapGestureRecognizer) {
        if inProgress { return }
        let box = sender.view!
        updateBackground(box)
        pushCollection(boxToCollectionMap[box]!!)
    }
    
    // make the background the cell selected background color
    // after half a second, return to transparent background
    func updateBackground(_ box: UIView) {
        inProgress = true
        box.addSubview(overlay)
        after(1) { [weak self] in
            self?.overlay.removeFromSuperview()
            self?.inProgress = false
        }
    }
    
    // update information
    func update() {
        totalCollection  = dataSource?.totalArticleCollectionForInfoCell (self)
        unreadCollection = dataSource?.unreadArticleCollectionForInfoCell(self)
        savedCollection  = dataSource?.savedArticleCollectionForInfoCell (self)
        updateArticleCounts()
    }
    
    // update unread only
    func updateUnreadMaybe(_ notification: Notification) {
        let article = notification.object as! Article
        if unreadCollection == nil {
            return
        }
        unreadCollection = dataSource?.unreadArticleCollectionForInfoCell(self)
        updateArticleCounts()
    }
    
    // update saved only
    func updateSavedMaybe(_ notification: Notification) {
        let article = notification.object as! Article
        if savedCollection == nil {
            return
        }
        savedCollection = dataSource?.savedArticleCollectionForInfoCell(self)
        updateArticleCounts()
    }
    
    // update the article counts in the buttons
    func updateArticleCounts() {
        for (box, collection) in boxToCollectionMap {
            (box.subviews.first as? UILabel)?.text = "\(collection?.articles.count)"
        }
    }
    
    // push a collection of articles with a generic article collection
    func pushCollection(_ collection: ArticleCollection) {
        if collection.articles.count == 0 { return }
        let articleVC  = ArticleListVC(collection: collection)
        rss.navigationController.pushViewController(articleVC, animated: true)
    }

}

// protocol for article collection data source
// defined as a class protocol so that data source can be weak
protocol InfoCellDataSource: class {
    func totalArticleCollectionForInfoCell (_ infoCell: InfoCell) -> ArticleCollection
    func unreadArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection
    func savedArticleCollectionForInfoCell (_ infoCell: InfoCell) -> ArticleCollection
}

