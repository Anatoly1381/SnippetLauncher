import SwiftUI
import Foundation
import CoreLocation
import Combine



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
    let objectWillChange = ObservableObjectPublisher()
    let id: String
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let area: Int
    let floor: Int
    @Published var status: ApartmentStatus
    @Published var bookingRanges: [BookingRange] = []
    @Published var photos: [NSImage] = []  // Массив для хранения фотографий

    // Инициализация объекта квартиры
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

    // Добавление фотографий
    func addPhotos(_ newPhotos: [NSImage]) {
        self.photos.append(contentsOf: newPhotos)  // Добавляем новые фотографии в массив
        savePhotos()  // Сохраняем фотографии
    }

    // Удаление фотографии по индексу
    func deletePhoto(at index: Int) {
        photos.remove(at: index)
        savePhotos()  // Сохраняем обновленный массив фотографий
    }

    // Сохранение фотографий в UserDefaults
    private func savePhotos() {
        let photosData = photos.compactMap { $0.tiffRepresentation }
        UserDefaults.standard.set(photosData, forKey: "\(id)_photos")
    }

    // Загрузка фотографий из UserDefaults
    private func loadPhotos() {
        if let savedData = UserDefaults.standard.array(forKey: "\(id)_photos") as? [Data] {
            photos = savedData.compactMap { NSImage(data: $0) }
        }
    }

    // Обновление статуса квартиры в зависимости от текущих бронирований
    func updateStatus() {
        status = bookingRanges.contains { $0.type == .confirmed } ? .rented : .available
        objectWillChange.send() // <-- это ключ к автоматическому обновлению иконки
    }

    // Сохранение информации о бронированиях
    private func save() {
        if let encoded = try? JSONEncoder().encode(bookingRanges) {
            UserDefaults.standard.set(encoded, forKey: "\(id)_bookings")
        }
    }

    // Статический метод для загрузки всех квартир
    static func loadAll() -> [Apartment] {
        let apartments = mockApartments  // Заглушка для списка квартир
        apartments.forEach { apt in
            // Загружаем сохраненные бронирования
            if let data = UserDefaults.standard.data(forKey: "\(apt.id)_bookings"),
               let ranges = try? JSONDecoder().decode([BookingRange].self, from: data) {
                apt.bookingRanges = ranges
                apt.updateStatus()
            }
            // Загружаем фотографии
            apt.loadPhotos()
        }
        return apartments
    }

    // Метод для добавления нового бронирования
    func addBooking(from startDate: Date, to endDate: Date, type: BookingType) {
        let newBooking = BookingRange(startDate: startDate, endDate: endDate, type: type)
        bookingRanges.append(newBooking)
        updateStatus()
        save()  // Сохраняем изменения
    }

    // Удаление бронирования по объекту
    func removeBooking(_ booking: BookingRange) {
        bookingRanges.removeAll { $0.id == booking.id }
        updateStatus() // <— добавляем обновление статуса
        save()
    }

    // Удаление всех бронирований
    func removeAllBookings() {
        bookingRanges.removeAll()
        updateStatus()
        save()  // Сохраняем изменения
    }
}
