//
//  UIViewController+DataController.swift
//  EpicEats-iOS
//
//  Created by Alois Barreras on 10/3/15.
//  Copyright © 2015 Vicino. All rights reserved.
//

import UIKit

extension UIViewController {
    func populateDataController(dataController: DataController) {
        if let dataSelf = self as? DataViewControllerProtocol {
            dataSelf.dataController = dataController
            return
        }
        
        if let navSelf = self as? UINavigationController, let dataViewController = navSelf.topViewController as? DataViewControllerProtocol {
            dataViewController.dataController = dataController
            return
        }
    }
}
