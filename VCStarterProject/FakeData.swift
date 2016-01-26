//
//  FakeData.swift
//  VCStarterProject
//
//  Created by Craig Barreras on 1/25/16.
//  Copyright © 2016 Vicino. All rights reserved.
//

import Foundation
import CoreData


class FakeData: NSManagedObject {

    class var entityName: String {
        get {
            return "FakeData"
        }
    }
}
