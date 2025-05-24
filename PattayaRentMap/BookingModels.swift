//
//  BookingModels.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 20/04/2025.
//

import Foundation

// MARK: - Тип бронирования

public enum BookingType: String, CaseIterable, Identifiable, Codable {
    case confirmed = "Забронировано"
    case tentative = "Предварительно"

    public var id: String { rawValue }

    // Цвет в HEX для UI (если понадобится)
    public var colorHex: String {
        switch self {
        case .confirmed: return "#FF3B30"   // Красный
        case .tentative: return "#FF9500"   // Оранжевый
        }
    }
}

// MARK: - Диапазон бронирования

public struct BookingRange: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var startDate: Date
    public var endDate: Date
    public var type: BookingType

    public init(startDate: Date, endDate: Date, type: BookingType) {
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
    }

    public func overlaps(with other: BookingRange) -> Bool {
        return (startDate...endDate).overlaps(other.startDate...other.endDate)
    }
}
extension BookingRange {
    func contains(_ date: Date, calendar: Calendar) -> Bool {
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let targetDay = calendar.startOfDay(for: date)

        return targetDay >= startDay && targetDay <= endDay
    }
}

// MARK: - Статус объекта (квартиры)

public enum ApartmentStatus: String, CaseIterable, Identifiable, Codable {
    case available = "Свободна"
    case rented = "Занята"

    public var id: String { rawValue }

    public var colorHex: String {
        switch self {
        case .available: return "#34C759"   // Зелёный
        case .rented:    return "#FF3B30"   // Красный
        }
    }
}
