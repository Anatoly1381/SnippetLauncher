
import SwiftUI

struct BookingCalendarView: View {
    var apartment: Apartment
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Календарь заезда
            VStack(spacing: 8) {
                Text("Дата заезда")
                    .font(.headline)
                
                DatePicker(
                    "",
                    selection: $checkInDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .frame(width: 300, height: 300)
                .overlay(
                    HighlightOverlay(
                        startDate: checkInDate,
                        endDate: checkOutDate,
                        isActive: true
                    )
                )
            }
            
            // Календарь выезда
            VStack(spacing: 8) {
                Text("Дата выезда")
                    .font(.headline)
                
                DatePicker(
                    "",
                    selection: $checkOutDate,
                    in: checkInDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.calendar, Calendar(identifier: .gregorian))
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .frame(width: 300, height: 300)
                .overlay(
                    HighlightOverlay(
                        startDate: checkInDate,
                        endDate: checkOutDate,
                        isActive: true
                    )
                )
            }
        }
        .padding()
    }
}

struct HighlightOverlay: View {
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            if isActive && endDate > startDate {
                let calendar = Calendar.current
                let cellWidth = geometry.size.width / 7
                let cellHeight = geometry.size.height / 6
                
                let start = calendar.startOfDay(for: startDate)
                let end = calendar.startOfDay(for: endDate)
                
                Path { path in
                    var current = start
                    while current <= end {
                        let weekday = (calendar.component(.weekday, from: current) + 5) % 7
                        let week = calendar.component(.weekOfMonth, from: current) - 1
                        
                        path.addRect(CGRect(
                            x: CGFloat(weekday) * cellWidth + 1,
                            y: CGFloat(week) * cellHeight + 1,
                            width: cellWidth - 2,
                            height: cellHeight - 2
                        ))
                        
                        current = calendar.date(byAdding: .day, value: 1, to: current)!
                    }
                }
                .fill(Color.blue.opacity(0.3))
                .cornerRadius(4)
            }
        }
    }
}
