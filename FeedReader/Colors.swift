//
//  Colors.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 1/31/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit

struct Colors {
    
    // MARK: General
    
    static let tableColor       = UIColor(red: 55/255, green:  55/255, blue:  55/255, alpha: 1)
    static let cellColor        = UIColor(red: 33/255, green:  33/255, blue:  33/255, alpha: 1)
    static let accentColor      = UIColor(red: 30/255, green: 170/255, blue: 255/255, alpha: 1)
    static let barTintColor     = tableColor
    static let separatorColor   = UIColor(white: 0.2, alpha: 1)
    
    // MARK: Operations
    
    static let unreadColor      = accentColor
    static let savedColor       = UIColor(red:  71/255, green: 203/255, blue:  0/255, alpha: 1)
    static let deleteColor      = UIColor(red: 255/255, green:  50/255, blue: 50/255, alpha: 1)
    
    // MARK: Cells
    
    static let cellSelectedBackgroundColor = UIColor(white: 1 , alpha: 0.1)
    
    static var cellSelectedBackgroundView: UIView {
        let view = UIView()
        view.backgroundColor = cellSelectedBackgroundColor
        return view
    }
    
    static var cellBackgroundView: UIView {
        let view = UIView()
        view.backgroundColor = cellColor
        return view
    }
    
}