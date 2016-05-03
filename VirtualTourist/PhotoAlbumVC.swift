//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/12/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "photoCell"

class PhotoAlbumVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var photoArray = []
    var pin: Pin!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        photoCollection.delegate = self
        photoCollection.dataSource = self
        loadPinLocation()
        photoCollection.registerClass(PhotoCellCVC.self, forCellWithReuseIdentifier: "photoCell")
        print("\(latitude) \(longitude)")
        
        photoCollection.backgroundColor = UIColor.whiteColor()
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.width - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        fetchedResultsController.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func back(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    func loadPinLocation () {
        mapView.zoomEnabled = false
        mapView.scrollEnabled = false
        mapView.userInteractionEnabled = false
        mapView.region.center.latitude = latitude!
        mapView.region.center.longitude = longitude!
        mapView.region.span.latitudeDelta = 0.01
        mapView.region.span.longitudeDelta = 0.01
        
        let pin = MKPointAnnotation()
        pin.coordinate.latitude = latitude!
        pin.coordinate.longitude = longitude!
    
        mapView.addAnnotation(pin)
    }
    
    
    //MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let fetchedSectionNumber = self.fetchedResultsController.sections![section]
        if(section < 4) {
            return fetchedSectionNumber.numberOfObjects
        } else {
            return 3
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCellCVC
        
        let photoImage = fetchedResultsController.objectAtIndexPath(indexPath)
        
        let urlData1 = UIImage(data: photoImage.valueForKey("image")! as! NSData)
        let imageView = UIImageView(image: urlData1)
        cell.backgroundView = imageView
        return cell
    }
    
    //Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //Mark: - Fetched Results COntroller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    @IBAction func refreshView(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.photoCollection.collectionViewLayout.invalidateLayout()
            self.photoCollection.reloadData()
            self.photoCollection.layoutIfNeeded()
        })
    }
}
