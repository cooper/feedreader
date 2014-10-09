//
//  AppDelegate.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 9/18/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

var rss : AppDelegate!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let feedQueue = NSOperationQueue()
    var window: UIWindow?
    let defaults = NSUserDefaults.standardUserDefaults()
    let group = FeedGroup() // temporary
    var navigationController: UINavigationController!
    var feedVC: FeedListVC!

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        rss = self
        
        // set up interface.
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        feedVC = FeedListVC(group: group)
        navigationController = UINavigationController(rootViewController: feedVC)
        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()

        // load feeds from user defaults.
        if let storedData = defaults.objectForKey("mainGroup") as? NSData {
            let storageDict = NSKeyedUnarchiver.unarchiveObjectWithData(storedData) as [String: AnyObject]
            group.addFeedsFromStorage(storageDict)
        }
        group.fetchAllFeeds()
        
        return true;
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        defaults.synchronize()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // add a new feed, reload the table, and fetch it.
    // this will be used for both the add button as well as
    // opening a feed from another application.
    func addNewFeed(feed: Feed) {
        group.addFeed(feed)
        feedVC.tableView.reloadData()
        feed.fetchThen(saveChanges)
    }

    // save changes in user defaults database.
    // note that this does not actually update the database immediately.
    func saveChanges() {
        println("Saving changes")
        let data = NSKeyedArchiver.archivedDataWithRootObject(group.forStorage())
        defaults.setObject(data, forKey: "mainGroup")
    }
    
}

