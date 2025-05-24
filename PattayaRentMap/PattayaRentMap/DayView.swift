//
//  DayView.swift
//  PattayaRentMap
//
//  Created by Anatoly Fedorov on 22/04/2025.
//

import SwiftUI

struct DayView: View {
    let date: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedRanges: [BookingRange]
    let currentMonth: Date
    let calendar: Calendar
    let isCurrentMonth: Bool

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = isInAnyBookedRange(date)
        let isStart = isStartDate(date)
        let isEnd = isEndDate(date)
        let isBooked = isDateBooked(date)
        let isPast = date < calendar.startOfDay(for: Date())
        let isFromOtherMonth = !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)

        Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .frame(width: 36, height: 36)
            .foregroundColor(foregroundColor(for: isBooked, isPast: isPast, isFromOtherMonth: isFromOtherMonth))
            .opacity(isCurrentMonth ? 1.0 : 0.5)
            .background(
                ZStack {
                    if isToday {
                        Circle().stroke(Color.blue, lineWidth: 1.5)
                    }
                }
            )
            .overlay(
                Circle()
                    .strokeBorder(
                        (isStart || isEnd || isSelected) ? Color.red : Color.clear,
                        lineWidth: 2
                    )
            )
            .onTapGesture {
                if !isBooked && !isPast {
                    selectDate(date)
                }
            }
            .disabled(isBooked || isPast)
    }

    private func isStartDate(_ date: Date) -> Bool {
        guard let start = startDate else { return false }
        return calendar.isDate(date, inSameDayAs: start)
    }

    private func isEndDate(_ date: Date) -> Bool {
        guard let end = endDate else { return false }
        return calendar.isDate(date, inSameDayAs: end)
    }

    private func isInAnyBookedRange(_ date: Date) -> Bool {
        bookedRanges.contains { range in
            let start = calendar.startOfDay(for: range.startDate)
            let end = calendar.startOfDay(for: range.endDate)
            let current = calendar.startOfDay(for: date)
            return (start...end).contains(current)
        }
    }

    private func isDateBooked(_ date: Date) -> Bool {
        let currentDate = calendar.startOfDay(for: date)
        return bookedRanges.contains { range in
            let startDate = calendar.startOfDay(for: range.startDate)
            let endDate = calendar.startOfDay(for: range.endDate)
            return (startDate...endDate).contains(currentDate)
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

    private func foregroundColor(for isBooked: Bool, isPast: Bool, isFromOtherMonth: Bool) -> Color {
        if isBooked && !isFromOtherMonth {
            return .red
        }
        if isPast {
            return .gray
        }
        if isFromOtherMonth {
            return .gray.opacity(0.5)
        }
        return .primary
    }
}
