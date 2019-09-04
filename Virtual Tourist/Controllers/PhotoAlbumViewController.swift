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

class PhotoAlbumViewController: UIViewController,NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pinPoint: PinPoint!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Gallery>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Gallery> = Gallery.fetchRequest()
        let predicate = NSPredicate(format: "pinPoint = %@", pinPoint)
        let sortDesciptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [sortDesciptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }
        catch{
            fatalError("Fetched Error: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.isUserInteractionEnabled = false
//        fetchedPhotos()
        setupFetchedResultsController()
        setupMapView()
        
        AppClient.requestPhoto(bbox: "23.33,37.74,24.42,38.8", complition: handlePhotosResponse(photoResponse:error:))
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    func handlePhotosResponse(photoResponse: FlickerPhotos?, error: Error?){
        if let photoResponse = photoResponse{
            print("Hello: \(photoResponse)")
        }
        else{
            print("Error: \(error?.localizedDescription ?? "")")
        }
    }
    
    func boxAreaToString(lat: Double, lon: Double, area: Double) -> String{
        let minLat = lat - area
        let maxLat = lat + area
        let minLon = lon - area
        let maxLon = lon + area
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        print("photos amount: \(photos.count)")
    }
    
    func setupMapView(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pinPoint.lat, longitude: pinPoint.lon)
        mapView.addAnnotation(annotation)
        
        let center = CLLocationCoordinate2D(latitude: pinPoint.lat, longitude: pinPoint.lon)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
//    fileprivate func fetchedPhotos() {
//        let fetchRequest: NSFetchRequest<Gallery> = Gallery.fetchRequest()
//        let predicate = NSPredicate(format: "pinPoint = %@", pinPoint)
//        let sortDesciptor = NSSortDescriptor(key: "creationDate", ascending: true)
//        fetchRequest.predicate = predicate
//        fetchRequest.sortDescriptors = [sortDesciptor]
//
//        if let result = try? dataController.viewContext.fetch(fetchRequest){
//            photos = result
//        }
//    }
    
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
        
        photo.pinPoint = pinPoint
        
        do{
            try dataController.viewContext.save()
        }
        catch{
            print("Save Failed!")
        }
//        self.fetchedPhotos()
    }
    
    func deletePhoto(indexPath: IndexPath){
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        dataController.saveContext()
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
        
        dismiss(animated: true, completion: nil)
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // if fetchResultController.section = nil then return 1 otherwise
        return fetchedResultsController.sections?.count ?? 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        let aPhoto = fetchedResultsController.object(at: indexPath)
        cell.image.image = UIImage(data: aPhoto.photo!)
//        if let imageData = photos[indexPath.item].photo{
//            cell.image.image = UIImage(data: imageData)
//        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.width / 3) - 4
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
