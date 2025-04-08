//
//  DateRangePickerView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 4/4/25.
//

import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    let calendar: Calendar
    
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        VStack(spacing: 12) {
            monthNavigation
            
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 8) {
                // Дни недели (начиная с понедельника)
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36)
                }
                
                // Дни месяца
                ForEach(daysInMonth, id: \.self) { date in
                    if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                        DayView(
                            date: date,
                            startDate: $startDate,
                            endDate: $endDate,
                            bookedRanges: bookedRanges,
                            currentMonth: currentMonth,
                            calendar: calendar
                        )
                    } else {
                        // Для дней не из текущего месяца
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16))
                            .frame(width: 36, height: 36)
                            .foregroundColor(.secondary)
                            .opacity(0.5)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .onAppear {
            currentMonth = calendar.startOfDay(for: currentMonth)
        }
    }
    
    private var monthNavigation: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .padding(12)
                    .contentShape(Rectangle())
            }
            
            Text(currentMonthTitle)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .padding(12)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? []
        let shift = (calendar.firstWeekday - 1 + 7) % 7
        guard !symbols.isEmpty, shift < symbols.count else { return [] }
        
        return Array(symbols[shift...] + symbols[..<shift])
    }
    
    private var currentMonthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private var daysInMonth: [Date] {
        guard let range = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        var dates: [Date] = []
        var current = range.start
        
        // Получаем первый день недели
        let firstWeekday = calendar.component(.weekday, from: current)
        let daysToAdd = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Добавляем дни из предыдущего месяца
        if daysToAdd > 0 {
            let prevMonth = calendar.date(byAdding: .month, value: -1, to: current)!
            let prevMonthDays = calendar.range(of: .day, in: .month, for: prevMonth)!.count
            let startDay = prevMonthDays - daysToAdd + 1
            
            for day in startDay...prevMonthDays {
                if let date = calendar.date(bySetting: .day, value: day, of: prevMonth) {
                    dates.append(date)
                }
            }
        }
        
        // Добавляем только дни текущего месяца
        while current < range.end {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        
        return dates
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
    }
}

struct DayView: View {
    let date: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    let currentMonth: Date
    let calendar: Calendar
    
    var body: some View {
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isBooked = isDateBooked(date)
        let isSelected = isDateSelected(date)
        let isStart = isStartDate(date)
        let isEnd = isEndDate(date)
        
        Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 16, weight: .medium))
            .frame(width: 36, height: 36)
            .background(background(for: isSelected, isStart: isStart, isEnd: isEnd))
            .foregroundColor(foregroundColor(for: isCurrentMonth, isBooked: isBooked))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(isStart || isEnd ? Color.blue : Color.clear, lineWidth: 2.5)
            )
            .onTapGesture {
                selectDate(date)
            }
            .disabled(isBooked)
    }
    
    private func isDateBooked(_ date: Date) -> Bool {
        bookedRanges.contains { range in
            calendar.isDate(date, inSameDayAs: range.startDate) ||
            calendar.isDate(date, inSameDayAs: range.endDate) ||
            (range.startDate...range.endDate).contains(date)
        }
    }
    
    private func isStartDate(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        return calendar.isDate(date, inSameDayAs: start)
    }
    
    private func isEndDate(_ date: Date) -> Bool {
        guard let end = endDate else { return false }
        return calendar.isDate(date, inSameDayAs: end)
    }
    
    private func background(for isSelected: Bool, isStart: Bool, isEnd: Bool) -> some View {
        ZStack {
            if isStart || isEnd {
                Circle()
                    .fill(Color.blue.opacity(0.4))
                    .shadow(color: Color.blue.opacity(0.2), radius: 3, x: 0, y: 2)
            } else if isSelected {
                Circle()
                    .fill(Color.blue.opacity(0.2))
            }
        }
    }
    
    private func selectDate(_ date: Date) {
        if startDate == nil {
            startDate = date
            endDate = nil
        } else if let start = startDate, endDate == nil {
            if date > start {
                endDate = date
            } else {
                startDate = date
                endDate = nil
            }
        } else {
            startDate = date
            endDate = nil
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        if let end = endDate {
            return date >= start && date <= end
        }
        return calendar.isDate(date, inSameDayAs: start)
    }
    
    private func foregroundColor(for isCurrentMonth: Bool, isBooked: Bool) -> Color {
        if isBooked {
            return .red
        }
        return isCurrentMonth ? .primary : .secondary
    }
}
