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
    @IBOutlet weak var noPhotoView: UIView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pinPoint: PinPoint!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Gallery>!
    var page = 1
    var maxPage = 1
    var photoAmount = 0
    var photos: [Data] = []
    var blockOperations: [BlockOperation] = []
    var itemChanges = [NSFetchedResultsChangeType: IndexPath]()
    var selectedImages: [IndexPath] = []
    var isOnSelectMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.isUserInteractionEnabled = false
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        if fetchedResultsController.sections?[0].numberOfObjects == 0{
            requestPhoto()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Gallery> = Gallery.fetchRequest()
        let predicate = NSPredicate(format: "pinPoint = %@", pinPoint)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }
        catch{
            print("Fetched Error: \(error.localizedDescription)")
        }
    }
    
    func requestPhoto(){
        AppClient.requestPhoto(pinPoint: pinPoint, page: page, complition: handlePhotosResponse(photoResponse:error:))
    }
    
    func handlePhotosResponse(photoResponse: FlickerPhotos?, error: Error?){
        if let photoResponse = photoResponse{
            if photoResponse.photos.photo.count == 0{
                noPhotoView.isHidden = false
            }
            else{
                self.photoAmount = photoResponse.photos.photo.count
                self.maxPage = photoResponse.photos.pages
                for index in 0..<photoResponse.photos.photo.count{
                    self.saveMetaData(imageUrl: photoResponse.photos.photo[index].url)
                }
            }
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
    
    func updateTitle(){
        if isOnSelectMode{
            newCollectionButton.title = "Delete Photo"
        }
        else{
            newCollectionButton.title = "New Collection"
        }
    }
    
    @IBAction func newCollectionButton(_ sender: Any) {
        if isOnSelectMode{
            for indexPath in selectedImages{
                deletePhoto(indexPath: indexPath)
            }
            selectedImages = []
            isOnSelectMode = false
            updateTitle()
        }
        else{
            noPhotoView.isHidden = true
            if page < maxPage{
                page += 1
            }
            else{
                page = 1
            }
            for data in fetchedResultsController!.fetchedObjects!{
                dataController.viewContext.delete(data)
            }
            self.collectionView.reloadData()
            requestPhoto()
            fetchedResultsController = nil
            setupFetchedResultsController()
        }
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
    func saveMetaData(imageUrl: String){
        let photo = Gallery(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.pinPoint = pinPoint
        photo.photoUrl = imageUrl
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
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCell", for: indexPath) as! GalleryCell
        cell.activityIndicator.startAnimating()
        cell.imageOverlay.isHidden = false
        let aPhoto = fetchedResultsController.object(at: indexPath)
        if aPhoto.photo == nil{
            AppClient.requestImageFile(url: URL(string: aPhoto.photoUrl!)!) { (image, error) in
                if let image = image{
                    aPhoto.photo = image.pngData()
                    self.dataController.saveContext()
                }
            }
        }
        else{
            cell.activityIndicator.stopAnimating()
            cell.imageOverlay.isHidden = true
            cell.image.image = UIImage(data: aPhoto.photo!)
        }
        checkSelectPhoto(cell: cell)
        return cell
    }
    func checkSelectPhoto(cell: GalleryCell){
        if cell.selectedPhoto{
            cell.alpha = 0.2
        }
        else{
            cell.alpha = 1.0
        }
    }
    func addSelectCell(cell: GalleryCell, indexPath: IndexPath){
        cell.selectedPhoto = true
        selectedImages.append(indexPath)
        isOnSelectMode = true
        updateTitle()
        checkSelectPhoto(cell: cell)
    }
    func removeSelectedCell(cell: GalleryCell, indexPath: IndexPath){
        for index in 0..<selectedImages.count{
            if selectedImages[index] == indexPath{
                selectedImages.remove(at: index)
                cell.selectedPhoto = false
                checkSelectPhoto(cell: cell)
                break
            }
        }
        if selectedImages == []{
            isOnSelectMode = false
            updateTitle()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! GalleryCell
        
        if cell.selectedPhoto{
            removeSelectedCell(cell: cell, indexPath: indexPath)
        }
        else{
            addSelectCell(cell: cell, indexPath: indexPath)
        }
        print(cell.selectedPhoto)
    }
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath) as! GalleryCell
//        if cell.image != nil{
//            if cell.selectedPhoto{
//                cell.selectedPhoto = false
//                cell.image.alpha = 1.0
//                for index in 0..<selectedImages.count{
//                    if selectedImages[index] == indexPath{
//                        selectedImages.remove(at: index)
//                        break
//                    }
//                }
//            }
//            else{
//                cell.selectedPhoto = true
//                cell.image.alpha = 0.2
//                selectedImages.append(indexPath)
//            }
//        }
//
//        if selectedImages != []{
//            isOnSelectMode = true
//            newCollectionButton.title = "Delete Photo"
//        }
//        else{
//            isOnSelectMode = false
//            newCollectionButton.title = "New Collection"
//        }
//    }
    
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
