import SwiftUI

struct YearCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let bookedRanges: [BookingRange]
    let calendar: Calendar

    @State private var currentYear: Int

    init(bookedRanges: [BookingRange], calendar: Calendar) {
        self.bookedRanges = bookedRanges
        var calendar = calendar
        calendar.firstWeekday = 2 // Monday as first weekday
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
        .frame(minWidth: 920, minHeight: 640)
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
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
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
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 16
        ) {
            ForEach(1...12, id: \.self) { month in
                MonthView(
                    month: month,
                    year: currentYear,
                    bookedRanges: bookedRangesForYear(currentYear),
                    calendar: calendar
                )
                .frame(maxWidth: .infinity, minHeight: 190)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
    }

    private func bookedRangesForYear(_ year: Int) -> [BookingRange] {
        bookedRanges.filter { range in
            let startYear = calendar.component(.year, from: range.startDate)
            let endYear = calendar.component(.year, from: range.endDate)
            return startYear <= year && endYear >= year
        }
    }

    private func previousYear() {
        currentYear -= 1
    }

    private func nextYear() {
        currentYear += 1
    }
}

// MARK: - Month View
extension YearCalendarView {
    struct MonthView: View {
        let month: Int
        let year: Int
        let bookedRanges: [BookingRange]
        let calendar: Calendar

        private var displayDates: [Date] {
            let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
            let weekdayOffset = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7

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

            let currentMonthRange = calendar.range(of: .day, in: .month, for: firstOfMonth)!
            let currentDates = currentMonthRange.compactMap { day in
                calendar.date(from: DateComponents(year: year, month: month, day: day))
            }

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
            VStack(spacing: 10) {
                Text(monthName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 2) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 3) {
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
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
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
}

// MARK: - Day Cell View
extension YearCalendarView {
    struct DayCellView: View {
        let date: Date
        let month: Int
        let calendar: Calendar
        let bookedRanges: [BookingRange]

        init(date: Date, month: Int, calendar: Calendar, bookedRanges: [BookingRange]) {
            self.date = date
            self.month = month
            var localCalendar = calendar
            localCalendar.timeZone = TimeZone.current
            self.calendar = localCalendar
            self.bookedRanges = bookedRanges
        }

        var body: some View {
            let isCurrentMonth = calendar.component(.month, from: date) == month
            let normalizedDate = calendar.startOfDay(for: date)
            let isToday = calendar.isDateInToday(date)

            let matchingRange = bookedRanges.first { range in
                let start = calendar.startOfDay(for: range.startDate)
                let end = calendar.startOfDay(for: range.endDate)
                return (start...end).contains(normalizedDate)
            }

            let isBooked = matchingRange != nil

            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 20, height: 20)
                .background(
                    isToday
                        ? Color.blue.opacity(0.15).clipShape(Circle())
                        : nil
                )
                .overlay(
                    Circle().stroke(
                        isBooked ? Color.red :
                        isToday ? Color.blue : Color.clear,
                        lineWidth: isBooked || isToday ? 1.5 : 0
                    )
                )
                .foregroundColor(
                    isBooked && !isCurrentMonth ? .gray.opacity(0.5) :
                    isBooked ? .red :
                    isCurrentMonth ? .primary : .gray.opacity(0.5)
                )
        }
    }
}

// MARK: - Sheet Wrapper
struct YearCalendarSheet: View {
    let bookedRanges: [BookingRange]
    let calendar: Calendar

    var body: some View {
        YearCalendarView(bookedRanges: bookedRanges, calendar: calendar)
    }
}
