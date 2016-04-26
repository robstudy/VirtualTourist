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
    
        var dataArray = [String]()

        
        FlickrAPI.sharedSession().getImageFromFlickr(latitude!, longitude: longitude!){returnedData in
            
            for item in returnedData {
                dataArray.append(item)
            }
            print(dataArray.count)
            self.photoArray = dataArray
        }
        mapView.addAnnotation(pin)
    }
    
    
    //MARK: - Collection View
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(section < 4) {
            return photoArray.count
        } else {
            return 3
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCellCVC
        
        let image = photoArray[indexPath.item] as! String
        let imageURL = NSURL(string: image)
        if let imageData = NSData(contentsOfURL: imageURL!) {
            let urlData = UIImage(data: imageData)
            let imageView = UIImageView(image: urlData)
            
            cell.backgroundView = imageView
            
        }
        return cell
    }
    
    @IBAction func refreshView(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), {
            self.photoCollection.collectionViewLayout.invalidateLayout()
            self.photoCollection.reloadData()
            self.photoCollection.layoutIfNeeded()
        })
    }
}
