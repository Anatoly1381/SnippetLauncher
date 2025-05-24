//
//  MapObjectBindingWrapper.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 24/04/2025.
//

import SwiftUI

struct MapObjectBindingWrapper: View {
    @ObservedObject var viewModel: MapViewModel
    var objectId: UUID

    var body: some View {
        if let index = viewModel.objects.firstIndex(where: { $0.id == objectId }) {
            let binding = Binding<MapObject>(
                get: { viewModel.objects[index] },
                set: { viewModel.objects[index] = $0 }
            )
            MapObjectDetailView(object: binding, viewModel: viewModel)
        } else {
            Text("Объект не найден")
        }
    }
}
