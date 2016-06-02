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
    
    //MARK: - IBOutlet & Variables
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var latitude: Double?
    var longitude: Double?
    var pin: Pin!
    
    //MARK: - Controller View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()
        configureController()
        loadPinLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: - MapView Delegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.purpleColor()
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //MARK: - Collection View Delegate
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 15
        /*if(section < 4) {
            return self.fetchedResultsController.sections![section].numberOfObjects
        } else {
            return 3
        }*/
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let countObjects = fetchedResultsController.fetchedObjects?.count
        
        if indexPath.item < countObjects {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            let photoImage = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            let urlData1 = UIImage(data: photoImage.image)
            let imageView = UIImageView(image: urlData1)
            cell.backgroundView = imageView
            cell.layer.cornerRadius = 4.0
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCellCVC
            cell.contentView.layer.cornerRadius = 4.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.blueColor().CGColor
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let countObjects = fetchedResultsController.fetchedObjects?.count
        
        if indexPath.item < countObjects {
        
        let photoIndex = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        sharedContext.deleteObject(photoIndex)
        
        saveData()
        performFetch()
        resetView()
        }
    }
    
    //MARK: - Core Data Functions
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
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
    
    //MARK: - IBActions
    
    @IBAction func back(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func newCollection(sender: AnyObject) {
        
        for entity in fetchedResultsController.fetchedObjects! {
            sharedContext.deleteObject(entity as! NSManagedObject)
        }
        
        performFetch()
        resetView()
        toggleActivityView(true)
        
        let lat = pin.latitude
        let long = pin.longitude
        
        FlickrAPI.sharedSession().getImageFromFlickr(lat, longitude: long, completion: { returnedData in
            
            if returnedData != [ "":"" ] {
                for (id, value) in returnedData {
                    let imageUrl = NSURL(string: value)
                    if let imageData = NSData(contentsOfURL: imageUrl!){
                        let getPhoto = Photo(data: imageData, picId: id, context: self.sharedContext)
                        getPhoto.setValue(self.pin, forKey: "pin")
                        self.saveData()
                        self.performFetch()
                        self.resetView()
                    }
                }
            } else {
                self.performFetch()
                self.resetView()
            }

            self.toggleActivityView(false)
        })
    }
    
    //MARK: - View Functions
    
    private func configureController() {
        print("\(latitude) \(longitude)")
        mapView.delegate = self
        photoCollection.delegate = self
        photoCollection.dataSource = self
        fetchedResultsController.delegate = self
        newCollectionButton.layer.zPosition = 1
        newCollectionButton.alpha = 0.5
        
        //photoCollection.registerClass(PhotoCellCVC.self, forCellWithReuseIdentifier: "photoCell")
        photoCollection.registerNib(UINib(nibName: "PhotoCellCVC", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        photoCollection.backgroundColor = UIColor.whiteColor()
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    private func loadPinLocation () {
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
    
    private func resetView() {
        dispatch_async(dispatch_get_main_queue(), {
            self.photoCollection.collectionViewLayout.invalidateLayout()
            self.photoCollection.reloadData()
            self.photoCollection.layoutIfNeeded()
        })
    }
    
    private func toggleActivityView(on: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
            if on {
                self.activityView.startAnimating()
                self.mapView.alpha = 0.5
                self.newCollectionButton.alpha = 0.5
                self.newCollectionButton.enabled = false
            } else {
                self.activityView.stopAnimating()
                self.mapView.alpha = 1
                self.newCollectionButton.alpha = 1
                self.newCollectionButton.enabled = true
            }
        })
    }
}
