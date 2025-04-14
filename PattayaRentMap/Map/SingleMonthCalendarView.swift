//
//  SingleMonthCalendarView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 10/04/2025.
//

import SwiftUI


struct SingleMonthCalendarView: View {
    @Binding var selectedRange: ClosedRange<Date>?
    @Binding var bookingType: BookingType
    
    var body: some View {
        VStack(spacing: 8) {
            Text("📆 \(monthYearText(for: Date()))")
                .font(.headline)

            // Заголовки дней недели
            HStack {
                ForEach(["П", "В", "С", "Ч", "П", "С", "В"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Ячейки дней (заглушка: 1–30)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(1...30, id: \.self) { day in
                    Text("\(day)")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
    }
    private func monthYearText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}
