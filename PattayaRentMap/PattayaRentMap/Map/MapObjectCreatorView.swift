//
//  MapObjectCreatorView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 09/04/2025.
//

import SwiftUI
import MapKit

struct MapObjectCreatorView: View {
    @ObservedObject var viewModel: MapViewModel
    let coordinate: CLLocationCoordinate2D
    
    @State private var title = ""
    @State private var description = ""
    @State private var showImagePicker = false
    @State private var selectedImages: [NSImage] = []
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Местоположение") {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), interactionModes: [])
                    .frame(height: 150)
                    .disabled(true)
                }
                
                Section("Информация") {
                    TextField("Название", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Фотографии") {
                    Button("Добавить фото") {
                        showImagePicker = true
                    }
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                Image(nsImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                            }
                        }
                    }
                    .frame(height: 120)
                }
            }
            .navigationTitle("Новый объект")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: saveObject)
                        .disabled(title.isEmpty)
                }
            }
            .fileImporter(
                isPresented: $showImagePicker,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                handleImageSelection(result: result)
            }
        }
        .frame(width: 400, height: 500)
    }
    
    private func saveObject() {
        let photosData = selectedImages.compactMap { $0.tiffRepresentation }
        let newObject = MapObject(
            title: title,
            description: description,
            coordinate: coordinate,
            photos: photosData
        )
        viewModel.addObject(newObject)
        dismiss()
    }
    
    private func handleImageSelection(result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            selectedImages = urls.compactMap { NSImage(contentsOf: $0) }
        } catch {
            print("Ошибка загрузки изображений: \(error)")
        }
    }
}
