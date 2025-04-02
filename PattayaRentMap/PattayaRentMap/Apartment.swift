//
//  Apartment.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 26/3/2568 BE.
//
import Foundation
import CoreLocation

enum BookingType: String, CaseIterable, Identifiable, Codable {
    var id: String { self.rawValue }
    case reserved = "Забронировано"
    case tentative = "Предварительно"
}

enum ApartmentStatus: String {
    case available = "Свободна"
    case rented = "Сдана"
}

struct BookingRange: Identifiable, Codable, Hashable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var type: BookingType

    func overlaps(with other: BookingRange) -> Bool {
        return (startDate...endDate).overlaps(other.startDate...other.endDate)
    }
}

class Apartment: Identifiable, ObservableObject {
    let id: String
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let area: Int
    let floor: Int
    @Published var status: ApartmentStatus
    @Published var bookingRanges: [BookingRange] = [] {
        didSet {
            save()
            updateStatus()
        }
    }

    init(id: String, title: String, description: String, coordinate: CLLocationCoordinate2D,
         address: String, area: Int, floor: Int, status: ApartmentStatus) {
        self.id = id
        self.title = title
        self.description = description
        self.coordinate = coordinate
        self.address = address
        self.area = area
        self.floor = floor
        self.status = status
    }

    func addBooking(from startDate: Date, to endDate: Date, type: BookingType) {
        let newBooking = BookingRange(startDate: startDate, endDate: endDate, type: type)
        bookingRanges.append(newBooking)
    }

    func removeBooking(_ booking: BookingRange) {
        bookingRanges.removeAll { $0.id == booking.id }
    }

    func removeAllBookings() {
        bookingRanges.removeAll()
    }

    private func updateStatus() {
        status = bookingRanges.contains { $0.type == .reserved } ? .rented : .available
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(bookingRanges) {
            UserDefaults.standard.set(encoded, forKey: "\(id)_bookings")
        }
    }

    static func loadAll() -> [Apartment] {
        let apartments = mockApartments
        apartments.forEach { apt in
            if let data = UserDefaults.standard.data(forKey: "\(apt.id)_bookings"),
               let ranges = try? JSONDecoder().decode([BookingRange].self, from: data) {
                apt.bookingRanges = ranges
                apt.updateStatus()
            }
        }
        return apartments
    }
}
