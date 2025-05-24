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
    var month: Date  // 👈 Новый параметр для отображаемого месяца

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.firstWeekday = 2 // Понедельник
        return calendar
    }()

    private var currentMonth: Date {
        calendar.startOfMonth(for: month)
    }

    private var displayDates: [Date] {
        let firstOfMonth = currentMonth
        let weekdayOffset = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonth)!.count
        let startDay = max(previousMonthDays - weekdayOffset + 1, 1)
        let leadingDates = (startDay...previousMonthDays).compactMap {
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: previousMonth),
                month: calendar.component(.month, from: previousMonth),
                day: $0
            ))
        }

        let currentMonthRange = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let currentDates = currentMonthRange.compactMap {
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: firstOfMonth),
                month: calendar.component(.month, from: firstOfMonth),
                day: $0
            ))
        }

        let totalCount = leadingDates.count + currentDates.count
        let trailingCount = max(42 - totalCount, 0)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        let trailingDates = (1...trailingCount).compactMap {
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: nextMonth),
                month: calendar.component(.month, from: nextMonth),
                day: $0
            ))
        }

        return leadingDates + currentDates + trailingDates
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("📆 \(monthYearText(for: currentMonth))")
                .font(.headline)

            HStack {
                ForEach(["П", "В", "С", "Ч", "П", "С", "В"], id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(displayDates, id: \.self) { date in
                    let day = calendar.startOfDay(for: date)
                    let start = selectedRange.map { calendar.startOfDay(for: $0.lowerBound) }
                    let end = selectedRange.map { calendar.startOfDay(for: $0.upperBound) }

                    let isStart = start == day
                    let isEnd = end == day
                    let isInRange = {
                        if let start = start, let end = end {
                            return (start...end).contains(day)
                        }
                        return false
                    }()
                    let isToday = calendar.isDateInToday(day)

                    Text("\(calendar.component(.day, from: day))")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Circle().fill(Color.clear))
                        .overlay(
                            Circle().stroke(
                                (isInRange || isStart || isEnd) ? Color.red : Color.clear,
                                lineWidth: 1.5
                            )
                        )
                        .overlay(
                            Circle().stroke(Color.blue, lineWidth: isToday ? 1.5 : 0)
                        )
                        .foregroundColor(.primary)
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

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        dateComponents([.year, .month], from: date).date!
    }
}
