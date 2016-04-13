//
//  PhotoAlbumVC.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/12/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumVC: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func back(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loadPinLocation () {
        //let geo = CLGeocoder()
    }

}
