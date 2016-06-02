//
//  PhotoCellCVC.swift
//  VirtualTourist
//
//  Created by Robert Garza on 4/24/16.
//  Copyright © 2016 Robert Garza. All rights reserved.
//

import UIKit

class PhotoCellCVC: UICollectionViewCell {
    
    @IBOutlet weak var noImageText: UITextView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
