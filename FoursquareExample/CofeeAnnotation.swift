//
//  CofeeAnnotation.swift
//  FoursquareExample
//
//  Created by Marius Skalstad on 29.04.2016.
//  Copyright © 2016 Marius Skalstad. All rights reserved.
//

import Foundation
import MapKit

class CoffeeAnnotation: NSObject, MKAnnotation
{
    let title:String?
    let subtitle:String?
    let coordinate: CLLocationCoordinate2D
    
    init(title: String?, subtitle:String?, coordinate: CLLocationCoordinate2D)
    {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        
        super.init()
    }
}
