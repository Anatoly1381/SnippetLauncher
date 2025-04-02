//
//  ApartmentViewModel.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 26/3/2568 BE.
//

import Foundation

class ApartmentViewModel: ObservableObject {
    @Published var showOnlyAvailable = false
    @Published var minArea: Int?
    @Published var maxFloor: Int?
    
    var allApartments: [Apartment] = Apartment.loadAll()
    
    var filteredApartments: [Apartment] {
        var result = showOnlyAvailable
            ? allApartments.filter { $0.status == .available }
            : allApartments
        
        if let minArea = minArea {
            result = result.filter { $0.area >= minArea }
        }
        
        if let maxFloor = maxFloor {
            result = result.filter { $0.floor <= maxFloor }
        }
        
        return result
    }
    var bookingStatistics: (total: Int, reserved: Int, tentative: Int) {
        let allBookings = allApartments.flatMap { $0.bookingRanges }
        return (
            total: allBookings.count,
            reserved: allBookings.filter { $0.type == .reserved }.count,
            tentative: allBookings.filter { $0.type == .tentative }.count
        )
    }
}

