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
        if UserDefaults.standard.isHasData(){
            self.setupCamera()
        }
        fetchPins()
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
    fileprivate func loadSavedLocation() {
        cameraPosition.lat = UserDefaults.standard.getLatitude()
        cameraPosition.lon = UserDefaults.standard.getLongitude()
        cameraPosition.latDelta = UserDefaults.standard.getLatDelta()
        cameraPosition.lonDelta = UserDefaults.standard.getLonDelta()
    }
    
    fileprivate func setupCenterLocation() {
        // load last camera from data model
        let center = CLLocationCoordinate2D(latitude: self.cameraPosition.lat, longitude: self.cameraPosition.lon)
        let span = MKCoordinateSpan.init(latitudeDelta: self.cameraPosition.latDelta, longitudeDelta: self.cameraPosition.lonDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: false)
    }
    
    func setupCamera(){
        loadSavedLocation()
        setupCenterLocation()
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
//        let center = CLLocationCoordinate2D(latitude: 20.957512092045484, longitude: 103.62369673117148)
//        let span = MKCoordinateSpan.init(latitudeDelta: 0.03493474022581111, longitudeDelta: 0.024062736300379584)
//        let region = MKCoordinateRegion(center: center, span: span)
//        mapView.setRegion(region, animated: false)
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
    
    // MARK: Remove pin
    func removePin(annotation: MKAnnotation){
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
    // MARK: Save the location and zoom level when the camera moved
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        cameraPosition.lat = center.latitude
        cameraPosition.lon = center.longitude
        cameraPosition.latDelta = mapView.region.span.latitudeDelta
        cameraPosition.lonDelta = mapView.region.span.longitudeDelta
        
        UserDefaults.standard.setLatitude(value: cameraPosition.lat)
        UserDefaults.standard.setLongitude(value: cameraPosition.lon)
        UserDefaults.standard.setLatDelta(value: cameraPosition.latDelta)
        UserDefaults.standard.setLonDelta(value: cameraPosition.lonDelta)
        UserDefaults.standard.setHasData()
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
