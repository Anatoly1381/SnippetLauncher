//
//  BookingType.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 10/04/2025.
//

import Foundation

public enum BookingType: String, CaseIterable, Identifiable, Codable {
    case confirmed = "Забронировано"
    case tentative = "Предварительно"
    case blocked = "Заблокировано"

    public var id: String { self.rawValue }
}
