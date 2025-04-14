//
//  MapObject.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 09/04/2025.
//

import Foundation
import MapKit

struct MapObject: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var coordinate: CLLocationCoordinate2D
    var photos: [Data] = []
    
    // Для удобной работы с координатами
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

// Расширение для работы с координатами
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(CLLocationDegrees.self)
        let longitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}
