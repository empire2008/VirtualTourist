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
    var fetchedResultsController: NSFetchedResultsController<Gallery>!
    let photoPerLoad = 25
    var page = 1
    var photoAmount = 0
    var photos: [Data] = []
    var blockOperations: [BlockOperation] = []
    var itemChanges = [NSFetchedResultsChangeType: IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.isUserInteractionEnabled = false
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        if fetchedResultsController.sections?[0].numberOfObjects == 0{
            AppClient.requestPhoto(pinPoint: pinPoint, page: page, complition: handlePhotosResponse(photoResponse:error:))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Gallery> = Gallery.fetchRequest()
        let predicate = NSPredicate(format: "pinPoint = %@", pinPoint)
//        let sortDesciptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }
        catch{
            fatalError("Fetched Error: \(error.localizedDescription)")
        }
    }
    
    func handlePhotosResponse(photoResponse: FlickerPhotos?, error: Error?){
        if let photoResponse = photoResponse{
            self.photoAmount = photoResponse.photos.photo.count
            for _ in 0..<photoResponse.photos.photo.count{
                self.saveMetaData()
            }
//            DispatchQueue.global(qos: .background).async {
//                for index in 0..<photoResponse.photos.photo.count{
//                    let photoData = try? Data(contentsOf: URL(string: photoResponse.photos.photo[index].url)!)
//                    if let photoData = photoData{
//                        self.savePhoto(photoData)
//                    }
//                }
//            }
        }
        else{
            print("Error: \(error?.localizedDescription ?? "")")
        }
    }
    
    fileprivate func savePhoto(_ photoData: Data) {
        let photoTosave = Gallery(context: self.dataController.viewContext)
        photoTosave.photo = photoData
        photoTosave.pinPoint = self.pinPoint
        self.dataController.saveContext()
    }
    
    func setupMapView(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pinPoint.lat, longitude: pinPoint.lon)
        mapView.addAnnotation(annotation)
        
        let center = CLLocationCoordinate2D(latitude: pinPoint.lat, longitude: pinPoint.lon)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
    @IBAction func newCollectionButton(_ sender: Any) {
        collectionView.reloadData()
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func savePhotoAt(imageData: Data, index: IndexPath){
        let photo = fetchedResultsController.object(at: index)
        photo.photo = imageData
        dataController.saveContext()
    }
    
    // MARK: Save to Data Model
    func saveMetaData(){
        let photo = Gallery(context: dataController.viewContext)
        photo.creationDate = Date()
//        photo.photo = imageData
        photo.pinPoint = pinPoint
        dataController.saveContext()
    
    }
    func deletePhoto(indexPath: IndexPath){
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        dataController.saveContext()
    }
}

// MARK: Collection View configured
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // if fetchResultController.section = nil then return 1 otherwise
        return fetchedResultsController.sections?.count ?? 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
//        return photoAmount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        cell.activityIndicator.startAnimating()
        cell.imageOverlay.isHidden = false
        
        let aPhoto = fetchedResultsController.object(at: indexPath)
        if aPhoto.photo == nil{
            AppClient.requestPhoto(pinPoint: pinPoint, page: page) { (photoResponse, error) in
                if let photoResponse = photoResponse{
                    DispatchQueue.global(qos: .background).async {
                        let photoData = try? Data(contentsOf: URL(string: photoResponse.photos.photo[indexPath.item].url)!)
                        if let photoData = photoData{
                            self.savePhotoAt(imageData: photoData, index: indexPath)
                        }
                    }
                }
            }
        }
        else{
            cell.activityIndicator.stopAnimating()
            cell.imageOverlay.isHidden = true
            cell.image.image = UIImage(data: aPhoto.photo!)
        }
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

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?){
        switch type {
        case .insert:
            itemChanges[type] = newIndexPath
        case .update:
            itemChanges[type] = indexPath
        case .delete:
            itemChanges[type] = indexPath
        default:
            collectionView.reloadData()
            break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        itemChanges.removeAll()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for (type, indexPath) in itemChanges{
                switch type{
                case .insert: self.collectionView.insertItems(at: [indexPath])
                case .delete: self.collectionView.deleteItems(at: [indexPath])
                case .update: self.collectionView.reloadItems(at: [indexPath])
                default:
                    collectionView.reloadData()
                    break
                }
            }
        }, completion: nil)
    }
}
