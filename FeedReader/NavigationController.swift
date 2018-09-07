//
//  NavigationController.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 1/31/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    convenience init(feedVC: UIViewController) {
        self.init(rootViewController: feedVC)
        navigationBar.barTintColor = Colors.barTintColor
        navigationBar.tintColor = Colors.accentColor
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.white
        ]
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

