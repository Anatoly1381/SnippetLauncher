
import SwiftUI

struct BookingCalendarView: View {
    var apartment: Apartment
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    
    // Добавьте этот календарь с понедельником как первым днем
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // 2 = понедельник
        calendar.locale = Locale(identifier: "ru_RU")
        return calendar
    }
    
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
                .environment(\.calendar, calendar) // Используем наш календарь
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .frame(width: 300, height: 300)
                .overlay(
                    HighlightOverlay(
                        startDate: checkInDate,
                        endDate: checkOutDate,
                        isActive: true,
                        calendar: calendar // Передаем календарь
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
                .environment(\.calendar, calendar) // Используем наш календарь
                .environment(\.locale, Locale(identifier: "ru_RU"))
                .frame(width: 300, height: 300)
                .overlay(
                    HighlightOverlay(
                        startDate: checkInDate,
                        endDate: checkOutDate,
                        isActive: true,
                        calendar: calendar // Передаем календарь
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
    let calendar: Calendar // Добавляем параметр календаря
    
    var body: some View {
        GeometryReader { geometry in
            if isActive && endDate > startDate {
                let cellWidth = geometry.size.width / 7
                let cellHeight = geometry.size.height / 6
                
                Path { path in
                    var current = startDate
                    while current <= endDate {
                        let weekday = (calendar.component(.weekday, from: current) + 5) % 7 // Корректировка для понедельника
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
