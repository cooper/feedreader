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
    
    var window:                 UIWindow!                       // the UI window
    var currentFeedVC:          FeedListVC?                     // the current feed group VC
    var navigationController:   UINavigationController!         // the navigation controller
    var defaultGroup:           FeedGroup!                      // the default feed group
    
    let feedQueue = NSOperationQueue()                          // queue for loading feeds
    let defaults  = NSUserDefaults.standardUserDefaults()       // standard user defaults
    let manager   = Manager()                                   // the single feed manager
    
    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        rss = self
        
        // load data from user defaults.
        fetchFromDefaults()
        manager.fetchAllFeeds()
        defaultGroup = manager.groups.first
        
        // set up interface.
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        currentFeedVC = FeedListVC(group: defaultGroup)
        navigationController = UINavigationController(rootViewController: currentFeedVC!)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
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

    func fetchFromDefaults() {

        // feeds. if no data is there, use empty array.
        let feedData = defaults.objectForKey("feeds") as? NSData
        let feedDict = feedData != nil ? NSKeyedUnarchiver.unarchiveObjectWithData(feedData!) as [NSDictionary] : [];
        manager.addFeedsFromStorage(feedDict)
        
        // groups. if no data is there, use array with default group.
        let groupData = defaults.objectForKey("groups") as? NSData
        let groupDict = groupData != nil ? NSKeyedUnarchiver.unarchiveObjectWithData(groupData!) as [NSDictionary] : [ FeedGroup(title: "Default").forStorage ]
        manager.addGroupsFromStorage(groupDict)
        
    }
    
    // save changes in user defaults database.
    // note that this does not actually update the database immediately.
    func saveChanges() {
        NSLog("Saving changes")
        
        // groups.
        let groupData = NSKeyedArchiver.archivedDataWithRootObject(manager.groupsForStorage)
        defaults.setObject(groupData, forKey: "groups")
        
        // feeds.
        let feedData = NSKeyedArchiver.archivedDataWithRootObject(manager.feedsForStorage)
        defaults.setObject(feedData, forKey: "feeds")
        
    }
    
}

public func mainQueue(handler: (Void -> Void)) {
    NSOperationQueue.mainQueue().addOperationWithBlock(handler)
}
