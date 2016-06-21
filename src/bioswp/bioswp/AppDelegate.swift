//
//  AppDelegate.swift
//  bioswp
//
//  Created by Stephan Thordal Larsen on 09/06/16.
//  Copyright © 2016 Stephan Thordal Larsen. All rights reserved.
//

import UIKit
import WatchConnectivity
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    let healthStore = HKHealthStore()
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activateSession()
            }
        }
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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

    // authorization from watch
    func applicationShouldRequestHealthAuthorization(application: UIApplication) {
        
        self.healthStore.handleAuthorizationForExtensionWithCompletion { success, error in
            
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        do {
            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
            guard let location = message["location"] as? String else {return}
            
            if let heartRateArray = message["heartRateArray"] as? Array<Double> {
                if let pathUrl = NSURL(string: location, relativeToURL: documentsDir) {
                    try heartRateArray.description.writeToURL(pathUrl, atomically: true, encoding: NSASCIIStringEncoding)
                    replyHandler([:])
                }
            }
            
            if let arrayX = message["accelerometerArrayX"] as? Array<Double> {
                if let arrayY = message["accelerometerArrayY"] as? Array<Double> {
                    if let arrayZ = message["accelerometerArrayZ"] as? Array<Double> {
                        var combinedArray = Array<(Double,Double,Double)>()
                        let num = min(arrayX.count, arrayY.count, arrayZ.count)
                        var index = 0
                        while index < num {
                            combinedArray.append((arrayX[index], arrayY[index], arrayZ[index]))
                            index += 1
                        }
                        if let pathUrl = NSURL(string: location, relativeToURL: documentsDir) {
                            try combinedArray.description.writeToURL(pathUrl, atomically: true, encoding: NSASCIIStringEncoding)
                            replyHandler([:])
                        }
                    }
                }
            }
            
            
        } catch { print("Write to/Creation of URL threw exception") }
    }

}

