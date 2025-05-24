import SwiftUI
import MapKit
import CoreLocation


struct ContentView: View {
    @StateObject private var mapVM: MapViewModel
    @State private var mapCameraPosition: MapCameraPosition
    @State private var searchText: String = ""
    @State private var searchResultAnnotation: IdentifiablePlace?

    init() {
        let vm = MapViewModel()
        _mapVM = StateObject(wrappedValue: vm)
        _mapCameraPosition = State(initialValue: vm.getMapCameraPosition())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                MapReader { proxy in
                    Map(position: $mapCameraPosition) {
                        objectAnnotations

                        if let result = searchResultAnnotation {
                            Annotation("Поиск", coordinate: result.location) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.25))
                                        .frame(width: 50, height: 50)

                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapUserLocationButton()
                        MapPitchToggle()
                        MapScaleView()
                    }
                    .onMapCameraChange { context in
                        mapVM.updateCameraPosition(.region(context.region))
                    }
                    .onTapGesture { location in
                        if let coordinate = proxy.convert(location, from: .local) {
                            let tappedExisting = mapVM.objects.contains { obj in
                                obj.coordinate.clLocation.isNearby(to: coordinate, threshold: 0.0001)
                            }

                            if !tappedExisting {
                                mapVM.startCreatingObject(at: coordinate)
                            } else {
                                if let tappedObject = mapVM.objects.first(where: {
                                    $0.coordinate.clLocation.isNearby(to: coordinate, threshold: 0.0001)
                                }) {
                                    mapVM.selectedObject = tappedObject
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .trailing) {
                    HStack {
                        TextField("Поиск на карте...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 250)
                            .onSubmit {
                                performSearch()
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResultAnnotation = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    Spacer()
                }
            }
            .sheet(item: $mapVM.selectedObject) { object in
                if let index = mapVM.objects.firstIndex(where: { $0.id == object.id }) {
                    MapObjectDetailView(
                        object: $mapVM.objects[index],
                        viewModel: mapVM
                    )
                    .frame(minWidth: 1100, idealWidth: 1200, maxWidth: .infinity, minHeight: 700, maxHeight: .infinity)
                }
            }
        }
    }

    private var objectAnnotations: some MapContent {
        ForEach(mapVM.objects) { object in
            Annotation(object.title, coordinate: object.clCoordinate) {
                // Открытие в .sheet (нужно для корректной работы FullScreenImageView)
                Button {
                    mapVM.selectedObject = object
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 34, height: 34)
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(object.status == .available ? .green : .red)
                    }
                }
                .contextMenu {
                    // Отдельное окно с системными кнопками
                    Button("Открыть в новом окне") {
                        if let index = mapVM.objects.firstIndex(where: { $0.id == object.id }) {
                            openWindowFor(
                                MapObjectBindingWrapper(viewModel: mapVM, objectId: mapVM.objects[index].id)
                            )
                        }
                    }

                    Button("Удалить", role: .destructive) {
                        mapVM.deleteObject(object)
                    }
                }
            }
        }
    }

    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            withAnimation {
                mapCameraPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                searchResultAnnotation = IdentifiablePlace(location: coordinate)
            }
        }
    }
}

struct IdentifiablePlace: Identifiable {
    let id = UUID()
    let location: CLLocationCoordinate2D
}

extension CLLocationCoordinate2D {
    func isNearby(to other: CLLocationCoordinate2D, threshold: Double = 0.0001) -> Bool {
        abs(latitude - other.latitude) < threshold && abs(longitude - other.longitude) < threshold
    }
}
