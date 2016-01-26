//
//  AppDelegate.swift
//  VCStarterProject
//
//  Created by Craig Barreras on 1/25/16.
//  Copyright © 2016 Vicino. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var dataController: DataController!
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        dataController = DataController { [unowned self] (success) -> Void in
            self.completeUserInterface()
        }
        
        return true
    }
    
    private func completeUserInterface() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = mainStoryboard.instantiateInitialViewController()
        rootViewController?.populateDataController(dataController)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }
}
