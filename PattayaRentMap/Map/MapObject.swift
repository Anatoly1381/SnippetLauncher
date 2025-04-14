import Foundation
import MapKit

struct MapObject: Identifiable, Codable, Equatable {
    struct Coordinate: Codable, Equatable {
        var latitude: Double
        var longitude: Double

        var clLocation: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    var id: UUID = UUID()
    var title: String
    var description: String
    var coordinate: Coordinate
    var photoURLs: [URL]

    var clCoordinate: CLLocationCoordinate2D {
        coordinate.clLocation
        
    }
}
