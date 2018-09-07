//
//  ArticleListCell.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 10/23/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class ArticleCell: UITableViewCell {
    @IBOutlet var iconView:         UIImageView!
    @IBOutlet var label:            UILabel!
    @IBOutlet var descriptionView:  UITextView!
    @IBOutlet var containerView:    UIView!
    @IBOutlet var publisherView:    UIImageView!
    
    // icon constraints
    @IBOutlet var iconWidthConstraint: NSLayoutConstraint!
    @IBOutlet var iconRightMarginConstraint: NSLayoutConstraint!
    
    // unread indicator constraints
    @IBOutlet var indicatorWidthConstraint: NSLayoutConstraint!
    @IBOutlet var indicatorRightMarginConstraint: NSLayoutConstraint!
    
    // save indicator constraints
    @IBOutlet var saveIndicatorWidthConstraint: NSLayoutConstraint!
    @IBOutlet var saveIndicatorRightMarginConstraint: NSLayoutConstraint!

    // publisher view constraints
    @IBOutlet var publisherWidthConstraint: NSLayoutConstraint!
    @IBOutlet var publisherLeftMarginConstraint: NSLayoutConstraint!
    
    var icon: UIImage? {
        set {
            
            // set to show
            if newValue != nil {
                iconWidthConstraint.constant = 100
                iconRightMarginConstraint.constant = 8
                iconView.isHidden = false
                iconView.image = newValue
            }
            
            // set to hide
            else {
                iconWidthConstraint.constant = 0
                iconRightMarginConstraint.constant = 0
                iconView.isHidden = true
                iconView.image = nil
            }
            
        }
        get {
            return iconView.image
        }
    }
    
    override func awakeFromNib() {
        
        // rounded corners.
        // consider: rasterization?
        self.containerView.layer.cornerRadius  = 10
        self.containerView.layer.masksToBounds = true
        
        // background, selected background view.
        backgroundColor = Colors.cellColor
        selectedBackgroundView = Colors.cellSelectedBackgroundView

    }
    
    func update() {
        setArticle(_article)
    }
    
    fileprivate var _article: Article!
    func setArticle(_ article: Article) {
        
        // update indicator constraints
        indicatorWidthConstraint.constant           = article.read  ? 0  : 10
        indicatorRightMarginConstraint.constant     = article.read  ? 0  : 8
        saveIndicatorWidthConstraint.constant       = article.saved ? 10 : 0
        saveIndicatorRightMarginConstraint.constant = article.saved ? 8  : 0
        
        // show/hide publisher view
        if article.feed.logo == nil {
            publisherWidthConstraint.constant = 0
            publisherLeftMarginConstraint.constant = 0
        }
        else {
            publisherWidthConstraint.constant = 60
            publisherLeftMarginConstraint.constant = 5
        }
        
        // title and images
        label.text = article.title
        publisherView.image = article.feed.logo?.white
        icon = article.thumbImage
        
        // summary
        // if there's no summary, use the title.
        // odds are it's gotten truncated anyway.
        descriptionView.attributedText = article.hasSummary ? article.attributedSummary : article.attributedTitle
        
        _article = article
    }
    
}
