//
//  TravelLocationVC.swift
//  VirtualTourist
//
//  Created by Robert Garza on 3/31/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationVC: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var travelMap: MKMapView!
    
    private let prefs = NSUserDefaults.standardUserDefaults()
    private var sendLat: Double?
    private var sendLong: Double?
    private var holdPin: Pin!
    
    //MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        persistentMap()
        
        let pinDrop = UILongPressGestureRecognizer(target: self, action: "dropPin:")
        pinDrop.minimumPressDuration = 1.5
        self.travelMap.addGestureRecognizer(pinDrop)
        
        fetchedResultsController.delegate = self
        travelMap.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveMapState()
    }
    
    override func viewWillAppear(animated: Bool) {
        performFetch()
        addAllPins()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - MapView Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        sendLat = view.annotation?.coordinate.latitude
        sendLong = view.annotation?.coordinate.longitude
        findPinToSend(sendLat!, long: sendLong!, completionHandler: { foundPin in
            if foundPin {
                self.performSegueWithIdentifier("showAlbum", sender: view)
            }
        })
    }
    
    //MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    lazy var fetchedResultsControllerPhoto: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "uuid", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    private func saveData() {
        do {
            try self.sharedContext.save()
        } catch {
            print("not saved")
        }
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showAlbum") {
            let album = segue.destinationViewController as! PhotoAlbumVC
            album.latitude = sendLat
            album.longitude = sendLong
            album.pin = holdPin
        }
    }
    
    //MARK: - Persist Map Functions
    
    private func persistentMap() {
        guard let latloc: Double = prefs.doubleForKey("lat") else {
            print("no latitude location yet")
            return
        }
        
        guard let longloc: Double = prefs.doubleForKey("long") else {
            print("no longitutde")
            return
        }
        
        guard let latDelta: Double = prefs.doubleForKey("latDelta") else {
            print("no latDelta")
            return
        }
        
        guard let longDelta: Double = prefs.doubleForKey("longDelta") else {
            print("no longDelta")
            return
        }
        
        if latloc != 0 && longloc != 0{
            travelMap.centerCoordinate.latitude = latloc
            travelMap.centerCoordinate.longitude = longloc
        }
        
        if latDelta != 0 && longDelta != 0 {
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
            travelMap.region.span = span
        }
    }
    
    private func saveMapState() {
        let latDelta = travelMap.region.span.latitudeDelta
        let longDelta = travelMap.region.span.longitudeDelta
        let lat: Double = travelMap.centerCoordinate.latitude
        let long: Double = travelMap.centerCoordinate.longitude
        
        prefs.setDouble(lat, forKey: "lat")
        prefs.setDouble(long, forKey: "long")
        prefs.setDouble(latDelta, forKey: "latDelta")
        prefs.setDouble(longDelta, forKey: "longDelta")
    }
    
    //MARK: - Pin Functions
    
    func dropPin(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {
            return
        }
        
        let touchPoint: CGPoint = gestureRecognizer.locationInView(self.travelMap)
        let touchMapCoordinate: CLLocationCoordinate2D = self.travelMap.convertPoint(touchPoint, toCoordinateFromView: self.travelMap)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        let lat: Double = touchMapCoordinate.latitude
        let long: Double = touchMapCoordinate.longitude
        let uuid: String = NSUUID().UUIDString
        
        let newPoint = ["latitude": lat, "longitude": long, "uuid": uuid]
        
        let savedPin = Pin(dictionary: newPoint as! [String : AnyObject], context: self.sharedContext)
        
        self.travelMap.addAnnotation(annotation)
        
        FlickrAPI.sharedSession().getImageFromFlickr(lat, longitude: long, completion: { returnedData in
            
            for (id, value) in returnedData {
                let imageUrl = NSURL(string: value)
                if let imageData = NSData(contentsOfURL: imageUrl!){
                    let getPhoto = Photo(data: imageData, picId: id, context: self.sharedContext)
                    getPhoto.setValue(savedPin, forKey: "pin")
                    print(getPhoto)
                    self.saveData()
                }
            }
        })
        
        saveData()
        performFetch()
        addAllPins()
    }
    
    private func addAllPins() {
        
        travelMap.removeAnnotations(travelMap.annotations)
        var annotations = [MKPointAnnotation]()
        
        for entity in self.fetchedResultsController.fetchedObjects! {
            
            let pin = entity as! Pin
            
            let lat = pin.latitude
            let long = pin.longitude
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        travelMap.addAnnotations(annotations)
    }
    
    private func findPinToSend(lat: Double, long: Double, completionHandler: (foundPin: Bool) -> Void) {
        for entity in self.fetchedResultsController.fetchedObjects!{
            let pin = entity as! Pin
            if lat == pin.latitude && long == pin.longitude {
                holdPin = pin
                print("Found pin!")
                
                completionHandler(foundPin: true)
            }
        }
    }
}
