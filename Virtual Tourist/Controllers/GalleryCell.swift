//
//  GalleryCell.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 31/8/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageOverlay: UIView!
    
    var selectedPhoto = false
    
    override func prepareForReuse() {
        alpha = 1.0
        selectedPhoto = false
        image.image = nil
    }
}
