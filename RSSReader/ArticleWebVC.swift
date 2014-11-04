//
//  ArticleWebVC.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 11/3/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

class ArticleWebVC: UIViewController {
    @IBOutlet var webView: UIWebView!
    var url: NSURL!
    var article: Article!

    // the view loaded, so we can load the URL now.
    override func viewDidLoad() {
        self.navigationItem.title = article.title
        webView.loadRequest(NSURLRequest(URL: article.url))
    }
    
}
