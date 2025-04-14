import SwiftUI

struct YearCalendarView: View {
    let bookedRanges: [BookingRange]
    let calendar: Calendar

    @State private var currentYear: Int
    @Environment(\.dismiss) private var dismiss

    init(bookedRanges: [BookingRange], calendar: Calendar) {
        self.bookedRanges = bookedRanges
        var calendar = calendar
        calendar.firstWeekday = 2 // Monday as first weekday
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // Ensure correct weekday offset
        self.calendar = calendar

        let currentYear = calendar.component(.year, from: Date())
        self._currentYear = State(initialValue: currentYear)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    yearNavigationHeader
                        .padding(.top, 20)
                    monthsGrid
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Календарь на год")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var yearNavigationHeader: some View {
        HStack {
            Button(action: previousYear) {
                Image(systemName: "chevron.left")
                    .font(.title2.bold())
                    .padding(12)
            }

            Text(String(currentYear))
                .font(.system(size: 24, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.blue.opacity(0.1)))
                .padding(.horizontal, 20)

            Button(action: nextYear) {
                Image(systemName: "chevron.right")
                    .font(.title2.bold())
                    .padding(12)
            }
        }
        .padding(.horizontal, 20)
        .buttonStyle(.plain)
    }

    private var monthsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 20)], spacing: 20) {
            ForEach(1...12, id: \.self) { month in
                MonthView(
                    month: month,
                    year: currentYear,
                    bookedRanges: bookedRangesForYear(currentYear),
                    calendar: calendar
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.windowBackgroundColor))
                )
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

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

    // MARK: - Display Dates (42 ячейки, как в Apple Calendar)
    private var displayDates: [Date] {
        let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!

        // Первый день недели (0 = Sunday, 1 = Monday, ...)
        let weekdayOffset = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

        // MARK: - Previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth)!
        let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonth)!.count
        let startDay = max(previousMonthDays - weekdayOffset + 1, 1)
        let leadingDates: [Date] = startDay <= previousMonthDays
            ? (startDay...previousMonthDays).compactMap { day in
                calendar.date(from: DateComponents(
                    year: calendar.component(.year, from: previousMonth),
                    month: calendar.component(.month, from: previousMonth),
                    day: day
                ))
            }
            : []

        // MARK: - Current month
        let currentMonthRange = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let currentDates = currentMonthRange.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        }

        // MARK: - Next month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth)!
        let totalCount = leadingDates.count + currentDates.count
        let trailingCount = max(42 - totalCount, 0)
        let trailingDates = (1...trailingCount).compactMap { day in
            calendar.date(from: DateComponents(
                year: calendar.component(.year, from: nextMonth),
                month: calendar.component(.month, from: nextMonth),
                day: day
            ))
        }

        return leadingDates + currentDates + trailingDates
    }



    var body: some View {
        VStack(spacing: 12) {
            Text(monthName)
                .font(.headline.bold())
                .foregroundColor(.primary)
                .padding(.top, 8)

            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(displayDates, id: \.self) { date in
                    DayCellView(
                        date: date,
                        month: month,
                        calendar: calendar,
                        bookedRanges: bookedRanges
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL"
        if let date = calendar.date(from: DateComponents(year: year, month: month)) {
            return formatter.string(from: date).capitalized
        }
        return ""
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = calendar
        
        guard let symbols = formatter.shortStandaloneWeekdaySymbols else {
            return []
        }

        let first = calendar.firstWeekday - 1
        let reordered = Array(symbols[first...] + symbols[..<first])
        return reordered.map { String($0.prefix(1)).capitalized }
    }
}

struct DayCellView: View {
    let date: Date
    let month: Int
    let calendar: Calendar
    let bookedRanges: [BookingRange]

    var body: some View {
        let isCurrentMonth = calendar.component(.month, from: date) == month
        let isToday = calendar.isDateInToday(date)
        let isBooked = bookedRanges.contains { range in
            calendar.isDate(date, inSameDayAs: range.startDate) ||
            calendar.isDate(date, inSameDayAs: range.endDate) ||
            (range.startDate...range.endDate).contains(date)
        }

        return Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 12, weight: .medium))
            .frame(width: 24, height: 24)
            .background(
                Group {
                    if isToday {
                        Circle().fill(Color.blue.opacity(0.3))
                    } else if isBooked {
                        Circle().fill(Color.red.opacity(0.3))
                    }
                }
            )
            .foregroundColor(
                !isCurrentMonth ? .gray :
                isBooked ? .red :
                isToday ? .blue : .primary
            )
            .cornerRadius(12)
    }
}

import SwiftUI

struct YearCalendarSheet: View {
    @Environment(\.dismiss) private var dismiss
    let bookedRanges: [BookingRange]
    let calendar: Calendar

    var body: some View {
        VStack {
            // Кнопка закрытия в верхнем правом углу для macOS
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding()
            }
            
            YearCalendarView(bookedRanges: bookedRanges, calendar: calendar)
                .frame(minWidth: 1000, minHeight: 800)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
        }
        .background(Color(.windowBackgroundColor))
    }

}

