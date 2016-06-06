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
    private var sendLat: Double = 0
    private var sendLong: Double = 0
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
        performFetch()
        addAllPins()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - MapView Delegate
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        sendLat = (view.annotation?.coordinate.latitude)!
        sendLong = (view.annotation?.coordinate.longitude)!
        mapView.deselectAnnotation(view.annotation, animated: false)
        findPinToSend(sendLat, long: sendLong, completionHandler: { didFindPin, foundPin in
            if didFindPin {
                self.holdPin = foundPin
                self.performSegueWithIdentifier("showAlbum", sender: view)
            }
        })
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {

        sendLat = (view.annotation?.coordinate.latitude)!
        sendLong = (view.annotation?.coordinate.longitude)!
        let sendDictionary = ["latitude": sendLat, "longitude": sendLong]

        findPinToSend(sendLat, long: sendLong, completionHandler: { didFindPin, foundPin in
            
            if didFindPin == false {
                foundPin.updatePin(sendDictionary)
                self.saveData()
            }
        })
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.draggable = true
            pinView!.pinTintColor = UIColor.purpleColor()
        } else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapState()
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
                    self.saveData()
                }
            }
            
            print(returnedData.count)
        })
        
        saveData()
        performFetch()
    }
    
    private func addAllPins() {
        
        self.travelMap.removeAnnotations(self.travelMap.annotations)
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
    
    private func findPinToSend(lat: Double, long: Double, completionHandler: (didFindPin: Bool, foundPin: Pin) -> Void) {
        for entity in self.fetchedResultsController.fetchedObjects!{
            let pin = entity as! Pin
            if lat == pin.latitude && long == pin.longitude {
                let theFoundPin = pin
                print("Found pin!")
                
                completionHandler(didFindPin: true, foundPin: theFoundPin)
            } else if self.holdPin != nil {
                completionHandler(didFindPin: false, foundPin: self.holdPin)
            }
        }
    }
    
    //MARK: - Clear Data
    
    @IBAction func clearMapData(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
        let actionAlert = UIAlertAction(title: "Yes", style: .Default) { (action) in
            for entity in self.fetchedResultsController.fetchedObjects! {
                self.sharedContext.deleteObject(entity as! NSManagedObject)
                self.saveData()
                self.performFetch()
                self.addAllPins()
            }
        }

        let okPress = UIAlertAction(title: "No", style: .Default) {(action) in
                return
        }
            
        let deleteAllPinsAlert = UIAlertController(title: "Warning!", message: "Do you want to delete all location data?", preferredStyle: .Alert)
            deleteAllPinsAlert.addAction(actionAlert)
            deleteAllPinsAlert.addAction(okPress)
            self.presentViewController(deleteAllPinsAlert, animated: true, completion: nil)
        })
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
}
