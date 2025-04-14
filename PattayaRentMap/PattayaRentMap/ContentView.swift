import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var apartmentVM = ApartmentViewModel()
    @StateObject private var mapVM = MapViewModel()

    @State private var selectedApartment: Apartment?
    @State private var showStatistics = false
    @State private var mapCameraPosition = MapCameraPosition.automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                MapReader { proxy in
                    // 🔴 Кнопка сброса пользовательских объектов
                    Button("Удалить метки") {
                        mapVM.resetUserObjects()
                    }
                    .padding(10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()

                    Map(position: $mapCameraPosition) {
                        apartmentAnnotations
                        objectAnnotations
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapUserLocationButton()
                        MapPitchToggle()
                        MapScaleView()
                    }
                    .onTapGesture { location in
                        if let coordinate = proxy.convert(location, from: .local) {
                            mapVM.startCreatingObject(at: coordinate)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .sheet(item: $selectedApartment) { apartment in
                ApartmentDetailView(apartment: apartment)
                    .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, maxHeight: .infinity)
            }
            .sheet(item: $mapVM.selectedObject) { object in
                if let index = mapVM.objects.firstIndex(where: { $0.id == object.id }) {
                    MapObjectDetailView(object: $mapVM.objects[index], viewModel: mapVM)
                }
            }
        }
    }

    private var apartmentAnnotations: some MapContent {
        ForEach(apartmentVM.filteredApartments) { apartment in
            Annotation(apartment.title, coordinate: apartment.coordinate) {
                Button {
                    selectedApartment = apartment
                } label: {
                    Image(systemName: "house.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(apartment.status == .available ? .green : .red)
                }
            }
        }
    }

    private var objectAnnotations: some MapContent {
        ForEach(mapVM.objects) { object in
            Annotation(object.title, coordinate: object.clCoordinate) {
                Button {
                    print("Tapped on object: \(object.title)")
                    mapVM.selectedObject = object
                } label: {
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
