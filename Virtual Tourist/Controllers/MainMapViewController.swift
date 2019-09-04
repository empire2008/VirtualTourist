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

    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var navTitle: UINavigationItem!
    
    var isEditActive = false
    
    var dataController: DataController!
    var annotationView: MKAnnotationView?
    var annotations: [MKAnnotation] = []
    var cameraPosition = CameraLocation()
    var pins: [PinPoint] = []
    var timer = Timer()
    var isMapReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPins()
        loadCurrentCamera()
        loadPins()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addNewPin))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    func fetchPins(){
        let fetchRequest: NSFetchRequest<PinPoint> = PinPoint.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            pins = result
        }
    }
    
    // Mark: To set location from database to the map
    func loadCurrentCamera(){
        cameraPosition.lat = UserDefaults.standard.getLatitude()
        cameraPosition.lon = UserDefaults.standard.getLongitude()
        cameraPosition.latDelta = UserDefaults.standard.getLatDelta()
        cameraPosition.lonDelta = UserDefaults.standard.getLonDelta()
        
        // load last camera from data model
        let center = CLLocationCoordinate2D(latitude: cameraPosition.lat, longitude: cameraPosition.lon)
        let span = MKCoordinateSpan.init(latitudeDelta: cameraPosition.latDelta, longitudeDelta: cameraPosition.lonDelta)
        mapView.setRegion(MKCoordinateRegion.init(center: center, span: span), animated: false)
    }
    
    // Mark: To load pin data then shows them on the map
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
    
    func editUI(isOnEditMode: Bool){
        if isOnEditMode{
            self.navTitle.title = "Select Pin to Delete"
            self.editButton.title = "Cancel"
        }
        else{
            self.navTitle.title = "Virtual Tourist"
            self.editButton.title = "Edit"
        }
    }
    
    @IBAction func editButton(_ sender: Any) {
        isEditActive = !isEditActive
        print(isEditActive)
        editUI(isOnEditMode: isEditActive)
    }
}

extension MainMapViewController{
    
    // Add tap when hold press
    @objc func addNewPin(gestureReconizer: UILongPressGestureRecognizer){
        if gestureReconizer.state != .began{
            return
        }
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
        pins.append(pin)
        dataController.saveContext()
    }
    
    func removePin(annotation: MKAnnotation){
        // do delete data
        let location = annotation.coordinate
        let selectedPinPoint = pins.first { pin in
            pin.lat == location.latitude && pin.lon == location.longitude
        }
        for index in 0..<pins.count{
            if pins[index] == selectedPinPoint{
                dataController.viewContext.delete(pins[index])
                dataController.saveContext()
                pins.remove(at: index)
                break
            }
        }
        // do remove pin
        mapView.removeAnnotation(annotation)
        
    }
    
    // Save the location and zoom level when the camera moved
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let center = mapView.camera.centerCoordinate
        cameraPosition.lat = center.latitude
        cameraPosition.lon = center.longitude
        cameraPosition.latDelta = mapView.region.span.latitudeDelta
        cameraPosition.lonDelta = mapView.region.span.longitudeDelta
        
        timerToSave()
    }
    
    // I don't know what it is but when I do like this then annotation do as I expected...
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
        if isEditActive{
            // Do remove a pin
            if let annotation = view.annotation{
                removePin(annotation: annotation)
            }
        }
        else{
            // Do add a new pin
            guard let annotation = view.annotation else{
                return
            }
            let location = annotation.coordinate
            let selectedPinPoint = pins.first { pin in
                pin.lat == location.latitude && pin.lon == location.longitude
            }
            
            performSegue(withIdentifier: "goToPinDetail", sender: selectedPinPoint)
        }
    }
}

extension MainMapViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPinDetail"{
            let vc = segue.destination as! PhotoAlbumViewController
            vc.dataController = dataController
            vc.pinPoint = sender as? PinPoint
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
        if isMapReady{
            UserDefaults.standard.setLatitude(value: cameraPosition.lat)
            UserDefaults.standard.setLongitude(value: cameraPosition.lon)
            UserDefaults.standard.setLatDelta(value: cameraPosition.latDelta)
            UserDefaults.standard.setLonDelta(value: cameraPosition.lonDelta)
        }
        else{
            isMapReady = true
        }
    }
}
