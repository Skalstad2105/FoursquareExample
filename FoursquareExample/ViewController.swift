//
//  ViewController.swift
//  FoursquareExample
//
//  Created by Marius Skalstad on 29.04.2016.
//  Copyright © 2016 Marius Skalstad. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate,UITableViewDataSource,UITableViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    //Properties
    var locationManager:CLLocationManager?;
    let distanceSpan:Double = 500
    
    var lastLocation:CLLocation?
    var venues:[Venue]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onVenuesUpdated:"), name: API.notifications.venuesUpdated, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewWillAppear(animated: Bool) {
        if let mapView = self.mapView
        {
            mapView.delegate = self;
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        if locationManager == nil
        {
            locationManager = CLLocationManager();
            
            locationManager!.delegate = self;
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager!.requestAlwaysAuthorization();
            locationManager!.distanceFilter = 50; // Don't send location updates with a distance smaller than 50 meters between them
            locationManager!.startUpdatingLocation();
        }
        
        mapView.showsUserLocation = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func nearbyLocation(sender: AnyObject) {
        
        mapView.setCenterCoordinate(mapView.userLocation.coordinate, animated: true)

    }
    func onVenuesUpdated(notification:NSNotification)
    {
        refreshVenues(nil)
    }
    
    func refreshVenues(location: CLLocation?, getDataFromFoursquare:Bool = false)
    {
        // If location isn't nil, set it as the last location
        if location != nil
        {
            lastLocation = location;
        }
        
        // If the last location isn't nil, i.e. if a lastLocation was set OR parameter location wasn't nil
        if let location = lastLocation
        {
            // Make a call to Foursquare to get data
            if getDataFromFoursquare == true
            {
                CoffeeAPI.sharedInstance.getCoffeeShopsWithLocation(location);
            }
            
            // Convenience method to calculate the top-left and bottom-right GPS coordinates based on region (defined with distanceSpan)
            let (start, stop) = calculateCoordinatesWithRegion(location);
            
            // Set up a predicate that ensures the fetched venues are within the region
            let predicate = NSPredicate(format: "latitude < %f AND latitude > %f AND longitude > %f AND longitude < %f", start.latitude, stop.latitude, start.longitude, stop.longitude);
            
            // Initialize Realm (while supressing error handling)
            let realm = try! Realm();
            
            // Get the venues from Realm. Note that the "sort" isn't part of Realm, it's Swift, and it defeats Realm's lazy loading nature!
            venues = realm.objects(Venue).filter(predicate).sort {
                location.distanceFromLocation($0.coordinate) < location.distanceFromLocation($1.coordinate);
            };
            
            // Throw the found venues on the map kit as annotations
            for venue in venues!
            {
                let annotation = CoffeeAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)));
                
                mapView?.addAnnotation(annotation);
            }
            
            // RELOAD ALL THE DATAS !!!
            tableView?.reloadData();
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation.isKindOfClass(MKUserLocation)
        {
            return nil;
        }
        
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationIdentifier");
        
        if view == nil
        {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier");
        }
        
        view?.canShowCallout = true;
        
        return view;
    }
    
    func calculateCoordinatesWithRegion(location:CLLocation) -> (CLLocationCoordinate2D, CLLocationCoordinate2D)
    {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distanceSpan, distanceSpan);
        
        var start:CLLocationCoordinate2D = CLLocationCoordinate2D();
        var stop:CLLocationCoordinate2D = CLLocationCoordinate2D();
        
        start.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
        start.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0);
        stop.latitude   = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
        stop.longitude  = region.center.longitude + (region.span.longitudeDelta / 2.0);
        
        return (start, stop);
    }

    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation)
    {
        if let mapView = self.mapView
        {
            // setRegion sets both the center coordinate, and the "zoom level"
            let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, distanceSpan, distanceSpan);
            mapView.setRegion(region, animated: true);
            
            // When a new location update comes in, reload from Realm and from Foursquare
            refreshVenues(newLocation, getDataFromFoursquare: true);
        }
    }
    
    //TableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues?.count ?? 0;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        
        if cell == nil
        {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cellIdentifier");
        }
        
        if let venue = venues?[indexPath.row]
        {
            cell!.textLabel?.text = venue.name;
            cell!.detailTextLabel?.text = venue.address;
        }
        
        return cell!
        
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return "Nearest places"
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if let header = view as? UITableViewHeaderFooterView
        {
            header.textLabel!.font = UIFont(name: "Verdana", size: 15.0)
            header.textLabel!.textColor = UIColor.orangeColor()
        }
        
        
    }
    
}

