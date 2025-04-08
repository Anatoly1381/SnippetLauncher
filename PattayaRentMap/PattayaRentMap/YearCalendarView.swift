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

import SwiftUI

struct MonthView: View {
    let month: Int
    let year: Int
    let bookedRanges: [BookingRange]
    let calendar: Calendar
    
    var body: some View {
        VStack(spacing: 8) {
            // Название месяца
            Text(monthName)
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            
            // Дни недели
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 20)
                        .foregroundColor(.secondary)
                }
            }
            
            // Сетка дней
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(24), spacing: 0), count: 7),
                spacing: 4
            ) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    let day = daysInMonth[index]
                    if day == 0 {
                        Text("")
                            .frame(width: 24, height: 24)
                    } else {
                        DayCellView(
                            day: day,
                            month: month,
                            year: year,
                            bookedRanges: bookedRanges,
                            calendar: calendar
                        )
                        .frame(width: 24, height: 24)
                    }
                }
            }
            .frame(width: 168) // 7 колонок × 24pt
            .padding(.bottom, 8)
        }
        .frame(width: 200)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var daysInMonth: [Int] {
        guard let date = calendar.date(from: DateComponents(year: year, month: month)),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: date)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: 0, count: offset) + Array(range)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        guard let date = dateForMonth() else { return "" }
        return formatter.string(from: date).capitalized
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        guard let symbols = formatter.shortStandaloneWeekdaySymbols else {
            return ["П", "В", "С", "Ч", "П", "С", "В"]
        }
        
        let startIndex = calendar.firstWeekday - 1
        return Array(symbols[startIndex...] + symbols[..<startIndex])
            .map { String($0.prefix(1)) }
    }
    
    private func dateForMonth() -> Date? {
        calendar.date(from: DateComponents(year: year, month: month))
    }
}

struct DayCellView: View {
    let day: Int
    let month: Int
    let year: Int
    let bookedRanges: [BookingRange]
    let calendar: Calendar
    
    var body: some View {
        let dateComponents = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: dateComponents) else {
            return AnyView(
                Text("")
                    .frame(width: 24, height: 24)
            )
        }
        
        let isBooked = bookedRanges.contains { range in
            calendar.isDate(date, inSameDayAs: range.startDate) ||
            calendar.isDate(date, inSameDayAs: range.endDate) ||
            (range.startDate...range.endDate).contains(date)
        }
        
        let isToday = calendar.isDate(date, inSameDayAs: Date())
        
        return AnyView(
            Text("\(day)")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 24, height: 24)
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
                .cornerRadius(12)
        )
    }
    
    
}
