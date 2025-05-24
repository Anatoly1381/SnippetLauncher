import Foundation
import _MapKit_SwiftUI
import MapKit

class MapViewModel: ObservableObject {
    @Published var objects: [MapObject] = []
    @Published var selectedObject: MapObject?
    @Published var cameraCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 12.927, longitude: 100.877)
    @Published var regionSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    

    private let cameraCenterKey = "cameraCenter"
    private let regionSpanKey = "regionSpan"
    private let saveKey = "savedMapObjects"

    init() {
        loadObjects()
    }

    func notifyUpdate() {
        objectWillChange.send()
    }

    func getMapCameraPosition() -> MapCameraPosition {
        let region = MKCoordinateRegion(center: cameraCenter, span: regionSpan)
        return .region(region)
    }

    func updateCameraPosition(_ position: MapCameraPosition) {
        if let region = position.region {
            let sameCenter = abs(region.center.latitude - cameraCenter.latitude) < 0.000001 &&
                             abs(region.center.longitude - cameraCenter.longitude) < 0.000001

            if !sameCenter || region.span.latitudeDelta != regionSpan.latitudeDelta ||
                              region.span.longitudeDelta != regionSpan.longitudeDelta {
                cameraCenter = region.center
                regionSpan = region.span
                saveObjects()
            }
        }
    }

    func updateObject(_ updated: MapObject) {
        if let index = objects.firstIndex(where: { $0.id == updated.id }) {
            objects[index] = updated
        }
    }

    func startCreatingObject(at coordinate: CLLocationCoordinate2D) {
        let newCoordinate = MapObject.Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let newObject = MapObject(title: "", description: "", coordinate: newCoordinate)
        objects.append(newObject)
        selectedObject = newObject
        saveObjects()
    }

    func updateTitle(for object: MapObject, with newTitle: String) {
        guard let index = objects.firstIndex(where: { $0.id == object.id }) else { return }
        objects[index].title = newTitle
        saveObjects()
    }

    func updateDescription(for object: MapObject, with newDescription: String) {
        guard let index = objects.firstIndex(where: { $0.id == object.id }) else { return }
        objects[index].description = newDescription
        saveObjects()
    }

    func resetUserObjects() {
        objects.removeAll()
        selectedObject = nil
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    func deleteObject(_ object: MapObject) {
        if let index = objects.firstIndex(where: { $0.id == object.id }) {
            objects.remove(at: index)
            saveObjects()
        }
    }

    func saveObjects() {
        if let encoded = try? JSONEncoder().encode(objects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }

        UserDefaults.standard.set(
            [cameraCenter.latitude, cameraCenter.longitude],
            forKey: cameraCenterKey
        )

        let spanArray = [regionSpan.latitudeDelta, regionSpan.longitudeDelta]
        UserDefaults.standard.set(spanArray, forKey: regionSpanKey)
    }

    private func loadObjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoded = try JSONDecoder().decode([MapObject].self, from: data)
                objects = decoded
            } catch {
                print("Failed to decode objects:", error)
            }
        }

        if let center = UserDefaults.standard.array(forKey: cameraCenterKey) as? [Double], center.count == 2 {
            cameraCenter = CLLocationCoordinate2D(latitude: center[0], longitude: center[1])
        }

        if let spanArray = UserDefaults.standard.array(forKey: regionSpanKey) as? [Double], spanArray.count == 2 {
            regionSpan = MKCoordinateSpan(latitudeDelta: spanArray[0], longitudeDelta: spanArray[1])
        }
    }
}
