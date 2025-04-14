//
//  ApartmentViewModel.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 26/3/2568 BE.
//

import Foundation
import SwiftUI

class ApartmentViewModel: ObservableObject {
    @Published var showOnlyAvailable = false
    @Published var minArea: Int?
    @Published var maxFloor: Int?

    @Published var apartmentData = ApartmentDataWrapper()

    var allApartments: [Apartment] = Apartment.loadAll()

    var filteredApartments: [Apartment] {
        var result = showOnlyAvailable
            ? allApartments.filter { $0.status == .available }
            : allApartments

        if let min = minArea {
            result = result.filter { $0.area >= min }
        }

        if let max = maxFloor {
            result = result.filter { $0.floor <= max }
        }

        return result
    }

    var bookingStatistics: (total: Int, reserved: Int, tentative: Int) {
        let allBookings = allApartments.flatMap { $0.bookingRanges }
        return (
            total: allBookings.count,
            reserved: allBookings.filter { $0.type == .confirmed }.count,
            tentative: allBookings.filter { $0.type == .tentative }.count
        )
    }
}

class ApartmentDataWrapper: ObservableObject {
    @Published var data = ApartmentData()

    func refreshApartments() {
        objectWillChange.send() // явно сообщаем об изменениях
    }
}
