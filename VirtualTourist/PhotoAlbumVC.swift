//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/12/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumVC: UIViewController, MKMapViewDelegate, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    
    var latitude: Double?
    var longitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        loadPinLocation()
        print("\(latitude) \(longitude)")
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
        }
        

        
        mapView.addAnnotation(pin)
    }
}
