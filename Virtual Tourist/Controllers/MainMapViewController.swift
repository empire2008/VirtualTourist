//
//  MainMapViewController.swift
//  Virtual Tourist
//
//  Created by SpaCE_MAC on 27/8/2562 BE.
//  Copyright © 2562 SpaCE_MAC. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MainMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var annotationView: MKAnnotationView?
    var annotations: [MKAnnotation] = []
    var cameraPosition: Camera?
    var pins: [PinPoint] = []
    var timer = Timer()
    var selectIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCamera()
        fetchPins()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addNewPin))
        mapView.addGestureRecognizer(longPressGesture)
        loadCurrentCamera()
        loadPins()
    }
    
    fileprivate func fetchCamera() {
        let fetchRequest: NSFetchRequest<Camera> = Camera.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            if !result.isEmpty{
                cameraPosition = result[0]
            }
        }
    }
    
    func fetchPins(){
        let fetchRequest: NSFetchRequest<PinPoint> = PinPoint.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pins = result
        }
    }
    
    func loadCurrentCamera(){
        if let cameraPosition = cameraPosition{
            // load last camera from data model
            let center = CLLocationCoordinate2D(latitude: cameraPosition.lat, longitude: cameraPosition.lon)
            let span = MKCoordinateSpan.init(latitudeDelta: cameraPosition.latDelta, longitudeDelta: cameraPosition.lonDelta)
            mapView.setRegion(MKCoordinateRegion.init(center: center, span: span), animated: false)
        }
        else{
            cameraPosition = Camera(context: dataController.viewContext)
        }
    }
    
    func loadPins(){
        if pins != []{
            for index in 0..<pins.count{
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pins[index].lat, longitude: pins[index].lon)
                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
        }
    }
}

extension MainMapViewController{
    
    // Add tap when hold press
    @objc func addNewPin(gestureReconizer: UILongPressGestureRecognizer){
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        savePin(annotation: annotation)
    }
    
    func savePin(annotation: MKPointAnnotation){
        let pin = PinPoint(context: dataController.viewContext)
        pin.lat = annotation.coordinate.latitude
        pin.lon = annotation.coordinate.longitude
        
        save()
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let center = mapView.camera.centerCoordinate
        cameraPosition?.lat = center.latitude
        cameraPosition?.lon = center.longitude
        cameraPosition?.latDelta = mapView.region.span.latitudeDelta
        cameraPosition?.lonDelta = mapView.region.span.longitudeDelta
        
        timerToSave()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if annotationView == nil{
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        if annotation is MKUserLocation{
            return nil
        }
        annotationView?.canShowCallout = false
        return annotationView
    }
    
    // MARK: Event when tapped on pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "goToPinDetail", sender: self)
    }
}

extension MainMapViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPinDetail"{
            let vc = segue.destination as! PhotoAlbumViewController
            vc.dataController = dataController
            
        }
    }
}

// MARK: Save Functions
extension MainMapViewController{
    // prevent from calling save every movement
    func timerToSave(){
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(save), userInfo: nil, repeats: false)
    }
    
    @objc func save(){
        self.dataController.saveContext()
    }
}
