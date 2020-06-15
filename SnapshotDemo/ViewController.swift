//
//  ViewController.swift
//  SnapshotDemo
//
//  Created by Russell Archer on 18/01/2016.
//  Copyright © 2016 RArcher. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MessageUI

class ViewController: UIViewController {
    
    @IBOutlet weak var map: MKMapView!

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        let status = getLocationServicesPermission()
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            print("We are already authorized to use location services - initializing...")
            initLocationServices()
        }
    }

    func initLocationServices() {
        let initialLoc = CLLocationCoordinate2D(latitude: 52, longitude: 0)
        let initialSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        map.showsUserLocation = true
        map.delegate = self
        map.mapType = .standard
        map.region = MKCoordinateRegion(center: initialLoc, span: initialSpan)
    }
    
    func getLocationServicesPermission() -> CLAuthorizationStatus {
        // See if we're authorized to use location services
        // Note: You MUST have the following in Info.plist:
        // key: NSLocationWhenInUseUsageDescription
        // value: Text describing to the user why you need location services permission
        
        let authStatus = CLLocationManager.authorizationStatus()
        if authStatus == .notDetermined {
            print("Need to request location services permission")
            // Request permission for when app is in foreground
            // Note that the dialog requesting permission runs ASYNC, so this
            // method returns before permission has actually been granted or denied
            // by the user. The locationManager(_, didChangeAuthorizationStatus status:)
            // delegate method is called when the user has granted/denied permission
            
            locationManager.requestWhenInUseAuthorization()
        } else if authStatus == .denied || authStatus == .restricted {
            print("Location services permission denied")
        }
        
        return authStatus
    }
    
    @IBAction func takeSnapshotClicked(_ sender: AnyObject) {
        /*
        
            Note that the MKMapSnapshotter() class would seem to be the best solution
            for taking a snapshot of the map. However, it DOES NOT include annotations
            to the map or the current user location marker!
            
            So, the following code works, but doesn't include the user location marker:
            
            let options = MKMapSnapshotOptions()
            options.region = map.region
            options.size = map.frame.size
            options.scale = UIScreen.main.scale
            
            let s = map.snapshotViewAfterScreenUpdates(true)
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.startWithCompletionHandler({ snapshot, error in
                guard snapshot != nil else {
                    print("Snapshot error");
                    return }
                
                print("Snapshot OK!")
                self.image.image = snapshot?.image
            })
        
        */
        
        // The following code can be adapted to capture the contents of any UIView-derived object
        UIGraphicsBeginImageContextWithOptions(map.bounds.size, true, UIScreen.main.scale)
        map.drawHierarchy(in: map.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Save the img
        if saveImage(img!, filename: "mapSnapshot.png") {
            print("Image saved to \(getCachesDirectory())/mapSnapshot.png")
        } else {
            print("Error saving file")
        }
    }
    
    func saveImage(_ img: UIImage, filename: String) -> Bool {
        var path = getCachesDirectory() as NSString
        path = path.appendingPathComponent(filename) as NSString

        guard let file = img.pngData() else {
            print("Unable to create PNG representation of UIImage")
            return false
        }
        
        return ((try? file.write(to: URL(fileURLWithPath: path as String), options: [.atomicWrite])) != nil)
    }
    
    func loadImage(_ filename: String) -> UIImage? {
        var path = getCachesDirectory() as NSString
        path = path.appendingPathComponent(filename) as NSString
        
        if !FileManager.default.fileExists(atPath: path as String) {
            return nil
        }
        
        return UIImage(contentsOfFile: path as String)
    }
    
    func getCachesDirectory() -> String {
        // Get the "Caches" folder in the *app's sandbox*
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        return paths[0]
    }
    
    func getSnapshotData(_ filename: String) -> Data? {
        var path = getCachesDirectory() as NSString
        path = path.appendingPathComponent(filename) as NSString
        
        return (try? Data(contentsOf: URL(fileURLWithPath: path as String)))
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        map.setCenter((userLocation.location?.coordinate)!, animated: true)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // This method is called when the location manager's authorization status changes
        // (e.g. when the user gives permission to use location services)
        
        if status == .authorizedWhenInUse {
            print("We are now authorized to use location services - initializing...")
            initLocationServices()
        }
    }
}
