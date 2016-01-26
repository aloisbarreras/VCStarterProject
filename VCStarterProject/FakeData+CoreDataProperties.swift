//
//  FakeData+CoreDataProperties.swift
//  VCStarterProject
//
//  Created by Craig Barreras on 1/25/16.
//  Copyright © 2016 Vicino. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension FakeData {

    @NSManaged var body: String?
    @NSManaged var identifier: String?
    @NSManaged var title: String?

}
