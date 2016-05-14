//
//  Pin.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/10/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin : NSManagedObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let UUID = "uuid"
        static let Photos = "photos"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var uuid: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Dictionary
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        uuid = dictionary[Keys.UUID] as! String
    }
    
    func updatePin(dictionary: [String : AnyObject]){
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
}