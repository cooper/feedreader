//
//  GroupCell.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/1/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit

class GroupCell: UITableViewCell {
    @IBOutlet var titleLabel:  UILabel!
    @IBOutlet var descLabel:   UILabel?
    @IBOutlet var unreadLabel: UILabel!
    @IBOutlet var iconView:    UIImageView?
    
    fileprivate weak var group: FeedGroup?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView = Colors.cellBackgroundView // to prevent transparent when dragging
        selectedBackgroundView = Colors.cellSelectedBackgroundView
        
        unreadLabel.layer.cornerRadius = 10
        unreadLabel.clipsToBounds = true
        
        // watch for feed changes
        rss.center.addObserver(self, selector: "update", name: Feed.Notifications.Fetched, object: nil)
    }
    
    // on highlight, set the unread color to the accent color.
    // by default, this will remove the background, but instead, I am assigning
    // a slightly different shade of blue to indicate a different state.
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        unreadLabel.backgroundColor = Colors.accentColor
    }
    
    // set the group for the cell
    func setGroup(_ group: FeedGroup) {
        self.group = group
        
        // watch for changes like title/icon
        rss.center.removeObserver(self, name: FeedGroup.Notifications.AppearanceChanged, object: self.group)
        rss.center.addObserver(self, selector: "update", name: FeedGroup.Notifications.AppearanceChanged, object: group)
        
        update()
    }
    
    // refresh displayed information
    func update() {
        if group == nil { return }
        titleLabel.text    = group!.title
        iconView?.image    = group!.icon
        unreadLabel.text   = "\(group!.unread.count)"
        unreadLabel.isHidden = group!.unread.count <= 0
    }

}
