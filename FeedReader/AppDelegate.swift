//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window:                 UIWindow!                       // the UI window
    var navigationController:   UINavigationController!         // the navigation controller
    var defaultGroup:           FeedGroup!                      // the default feed group
    let feedQueue = OperationQueue()                          // queue for loading feeds
    let defaults  = UserDefaults.standard       // standard user defaults
    let center    = NotificationCenter.default        // default notification center
    let manager   = Manager()                                   // the single feed manager
    
    // the current feed list, if any
    var currentFeedVC: FeedListVC? {
        return navigationController.topViewController as? FeedListVC
    }
    
    // MARK: Application delegate
    
    // application will finish launching
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        rss = self
        
        // load data from storage.
        manager.loadContext()
        manager.fetchAllFeeds()
        
        // fetch or create default group.
        defaultGroup = manager.defaultGroup ?? {
            let group = FeedGroup(title: "Default")
            self.manager.groups.append(group)
            return group
        }()
                
        // set up interface.
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // navigation controller and default group view controller
        let feedVC = FeedDefaultVC(group: defaultGroup)
        navigationController = NavigationController(feedVC: feedVC)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // background refresh setup
        let freq = TimeInterval(3600 * settings.backgroundFrequency)
        application.setMinimumBackgroundFetchInterval(settings.backgroundRefresh ? freq :UIApplicationBackgroundFetchIntervalNever)
        
        return true
    }

    // save changes when resigning active
    func applicationWillResignActive(_ application: UIApplication) {
        manager.saveContext()
    }

    // save changes when terminating
    func applicationWillTerminate(_ application: UIApplication) {
        manager.saveContext()
    }
 
    // if it's been 20 minutes; update all feeds
    func applicationDidBecomeActive(_ application: UIApplication) {
        if manager.lastFetchTime.timeIntervalSinceNow <= -1200 {
            rss.log("It's been a while; updating")
            manager.fetchAllFeeds()
        }
    }
    // MARK: Activity indicator
    
    // activity indicator in status bar
    fileprivate var _activityLevel: Int = 0
    var activityLevel: Int {
        get {
            return _activityLevel
        }
        set {
            _activityLevel = newValue < 0 ? 0 : newValue
            UIApplication.shared.isNetworkActivityIndicatorVisible = newValue > 0
        }
    }
    
    // MARK: Logging
    
    let logging = false
    
    func log(_ format: String) {
        if !logging { return }
        NSLog(format.replacingOccurrences(of: "%", with: "%%"))
    }
    
    // MARK: Background refresh
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let articleCount = manager.articles.count
        manager.fetchAllFeedsThen {
            let changed = articleCount != self.manager.articles.count
            completionHandler(changed ? .newData : .noData)
        }
    }
    
}

// application delegate instance
var rss : AppDelegate!

// MARK:- Dispatch convenience

// perform a block of code in the main queue
func mainQueue(_ handler: @escaping ()->()) {
    DispatchQueue.main.async(execute: handler)
}

// perform a block of code in the main queue after a delay
func after(_ delay: Double, closure: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
        execute: closure
    )
}
