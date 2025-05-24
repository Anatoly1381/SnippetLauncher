import Foundation
import CoreLocation
import MapKit
import AppKit


struct MapObject: Identifiable, Codable {
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
    
    // 📸 Новое поле вместо photoURLs
    var photoPaths: [String] = []
    
    
    var area: Int = 0
    var floor: Int = 0
    var status: ApartmentStatus = .available
    var bookingRanges: [BookingRange] = []
    
    var clCoordinate: CLLocationCoordinate2D {
        coordinate.clLocation
    }
    
    // ✅ Метод для загрузки NSImage по сохранённым путям
    func loadImages() -> [NSImage] {
        photoPaths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            return NSImage(contentsOf: url)
        }
    }
    
    // Обновлённый список кодируемых ключей
    enum CodingKeys: String, CodingKey {
        case id, title, description, coordinate, photoPaths, area, floor, status, bookingRanges
    }
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        coordinate: Coordinate,
        area: Int = 0,
        floor: Int = 0,
        status: ApartmentStatus = .available,
        bookingRanges: [BookingRange] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coordinate = coordinate
        self.area = area
        self.floor = floor
        self.status = status
        self.bookingRanges = bookingRanges
    }
    
}
extension MapObject {
    static var empty: MapObject {
        MapObject(
            title: "",
            description: "",
            coordinate: .init(latitude: 0, longitude: 0)
            
        )
    }
}
