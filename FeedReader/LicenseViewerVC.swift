//
//  LicenseViewerVC.swift
//  FeedReader
//
//  Created by Mitchell Cooper on 2/23/15.
//  Copyright (c) 2015 Mitchell Cooper. All rights reserved.
//

import UIKit

class LicenseViewerVC: UIViewController {
    @IBOutlet var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Licenses & Credits"
        let filePath = Bundle.main.resourcePath! + "/licenses.txt"
        textView.text = String(contentsOf: filePath, encoding: String.Encoding.utf8)
    }
}
