//
//  FeedListVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class FeedDefaultVC: FeedListVC, InfoCellDataSource {
    var secGroupList = 1
    
    // MARK:- View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "GroupCell", bundle: nil), forCellReuseIdentifier: "group")
        navigationItem.title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    }
    
    // MARK:- Table view source
    
    // number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        // if there are no feeds in the default group,
        // omit that section, at least for now.
        if group.feeds.isEmpty {
            secInfo      = 0
            secGroupList = 1
            secOptions   = 2
            secFeedList  = -1
            return 3
        }
        
        // there are feeds, so use this configuration
        secInfo      = 0
        secGroupList = 1
        secFeedList  = 2
        secOptions   = 3
        return 4
        
    }
    
    // number of rows in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 0 = all articles button
        // 1 = group list
        // 2 = feeds in default group
        switch section {
            case secInfo:        return 1
            case secGroupList:   return rss.manager.notDefaultGroups.count
            case secFeedList:    return group.feeds.count
            case secOptions:     return 3
            default: return 0
        }
        
    }
    
    // row height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
            case secInfo:        return 120
            case secGroupList:   return 80
            case secFeedList:    return 80
            case secOptions:     return 55
            default:             return 0
        }
    }

    // perform a deletion
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { return }
        switch indexPath.section {
            
            // group list edit.
            case secGroupList:
                rss.manager.groups.remove(at: indexPath.row + 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                return
            
            // default group feed list edit.
            case secFeedList:
                group.feeds.remove(at: indexPath.row)

                // if this was the last feed, get rid of the section
                if group.feeds.count == 0 {
                    tableView.deleteSections(IndexSet(integer: secFeedList), with: .automatic)
                    secInfo      = 0
                    secGroupList = 1
                    secOptions   = 2
                    secFeedList  = -1
                }
                    
                // otherwise, just delete the row
                else {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            
            default: break
        }
    }
    
    // allow editing groups and feeds
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // can't edit options
        if indexPath.section == secOptions {
            return false
        }
        
        // can edit groups
        if indexPath.section == secGroupList {
            return true
        }
        
        return super.tableView(tableView, canEditRowAt: indexPath)
    }
    
    // returns where to drop a cell when moving it
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        // cannot move settings or add buttons
        if proposedDestinationIndexPath.section == secOptions {
            return sourceIndexPath
        }
        
        return super.tableView(tableView, targetIndexPathForMoveFromRowAt: sourceIndexPath, toProposedIndexPath: proposedDestinationIndexPath)
    }
    
    // cannot move option buttons
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        
        // can't move settings
        if indexPath.section == secOptions {
            return false
        }
        
        return super.tableView(tableView, canMoveRowAt: indexPath)
    }
    
    // swap two groups' or feeds' locations
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // if we're moving a group, handle that here.
        if sourceIndexPath.section == secGroupList {
            swap(&rss.manager.groups[sourceIndexPath.row + 1], &rss.manager.groups[destinationIndexPath.row + 1])
            return
        }
        
        // otherwise, send this on to the feed list handler.
        super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        
    }
    
    // return a cell for a row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 0 = all articles button
        // 1 = group list
        // 2 = feeds in default group
        // 3 = options

        switch indexPath.section {
            
            // info cell: pass it on to feed list, but use this class as data source
            case secInfo:
                let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as InfoCell
                cell.dataSource = self
                return cell
            
            // group
            case secGroupList:
                return cellForGroupAtRow(indexPath.row)
            
            // feed, pass it on
            case secFeedList:
                let path = IndexPath(row: indexPath.row, section: 1)
                return super.tableView(tableView, cellForRowAt: path)
            
            // option buttons
            case secOptions:
                if indexPath.row == 0 { return addButtonCellNamed("add group") }
                if indexPath.row == 1 { return addButtonCellNamed("add feed")  }
                return settingsCellNamed("settings")

            // fallback
            default:
                return UITableViewCell()
            
        }
    }
    
    // returns a cell for a group
    func cellForGroupAtRow(_ row: NSInteger) -> UITableViewCell {
        let group = rss.manager.notDefaultGroups[row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "group") as! GroupCell
        cell.setGroup(group)
        return cell
    }
    
    // user selected a feed
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // show feeds in group
        if indexPath.section == secGroupList {
            let group = rss.manager.notDefaultGroups[indexPath.row]
            return pushFeedViewForGroup(group)
        }
        
        // options
        if indexPath.section == secOptions {
            switch indexPath.row {
                case 0:  return presentGroupCreator(nil)
                case 1:  return presentFeedCreator(nil)
                default: return pushSettingsView()
            }
        }
        
        super.tableView(tableView, didSelectRowAt: indexPath)
    }
    
    // MARK:- Interface actions
    
    // push master settings view
    func pushSettingsView() {
        let settingsVC = MasterSettingsVC()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // present feed creator
    fileprivate var _textField : UITextField?
    func presentGroupCreator(_ sender: AnyObject?) {
        let alert = PSTAlertController(title: "Add group", message: nil, preferredStyle: .alert)
        
        // text field.
        alert?.addTextField { textField in
            self._textField = textField
            textField?.placeholder = "Name"
            textField?.keyboardAppearance = .dark
        }
        
        // OK button.
        let action = PSTAlertAction(title: "OK", style: .default) { _ in
            
            // empty string?
            let string = self._textField!.text!
            self._textField = nil
            if string.isEmpty { return }

            // create the group.
            let group = FeedGroup(title: string)
            rss.manager.groups.append(group)
            let path = IndexPath(row: rss.manager.notDefaultGroups.count - 1, section: self.secGroupList)
            self.tableView.insertRows(at: [path], with: .automatic)
            
            return
        }
        alert?.addAction(action)
        alert?.addAction(PSTAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // present it.
        alert?.showWithSender(sender, controller: self, animated: true, completion: nil)

    }
    
    // MARK:- Info cell data source
    
    // all articles in entire library
    override func totalArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        return GenericArticleCollection(title: "all articles", articles: rss.manager.articles)
    }
    
    // all unread articles in entire library
    override func unreadArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        let collection = totalArticleCollectionForInfoCell(infoCell)
        return GenericArticleCollection(title: "all unread", articles: collection.unread)
    }
    
    // all saved articles in entire library
    override func savedArticleCollectionForInfoCell(_ infoCell: InfoCell) -> ArticleCollection {
        let collection = totalArticleCollectionForInfoCell(infoCell)
        return GenericArticleCollection(title: "all saved", articles: collection.saved)
    }
    
    
}
