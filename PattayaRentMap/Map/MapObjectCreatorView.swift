import SwiftUI
import MapKit

struct MapObjectCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MapViewModel
    var coordinate: CLLocationCoordinate2D

    @State private var title: String = ""
    @State private var description: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Основная информация") {
                    TextField("Название", text: $title)
                    TextField("Описание", text: $description)
                }

                Section("Секция действий") {
                    Button("Сохранить объект") {
                        let newObject = MapObject(
                            title: title,
                            description: description,
                            coordinate: MapObject.Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            
                        )
                        viewModel.objects.append(newObject)
                        viewModel.selectedObject = newObject
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Новый объект")
            .padding()
        }
    }
}
