//
//  ArticleListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/7/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ArticleListVC: UITableViewController, UITableViewDataSource, UISearchBarDelegate {
    var collection: ArticleCollection!
    fileprivate var sortedArticles = [Article]()
    
    convenience init(collection: ArticleCollection) {
        self.init(style: .plain)
        self.collection = collection
    }
    
    // MARK:- View controller

    override func viewDidLoad() {
        
        // register the nibs for the cells in the table view.
        let nib = UINib(nibName: "ArticleCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "article")
        
        // table options
        tableView.separatorColor  = UIColor.clear
        tableView.separatorStyle  = .none
        tableView.backgroundColor = Colors.tableColor
        tableView.rowHeight       = 140
        
        // search bar
        let searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
        searchBar.sizeToFit()
        searchBar.barTintColor = Colors.barTintColor
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.keyboardAppearance = .dark
        
        // I decided that light looks better because it fits in with the action sheets
        navigationItem.titleView = searchBar
        
        // find the text field within the search bar.
        // this is a hacky way to do this, but there's no public property.
        // I think the array flattening here is neat though.
        let subSubViews = searchBar.subviews.map { $0.subviews }.reduce([], +)
        for subsubView in subSubViews  {
            if let textField = subsubView as? UITextField {
                textField.attributedPlaceholder = NSAttributedString(string: "Search \(collection.shortTitle)", attributes: [ NSForegroundColorAttributeName: UIColor(white: 0.85, alpha: 1) ])
                textField.textColor = UIColor.white
                break
            }
        }
        
        // refresh pull-down
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(ArticleListVC.refreshInitiated), for: .valueChanged)
        refreshControl!.tintColor = UIColor.white
        refreshControl!.attributedTitle = NSAttributedString(string: "Update \(collection.feeds.count) feed" + (collection.feeds.count == 1 ? "" : "s"), attributes: [ NSForegroundColorAttributeName: UIColor.white ])

        // menu button in navigation bar
        let item = UIBarButtonItem(image: UIImage(named: "icons/menu")!, style: .plain, target: self, action: #selector(ArticleListVC.menuButtonTapped(_:)))
        navigationItem.rightBarButtonItem = item

    }
    
    // refresh when view will appear
    override func viewWillAppear(_ animated: Bool) {
        refresh()
    }
    
    // MARK:- Table view data source
    
    // number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedArticles.count
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "article", for: indexPath) as! ArticleCell
        cell.setArticle(sortedArticles[indexPath.row])
        return cell
    }
    
    // selected an article
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // create an article web view controller.
        let webVC = ArticleWebVC(articleList: sortedArticles, index: indexPath.row)
        rss.navigationController.pushViewController(webVC, animated: true)
    
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // can edit all articles
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // edit operations that appear when you swipe
    override func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [AnyObject]? {
        let article = self.sortedArticles[indexPath.row]
        
        var readAction: UITableViewRowAction
        
        // Mark unread
        if article.read {
            readAction = UITableViewRowAction(style: .default, title: "Unread") { _ in
                article.read = false
                tableView.isEditing = false
                after(0.3) { tableView.reloadRows(at: [indexPath], with: .fade) }
            }
            readAction.backgroundColor = Colors.unreadColor
        }
            
        // Mark read
        else {
            readAction = UITableViewRowAction(style: .default, title: "Read") { _ in
                article.read = true
                tableView.isEditing = false
                after(0.3) { tableView.reloadRows(at: [indexPath], with: .fade) }
            }
            readAction.backgroundColor = Colors.unreadColor
        }
        
        var saveAction: UITableViewRowAction
            
        // Mark unsaved
        if article.saved {
            saveAction = UITableViewRowAction(style: .default, title: "Unsave") { _ in
                article.saved = false
                tableView.isEditing = false
                after(0.3) { tableView.reloadRows(at: [indexPath], with: .fade) }
            }
            saveAction.backgroundColor = Colors.savedColor
        }
            
        // Mark saved
        else {
            saveAction = UITableViewRowAction(style: .default, title: "Save") { _ in
                article.saved = true
                tableView.isEditing = false
                after(0.3) { tableView.reloadRows(at: [indexPath], with: .fade) }
            }
            saveAction.backgroundColor = Colors.savedColor
        }

        // Delete with confirmation
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { _ in
            self.presentArticleDeleteConfirmation(article, forIndexPath: indexPath)
        }

        return [readAction, saveAction, deleteAction]
    }
    
    // this has to be implemented for the custom editing buttons to work,
    // even though deletions are implemented as a custom action above
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }

