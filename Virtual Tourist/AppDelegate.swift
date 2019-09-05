//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 27/8/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var storyBoard: UIStoryboard?
    let dataController = DataController(modelName: "VirtualTourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        dataController.load()
        
        print("\(UserDefaults.standard.getLatitude()) \(UserDefaults.standard.getLongitude()) \(UserDefaults.standard.getLatDelta()) \(UserDefaults.standard.getLonDelta()))")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "MainMapViewController") as! MainMapViewController
        viewController.dataController = dataController
        window?.rootViewController = viewController
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        dataController.saveContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        dataController.saveContext()
    }
}

