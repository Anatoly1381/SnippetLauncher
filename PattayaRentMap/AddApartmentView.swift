//
//  AddApartmentView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 09/04/2025.
//

import SwiftUI
import MapKit

struct AddApartmentView: View {
    @Binding var isPresented: Bool
    var coordinate: CLLocationCoordinate2D
    var apartmentData: ApartmentDataWrapper

    var body: some View {
        Text("Добавление объекта в координате: \(coordinate.latitude), \(coordinate.longitude)")
            .padding()
        Button("Закрыть") {
            isPresented = false
        }
    }
}