// disabled -- too expensive/slow
//
//    // if enabled, mark the article as read from the list
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        if settings.markReadMethod == .MarkFromList {
//            let article = sortedArticles[indexPath.row]
//            article.read = true
//            (cell as ArticleCell).update() // rid of indicator
//        }
//    }
    
    // MARK:- Interface actions
    
    // initiate a refresh
    func refreshInitiated() {
        collection.fetchThen(refresh)
    }
    
    // menu button in navigation bar tapped
    func menuButtonTapped(_ sender: UIBarButtonItem) {
        let alert = PSTAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // newest first
        if settings.articleSortMethod != .NewestFirst {
            alert?.addAction(PSTAlertAction(title: "Sort Newest First", style: .default) { _ in
                settings.articleSortMethod = .NewestFirst
                self.refresh()
            })
        }
        
        // oldest first
        if settings.articleSortMethod != .OldestFirst {
            alert?.addAction(PSTAlertAction(title: "Sort Oldest First", style: .default) { _ in
                settings.articleSortMethod = .OldestFirst
                self.refresh()
            })
        }
    
        // a-z
        if settings.articleSortMethod != .Alphabetical {
            alert?.addAction(PSTAlertAction(title: "Sort Alphabetically", style: .default) { _ in
                settings.articleSortMethod = .Alphabetical
                self.refresh()
            })
        }
        
//        // multi select
//        alert.addAction(UIAlertAction(title: "Select", style: .Default) { _ in
//            // also use allowsMultipleSelectDuringEditing
//            self.tableView.setEditing(true, animated: true)
//        })
        
        // cancel
        alert?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alert?.showWithSender(sender, controller: self, animated: true, completion: nil)
    }

    // present article deletion confirmation
    func presentArticleDeleteConfirmation(_ article: Article, forIndexPath indexPath: IndexPath) {
        let areYouSure = PSTAlertController(title: "Delete this article?", message: "\"\(article.title)\" will be deleted permanently.", preferredStyle: .alert)
        areYouSure?.addAction(PSTAlertAction(title: "Delete", style: .default) { _ in
            if let i = find(self.sortedArticles, article) {
                self.sortedArticles.remove(at: i)
            }
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            article.disposeOf()
        })
        areYouSure?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))
        areYouSure?.showWithSender(nil, controller: self, animated: true, completion: nil)
    }
    
    // refresh/update articles in view
    func refresh() {
        if collection == nil { return }
        navigationItem.title = collection.title
        
        // no search, just sort all the articles
        if !searchInProgress {
            sortedArticles = collection.articles.filter {
                !$0.deleted
            }.sorted(settings.articleSorter)
        }
        
        // update refresh
        if collection.loading {
            refreshControl?.beginRefreshing()
        }
        else {
            refreshControl?.endRefreshing()
        }
        
        tableView.reloadData()
    }
    
    // MARK: Searching
    
    var searchInProgress = false
    var previousSearchText = ""
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        rss.log("Search text: \(searchText)")
        
        // if there is no search text, reset to all articles
        if searchText.isEmpty {
            searchInProgress = false
            after(0.2) {
                searchBar.resignFirstResponder()
                return
            }
            refresh()
            return
        }
        
        // begin a search.
        searchInProgress = true
        
        // one character can match too much.
        // clicking Search will force search.
        if countElements(searchText) != 1 {
            performSearch(searchText.lowercased())
        }
        
    }
    
    func performSearch(_ searchText: String) {
        var pointsPending = [Article: Int]()
        
        // if the new search text contains the previous,
        // only search the articles matching the previous query
        let articles = (searchText as NSString).contains(previousSearchText) ? sortedArticles : collection.articles
        previousSearchText = searchText
        
        sortedArticles = articles.filter { article in
            
            // this nested function determines how good of a match it is
            func points(_ article: Article) -> Int {
                var pt = 0
                let title   = article.title.lowercased()   as NSString
                let summary = article.summary.lowercased() as NSString
                
                // matching title is worth two points
                if title.contains(searchText) {
                    pt += 2
                    
                    // prefixed title is even better
                    if title.hasPrefix(searchText) {
                        pt += 2
                    }
                    
                }
                
                // matching summary is worth one point
                if article.hasSummary && summary.contains(searchText) {
                    pt += 1
                }
                
                return pt
            }
            
            // if this has points, store them for later
            // this is so we don't have to do calculations in two iterations
            let pt = points(article)
            if pt != 0 {
                pointsPending[article] = pt
                return true
            }
            
            return false
        }
        
        // now actually do the sorting
        sortedArticles.sorted { article1, article2 in
            let points1 = pointsPending[article1], points2 = pointsPending[article2]
            
            // if they're the same, fall back to the current sort method
            if points1 == points2 {
                return settings.articleSorter(article1, article2)
            }
            
            // they're not the same, so one of them wins.
            return points1 > points2
            
        }
        
        // reload and scroll to top
        refresh()
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        
    }
    
    // search button in keyboard tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !(searchBar.text?.isEmpty)! {
            performSearch((searchBar.text?.lowercased())!)
        }
        searchBar.resignFirstResponder()
    }
    
}
