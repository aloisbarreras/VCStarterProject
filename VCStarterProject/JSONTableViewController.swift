//
//  JSONTableViewController.swift
//  VCStarterProject
//
//  Created by Craig Barreras on 1/25/16.
//  Copyright © 2016 Vicino. All rights reserved.
//

import UIKit
import CoreData

class JSONTableViewController: UITableViewController, DataViewControllerProtocol {
    
    weak var dataController: DataController!
    
    private var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController = dataController.jsonDataResultsController(delegate: self)
        
        refreshControl?.beginRefreshing()
        dataController.fetchJSONData() { [weak self] in
            self?.refreshControl?.endRefreshing()
            self?.tableView.reloadData()
        }
    }
}

extension JSONTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let fakeDataObject = fetchedResultsController.objectAtIndexPath(indexPath) as! FakeData
        
        cell.textLabel?.text = fakeDataObject.title
        cell.detailTextLabel?.text = fakeDataObject.body
        
        return cell
    }
}

extension JSONTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case NSFetchedResultsChangeType.Insert:
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: .Automatic)
            }
        case NSFetchedResultsChangeType.Delete:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([deleteIndexPath], withRowAnimation: .Automatic)
            }
        case NSFetchedResultsChangeType.Update:
            if let indexPath = indexPath {
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case NSFetchedResultsChangeType.Move:
            // Note that for Move, we delete the row at __indexPath__
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRowsAtIndexPaths([deleteIndexPath], withRowAnimation: .Automatic)
            }
            
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRowsAtIndexPaths([insertIndexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.insertSections(sectionIndexSet, withRowAnimation: .Automatic)
        case .Delete:
            let sectionIndexSet = NSIndexSet(index: sectionIndex)
            self.tableView.deleteSections(sectionIndexSet, withRowAnimation: .Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
