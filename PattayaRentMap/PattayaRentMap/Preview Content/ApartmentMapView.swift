//
//  ApartmentMapView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 09/04/2025.
//

import SwiftUI
import MapKit

struct ApartmentMapView: View {
    @ObservedObject var apartmentData: ApartmentDataWrapper

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 12.9236, longitude: 100.8825),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var isAddingApartment = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedApartment: Apartment?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $mapRegion,
                interactionModes: .all,
                showsUserLocation: false,
                annotationItems: apartmentData.data.apartments) { apartment in
                MapMarker(coordinate: apartment.coordinate, tint: .blue)
            }
            .onTapGesture {
                selectedCoordinate = mapRegion.center
                isAddingApartment = true
            }

            Button(action: {
                selectedCoordinate = mapRegion.center
                isAddingApartment = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .padding()
            }
        }
        .sheet(isPresented: $isAddingApartment) {
            if let coordinate = selectedCoordinate {
                AddApartmentView(
                    isPresented: $isAddingApartment,
                    coordinate: coordinate,
                    apartmentData: apartmentData
                )
            }
        }
    }
}
