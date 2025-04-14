//
//  MapViewModel.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 09/04/2025.
//

import Foundation
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var objects: [MapObject] = []
    @Published var draftCoordinate: CLLocationCoordinate2D?
    
    private let saveKey = "savedMapObjects"
    
    init() {
        loadObjects()
    }
    
    func addObject(_ object: MapObject) {
        objects.append(object)
        saveObjects()
    }
    
    func deleteObject(at offsets: IndexSet) {
        objects.remove(atOffsets: offsets)
        saveObjects()
    }
    
    private func saveObjects() {
        if let encoded = try? JSONEncoder().encode(objects) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadObjects() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MapObject].self, from: data) {
            objects = decoded
        }
    }
}
