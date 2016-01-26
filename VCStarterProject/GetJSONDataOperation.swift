//
//  GetJSONDataOperation.swift
//  VCStarterProject
//
//  Created by Craig Barreras on 1/25/16.
//  Copyright © 2016 Vicino. All rights reserved.
//

import UIKit
import CoreData

private let url = "http://jsonplaceholder.typicode.com/posts" // fake json data provider

class GetJSONDataOperation: NSOperation {
    private var innerMOC: NSManagedObjectContext
    private var data = NSMutableData()
    private var task: NSURLSessionTask?
    private let dispatchGroup = dispatch_group_create()
    
    init(parentMOC: NSManagedObjectContext) {
        innerMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        innerMOC.parentContext = parentMOC
        super.init()
        name = "GetJSONDataOperation"
    }
    
    override func main() {
        if cancelled {
            return
        }
        
        // build network request
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "GET"
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: self,
            delegateQueue: nil)
        task = session.dataTaskWithRequest(request)
        dispatch_sync(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        task?.resume()
        dispatch_group_enter(dispatchGroup)
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER) // pause run loop to wait for network request to finish
        
        if cancelled {
            return
        }
        
        let localData = data
        var json: AnyObject? = nil
        do {
            json = try NSJSONSerialization.JSONObjectWithData(localData, options: .MutableContainers)
        } catch let error as NSError {
            // TODO: do something with an error
            print(error.localizedDescription, __FILE__, __FUNCTION__, __LINE__)
        }
        
        // case the results data to JSON
        guard let localJson = json as? [JSON] else {
            print("error reading json", __FILE__, __FUNCTION__, __LINE__)
            return
        }
        
        // manipulate the data
        let innerMOC = self.innerMOC
        innerMOC.performBlockAndWait {
            for jsonObject in localJson {
                let managedFakeDataObject = NSEntityDescription.insertNewObjectForEntityForName(FakeData.entityName, inManagedObjectContext: innerMOC) as! FakeData
                managedFakeDataObject.title = jsonObject["title"] as? String
                managedFakeDataObject.body = jsonObject["body"] as? String
                managedFakeDataObject.identifier = jsonObject["id"] as? String
            }
        }
        
        do {
            try innerMOC.save()
        } catch let error as NSError {
            print(error.localizedDescription, __FILE__, __FUNCTION__, __LINE__)
        }
    }
}

extension GetJSONDataOperation: NSURLSessionDataDelegate {
    private func finish() {
        dispatch_sync(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        dispatch_group_leave(dispatchGroup)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.data.appendData(data)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        finish()
    }
}
