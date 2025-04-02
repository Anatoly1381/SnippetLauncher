// ContentView.swift

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = ApartmentViewModel()
    @State private var selectedApartment: Apartment?
    @State private var showStatistics = false
    
    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $viewModel.showOnlyAvailable) {
                    Text("Показать только доступные")
                }
                
                Button(action: { showStatistics.toggle() }) {
                    Image(systemName: "chart.bar")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            if showStatistics {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Статистика бронирований")
                        .font(.headline)
                    
                    HStack {
                        StatisticBadge(value: viewModel.bookingStatistics.total, label: "Всего", color: .gray)
                        StatisticBadge(value: viewModel.bookingStatistics.reserved, label: "Забронировано", color: .red)
                        StatisticBadge(value: viewModel.bookingStatistics.tentative, label: "Предварительно", color: .orange)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                }

                Map {
                    ForEach(viewModel.filteredApartments) { apartment in
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
            .mapControls {
                MapUserLocationButton()
            }
            .mapStyle(.standard(elevation: .realistic))
        }
        .sheet(item: $selectedApartment) { apartment in
            ApartmentDetailView(apartment: apartment)
                .frame(minWidth: 900, idealWidth: 1000, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct StatisticBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))  // Замена systemGray5
        .cornerRadius(8)
    }
}
