//
//  YearCalendarView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 2/4/25.
//

//
//  YearCalendarView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 2/4/25.
//

import SwiftUI

struct YearCalendarView: View {
    let bookedRanges: [BookingRange]
    let calendar: Calendar
    
    @State private var currentYear: Int
    @Environment(\.dismiss) private var dismiss
    
    init(bookedRanges: [BookingRange], calendar: Calendar = .current) {
        self.bookedRanges = bookedRanges
        self.calendar = calendar
        let components = calendar.dateComponents([.year], from: Date())
        self._currentYear = State(initialValue: components.year ?? 2025)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    yearNavigationHeader
                        .padding(.top, 20)
                    
                    monthsGrid
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItem {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Календарь бронирований")
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - View Components
    private var yearNavigationHeader: some View {
        HStack {
            Button(action: previousYear) {
                Image(systemName: "chevron.left")
                    .padding(8)
            }
            
            Text(String(currentYear))
                .font(.title.bold())
                .frame(maxWidth: .infinity)
            
            Button(action: nextYear) {
                Image(systemName: "chevron.right")
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var monthsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
            ForEach(1...12, id: \.self) { month in
                MonthView(
                    month: month,
                    year: currentYear,
                    bookedRanges: bookedRangesForYear(currentYear),
                    calendar: calendar
                )
            }
        }
    }
    
    // MARK: - Data Methods
    private func bookedRangesForYear(_ year: Int) -> [BookingRange] {
        bookedRanges.filter { range in
            calendar.component(.year, from: range.startDate) == year
        }
    }
    
    private func previousYear() {
        currentYear -= 1
    }
    
    private func nextYear() {
        currentYear += 1
    }
}

struct MonthView: View {
    let month: Int
    let year: Int
    let bookedRanges: [BookingRange]
    let calendar: Calendar
    
    private var daysInMonth: [Int] {
        guard let date = calendar.date(from: DateComponents(year: year, month: month)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }
        
        let firstWeekday = (calendar.component(.weekday, from: date) + 5) % 7
        return Array(repeating: 0, count: firstWeekday) + Array(range)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(monthName)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(width: 28)
                        .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { day in
                    if day == 0 {
                        Color.clear
                            .frame(height: 28)
                    } else {
                        dayView(for: day)
                    }
                }
            }
            .frame(minHeight: 160)
        }
        .padding(12)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .frame(width: 200)
    }
    
    private func dayView(for day: Int) -> some View {
        // Проверяем валидность дня
        guard day > 0 else {
            return AnyView(EmptyView())
        }
        
        // Создаем компоненты даты
        let dateComponents = DateComponents(
            year: year,
            month: month,
            day: day
        )
        
        // Получаем дату
        guard let date = calendar.date(from: dateComponents) else {
            return AnyView(
                Text("")
                    .frame(width: 28, height: 28)
            )
        }
        
        // Проверяем статус даты
        let isBooked = isDateBooked(date)
        let isToday = calendar.isDate(date, inSameDayAs: Date())
        
        // Создаем представление
        return AnyView(
            Text("\(day)")
                .font(.system(size: 12))
                .frame(width: 28, height: 28)
                .background(
                    Group {
                        if isToday {
                            Circle().fill(Color.blue.opacity(0.2))
                        } else if isBooked {
                            Circle().fill(Color.red.opacity(0.2))
                        }
                    }
                )
                .foregroundColor(isBooked ? .red : (isToday ? .blue : .primary))
                .cornerRadius(14)
        )
    }
    
    // Единственная версия метода isDateBooked
    private func isDateBooked(_ date: Date) -> Bool {
        guard !bookedRanges.isEmpty else {
            return false
        }
        
        return bookedRanges.contains { range in
            calendar.isDate(date, inSameDayAs: range.startDate) ||
            calendar.isDate(date, inSameDayAs: range.endDate) ||
            (range.startDate...range.endDate).contains(date)
        }
    }
    
    // MARK: - Date Calculations
    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "MMMM"
        guard let date = dateForMonth() else { return "" }
        return dateFormatter.string(from: date)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.veryShortWeekdaySymbols.map { String($0.prefix(1)) }
    }
    
    private func dateForMonth() -> Date? {
        calendar.date(from: DateComponents(year: year, month: month))
    }
}
