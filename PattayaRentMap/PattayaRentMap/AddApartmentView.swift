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
    @ObservedObject var viewModel: MapViewModel

    @State private var title: String = ""
    @State private var description: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Новый объект по координате:")
            Text("Широта: \(coordinate.latitude)")
            Text("Долгота: \(coordinate.longitude)")

            TextField("Название", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Описание", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Отмена") {
                    isPresented = false
                }

                Spacer()

                Button("Сохранить") {
                    let newObject = MapObject(
                        title: title,
                        description: description,
                        coordinate: .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    )
                    viewModel.objects.append(newObject)
                    viewModel.selectedObject = newObject
                    viewModel.saveObjects()
                    isPresented = false
                }
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
