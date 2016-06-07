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

class PhotoAlbumVC: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    //MARK: - IBOutlet & Variables
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    private var loading = false
    private var canDelete = false
    var latitude: Double?
    var longitude: Double?
    var pin: Pin!
    
    //MARK: - Controller View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()
        allPicturesSelectedSetFalse()
        configureController()
        loadPinLocation()
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
        if loading {
            return 15
        } else {
            return self.fetchedResultsController.sections![section].numberOfObjects
        }
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
            if photoImage.selected {
                cell.alpha = 0.3
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! PhotoCellCVC
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
            
            if photoIndex.selected {
                photoIndex.selected = false
            } else {
                photoIndex.selected = true
            }
        
            saveData()
            performFetch()
            resetView()
            toggleNewCollectionButton()
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
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func newCollection(sender: AnyObject) {
        
        if canDelete {
            deletePictures()
            return
        }
        
        loading = true
        
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
                        self.performFetch()
                        self.resetView()
                    }
                }
                self.saveData()
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
        
        photoCollection.registerNib(UINib(nibName: "PhotoCellCVC", bundle: nil), forCellWithReuseIdentifier: "photoCell")
        photoCollection.backgroundColor = UIColor.whiteColor()
        newCollectionButton.layer.zPosition = 1
        newCollectionButton.alpha = 0.5
        
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
                self.mapView.alpha = 0.5
                self.newCollectionButton.alpha = 0.5
                self.newCollectionButton.enabled = false
            } else {
                self.loading = on
                self.mapView.alpha = 1
                self.newCollectionButton.alpha = 1
                self.newCollectionButton.enabled = true
            }
        })
    }
    
    private func toggleNewCollectionButton() {
        
        var canToggleButton = false
        
        for item in fetchedResultsController.fetchedObjects! {
            if item.selected == true {
                canToggleButton = true
            }
        }
        
        if canToggleButton {
            newCollectionButton.setTitle("Delete Pictures", forState: .Normal)
            canDelete = true
        } else {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    private func deletePictures() {
        for item in fetchedResultsController.fetchedObjects! {
            if item.selected == true {
                sharedContext.deleteObject(item as! NSManagedObject)
            }
        }
        
        saveData()
        performFetch()
        resetView()
        toggleNewCollectionButton()
        canDelete = false
    }
    
    private func allPicturesSelectedSetFalse() {
        for item in fetchedResultsController.fetchedObjects! {
            let photoIndex = item as! Photo
            photoIndex.selected = false
        }
        saveData()
        resetView()
    }
}
