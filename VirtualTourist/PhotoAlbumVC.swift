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
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()
        configureController()
        loadPinLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        print(self.fetchedResultsController.sections![section].numberOfObjects)
        if(section < 4) {
            return self.fetchedResultsController.sections![section].numberOfObjects
        } else {
            return 3
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCellCVC
        
        let photoImage = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let urlData1 = UIImage(data: photoImage.image)
        let imageView = UIImageView(image: urlData1)
        cell.backgroundView = imageView
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photoIndex = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        sharedContext.deleteObject(photoIndex)
        
        saveData()
        performFetch()
        resetView()
    }
    
    //Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin.uuid == %@", self.pin.uuid)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    //Mark: - Configure Loaded View
    
    private func configureController() {
        print("\(latitude) \(longitude)")
        mapView.delegate = self
        photoCollection.delegate = self
        photoCollection.dataSource = self
        fetchedResultsController.delegate = self
        newCollectionButton.layer.zPosition = 1
        newCollectionButton.alpha = 0.5
        
        photoCollection.registerClass(PhotoCellCVC.self, forCellWithReuseIdentifier: "photoCell")
        photoCollection.backgroundColor = UIColor.whiteColor()
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func resetView() {
        dispatch_async(dispatch_get_main_queue(), {
            self.photoCollection.collectionViewLayout.invalidateLayout()
            self.photoCollection.reloadData()
            self.photoCollection.layoutIfNeeded()
        })
    }
    
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
    
    @IBAction func newCollection(sender: AnyObject) {
        
        for entity in fetchedResultsController.fetchedObjects! {
            sharedContext.deleteObject(entity as! NSManagedObject)
        }
        
        performFetch()
        resetView()
        
        let lat = pin.latitude
        let long = pin.longitude
        
        FlickrAPI.sharedSession().getImageFromFlickr(lat, longitude: long, completion: { returnedData in
            
            for (id, value) in returnedData {
                let imageUrl = NSURL(string: value)
                if let imageData = NSData(contentsOfURL: imageUrl!){
                    let getPhoto = Photo(data: imageData, picId: id, context: self.sharedContext)
                    getPhoto.setValue(self.pin, forKey: "pin")
                    print(getPhoto)
                    self.saveData()
                }
            }
            
            self.performFetch()
            self.resetView()
        })
        

    }
    
}
