//
//  FeedListCell.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/17/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class FeedCell: UITableViewCell {
    @IBOutlet var iconView:     UIImageView!
    @IBOutlet var label:        UILabel!
    @IBOutlet var unreadLabel:  UILabel!
    @IBOutlet var iconWidthConstraint: NSLayoutConstraint!
    
    fileprivate weak var feed: Feed?
    
    override func awakeFromNib() {
        backgroundView = Colors.cellBackgroundView
        selectedBackgroundView = Colors.cellSelectedBackgroundView
        
        unreadLabel.layer.cornerRadius = 10
        unreadLabel.clipsToBounds = true
    }
    
    // on highlight, set the unread color to the accent color.
    // by default, this will remove the background, but instead, I am assigning
    // a slightly different shade of blue to indicate a different state.
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        unreadLabel.backgroundColor = Colors.accentColor
    }
    
    // set the feed for the cell
    func setFeed(_ feed: Feed) {
        self.feed = feed
        update()
    }
    
    // refresh displayed information
    func update() {
        if feed == nil { return }
        label.text         = feed!.loading ? "Loading..." : feed!.title
        iconView.image     = feed!.logo?.white
        unreadLabel.text   = "\(feed!.unread.count)"
        unreadLabel.isHidden = feed!.unread.count <= 0
        
        // no logo
        if feed!.logo == nil {
            iconView.isHidden = true
            iconWidthConstraint.constant = 0
        }
            
        // has logo
        else {
            iconView.isHidden = false
            iconWidthConstraint.constant = 120
        }
        
    }
    
}
