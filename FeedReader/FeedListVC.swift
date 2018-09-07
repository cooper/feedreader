//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class FeedListVC: UITableViewController, InfoCellDataSource {
    var group: FeedGroup!
    
    // standard section identifiers
    var secInfo     = 0
    var secFeedList = 1
    var secOptions  = 2
    
    // initialize with a group
    convenience init(group: FeedGroup) {
        self.init(style: .grouped)
        self.group = group
    }
    
    // MARK:- View controller
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: "InfoCell", bundle: nil), forCellReuseIdentifier: "info")
        
        navigationItem.title = group.title.capitalized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target:nil, action:nil)
        
        navigationItem.rightBarButtonItem = self.editButtonItem
        //tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.separatorColor  = UIColor.clear
        tableView.separatorStyle  = .none
        tableView.backgroundColor = Colors.tableColor
        
        // watch for group title change
        rss.center.addObserver(self, selector: "groupChanged", name: FeedGroup.Notifications.AppearanceChanged, object: group)
        
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK:- Table view data source
    
    // info, feed list, and settings
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    // number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case secInfo:     return 1
            case secFeedList: return group.feeds.count
            case secOptions:  return 2
            default:          return 0
        }
    }
    
    // row height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case secInfo:        return 120
            case secFeedList:    return 80
            case secOptions:     return 55
            default:             return 0
        }
    }
    
    // section header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        // 0 height not permitted
        // this is a workaround to use a cell for a table header view
        if section == secInfo { return 0.000001 }

        return 20
    }
    
    // can't edit add, settings, or info cells
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == secFeedList
    }

    // allow moving of feed cells but not fixed cells
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        // can't move info or options
        if indexPath.section == secInfo || indexPath.section == secOptions {
            return false
        }
        
        return true
    }
    
    // returns the location to drop a cell when moving it
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        // can never move between sections
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        
        // cannot move options
        if proposedDestinationIndexPath.section == secOptions {
            return sourceIndexPath
        }
    
        return proposedDestinationIndexPath
    }
    
    // perform a deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            group.feeds.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // swap two feeds' locations
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        rss.log("Swapping feed at \(sourceIndexPath.row) with \(destinationIndexPath.row)")
        swap(&group.feeds[sourceIndexPath.row], &group.feeds[destinationIndexPath.row])
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // top info cell.
        if indexPath.section == secInfo {
            let cell = tableView.dequeueReusableCell(withIdentifier: "info") as! InfoCell
            cell.dataSource = self
            cell.backgroundColor = Colors.cellColor
            return cell
        }
        
        // options
        if indexPath.section == secOptions {
            if indexPath.row == 0 { return addButtonCellNamed("add feed") }
            if indexPath.row == 1 { return settingsCellNamed("group settings") }
        }
        
        // feed cell
        
        // first, try to dequeue a cell.
        var cell: FeedCell
        if let cellMaybe = tableView.dequeueReusableCell(withIdentifier: "feed") as? FeedCell {
            cell = cellMaybe
        }
        
        // create a new cell.
        else {
            let items = Bundle.main.loadNibNamed("FeedCell", owner: self, options: nil)
            cell = items?[0] as! FeedCell
            //cell.accessoryType = .DisclosureIndicator
            cell.backgroundColor = Colors.cellColor
        }
        
        let feed = group.feeds[indexPath.row]
        cell.setFeed(feed)
        
        // this is an attempt to smooth edges
        cell.iconView.layer.shadowColor = UIColor.white.cgColor
        cell.iconView.layer.shadowRadius = 1
        cell.iconView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.iconView.layer.shadowOpacity = 0.8
        cell.iconView.layer.shouldRasterize = true
        cell.iconView.layer.rasterizationScale = 3
                
        return cell
    }
    
    // the info section should never be selected; only individual buttons in it should
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != secInfo
    }
    
    // user selected a feed
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // all articles.
        if indexPath.section == secInfo {
            pushArticleViewToCollection(group)
            return
        }
        
        // add feed
        if indexPath == IndexPath(row: 0, section: secOptions) {
            presentFeedCreator(nil)
            return
        }
        
        // group settings
        if indexPath == IndexPath(row: 1, section: secOptions) {
            pushGroupEditorForGroup(group)
            return
        }
        
        // feed.
        let feed = group.feeds[indexPath.row]
        
        // no articles; fetch them
        if feed.articles.isEmpty {
            feed.fetch()
        }
    
        pushArticleViewToCollection(feed)
    }
    
    // returns a settings button cell with a title
    func settingsCellNamed(_ title: String) -> UITableViewCell {
        var cell: UITableViewCell
        if let oldCell = tableView.dequeueReusableCell(withIdentifier: "settings") as? UITableViewCell {
            cell = oldCell
        }
        else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "settings")
            cell.imageView?.image = UIImage(named: "icons/gear")
            cell.backgroundColor = Colors.cellColor
            cell.textLabel?.textColor = UIColor.white
            cell.selectedBackgroundView = Colors.cellSelectedBackgroundView
        }
        cell.textLabel?.text = title
        return cell
    }
    
    // returns an add button cell with a title
    func addButtonCellNamed(_ title: String) -> UITableViewCell {
        
        // reuse cell
        if let cell = tableView.dequeueReusableCell(withIdentifier: "add") as? UITableViewCell {
            cell.textLabel?.text = title
            return cell
        }
        
        // create base cell
        let cell = UITableViewCell(style: .default, reuseIdentifier: "add")
        cell.textLabel?.text = title
        cell.imageView?.image = UIImage(named: "icons/plus")
        cell.backgroundColor = Colors.cellColor
        cell.textLabel?.textColor = UIColor.white
        cell.selectedBackgroundView = Colors.cellSelectedBackgroundView
        
        // add hairline border
        let hairline = UIView()
        hairline.setTranslatesAutoresizingMaskIntoConstraints(false)
        hairline.backgroundColor = Colors.separatorColor
        cell.contentView.addSubview(hairline)

        // constraints
        let views = [ "hl": hairline ]
        let c1 = NSLayoutConstraint.constraintsWithVisualFormat("V:[hl(1)]-0-|", options: nil, metrics: nil, views: views)
        let c2 = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[hl]-0-|", options: nil, metrics: nil, views: views)
        
        // iOS 8
        // activate constraints
        if NSLayoutConstraint.responds(to: #selector(NSLayoutConstraint.activate(_:))) {
            NSLayoutConstraint.activateConstraints(c1 + c2)
        }
        
        // iOS 7
        // add constraints to superview
        else {
            cell.addConstraints(c1 + c2)
        }
        
        return cell
    }
    
    // MARK:- Interface interaction
    
    // push to the article list view for a feed.
    func pushArticleViewToCollection(_ collection: ArticleCollection) {
        let artVC = ArticleListVC(style: .plain)
        artVC.collection = collection
        navigationController?.pushViewController(artVC, animated: true)
    }
    
    // present the feed creator
    fileprivate var _textField : UITextField?
    func presentFeedCreator(_ sender: AnyObject?) {
        tableView.setEditing(false, animated: true)
        let alert = PSTAlertController(title: "Add feed", message: nil, preferredStyle: .alert)
        
        // text field.
        alert?.addTextField { textField in
            self._textField = textField
            textField?.placeholder = "URL"
            textField?.keyboardAppearance = .dark
        }
        
        // OK button.
        let action = PSTAlertAction(title: "OK", style: .default) { _ in
            
            // empty string?
            let string = self._textField!.text!
            self._textField = nil
            if string.isEmpty { return }
            
            // does the feed exist already? reload it.
            if let feed = rss.manager.feedFromURLString(string) {
                let alert = PSTAlertController(title: "Already exists", message: "The feed you tried to add already exists in your collection.", preferredStyle: .alert)
                alert?.addAction(PSTAlertAction(title: "OK", handler: nil))
                alert?.showWithSender(nil, controller: self, animated: true, completion: nil)
                feed.fetch()
                self.tableView.reloadData()
                return
            }
            
            // create and add the feed.
            let newFeed: Feed! = Feed(group: self.group, storage: string)
            
            // the url was not valid
            if newFeed == nil {
                let alert = PSTAlertController(title: "Feed error", message: "The supplied URL is not valid.", preferredStyle: .alert)
                alert?.addAction(PSTAlertAction(title: "OK", handler: nil))
                alert?.showWithSender(nil, controller: self, animated: true, completion: nil)
                return
            }
            
            self.group.addFeed(newFeed)
        
            // fetch feed, update the table, save to database.
            newFeed.fetch()
            self.tableView.reloadData()
            
            return
        }
        alert?.addAction(action)
        alert?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // present it.
        alert?.showWithSender(sender, controller: self, animated: true, completion: nil)
        
    }
    
    // push group editor
    func pushGroupEditorForGroup(_ group: FeedGroup) {
        let groupVC = GroupEditorVC(group: group)
        navigationController?.pushViewController(groupVC, animated: true)
    }
    
    // push feed list for group
    func pushFeedViewForGroup(_ group: FeedGroup) {
        let feedVC = FeedListVC(group: group)
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // the current group's title has changed
    func groupChanged() {
        navigationItem.title = group.title.capitalized
    }
    
    // MARK:- Info cell data source
    
    // all articles in group
    func totalArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        return GenericArticleCollection(title: "all \(group.title)", articles: group.articles)
    }
    
    // unread articles in group
    func unreadArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        let collection = totalArticleCollectionForInfoCell(infoCell)
        return GenericArticleCollection(title: "unread \(group.title)", articles: collection.unread)
    }
    
    // saved articles in group
    func savedArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        let collection = totalArticleCollectionForInfoCell(infoCell)
        return GenericArticleCollection(title: "saved \(group.title)", articles: collection.saved)
    }
    
}
