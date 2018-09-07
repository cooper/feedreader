//
//  ArticleWebVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 11/3/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class ArticleWebVC: UIViewController, UIWebViewDelegate {
    @IBOutlet var webView: UIWebView?
    @IBOutlet var indicator: UIActivityIndicatorView?
    
    var activityController: UIActivityViewController!
    var titleView: UILabel?
    var countLabel: UILabel?
    var upButton, downButton: UIBarButtonItem?
    
    var url: URL!
    var articleIndex = 0
    var articleList: [Article]!
    var article: Article { return articleList[articleIndex] }

    // initialize with an article
    convenience init(articleList list: [Article], index: Int) {
        self.init(nibName: "ArticleWebVC", bundle: nil)
        articleList = list
        setArticleIndex(index)
    }
    
    func setArticleIndex(_ index: Int) {
        articleIndex = index
        navigationItem.title = article.title
        loadArticle()
        updateArrows()
    }
    
    // MARK:- View controller
    
    // the view loaded, so we can load the URL now.
    override func viewDidLoad() {
        loadArticle()
        
        // menu button
        let item = UIBarButtonItem(image: UIImage(named: "icons/menu")!, style: .plain, target: self, action: #selector(ArticleWebVC.menuButtonTapped(_:)))
        navigationItem.rightBarButtonItem = item
        
        // toolbar label
        countLabel = UILabel()
        countLabel!.textColor = UIColor.darkGray
        
        // toolbar items
        let shareButton   = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(ArticleWebVC.presentShareView(_:)))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            upButton      = UIBarButtonItem(image: UIImage(named: "icons/up"), style: .plain, target: self, action: #selector(ArticleWebVC.upTapped(_:)))
            downButton    = UIBarButtonItem(image: UIImage(named: "icons/down"), style: .plain, target: self, action: #selector(ArticleWebVC.downTapped(_:)))
        let counter       = UIBarButtonItem(customView: countLabel!)
        setToolbarItems([ shareButton, flexibleSpace, counter, flexibleSpace, upButton!, downButton! ], animated: false)
        updateArrows()
        
        // sharing
        activityController = UIActivityViewController(activityItems: [ self.article.urlString ], applicationActivities: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.toolbar.barTintColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    // mark the article read when the view appears
    override func viewDidAppear(_ animated: Bool) {
        markRead()
    }
    
    // MARK:- Article

    // load the article webpage
    func loadArticle() {
        indicator?.isHidden = false
        indicator?.startAnimating()
        webView?.delegate = self
        webView?.loadRequest(URLRequest(url: article.url as URL))
        markRead()
    }
    
    // mark the article read
    func markRead() {
        
        // mark article read
        article.read = true
        
        // remove dot in article list
        let vcs: [AnyObject]! = navigationController?.viewControllers
        if vcs == nil { return }
        if let vc = vcs[vcs.count - 2] as? ArticleListVC {
            // TODO: reloadArticle method
            vc.tableView.reloadData()
        }
        
    }
    
    
    // MARK:- Web view delegate
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        indicator?.stopAnimating()
        indicator?.isHidden = true
        // markRead()
    }
    
    // MARK:- Interface actions
    
    // menu button in navigation bar tapped
    func menuButtonTapped(_ sender: UIBarButtonItem) {
        let sheet = PSTAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // delete
        var action = PSTAlertAction(title: "Delete", style: .destructive) { _ in
            let areYouSure = PSTAlertController(title: "Delete this article?", message: "\"\(self.article.title)\" will be deleted permanently.", preferredStyle: .alert)
            areYouSure?.addAction(PSTAlertAction(title: "Delete", style: .default) { _ in
                
                // dispose of the current article
                self.article.disposeOf()
                
                // delete in the local list
                self.articleList.remove(at: self.articleIndex)

                // set article index to the current
                // because the next article will have taken this one's place
                self.setArticleIndex(self.articleIndex)
                
            })
            areYouSure?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))
            areYouSure?.showWithSender(nil, controller: self, animated: true, completion: nil)
    
        }
        sheet?.addAction(action)
        
        // share
        action = PSTAlertAction(title: "Share", handler: presentShareView)
        sheet?.addAction(action)
        
        // save
        if !article.saved {
            action = PSTAlertAction(title: "Save for later") { _ in
                self.article.saved = true
            }
            sheet?.addAction(action)
        }
        
        // unsave
        else {
            action = PSTAlertAction(title: "Unsave") { _ in
                self.article.saved = false
            }
            sheet?.addAction(action)
        }
        
        // mark unread
        if article.read {
            action = PSTAlertAction(title: "Mark unread") { _ in
                self.article.read = false
            }
            sheet?.addAction(action)
        }
        
        // mark read
        else {
            action = PSTAlertAction(title: "Mark read") { _ in
                self.article.read = true
            }
            sheet?.addAction(action)
        }
        
        // cancel
        sheet?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        sheet?.showWithSender(sender, controller: self, animated: true, completion: nil)
    }
    
    // present share controller
    func presentShareView(_: AnyObject?) {
        present(activityController, animated: true, completion: nil)
    }
    
    // up arrow tapped
    func upTapped(_: AnyObject) {
        setArticleIndex(articleIndex - 1)
    }
    
    // down arrow tapped
    func downTapped(_: AnyObject) {
        setArticleIndex(articleIndex + 1)
    }
    
    // enable/disable arrow buttons
    // also, update the counter
    func updateArrows() {
        upButton?.isEnabled   = articleIndex != 0
        downButton?.isEnabled = articleIndex != articleList.count - 1
        countLabel?.text = "\(articleIndex + 1) of \(articleList.count)"
        countLabel?.sizeToFit()
    }
    
// This is code for WAMenu, a custom menu that I created for this application,
// but it is not included in this release because it is not yet functional
// in landscape viewing mode.
//
//private struct MenuDefinition {
//    typealias Item = (title: String, iconName: String?, color: UIColor?)
//
//    static let deleteItem:     Item = ("Delete",          "x",        Colors.deleteColor)
//    static let saveItem:       Item = ("Save for later",  "plus2",    Colors.savedColor)
//    static let markUnreadItem: Item = ("Mark unread",     "mail",     Colors.unreadColor)
//
//    static let unsaveItem:     Item = ("Unsave",          "plus2",    Colors.savedColor)
//    static let markReadItem:   Item = ("Mark read",       "mail",     Colors.unreadColor)
//
//}
//
//    private func updateMenu() {
//        menu.menuItems.removeAllObjects()
//        
//        let items = [
//            MenuDefinition.deleteItem,
//            article.saved ? MenuDefinition.unsaveItem     : MenuDefinition.saveItem,
//            article.read  ? MenuDefinition.markUnreadItem : MenuDefinition.markReadItem
//        ]
//        
//        let font = UIFont.systemFontOfSize(25)
//        for item in items {
//            let icon = item.iconName == nil ? nil : UIImage(named: "icons/\(item.iconName!)")
//            menu.addItem(item.title, icon: icon, color: item.color, font: font)
//        }
//    }
//
//    func menuItemSelected(action: String!) {
//        switch action {
//            
//            // delete
//        case MenuDefinition.deleteItem.title:
//            let areYouSure = PSTAlertController(title: "Delete this article?", message: "\"\(article.title)\" will be deleted permanently.", preferredStyle: .Alert)
//            areYouSure.addAction(PSTAlertAction(title: "Delete", style: .Default) { _ in
//                self.article.disposeOf()
//                self.navigationController?.popViewControllerAnimated(true)
//                })
//            areYouSure.addAction(PSTAlertAction(title: "Cancel", style: .Cancel, handler: nil))
//            areYouSure.showWithSender(nil, controller: self, animated: true, completion: nil)
//            
//            // save
//        case MenuDefinition.saveItem.title:
//            article.saved = true
//            
//            // mark unread
//        case MenuDefinition.markUnreadItem.title:
//            article.read = false
//            
//            // unsave
//        case MenuDefinition.unsaveItem.title:
//            article.saved = false
//            
//            // mark read
//        case MenuDefinition.markReadItem.title:
//            article.read = true
//            
//        default:
//            break
//        }
//    }

    
}
