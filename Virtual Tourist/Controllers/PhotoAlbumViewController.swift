//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 27/8/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pinPoint: PinPoint!
    var dataController: DataController!
    var photos: [Gallery] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.isUserInteractionEnabled = false

        fetchedPhotos()
    }
    
    fileprivate func fetchedPhotos() {
        let fetchRequest: NSFetchRequest<Gallery> = Gallery.fetchRequest()
        let predicate = NSPredicate(format: "pinPoint == %@", pinPoint)
        let sortDesciptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDesciptor]
        
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            photos = result
        }
        
        collectionView.reloadData()
    }
    
    @IBAction func addPhotoButton(_ sender: Any) {
        let alert = UIAlertController(title: "Add Photo Selection", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Open Camera", style: .default, handler: { (action) in
            // open camera
            self.pickPhoto(isCamera: true)
        }))
        alert.addAction(UIAlertAction(title: "Open Library", style: .default, handler: { (action) in
            // open library
            self.pickPhoto(isCamera: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func pickPhoto(isCamera: Bool){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if isCamera{
            imagePicker.sourceType = .camera
        }
        else{
            imagePicker.sourceType = .photoLibrary
        }
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func save(imageData: Data){
        let photo = Gallery(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.photo = imageData
        
        do{
            try dataController.viewContext.save()
        }
        catch{
            print("Save Failed!")
        }
        
        self.fetchedPhotos()
    }
}

extension PhotoAlbumViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let selectedImage:UIImage?
        if let image = info[.originalImage] as? UIImage{
            selectedImage = image
            if let imageData = selectedImage?.pngData(){
                self.save(imageData: imageData)
            }
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        if let imageData = photos[indexPath.item].photo{
            cell.image.image = UIImage(data: imageData)
        }
        return cell
    }
}
