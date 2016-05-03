//
//  Photo.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/25/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    struct Keys {
        static let Image = "image"
        static let Id = "id"
    }

    @NSManaged var image: NSData
    @NSManaged var id: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(data: NSData, picId: String, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Image
        image = data
        
        //Id
        id = picId
    }
    
}
